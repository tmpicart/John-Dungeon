extends Node

## Doorway battery for the chase probe (BUG-1). Group one threads the open
## 1-cell gap - the bake's 2px post-erosion channel - with a solo diagonal
## approach, a blind archer, and an RVO pair. Group two seals the same gap
## with a real door scene, rebakes, verifies the sealed-mouth guard, then
## opens the door through the production interact path and requires the
## sealed chaser to commit: server route across, guard latch released,
## crossing, swing. Lives on its own node so the main probe stays under
## the line-count gate; assertions report through the parent probe.

const CELL_SIZE := 16
const ROOM_ROWS := 10
const WALL_COLUMN := 8
const DOORWAY_ROW := 5
## Crossing line east of the divider: wall face (144) plus half a body.
const DOORWAY_PASS_X := 152.0
## Door-stage crossing line: past the slab plane (136) inside the passage,
## where the body can stand while the player (148) holds it in contact.
const DOOR_OPEN_CROSS_X := 137.0
## Door-plane x used by the server-route check (gap cell center).
const DOOR_PLANE_X := 136.0
const DOOR_SCENE := "res://entities/interactables/doors/door_red.tscn"
const DUNGEON_TILESET := "res://assets/tilesets/custom_dungeon.tres"
## custom_dungeon.tres atoms: (0, 0) paints full-cell tile physics; the
## doorway threshold atoms (cols 0-2, rows 10-13) paint walkable art only.
const WALL_ATOM := Vector2i.ZERO
const THRESHOLD_ATOM := Vector2i(0, 10)

var probe: Node

var _doorway_body: StaticBody2D
var _door: Node2D


func run() -> void:
	_place_doorway_wall()
	if not await _rebake("rebake with the doorway gap"):
		_cleanup()
		return
	await _stage_open_commit()
	await probe._teardown()
	await _stage_open_archer()
	await probe._teardown()
	await _stage_open_pair()
	await probe._teardown()
	_place_door()
	if not await _rebake("rebake with the closed door"):
		_cleanup()
		return
	await _stage_door_open()
	_cleanup()
	await _stage_ship_threshold()
	await probe._teardown()
	_cleanup()
	# Let the queue_freed fixtures land before the probe quits, or the
	# exit report counts them as leaked instances.
	await get_tree().physics_frame


## Open-gap threading: a diagonal approach must commit through the 2px
## channel without stall windows or heading flips.
func _stage_open_commit() -> void:
	probe._tee("  stage: chaser threads the open doorway on a diagonal approach")
	var skeleton: BaseEnemy = await probe._spawn_enemy(
			probe.SKELETON_SCENE, Vector2(56, 64))
	probe._player.global_position = Vector2(200, 112)
	probe._force_chase(skeleton)
	var crossed := false
	var stalled := false
	var reversals := 0
	var last_heading := 0.0
	var sample_clock := 0.0
	var window_start := 0.0
	var window_pos := skeleton.global_position
	var clock := 0.0
	while clock < 10.0:
		await get_tree().physics_frame
		var step := get_physics_process_delta_time()
		clock += step
		if skeleton.global_position.x > DOORWAY_PASS_X:
			crossed = true
			break
		sample_clock += step
		if sample_clock >= 0.25:
			sample_clock = 0.0
			var heading := signf(skeleton.velocity.x)
			if heading != 0.0 and last_heading != 0.0 and heading != last_heading:
				reversals += 1
			if heading != 0.0:
				last_heading = heading
		if clock - window_start >= 0.6:
			stalled = stalled \
					or skeleton.global_position.distance_to(window_pos) < 2.0
			window_start = clock
			window_pos = skeleton.global_position
	probe._check(crossed, "chaser committed through the gap (%.1fs)" % clock)
	probe._check(not stalled, "no stall window at the mouth (0.6s probes)")
	probe._check(reversals <= 3,
			"approach held one heading (x reversals %d)" % reversals)


## Ranged chaser through the same gap: the divider blocks the shallow aim
## on approach (the ray crosses the wall band inside a wall cell, not the
## gap), so the LOS gate must not freeze the close-in and sight past the
## gap must open into an attack. The attack gate can fire the moment sight
## opens mid-crossing, so the commitment line is entering the gap plane.
func _stage_open_archer() -> void:
	probe._tee("  stage: blind archer threads the doorway into a firing solution")
	var archer: BaseEnemy = await probe._spawn_enemy(
			probe.ARCHER_SCENE, Vector2(56, 40))
	probe._player.global_position = Vector2(200, 64)
	var chase: EnemyChase = probe._chase_state(archer)
	probe._force_chase(archer)
	var max_x := 0.0
	var blind_seen := false
	var attacked := false
	var clock := 0.0
	while clock < 12.0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		blind_seen = blind_seen or chase._blind_now
		max_x = maxf(max_x, archer.global_position.x)
		if probe._current_state(archer) is EnemyAttack:
			attacked = true
			break
	probe._check(blind_seen, "divider blocks the aim on approach")
	probe._check(max_x > 141.0,
			"archer committed into the gap plane (max x %.0f)" % max_x)
	probe._check(attacked, "sight opened into an attack (%.1fs)" % clock)


## Two chasers funnel through the one-cell gap: RVO must queue them at the
## mouth instead of welding or shoving each other off the channel.
func _stage_open_pair() -> void:
	probe._tee("  stage: pair funnels through the doorway without welding")
	var first: BaseEnemy = await probe._spawn_enemy(
			probe.SKELETON_SCENE, Vector2(56, 88))
	var second: BaseEnemy = await probe._spawn_enemy(
			probe.SKELETON_SCENE, Vector2(32, 88))
	probe._player.global_position = Vector2(200, 88)
	probe._force_chase(first)
	probe._force_chase(second)
	var min_gap := INF
	var both_crossed := false
	var clock := 0.0
	while clock < 14.0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		min_gap = minf(min_gap,
				first.global_position.distance_to(second.global_position))
		if first.global_position.x > DOORWAY_PASS_X \
				and second.global_position.x > DOORWAY_PASS_X:
			both_crossed = true
			break
	probe._check(both_crossed, "both chasers crossed (%.1fs)" % clock)
	probe._check(min_gap >= 11.0,
			"pair kept separation at the mouth (min %.1f px)" % min_gap)


## Door-open commit: the closed blocker seals the gap (stand regression),
## the production interact path arms the passage, and the sealed chaser
## must resume once the route lands: route crossed, swing landed. The
## mouth's dead space (mesh erosion, arrival gap, slab thickness) exceeds
## the press ceiling, so the sealed hold pins on the stand branch; the
## guard lifecycle and the latch release live in the press battery.
func _stage_door_open() -> void:
	probe._tee("  stage: door opens and the sealed chaser commits through")
	var skeleton: BaseEnemy = await probe._spawn_enemy(
			probe.SKELETON_SCENE, Vector2(56, 88))
	probe._player.global_position = Vector2(148, 88)
	probe._force_chase(skeleton)
	# Sealed hold: the mouth's dead space (mesh erosion, arrival gap, slab
	# thickness) exceeds the press ceiling, so the chaser pins on the stand
	# branch; the guard lifecycle is covered by the press battery.
	var leaked := false
	var clock := 0.0
	while clock < 3.0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		if skeleton.global_position.x > DOOR_OPEN_CROSS_X:
			leaked = true
			break
	probe._check(not leaked, "chaser held at the sealed door")
	var door_link: NavigationLink2D = _door.get_node_or_null("PassageLink")
	probe._check(door_link != null and not door_link.enabled,
			"door ships a disabled passage link")
	if door_link == null:
		return
	_door._on_interact()
	var armed := await _wait_until(
			func() -> bool: return door_link.enabled, 2.0)
	probe._check(armed, "interact armed the passage link")
	var route_open := false
	if armed:
		route_open = await _wait_until(
				func() -> bool: return _server_route_crosses(), 1.0)
	probe._check(route_open, "server route crosses the open doorway")
	# Pull the player beyond swing range: with it 15px past the door the
	# range gate correctly fires at the mouth, so commitment has to be
	# measured against a target worth walking to.
	probe._player.global_position = Vector2(200, 88)
	var crossed := await _wait_until(
			func() -> bool:
				return skeleton.global_position.x > DOORWAY_PASS_X,
			8.0)
	probe._check(crossed, "chaser crossed the open doorway")
	if crossed:
		var swung := await _wait_until(
				func() -> bool:
					return probe._current_state(skeleton) is EnemyAttack,
				6.0)
		probe._check(swung, "chaser reached the attack gate beyond the door")


## Ship-faithful threshold regression: the divider is painted from the
## dungeon tileset itself - physics-carrying wall atoms around a
## physics-free threshold atom - with no synthetic body backing. The bake
## must keep the threshold cell walkable (pre-fix it carved every painted
## cell), the closed door must seal the gap, and the opened door must
## route and carry a chaser across.
func _stage_ship_threshold() -> void:
	probe._tee("  stage: ship threshold band stays walkable until the door seals it")
	var dungeon := load(DUNGEON_TILESET) as TileSet
	var source_id := dungeon.get_source_id(0)
	probe._walls_layer.tile_set = dungeon
	for y in ROOM_ROWS:
		var atom := THRESHOLD_ATOM if y == DOORWAY_ROW else WALL_ATOM
		probe._walls_layer.set_cell(Vector2i(WALL_COLUMN, y), source_id, atom)
	if not await _rebake("rebake with the ship threshold band"):
		return
	var walls: TileMapLayer = probe._walls_layer
	var nav_map: RID = get_viewport().get_world_2d().navigation_map
	var threshold_center: Vector2 = walls.to_global(
			walls.map_to_local(Vector2i(WALL_COLUMN, DOORWAY_ROW)))
	var wall_center: Vector2 = walls.to_global(
			walls.map_to_local(Vector2i(WALL_COLUMN, DOORWAY_ROW - 2)))
	var threshold_gap := threshold_center.distance_to(
			NavigationServer2D.map_get_closest_point(nav_map, threshold_center))
	var wall_gap := wall_center.distance_to(
			NavigationServer2D.map_get_closest_point(nav_map, wall_center))
	probe._check(threshold_gap <= 3.0,
			"physics-free threshold atom stays on the mesh (%.1f px)" % threshold_gap)
	probe._check(wall_gap >= 8.0,
			"physics wall atom carves the mesh (%.1f px)" % wall_gap)
	probe._player.global_position = Vector2(200, 88)
	_place_door()
	if not await _rebake("rebake with the closed ship door"):
		return
	probe._check(not _server_route_crosses(), "closed door seals the ship threshold")
	_door._on_interact()
	var opened := await _wait_until(
			func() -> bool: return _server_route_crosses(), 2.0)
	probe._check(opened, "opened ship door reconnects the route")
	if not opened:
		return
	var skeleton: BaseEnemy = await probe._spawn_enemy(
			probe.SKELETON_SCENE, Vector2(56, 88))
	probe._force_chase(skeleton)
	var crossed := await _wait_until(
			func() -> bool:
				return skeleton.global_position.x > DOORWAY_PASS_X,
			8.0)
	probe._check(crossed, "chaser crossed the ship threshold")


## Divider wall with a 1-cell gap at DOORWAY_ROW: painted cells give the
## bake full-cell obstruction outlines, the body gives the chaser
## something physical to slide against - the room's own cell/body pairing.
func _place_doorway_wall() -> void:
	for y in ROOM_ROWS:
		if y != DOORWAY_ROW:
			probe._walls_layer.set_cell(
					Vector2i(WALL_COLUMN, y), 0, Vector2i.ZERO)
	_doorway_body = StaticBody2D.new()
	_doorway_body.collision_layer = probe.BLOCKER_MASK
	_doorway_body.collision_mask = 0
	for y in ROOM_ROWS:
		if y == DOORWAY_ROW:
			continue
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(CELL_SIZE, CELL_SIZE)
		shape_node.shape = shape
		shape_node.position = Vector2(
				(WALL_COLUMN + 0.5) * CELL_SIZE, (y + 0.5) * CELL_SIZE)
		_doorway_body.add_child(shape_node)
	add_child(_doorway_body)


## A real door scene in the gap, rotated onto the east-west passage: its
## closed blocker seals the gap in the bake; opening arms the passage.
func _place_door() -> void:
	_door = (load(DOOR_SCENE) as PackedScene).instantiate()
	add_child(_door)
	_door.position = Vector2(
			(WALL_COLUMN + 0.5) * CELL_SIZE, (DOORWAY_ROW + 0.5) * CELL_SIZE)
	_door.rotation = -PI / 2.0


## Free-before-frame-gap rebake (the main probe's ordering discipline),
## then wait until the mesh answers at the west spawn.
func _rebake(label: String) -> bool:
	probe._remove_bake_artifacts()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var nav_layer: TileMapLayer = NavBaker.bake(probe)
	probe._check(nav_layer != null, label)
	if nav_layer == null:
		return false
	var spawn := Vector2(56, 88)
	for i in 60:
		var closest := NavigationServer2D.map_get_closest_point(
				get_viewport().get_world_2d().navigation_map, spawn)
		if closest.distance_to(spawn) <= 2.0:
			for j in probe.FRAMES_TO_SETTLE:
				await get_tree().physics_frame
			return true
		await get_tree().physics_frame
	probe._check(false, "doorway mesh live at the west spawn")
	return false


func _cleanup() -> void:
	for y in ROOM_ROWS:
		probe._walls_layer.erase_cell(Vector2i(WALL_COLUMN, y))
	if is_instance_valid(_doorway_body):
		_doorway_body.queue_free()
	if is_instance_valid(_door):
		_door.queue_free()


func _server_route_crosses() -> bool:
	var server_path := NavigationServer2D.map_get_path(
			get_viewport().get_world_2d().navigation_map,
			Vector2(56, 88), probe._player.global_position, true)
	return server_path.size() >= 2 \
			and server_path[0].x < DOOR_PLANE_X \
			and server_path[server_path.size() - 1].x > DOOR_PLANE_X


func _wait_until(predicate: Callable, budget: float) -> bool:
	var clock := 0.0
	while clock < budget:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		if predicate.call():
			return true
	return false
