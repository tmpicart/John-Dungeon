extends Node

## Headless regression probe for the hybrid-routing magic missile. Run:
## Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/missile_probe.tscn
## Exits 0 on pass, 1 on failure. A real missile scene is flown against a stub
## player body on a synthetic baked room. The stages cover the untouched direct
## arc (contact kill on a clear lane), cover rounding (the missile crosses a
## walled column through its open rows and converges on the shadowed stub
## instead of dying on the wall), and convergence while the stub drifts behind
## cover (repath while blocked).

const CELL_SIZE := 16
const ROOM_COLUMNS := 16
const ROOM_ROWS := 10
const FRAMES_TO_SETTLE := 3
const MISSILE_SCENE := "res://entities/projectiles/magic_missile.tscn"
const STUB_SCRIPT := "res://tests/stub_player_body.gd"
## Wall column rows: the column leaves rows 0 and 8-9 open so the mesh stays
## connected around its ends (a full-height wall disconnects the halves and
## no path exists to find).
const WALL_COLUMN := 8
const WALL_FIRST_ROW := 1
const WALL_LAST_ROW := 7
const SPAWN := Vector2(2.5, 5.5)
const TARGET := Vector2(13.5, 5.5)
const CONTACT_BUDGET := 10.0
const ROUTE_BUDGET := 14.0

var _failures := 0
var _completed := false
var _log: FileAccess
var _floor_layer: TileMapLayer
var _walls_layer: TileMapLayer


func _ready() -> void:
	var result_path := ProjectSettings.globalize_path("res://missile_probe_result.txt")
	_log = FileAccess.open(result_path, FileAccess.WRITE)
	_tee("missile_probe: start")
	await _run()
	_check(_completed, "probe reached the end of the stage list")
	_tee("missile_probe: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	_log.close()
	get_tree().quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		_tee("  ok   %s" % label)
	else:
		_failures += 1
		_tee("  FAIL %s" % label)


func _tee(line: String) -> void:
	print(line)
	if _log != null:
		_log.store_line(line)


func _run() -> void:
	_build_room()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var nav_layer: TileMapLayer = NavBaker.bake(self)
	_check(nav_layer != null, "bake produced the GeneratedNav layer")
	if nav_layer == null:
		return
	for i in FRAMES_TO_SETTLE:
		await get_tree().physics_frame

	await _stage_clear_lane_contact()
	_stage_build_wall()
	await get_tree().physics_frame
	NavBaker.bake(self)
	for i in FRAMES_TO_SETTLE:
		await get_tree().physics_frame
	await _stage_cover_rounding_prep()
	await _stage_cover_rounding()
	await _stage_drift_behind_cover()
	_completed = true


## Logs the exact route query the missile will make after the wall bake: the
## clamped endpoints and the raw server path. A 2-point path means the mesh
## has no hole; a multi-point path names the corridor the missile was given.
func _log_baked_path() -> void:
	var map := get_viewport().get_world_2d().get_navigation_map()
	var from := NavigationServer2D.map_get_closest_point(map, SPAWN * CELL_SIZE)
	var to := NavigationServer2D.map_get_closest_point(map, TARGET * CELL_SIZE)
	_tee("    clamped endpoints: from %s to %s" % [from, to])
	_tee("    raw server path: %s"
			% str(NavigationServer2D.map_get_path(map, from, to, false)))


## Shared tail of the wall stages: settle frames after the second bake, then
## the mesh inspection.
func _stage_cover_rounding_prep() -> void:
	NavBaker.bake(self)
	for i in FRAMES_TO_SETTLE:
		await get_tree().physics_frame
	_log_baked_path()


## Direct arcs are untouched: on a clear lane the missile homes in and dies on
## the stub body, exactly as before routing existed.
func _stage_clear_lane_contact() -> void:
	var stub := _spawn_stub(TARGET)
	var outcome := await _fly(_spawn_missile(SPAWN), stub, CONTACT_BUDGET)
	_check(outcome.freed, "clear-lane direct arc ends on contact")
	var label := "direct arc reached the stub (min %.1f px)" % outcome.min_distance
	_check(outcome.min_distance < 14.0, label)
	await _clear_stage_actors(stub)


## Cover rounding: a straight flight dies on the wall column; the routed
## missile crosses the column's open rows and converges on the shadowed stub.
## Crossing while alive proves the route — the wall is physical, and touching
## it frees the missile.
func _stage_cover_rounding() -> void:
	var stub := _spawn_stub(TARGET)
	var outcome := await _fly(_spawn_missile(SPAWN), stub, ROUTE_BUDGET)
	_check(outcome.crossed, "missile rounded the cover column")
	var label := "routed missile closed on stub (min %.1f px)" % outcome.min_distance
	_check(outcome.min_distance < 20.0, label)
	_check(outcome.freed, "routed volley ended on contact")
	_log_flight(outcome)
	await _clear_stage_actors(stub)


## Repath while blocked: the stub strafes behind the wall mid-flight and the
## missile still converges — the loaded path is re-queried, not abandoned.
func _stage_drift_behind_cover() -> void:
	var stub := _spawn_stub(TARGET)
	var outcome := await _fly(_spawn_missile(SPAWN), stub, ROUTE_BUDGET, _drift)
	var label := "drifting stub was still rounded (min %.1f px)" % outcome.min_distance
	_check(outcome.min_distance < 24.0, label)
	_log_flight(outcome)
	await _clear_stage_actors(stub)


## Flies one missile until freed or the budget runs out, sampling validity,
## wall crossing and closest approach per physics frame.
func _fly(missile: Node2D, stub: Node2D, budget: float,
		drift: Callable = Callable()) -> Dictionary:
	var crossed := false
	var min_distance := INF
	var wall_x := (WALL_COLUMN + 1) * CELL_SIZE
	var clock := 0.0
	var frame := 0
	var last_pos: Vector2 = missile.global_position
	var samples: Array[String] = []
	while clock < budget:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		frame += 1
		if drift.is_valid():
			drift.call(clock, stub)
		if not is_instance_valid(missile):
			return {
				"freed": true, "crossed": crossed, "min_distance": min_distance,
				"end_pos": last_pos, "samples": samples,
			}
		last_pos = missile.global_position
		if frame % 15 == 0:
			var points: PackedVector2Array = missile.get("_route_points")
			samples.append("t=%.1f (%.0f,%.0f) r=%s i=%s p=%s" % [clock,
					missile.global_position.x, missile.global_position.y,
					str(missile.get("_routing")), str(missile.get("_route_index")),
					str(points)])
		min_distance = minf(min_distance,
				missile.global_position.distance_to(stub.global_position))
		crossed = crossed or missile.global_position.x > wall_x
	if is_instance_valid(missile):
		missile.queue_free()
	return {
		"freed": false, "crossed": crossed, "min_distance": min_distance,
		"end_pos": last_pos, "samples": samples,
	}


func _log_flight(outcome: Dictionary) -> void:
	var end_pos: Vector2 = outcome.end_pos
	_tee("    flight end (%.0f, %.0f), min %.1f px"
			% [end_pos.x, end_pos.y, outcome.min_distance])
	for sample in outcome.samples:
		_tee("    %s" % sample)


## Strafes the stub behind the wall so the loaded route goes stale mid-flight.
func _drift(clock: float, stub: Node2D) -> void:
	stub.global_position = TARGET * CELL_SIZE + Vector2(0.0, sin(clock * 2.0) * 48.0)


func _build_room() -> void:
	var tile_set := _build_plain_tile_set()
	_floor_layer = _make_layer("Floor", tile_set, true)
	_walls_layer = _make_layer("Walls", tile_set, false)
	# Ship stack: floor art never collides even though the shared synthetic
	# tile carries the blocker polygon for the Walls layer.
	_floor_layer.collision_enabled = false
	for x in ROOM_COLUMNS:
		for y in ROOM_ROWS:
			_floor_layer.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)


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
	# The bake carves Walls cells through their tile physics (the ship
	# semantic; physics-free painted atoms are the doorway-threshold
	# exception), so the synthetic blocker tile carries the full-cell polygon.
	# The source must join the TileSet before tile physics are set: TileData
	# sizes its physics layers through the owning TileSet.
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1 << 2)
	var source := TileSetAtlasSource.new()
	var image := Image.create_empty(CELL_SIZE, CELL_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = Vector2i(CELL_SIZE, CELL_SIZE)
	source.create_tile(Vector2i.ZERO)
	tile_set.add_source(source, 0)
	var tile_data: TileData = source.get_tile_data(Vector2i.ZERO, 0)
	tile_data.set_collision_polygons_count(0, 1)
	tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-CELL_SIZE / 2.0, -CELL_SIZE / 2.0),
		Vector2(-CELL_SIZE / 2.0, CELL_SIZE / 2.0),
		Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0),
		Vector2(CELL_SIZE / 2.0, -CELL_SIZE / 2.0),
	]))
	return tile_set


func _spawn_stub(at: Vector2) -> CharacterBody2D:
	var stub: CharacterBody2D = load(STUB_SCRIPT).new()
	stub.add_to_group("Player")
	add_child(stub)
	stub.global_position = at * CELL_SIZE
	return stub


func _spawn_missile(at: Vector2) -> Node2D:
	var missile: Node2D = load(MISSILE_SCENE).instantiate()
	add_child(missile)
	missile.global_position = at * CELL_SIZE
	return missile


func _clear_stage_actors(stub: Node2D) -> void:
	stub.queue_free()
	await get_tree().physics_frame


func _stage_build_wall() -> void:
	for y in range(WALL_FIRST_ROW, WALL_LAST_ROW + 1):
		_walls_layer.set_cell(Vector2i(WALL_COLUMN, y), 0, Vector2i.ZERO)
	var wall_body := StaticBody2D.new()
	wall_body.collision_layer = 1 << 2
	wall_body.collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(
			CELL_SIZE, (WALL_LAST_ROW - WALL_FIRST_ROW + 1) * CELL_SIZE)
	shape_node.shape = shape
	wall_body.add_child(shape_node)
	add_child(wall_body)
	wall_body.position = Vector2(
			(WALL_COLUMN + 0.5) * CELL_SIZE,
			(WALL_FIRST_ROW + (WALL_LAST_ROW - WALL_FIRST_ROW + 1) / 2.0) * CELL_SIZE)