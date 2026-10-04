extends Node

## Headless regression probe for the practice range's runtime navmesh. Run:
## Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/level_nav_probe.tscn
## Loads levels/test_room.tscn, lets its own main-scene bake run, then checks
## that the mesh routes from the archer spawn to the west-side targets (gap
## mouth, lower-west pocket, west strip) and that a disc walker reaches the
## lower-west pocket through the live physics. Also reports the baked region
## geometry, an obstruction-cause map of the west wall area, NPC carve facts
## (foot body carved, prompt zone walkable), and a doorway audit: cell maps
## for every mouth, each door's passage-link endpoints measured against the
## live mesh, the opened key door bridging route and walker body through its
## mouth, and bare-mouth facts for the north passage. Instrument-health
## or route failures exit 1.

const ROOM_SCENE := "res://levels/test_room.tscn"
const ARCHER_SPAWN := Vector2(214, 63)
## On the mesh east of the gap chest: the chest's real footprint carve ends
## just east of x=91 at this row, so the old (88, 104) point sat off-mesh.
const GAP_MOUTH := Vector2(96, 104)
const WEST_POCKET := Vector2(24, 140)
const WEST_STRIP := Vector2(24, 40)
const WEST_EXIT := Vector2(-6, 95)
## Solid annex floor west of the key door: the open-door crossing target
## (WEST_EXIT sits at the slab face, inside the baked door gap).
const ANNEX_POINT := Vector2(-88, 96)
## Mouth of the doorless north passage (level-authoring facts; no route
## target exists beyond it).
const NORTH_PASSAGE := Vector2(144, 8)
const NORTH_PASSAGE_INNER := Vector2(144, 24)
## Endpoint-to-mesh tolerance for a usable passage link: an off-mesh
## endpoint adds no pathfinding edge.
const LINK_REACH_MAX := 2.0
## Cell window printed around the west wall: position is the top-left cell,
## size the column/row count.
const MAP_WINDOW := Rect2i(-6, -2, 21, 16)
const GAP_DETAIL_COLUMNS: Array[int] = [-5, -4, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7]
## Physics masks: Environment blockers (walls, props, chests, NPC foot
## bodies), default characters.
const BLOCKER_MASK := 1 << 2
const CHARACTER_MASK := 1
## Cause-map approximation: a body whose collision reaches within this radius
## of a cell center is reported as the cell's obstruction cause; the bake
## itself carves bodies at their real footprint + NavBaker.AGENT_RADIUS.
const CLAIM_RADIUS := 12.0
const CLAIM_MASK := BLOCKER_MASK
const REGION_TIMEOUT_FRAMES := 240
const SETTLE_FRAMES := 5
## Clearance-sized disc, a hair over the nav clearance: stricter than the
## enemies' 5px feet discs, so a walker pass implies every body fits.
const WALKER_RADIUS := 7.14
const WALKER_SPEED := 42.0
const WALKER_TIME_BUDGET := 25.0
const WALKER_STALL_SECONDS := 1.0
const WALKER_ARRIVAL_DISTANCE := 12.0
const WALKER_LOG_EVERY_FRAMES := 45
## Reference export from the archer's EnemyChase for the drop-distance table.
const REFERENCE_CHASE_DROP := 300.0

var _failures := 0
var _completed := false
var _log: FileAccess


func _ready() -> void:
	_log = FileAccess.open("res://level_nav_probe_result.txt", FileAccess.WRITE)
	await _run()
	if not _completed:
		# A script error aborts the coroutine without failing a check; a
		# truncated run must count as an instrument failure, never a pass.
		_check(false, "probe ran to completion (aborted mid-run)")
	if _failures > 0:
		_tee("LEVEL NAV PROBE: %d instrument failure(s)" % _failures)
		_log.close()
		get_tree().quit(1)
	else:
		_tee("LEVEL NAV PROBE: instrument healthy (findings above)")
		_log.close()
		get_tree().quit(0)


func _tee(message: String) -> void:
	print(message)
	_log.store_line(message)


func _check(condition: bool, test_name: String) -> void:
	if condition:
		_tee("  OK: " + test_name)
	else:
		_failures += 1
		_tee("  BROKEN: " + test_name)


func _run() -> void:
	var packed: PackedScene = load(ROOM_SCENE)
	_check(packed != null, "room scene loads")
	if packed == null:
		return
	var room: Node2D = packed.instantiate()
	add_child(room)
	# The archer runs its state machine during the probe; removing it keeps
	# the walker passes deterministic (its body would be a mask-7 obstacle).
	var archer := room.get_node_or_null("Arcane_Archer")
	if archer != null:
		archer.queue_free()
	# Same for the player: it idles at (136, 80) on the spawn->pocket
	# corridor and would stall the mask-7 walker on contact.
	var player := room.get_node_or_null("Character")
	if player != null:
		player.queue_free()

	var region := await _wait_for_region(room)
	_check(region != null, "bake produced GeneratedNavRegion within timeout")
	if region == null:
		return
	for i in SETTLE_FRAMES:
		await get_tree().physics_frame
	var map: RID = room.get_world_2d().navigation_map
	# Region-to-map registration lands on a later sync frame than the region
	# node's creation, and queries before it return an empty map. Wait until
	# the mesh answers at the spawn point instead of a fixed frame count.
	var mesh_ready := false
	for i in REGION_TIMEOUT_FRAMES:
		var closest := NavigationServer2D.map_get_closest_point(map, ARCHER_SPAWN)
		if closest.distance_to(ARCHER_SPAWN) <= 2.0:
			mesh_ready = true
			break
		await get_tree().physics_frame
	_check(mesh_ready, "merged mesh live on the map at the spawn point")

	var floor_layer := _find_layer(room, "Floor")
	var walls_layer := _find_layer(room, "Walls")
	var obstacles_layer := _find_layer(room, "Obstacles")
	var nav_layer := _find_layer(room, NavBaker.GENERATED_LAYER_NAME)
	_check(floor_layer != null, "Floor layer found")
	_check(nav_layer != null, "GeneratedNav layer found")
	if floor_layer == null or nav_layer == null:
		return
	var space := room.get_world_2d().direct_space_state

	_report_region(region, floor_layer)
	_report_server_state(region, map)
	_report_nav_islands(nav_layer)
	_print_map(floor_layer, walls_layer, obstacles_layer, nav_layer, space)
	_print_gap_detail(floor_layer, walls_layer, obstacles_layer, space)

	_tee("")
	_tee("== path queries (archer spawn -> west targets) ==")
	# Beyond the closed key door the mesh must stay severed; the open-door
	# stage below reroutes it through the door's production open flow.
	_check(not _report_path(map, ARCHER_SPAWN, WEST_EXIT),
			"mesh stays severed beyond the closed key door")
	_check(_report_path(map, ARCHER_SPAWN, GAP_MOUTH),
			"mesh routes spawn -> gap mouth")
	_check(_report_path(map, ARCHER_SPAWN, WEST_POCKET),
			"mesh routes spawn -> lower-west pocket")
	_check(_report_path(map, ARCHER_SPAWN, WEST_STRIP),
			"mesh routes spawn -> west strip")
	_report_path(map, WEST_POCKET, ARCHER_SPAWN)

	_tee("")
	_tee("== NPC carve facts (blacksmith foot body + prompt zone) ==")
	var blacksmith := room.get_node_or_null("Blacksmith")
	if blacksmith != null:
		var body_point: Vector2 = blacksmith.global_position + Vector2(0, -2)
		var prompt_point: Vector2 = blacksmith.global_position + Vector2(0, 13)
		var body_gap := body_point.distance_to(
				NavigationServer2D.map_get_closest_point(map, body_point))
		var prompt_gap := prompt_point.distance_to(
				NavigationServer2D.map_get_closest_point(map, prompt_point))
		_tee("  body point %s -> mesh %.1f px | prompt point %s -> mesh %.1f px" % [
				body_point, body_gap, prompt_point, prompt_gap])
		_check(body_gap >= 10.0,
				"NPC foot body carved at its real capsule (mesh %.1f px away)" % body_gap)
		_check(prompt_gap <= 3.0,
				"prompt zone stays walkable (mesh %.1f px away)" % prompt_gap)
	else:
		_check(false, "blacksmith present for carve checks")

	_tee("")
	_tee("== chase-drop table (reference drop = %.0f px) ==" % REFERENCE_CHASE_DROP)
	for target in [GAP_MOUTH, WEST_POCKET, WEST_STRIP, WEST_EXIT]:
		_tee("  spawn -> %s: euclidean %.1f px" % [target, ARCHER_SPAWN.distance_to(target)])

	var blocker_mask_label := BLOCKER_MASK
	_tee("")
	_tee("== walker: spawn -> lower-west pocket, walls/props mask (%d) ==" % blocker_mask_label)
	_check((await _walk_route(room, ARCHER_SPAWN, WEST_POCKET, BLOCKER_MASK)) == "reached",
			"walker reaches lower-west pocket (walls/props mask)")
	var enemy_mask := CHARACTER_MASK | 2 | BLOCKER_MASK
	_tee("")
	_tee("== walker: spawn -> lower-west pocket, full enemy mask (%d) ==" % enemy_mask)
	_check((await _walk_route(room, ARCHER_SPAWN, WEST_POCKET, enemy_mask)) == "reached",
			"walker reaches lower-west pocket (full enemy mask)")

	_tee("")
	_tee("== west key door: production open flow ==")
	var key_door := room.get_node_or_null("Environment/KeyDoor")
	_check(key_door != null, "key door present at the west exit")
	if key_door != null:
		var door_link: NavigationLink2D = key_door.get_node_or_null("PassageLink")
		_check(door_link != null and not door_link.enabled,
				"closed key door ships a disabled passage link")
		var door_animation: AnimationPlayer = key_door.get_node("AnimationPlayer")
		door_animation.play("open")
		await door_animation.animation_finished
		for i in SETTLE_FRAMES:
			await get_tree().physics_frame
		_check(door_link != null and door_link.enabled,
				"open flow arms the passage link")
		_report_path(map, ARCHER_SPAWN, WEST_EXIT)
		await _audit_doorways(map, room, space, floor_layer, walls_layer,
				obstacles_layer, nav_layer)

	_completed = true
	room.queue_free()
	await get_tree().physics_frame


func _wait_for_region(room: Node2D) -> NavigationRegion2D:
	for i in REGION_TIMEOUT_FRAMES:
		await get_tree().physics_frame
		var region: NavigationRegion2D = room.get_node_or_null(NodePath(NavBaker.GENERATED_REGION_NAME))
		if region != null:
			return region
	return null


## Server-vs-node state at query time: separates "region never reached the
## server" from "map identity mismatch" when path queries come back empty.
func _report_server_state(region: NavigationRegion2D, map: RID) -> void:
	_tee("")
	_tee("== server state at query time ==")
	_tee("  regions on query map: %d | region node bound to query map: %s" % [
		NavigationServer2D.map_get_regions(map).size(),
		region.get_navigation_map() == map,
	])
	_tee("  region RID valid: %s | node polygons: %d" % [
		region.get_rid() != RID(),
		region.navigation_polygon.get_polygon_count() if region.navigation_polygon != null else -1,
	])


func _find_layer(root: Node, layer_name: String) -> TileMapLayer:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			if child is TileMapLayer and child.name == layer_name:
				return child
			stack.append(child)
	return null


func _report_region(region: NavigationRegion2D, floor_layer: TileMapLayer) -> void:
	_tee("")
	_tee("== baked region ==")
	var poly := region.navigation_polygon
	_check(poly != null, "region carries a NavigationPolygon")
	if poly == null:
		return
	var vertices := poly.get_vertices()
	_check(vertices.size() > 0, "region has baked vertices (%d)" % vertices.size())
	_tee("  floor used_rect (cells): %s" % floor_layer.get_used_rect())
	var polygon_count := poly.get_polygon_count()
	_tee("  polygons: %d, total vertices: %d" % [polygon_count, vertices.size()])
	for i in polygon_count:
		var indices := poly.get_polygon(i)
		var aabb := Rect2(vertices[indices[0]], Vector2.ZERO)
		for j in indices.size():
			aabb = aabb.expand(vertices[indices[j]])
		_tee("    poly %d: %d verts, bounds %s" % [i, indices.size(), aabb])


func _report_nav_islands(nav_layer: TileMapLayer) -> void:
	var visited := {}
	var sizes: Array[int] = []
	for cell in nav_layer.get_used_cells():
		if visited.has(cell):
			continue
		var stack: Array[Vector2i] = [cell]
		visited[cell] = true
		var size := 0
		var offsets: Array[Vector2i] = [
			Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
		]
		while not stack.is_empty():
			var current: Vector2i = stack.pop_back()
			size += 1
			for offset in offsets:
				var next := current + offset
				if not visited.has(next) and nav_layer.get_cell_source_id(next) != -1:
					visited[next] = true
					stack.append(next)
		sizes.append(size)
	sizes.sort()
	sizes.reverse()
	_tee("  painted-cell islands (8-neighbour): %s" % [sizes])


func _print_map(
		floor_layer: TileMapLayer,
		walls_layer: TileMapLayer,
		obstacles_layer: TileMapLayer,
		nav_layer: TileMapLayer,
		space: PhysicsDirectSpaceState2D) -> void:
	_tee("")
	_tee("== west-window cell map (rows = world y of cell centers) ==")
	_tee("  legend: '#' wall/obstacle paint   'P' blocker body claim   'n' body-on-walkable")
	_tee("          '.' walkable   ' ' no floor paint   '!' walkable but unpainted")
	var blockers: Array[TileMapLayer] = []
	if walls_layer != null:
		blockers.append(walls_layer)
	if obstacles_layer != null:
		blockers.append(obstacles_layer)
	_print_cell_window(MAP_WINDOW, floor_layer, blockers, nav_layer, space)


func _classify_cell(
		cell: Vector2i,
		floor_layer: TileMapLayer,
		blockers: Array[TileMapLayer],
		nav_layer: TileMapLayer,
		space: PhysicsDirectSpaceState2D) -> String:
	if floor_layer.get_cell_source_id(cell) == -1:
		return " "
	for layer in blockers:
		if layer.get_cell_source_id(cell) != -1:
			return "#"
	var center: Vector2 = floor_layer.to_global(floor_layer.map_to_local(cell))
	if not _probe_hits(space, center, CLAIM_MASK).is_empty():
		return "P"
	if nav_layer.get_cell_source_id(cell) == -1:
		return "!"
	if not _probe_hits(space, center, CHARACTER_MASK).is_empty():
		return "n"
	return "."


func _print_gap_detail(
		floor_layer: TileMapLayer,
		walls_layer: TileMapLayer,
		obstacles_layer: TileMapLayer,
		space: PhysicsDirectSpaceState2D) -> void:
	_tee("")
	_tee("== left-wall column detail (paint + collider names) ==")
	for x in GAP_DETAIL_COLUMNS:
		for y in range(MAP_WINDOW.position.y, MAP_WINDOW.end.y):
			var cell := Vector2i(x, y)
			if floor_layer.get_cell_source_id(cell) == -1:
				continue
			var center: Vector2 = floor_layer.to_global(floor_layer.map_to_local(cell))
			var causes: Array[String] = []
			if walls_layer != null and walls_layer.get_cell_source_id(cell) != -1:
				causes.append("walls-paint")
			if obstacles_layer != null and obstacles_layer.get_cell_source_id(cell) != -1:
				causes.append("obstacles-paint")
			for hit in _probe_hits(space, center, CLAIM_MASK):
				causes.append("claim:" + _hit_label(hit))
			if not causes.is_empty():
				_tee("  cell %s @ %.0f,%.0f: %s" % [cell, center.x, center.y, ", ".join(causes)])


func _probe_hits(space: PhysicsDirectSpaceState2D, at: Vector2, mask: int) -> Array:
	var probe := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = CLAIM_RADIUS
	probe.shape = shape
	probe.collision_mask = mask
	probe.transform = Transform2D(0.0, at)
	return space.intersect_shape(probe, 8)


func _hit_label(hit: Dictionary) -> String:
	var collider: Object = hit["collider"]
	var label: String = str(collider.name)
	var parent: Node = collider.get_parent()
	if parent != null:
		label = str(parent.name) + "/" + label
	return label


func _report_path(map: RID, from: Vector2, to: Vector2) -> bool:
	var path := NavigationServer2D.map_get_path(map, from, to, true)
	var closest := NavigationServer2D.map_get_closest_point(map, to)
	var end_point := path[path.size() - 1] if path.size() > 0 else from
	_tee("  %s -> %s" % [from, to])
	_tee("    euclidean %.1f | path points %d, length %.1f" % [
		from.distance_to(to), path.size(), _path_length(path)])
	_tee("    end %s | end-vs-target %.1f px | target-to-mesh %.1f px" % [
		end_point, to.distance_to(end_point), to.distance_to(closest)])
	if path.size() <= 10:
		_tee("    waypoints: %s" % [path])
	else:
		_tee("    waypoints[0..4]: %s ... [%d more]" % [path.slice(0, 5), path.size() - 5])
	return to.distance_to(end_point) <= 2.0


func _path_length(path: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i - 1].distance_to(path[i])
	return total


func _walk_route(room: Node2D, from: Vector2, to: Vector2, mask: int) -> String:
	var walker := CharacterBody2D.new()
	walker.collision_layer = 0
	walker.collision_mask = mask
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = WALKER_RADIUS
	shape_node.shape = shape
	walker.add_child(shape_node)
	var agent := NavigationAgent2D.new()
	agent.path_desired_distance = NavBaker.WAYPOINT_REACH_DISTANCE
	walker.add_child(agent)
	room.add_child(walker)
	walker.global_position = from
	agent.target_position = to

	var outcome := "budget-exhausted"
	var elapsed := 0.0
	var stalled_clock := 0.0
	var last_distance := from.distance_to(to)
	while elapsed < WALKER_TIME_BUDGET:
		await get_tree().physics_frame
		var delta := get_physics_process_delta_time()
		elapsed += delta
		# get_next_path_position() also drives the agent's lazy path update.
		var next := agent.get_next_path_position()
		var to_next := next - walker.global_position
		if to_next.length() > 1.0:
			walker.velocity = to_next.normalized() * WALKER_SPEED
		else:
			walker.velocity = Vector2.ZERO
		walker.move_and_slide()

		var distance := walker.global_position.distance_to(to)
		if distance <= WALKER_ARRIVAL_DISTANCE:
			outcome = "reached"
			break
		# The stall gate arms only on contact plus no progress: a real snag is
		# a body pressed against geometry and not moving, not a slow phase.
		if last_distance - distance > 0.05:
			stalled_clock = 0.0
		elif walker.get_slide_collision_count() > 0:
			stalled_clock += delta
			if stalled_clock >= WALKER_STALL_SECONDS:
				outcome = "stalled-on-contact"
				break
		else:
			stalled_clock = 0.0
		last_distance = distance
		if Engine.get_physics_frames() % WALKER_LOG_EVERY_FRAMES == 0:
			_tee("    t=%.2f pos=%s steer=%s idx=%d/%d fin=%s contacts=%d" % [
				elapsed, walker.global_position, next,
				agent.get_current_navigation_path_index(),
				agent.get_current_navigation_path().size(),
				agent.is_navigation_finished(),
				walker.get_slide_collision_count()])

	_tee("  mask %d: %s after %.2fs at %s (%.1f px short)" % [
		mask, outcome, elapsed, walker.global_position,
		walker.global_position.distance_to(to)])
	walker.queue_free()
	await get_tree().physics_frame
	return outcome


## Every opening audited on the live map: per-mouth cell windows, each door's
## link endpoint reach, the opened west doorway's route+body crossing, and
## bare-mouth facts for the north passage (level-authoring side).
func _audit_doorways(
		map: RID,
		room: Node2D,
		space: PhysicsDirectSpaceState2D,
		floor_layer: TileMapLayer,
		walls_layer: TileMapLayer,
		obstacles_layer: TileMapLayer,
		nav_layer: TileMapLayer) -> void:
	_tee("")
	_tee("== doorway audit ==")
	var blockers: Array[TileMapLayer] = []
	if walls_layer != null:
		blockers.append(walls_layer)
	if obstacles_layer != null:
		blockers.append(obstacles_layer)
	_print_cell_window(Rect2i(-5, 3, 6, 6), floor_layer, blockers, nav_layer, space)
	_print_cell_window(Rect2i(5, -2, 6, 5), floor_layer, blockers, nav_layer, space)
	_print_cell_window(Rect2i(7, 10, 4, 5), floor_layer, blockers, nav_layer, space)
	for door_name in ["KeyDoor", "DoorRed", "DoorRed4"]:
		var usable := _report_link_reach(map, room, door_name)
		if door_name == "KeyDoor":
			_check(usable, "opened key door link endpoints sit on the mesh")
	_check(_report_path(map, ARCHER_SPAWN, ANNEX_POINT),
			"opened key door bridges the annex (route reaches the annex floor)")
	_check((await _walk_route(room, ARCHER_SPAWN, ANNEX_POINT,
			CHARACTER_MASK | 2 | BLOCKER_MASK)) == "reached",
			"enemy-size walker crosses the opened west doorway")
	_report_mouth(map, space, "north bare passage mouth", NORTH_PASSAGE)
	_report_mouth(map, space, "north bare passage inner lip", NORTH_PASSAGE_INNER)


## Classified-cell rows for one mouth's neighborhood (same legend as the
## west-window map).
func _print_cell_window(
		window: Rect2i,
		floor_layer: TileMapLayer,
		blockers: Array[TileMapLayer],
		nav_layer: TileMapLayer,
		space: PhysicsDirectSpaceState2D) -> void:
	for y in range(window.position.y, window.end.y):
		var row := ""
		for x in range(window.position.x, window.end.x):
			row += _classify_cell(Vector2i(x, y), floor_layer, blockers, nav_layer, space)
		var row_world_y: float = floor_layer.to_global(floor_layer.map_to_local(Vector2i(0, y))).y
		_tee("  %6.1f %s" % [row_world_y, row])


## Endpoint-to-mesh distances for one door's passage link; true when both
## endpoints sit on the live mesh (an off-mesh endpoint adds no edge).
func _report_link_reach(map: RID, room: Node2D, door_name: String) -> bool:
	var door := room.get_node_or_null("Environment/" + door_name)
	if door == null:
		_tee("  %s: absent" % door_name)
		return false
	var link: NavigationLink2D = door.get_node_or_null("PassageLink")
	if link == null:
		_tee("  %s: ships no PassageLink" % door_name)
		return false
	var start: Vector2 = link.to_global(link.start_position)
	var end: Vector2 = link.to_global(link.end_position)
	var start_gap := start.distance_to(NavigationServer2D.map_get_closest_point(map, start))
	var end_gap := end.distance_to(NavigationServer2D.map_get_closest_point(map, end))
	_tee("  %s link %s -> %s | start-to-mesh %.1f px | end-to-mesh %.1f px | enabled %s" % [
			door_name, start, end, start_gap, end_gap, link.enabled])
	return start_gap <= LINK_REACH_MAX and end_gap <= LINK_REACH_MAX


## Bare-mouth facts: blocker claims at the point plus the gap to the live
## mesh (0 px means the mesh reaches the wall line).
func _report_mouth(
		map: RID,
		space: PhysicsDirectSpaceState2D,
		label: String,
		at: Vector2) -> void:
	var claims: Array[String] = []
	for hit in _probe_hits(space, at, CLAIM_MASK):
		claims.append(_hit_label(hit))
	var gap := at.distance_to(NavigationServer2D.map_get_closest_point(map, at))
	var claim_text := ", ".join(claims) if not claims.is_empty() else "none"
	_tee("  %s @ %s -> mesh %.1f px | claims: %s" % [label, at, gap, claim_text])