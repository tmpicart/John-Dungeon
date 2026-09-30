extends Node

## Headless probe for the NavBaker runtime navmesh. Run:
## Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/nav_probe.tscn
## Exits 0 on pass, 1 on failure. Gates: walkable-cell painting, wall /
## obstacle exclusion, the prop's real-footprint carve, a route that curves
## around a wall line, and a capsule-sized follower walking it through
## physical blockers.

const CELL_SIZE := 16
const ROOM_SIZE := 8
const WALL_COLUMN := 4
const WALL_ROWS := [0, 1, 2, 3, 4, 5]
const OBSTACLE_CELL := Vector2i(2, 5)
const PROP_CELL := Vector2i(6, 1)
const START_CELL := Vector2i(0, 3)
const GOAL_CELL := Vector2i(7, 3)
## 64 cells minus 6 wall, 1 obstacle, 1 prop footprint.
const EXPECTED_COVERAGE := 56
const FRAMES_TO_SETTLE := 5
## Walker stage: an archer-like follower (the inscribed disc of its capsule)
## driven with the states' steering — get_next_path_position() every physics
## frame at NavBaker.WAYPOINT_REACH_DISTANCE — through physical blocker bodies.
const WALKER_RADIUS := 7.14
const WALKER_SPEED := 42.0
const WALKER_TIME_BUDGET := 12.0
const WALKER_STALL_SECONDS := 1.0
const WALKER_ARRIVAL_DISTANCE := 12.0
## Physics layer of the walker-stage blocker bodies (Environment), the
## Environment bit of NavBaker's exclusion mask.
const BLOCKER_MASK := 1 << 2

var _failures := 0
var _completed := false
var _log: FileAccess
var _floor_layer: TileMapLayer
var _walls_layer: TileMapLayer
var _obstacles_layer: TileMapLayer


func _ready() -> void:
	_log = FileAccess.open("res://nav_probe_result.txt", FileAccess.WRITE)
	await _run()
	if not _completed:
		# A script error aborts the coroutine without failing a check; a
		# truncated run must count as a failure, never a pass.
		_check(false, "probe ran to completion (aborted mid-run)")
	if _failures > 0:
		_tee("NAV PROBE FAILED: %d failure(s)" % _failures)
		_log.close()
		get_tree().quit(1)
	else:
		_tee("NAV PROBE PASSED")
		_log.close()
		get_tree().quit(0)


func _tee(message: String) -> void:
	print(message)
	_log.store_line(message)


func _check(condition: bool, test_name: String) -> void:
	if condition:
		_tee("  PASS: " + test_name)
	else:
		_failures += 1
		_tee("  FAIL: " + test_name)


func _run() -> void:
	_build_room()

	# Two physics frames flush the freshly added bodies into the space before
	# NavBaker's exclusion probes query it — the load-time convention too.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var nav_layer := NavBaker.bake(self)
	_check(nav_layer != null, "bake produced the GeneratedNav layer")
	if nav_layer == null:
		return

	for i in FRAMES_TO_SETTLE:
		await get_tree().physics_frame
	_check(_floor_layer.navigation_enabled == false, "floor art layer nav disabled")
	_check(nav_layer.navigation_enabled == false, "generated layer kept as visualization only")
	_check(nav_layer.visible and nav_layer.modulate.a == 0.0, "hidden via modulate, not visibility")
	_check(nav_layer.get_used_cells().size() == EXPECTED_COVERAGE,
			"coverage: %d cells painted (%d expected)"
			% [nav_layer.get_used_cells().size(), EXPECTED_COVERAGE])
	_check(nav_layer.get_cell_source_id(START_CELL) != -1, "walkable interior painted")
	_check(nav_layer.get_cell_source_id(Vector2i(WALL_COLUMN, 3)) == -1, "wall cells excluded")
	_check(nav_layer.get_cell_source_id(Vector2i(WALL_COLUMN, 6)) != -1, "wall gap stays walkable")
	_check(nav_layer.get_cell_source_id(OBSTACLE_CELL) == -1, "obstacle cells excluded")
	_check(nav_layer.get_cell_source_id(PROP_CELL) == -1, "prop footprint cell excluded")

	var region: NavigationRegion2D = get_node_or_null(NodePath(NavBaker.GENERATED_REGION_NAME))
	_check(region != null, "bake produced the merged nav region")
	if region != null:
		var poly := region.navigation_polygon
		_check(poly != null and poly.vertices.size() > 0, "region holds a baked polygon")
		_check(poly != null and poly.agent_radius == NavBaker.AGENT_RADIUS,
				"polygon baked with agent clearance")

	# NavigationAgent2D extends Node, not Node2D: it paths from its parent's
	# transform, so the start position lives on a holder node.
	var agent_holder := Node2D.new()
	agent_holder.position = _floor_layer.map_to_local(START_CELL)
	add_child(agent_holder)
	var agent := NavigationAgent2D.new()
	agent_holder.add_child(agent)
	agent.target_position = _floor_layer.map_to_local(GOAL_CELL)
	for i in FRAMES_TO_SETTLE:
		await get_tree().physics_frame
		# The agent's path updates lazily inside get_next_path_position();
		# without driving it the stored path stays empty no matter what the
		# map holds (techContext engine fact).
		agent.get_next_path_position()

	var path := agent.get_current_navigation_path()
	_check(path.size() >= 2, "a route exists around the wall")
	if path.size() < 2:
		# Diagnose the empty route: no map binding, no regions (bake or
		# polygon-registration failure), or regions present but the query
		# could not connect (connectivity failure).
		var agent_map: RID = agent.get_navigation_map()
		_check(agent_map != RID(), "agent bound to a navigation map")
		var region_count := NavigationServer2D.map_get_regions(agent_map).size()
		_check(region_count > 0, "navigation map has regions (%d)" % region_count)
		return
	var straight := float((GOAL_CELL.x - START_CELL.x) * CELL_SIZE)
	var length := 0.0
	for i in range(1, path.size()):
		length += path[i - 1].distance_to(path[i])
	_check(length > straight * 1.3,
			"route detours: %d px > %d px straight-line" % [int(length), int(straight * 1.3)])
	_check(_path_avoids_blocked_cells(path), "no waypoint enters a blocked cell")

	# Real-footprint carve regression guard: the nearest baked boundary sits
	# at prop radius + agent clearance (10px). A cell-claim bake would push
	# the boundary to the cell edge plus clearance (>= 15px).
	var prop_center: Vector2 = _floor_layer.map_to_local(PROP_CELL)
	var map: RID = get_viewport().get_world_2d().navigation_map
	var closest_point: Vector2 = NavigationServer2D.map_get_closest_point(map, prop_center)
	var clearance: float = closest_point.distance_to(prop_center)
	_check(clearance >= 9.0 and clearance <= 11.5,
			"prop carves at its footprint: %.1f px clearance (want 10 +/- slack)" % clearance)

	_spawn_blocker_bodies()
	var walker_result: Dictionary = await _walk_the_route()
	_check(walker_result["reached"], "walker reached the goal around the wall")
	_check(not walker_result["stalled"], "walker never stalled for over a second")
	_check(not walker_result["left_walkable"], "walker body stayed out of blocked cells")
	_completed = true


func _build_room() -> void:
	var tile_set := _build_plain_tile_set()
	_floor_layer = _make_layer("Floor", tile_set, true)
	_walls_layer = _make_layer("Walls", tile_set, false)
	_obstacles_layer = _make_layer("Obstacles", tile_set, false)
	for x in ROOM_SIZE:
		for y in ROOM_SIZE:
			_floor_layer.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
	for y in WALL_ROWS:
		_walls_layer.set_cell(Vector2i(WALL_COLUMN, y), 0, Vector2i.ZERO)
	_obstacles_layer.set_cell(OBSTACLE_CELL, 0, Vector2i.ZERO)

	var body := StaticBody2D.new()
	body.collision_layer = 1 << 2
	body.collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 3.0
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)
	body.position = _floor_layer.map_to_local(PROP_CELL)


func _make_layer(layer_name: String, tile_set: TileSet, nav_enabled: bool) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tile_set
	layer.navigation_enabled = nav_enabled
	add_child(layer)
	return layer


func _build_plain_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(CELL_SIZE, CELL_SIZE)
	var source := TileSetAtlasSource.new()
	var image := Image.create_empty(CELL_SIZE, CELL_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = Vector2i(CELL_SIZE, CELL_SIZE)
	source.create_tile(Vector2i.ZERO)
	tile_set.add_source(source, 0)
	return tile_set


func _path_avoids_blocked_cells(path: PackedVector2Array) -> bool:
	var blocked_cells: Array[Vector2i] = []
	for y in WALL_ROWS:
		blocked_cells.append(Vector2i(WALL_COLUMN, y))
	blocked_cells.append(OBSTACLE_CELL)
	var margin := CELL_SIZE / 2.0 - 1.0
	for point in path:
		for cell in blocked_cells:
			var center: Vector2 = _floor_layer.map_to_local(cell)
			if absf(point.x - center.x) < margin and absf(point.y - center.y) < margin:
				return false
	return true


## Physical blockers for the walker stage. Spawned after NavBaker.bake so
## their outlines cannot add bake obstruction (walls and the obstacle are
## already carved by their layers; the prop body exists since _build_room and
## its real outline is the carve).
func _spawn_blocker_bodies() -> void:
	for cell in _blocked_cells():
		if cell == PROP_CELL:
			continue
		var body := StaticBody2D.new()
		body.collision_layer = BLOCKER_MASK
		body.collision_mask = 0
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(CELL_SIZE, CELL_SIZE)
		shape_node.shape = shape
		body.add_child(shape_node)
		add_child(body)
		body.position = _floor_layer.map_to_local(cell)


## Drives a capsule-sized disc from the start cell to the goal with the same
## steering the enemy states use: get_next_path_position() every physics frame
## (lazy path update) at WAYPOINT_REACH_DISTANCE. Breaks early on arrival, a
## stall (snag), or leaving walkable space.
func _walk_the_route() -> Dictionary:
	var walker := CharacterBody2D.new()
	walker.collision_layer = 0
	walker.collision_mask = BLOCKER_MASK
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = WALKER_RADIUS
	shape_node.shape = shape
	walker.add_child(shape_node)
	var agent := NavigationAgent2D.new()
	agent.path_desired_distance = NavBaker.WAYPOINT_REACH_DISTANCE
	walker.add_child(agent)
	var goal: Vector2 = _floor_layer.map_to_local(GOAL_CELL)
	agent.target_position = goal
	walker.position = _floor_layer.map_to_local(START_CELL)
	add_child(walker)

	var result := {"reached": false, "stalled": false, "left_walkable": false}
	var elapsed := 0.0
	var stalled_clock := 0.0
	var last_distance := walker.global_position.distance_to(goal)
	while elapsed < WALKER_TIME_BUDGET:
		await get_tree().physics_frame
		var delta := get_physics_process_delta_time()
		elapsed += delta
		# get_next_path_position() also drives the agent's lazy path update.
		var next := agent.get_next_path_position()
		if Engine.get_physics_frames() % 30 == 0:
			_tee("    t=%.2f pos=%s steer=%s idx=%d/%d fin=%s vel=%s contacts=%d" % [
				elapsed, walker.global_position, next,
				agent.get_current_navigation_path_index(),
				agent.get_current_navigation_path().size(),
				agent.is_navigation_finished(), walker.velocity,
				walker.get_slide_collision_count()])
		var to_next := next - walker.global_position
		if to_next.length() > 1.0:
			walker.velocity = to_next.normalized() * WALKER_SPEED
		else:
			walker.velocity = Vector2.ZERO
		walker.move_and_slide()

		var distance := walker.global_position.distance_to(goal)
		if distance <= WALKER_ARRIVAL_DISTANCE:
			result["reached"] = true
			break
		# The stall gate arms only on contact plus no progress: a real snag is
		# a body pressed against geometry and not moving, not a slow phase.
		if last_distance - distance > 0.05:
			stalled_clock = 0.0
		elif walker.get_slide_collision_count() > 0:
			stalled_clock += delta
			if stalled_clock >= WALKER_STALL_SECONDS:
				result["stalled"] = true
				break
		else:
			stalled_clock = 0.0
		last_distance = distance
		if _in_blocked_cell(walker.global_position):
			result["left_walkable"] = true
			break
	return result


func _blocked_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in WALL_ROWS:
		cells.append(Vector2i(WALL_COLUMN, y))
	cells.append(OBSTACLE_CELL)
	cells.append(PROP_CELL)
	return cells


func _in_blocked_cell(point: Vector2) -> bool:
	for cell in _blocked_cells():
		var center: Vector2 = _floor_layer.map_to_local(cell)
		var dx := absf(point.x - center.x)
		var dy := absf(point.y - center.y)
		if dx < CELL_SIZE / 2.0 and dy < CELL_SIZE / 2.0:
			return true
	return false
