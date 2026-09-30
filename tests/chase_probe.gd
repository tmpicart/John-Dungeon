extends Node

## Headless regression probe for the reworked EnemyChase behaviors. Run:
## Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/chase_probe.tscn
## Exits 0 on pass, 1 on failure. Real enemy scenes are driven through their
## state machines against a stub player body on a synthetic baked room. The
## stages cover the RVO velocity flush, the sealed-wall archer guard (hold
## the approach instead of orbiting, proximity-retreat suppression while
## sightless), cover firing on the blind close-in, blind closing under
## player drift (no side-flip zig-zag and no far tours while the player
## strafes), the level-point melee press from vertical and diagonal
## approaches,
## no-lean arrival, path commitment under player drift, RVO separation,
## attack-time projectile re-aim, and the sealed-pocket melee guard (press
## stalls flip sides once, then hold the mouth facing the player until the
## box reopens), the NPC-pocket archer guard (a player shadowed
## beside a body-sized blocker: hold the mouth, fire when the shadow
## clears), and L-corner rounding - solo and as a pair - holding the
## corridor line off the tile apices.

const CELL_SIZE := 16
const ROOM_COLUMNS := 16
const ROOM_ROWS := 10
## Environment layer: cover bodies block aim rays and carve the mesh.
const BLOCKER_MASK := 1 << 2
const FRAMES_TO_SETTLE := 5
const ARCHER_SCENE := "res://entities/enemies/arcane_archer/arcane_archer.tscn"
const SKELETON_SCENE := "res://entities/enemies/flail_skeleton/flail_skeleton.tscn"
const SLIME_SCENE := "res://entities/enemies/slime_green/slime_green.tscn"
const ARROW_SCRIPT_PATH := "res://entities/projectiles/arcane_arrow.gd"
## The blind-orbit wall column and the cover candle both sit on the archer's
## approach row, so the clamped aim ray crosses them.
const WALL_COLUMN := 8

var _failures := 0
var _completed := false
var _log: FileAccess
var _floor_layer: TileMapLayer
var _walls_layer: TileMapLayer
var _wall_body: StaticBody2D
var _cover_body: StaticBody2D
var _alcove_body: StaticBody2D
var _pocket_body: StaticBody2D
var _corner_body: StaticBody2D
var _player: CharacterBody2D
var _stage_actors: Array[Node] = []
var _flush_count := 0
var _last_safe := Vector2.INF


func _ready() -> void:
	var result_path := ProjectSettings.globalize_path("res://chase_probe_result.txt")
	_log = FileAccess.open(result_path, FileAccess.WRITE)
	_tee("chase_probe: start")
	await _run()
	_check(_completed, "probe reached the end of the stage list")
	_tee("chase_probe: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
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

	_spawn_player()
	Global.player = _player

	await _stage_sealed_archer_guard()
	await _teardown()

	# Rebake for the remaining stages: wall out, cover candle in.
	_clear_walls()
	_remove_bake_artifacts()
	_place_cover()
	await get_tree().physics_frame
	await get_tree().physics_frame
	nav_layer = NavBaker.bake(self)
	_check(nav_layer != null, "rebake after wall removal")
	if nav_layer == null:
		return
	for i in FRAMES_TO_SETTLE:
		await get_tree().physics_frame

	await _stage_rvo_flush()
	await _teardown()
	await _stage_cover_firing()
	await _stage_point_blank_fire()
	await _stage_ally_lane_fire()
	await _teardown()
	await _stage_drift_close_in()
	await _teardown()
	await _stage_press(Vector2(200, 106), "vertical")
	await _teardown()
	await _stage_press(Vector2(212, 108), "diagonal")
	await _teardown()
	await _stage_no_lean_arrival()
	await _teardown()
	await _stage_path_commitment()
	await _teardown()
	await _stage_rvo_separation()
	await _teardown()
	await _stage_arrow_reaim()
	await _teardown()

	# Sealed-pocket stage: candle out, alcove walls in, fresh bake. Free the
	# old bake artifacts BEFORE the frame gap: a same-frame rebake would find
	# the doomed-but-still-in-tree region and recycle it, losing the fresh
	# polygon when the deferred free lands (the map ends up region-less).
	_remove_cover()
	_place_alcove()
	_remove_bake_artifacts()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var sealed_layer: TileMapLayer = NavBaker.bake(self)
	_check(sealed_layer != null, "rebake with sealed alcove")
	if sealed_layer != null:
		# Region-to-map registration syncs on a later frame than the bake;
		# a chase query before it lands stays cached-empty. Wait until the
		# mesh answers at the melee spawn, as the level-nav probe does.
		var melee_spawn := Vector2(168, 120)
		var mesh_ready := false
		for i in 60:
			var closest := NavigationServer2D.map_get_closest_point(
					get_viewport().get_world_2d().navigation_map, melee_spawn)
			if closest.distance_to(melee_spawn) <= 2.0:
				mesh_ready = true
				break
			await get_tree().physics_frame
		_check(mesh_ready, "rebaked mesh live at the melee spawn")
		for i in FRAMES_TO_SETTLE:
			await get_tree().physics_frame
		await _stage_sealed_melee_guard()
		if is_instance_valid(_alcove_body):
			_alcove_body.queue_free()
	await _teardown()
	# NPC-pocket group: body-sized blocker pocket in, fresh bake (same
	# free-before-frame-gap ordering as the alcove group above).
	_place_npc_pocket()
	_remove_bake_artifacts()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var pocket_layer: TileMapLayer = NavBaker.bake(self)
	_check(pocket_layer != null, "rebake with the NPC pocket")
	if pocket_layer != null:
		var pocket_spawn := Vector2(40, 88)
		var pocket_mesh_ready := false
		for i in 60:
			var pocket_closest := NavigationServer2D.map_get_closest_point(
					get_viewport().get_world_2d().navigation_map, pocket_spawn)
			if pocket_closest.distance_to(pocket_spawn) <= 2.0:
				pocket_mesh_ready = true
				break
			await get_tree().physics_frame
		_check(pocket_mesh_ready, "pocket mesh live at the archer spawn")
		for i in FRAMES_TO_SETTLE:
			await get_tree().physics_frame
		await _stage_npc_pocket_guard()
		if is_instance_valid(_pocket_body):
			_pocket_body.queue_free()
	# Corner group: L-corner block run in, fresh bake (same free-before-
	# frame-gap ordering). Reaching the player takes two tight 90-degree
	# turns through a 16px channel: the planned-path corner case.
	_place_corner_wall()
	_remove_bake_artifacts()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var corner_layer: TileMapLayer = NavBaker.bake(self)
	_check(corner_layer != null, "rebake with the corner wall")
	if corner_layer != null:
		var corner_spawn := Vector2(56, 88)
		var corner_mesh_ready := false
		for i in 60:
			var corner_closest := NavigationServer2D.map_get_closest_point(
					get_viewport().get_world_2d().navigation_map, corner_spawn)
			if corner_closest.distance_to(corner_spawn) <= 2.0:
				corner_mesh_ready = true
				break
			await get_tree().physics_frame
		_check(corner_mesh_ready, "corner mesh live at the archer spawn")
		for i in FRAMES_TO_SETTLE:
			await get_tree().physics_frame
		await _stage_corner_round()
		await _teardown()
		await _stage_corner_pair()
		if is_instance_valid(_corner_body):
			_corner_body.queue_free()
	_completed = true

func _stage_sealed_archer_guard() -> void:
	_tee("  stage: sightless archer guards a sealed wall instead of orbiting")
	var archer := await _spawn_enemy(ARCHER_SCENE, Vector2(120, 88))
	var chase: EnemyChase = _chase_state(archer)
	_force_chase(archer)
	var spawn := archer.global_position
	var max_drift := 0.0
	var targets := {}
	var blind_seen := false
	var retreated := false
	var clock := 0.0
	while clock < 8.0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		blind_seen = blind_seen or chase._blind_now
		max_drift = maxf(max_drift, archer.global_position.distance_to(spawn))
		targets[chase.navigation_agent.target_position] = true
		if _current_state(archer) is EnemyRetreat:
			retreated = true
			break
	_check(blind_seen, "archer reads as blind behind the wall")
	_check(not retreated, "proximity retreat stays suppressed while blind")
	_check(max_drift <= 40.0,
			"archer holds the wall approach (max drift %.1f px)" % max_drift)
	_check(targets.size() <= 4,
			"standoff stays pinned to the sealed mouth (%d distinct targets)" % targets.size())
	_check(archer.get_node("Sprite2D").scale.x > 0.0,
			"guarding archer faces the player through the wall")


func _stage_rvo_flush() -> void:
	_tee("  stage: RVO velocity flush reaches the body")
	var archer := await _spawn_enemy(ARCHER_SCENE, Vector2(40, 88))
	_player.global_position = Vector2(200, 88)
	var chase: EnemyChase = _chase_state(archer)
	chase.navigation_agent.velocity_computed.connect(_note_flush)
	_flush_count = 0
	_force_chase(archer)
	var clock := 0.0
	while clock < 1.0 and _flush_count == 0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
	_check(_flush_count > 0, "velocity_computed fired headless (%d flushes)" % _flush_count)
	chase.navigation_agent.velocity_computed.disconnect(_note_flush)


func _stage_cover_firing() -> void:
	_tee("  stage: blind close-in rounds the candle and fires")
	var archer := await _spawn_enemy(ARCHER_SCENE, Vector2(40, 88))
	_player.global_position = Vector2(200, 88)
	var chase: EnemyChase = _chase_state(archer)
	_force_chase(archer)
	var blind_seen := false
	var clock := 0.0
	while clock < 10.0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		blind_seen = blind_seen or chase._blind_now
		if _current_state(archer) is EnemyAttack:
			break
	_check(blind_seen, "archer closed blind up to the cover")
	_check(_current_state(archer) is EnemyAttack,
			"blind close-in cleared cover into an attack (%.1fs)" % clock)


## Point-blank regression: the proximity retreat must never starve the
## attack gate. When sight opens only inside retreat_range (an approach
## shadowed up close), fleeing before firing means the archer never shoots
## at all: it must take the ready shot first and kite on the cooldown.
func _stage_point_blank_fire() -> void:
	_tee("  stage: point-blank sighted archer fires before kiting")
	var archer := await _spawn_enemy(ARCHER_SCENE, Vector2(180, 100))
	_player.global_position = Vector2(200, 88)
	_force_chase(archer)
	var attacked := false
	var retreated := false
	var clock := 0.0
	while clock < 1.2 and not attacked:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		attacked = _current_state(archer) is EnemyAttack
	_check(attacked, "point-blank archer fired instead of fleeing")
	if not attacked:
		return
	while clock < 6.0 and not retreated:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		retreated = _current_state(archer) is EnemyRetreat
	_check(retreated, "kite followed the shot (cooldown pressure)")


## Teammate lane: an ally body on the Enemies layer parked dead-center in
## the firing lane must neither gate the shot nor eat the arrow. The aim
## gate (AIM_BLOCKING_MASK) and the arrow's flight mask see only the player
## and layer 3: ranged enemies shoot through teammates by design. Only
## walls, props, and NPC bodies (which share the blocker bit) block.
func _stage_ally_lane_fire() -> void:
	_tee("  stage: archer fires through an ally body in the lane")
	var ally := CharacterBody2D.new()
	ally.collision_layer = 2
	ally.collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 5.0
	shape_node.shape = shape
	ally.add_child(shape_node)
	add_child(ally)
	# On the muzzle-to-player line from (120, 96.65) to (200, 104): at
	# x = 160 the flight line sits at y ~= 100, so a 5 px disc there covers
	# the aim ray and both AIM_CLEARANCE_PX side rays.
	ally.position = Vector2(160, 100)
	_stage_actors.append(ally)
	var archer := await _spawn_enemy(ARCHER_SCENE, Vector2(120, 104))
	_player.global_position = Vector2(200, 104)
	_force_chase(archer)
	var attacked := false
	var arrow_max_x := -INF
	var pass_x := 168.0
	var clock := 0.0
	while clock < 6.0 and (not attacked or arrow_max_x < pass_x):
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		if not attacked and _current_state(archer) is EnemyAttack:
			attacked = true
		for enemy_node in get_tree().get_nodes_in_group("Enemies"):
			var script: Script = enemy_node.get_script()
			if script != null and script.resource_path == ARROW_SCRIPT_PATH:
				arrow_max_x = maxf(arrow_max_x, enemy_node.global_position.x)
	_check(attacked, "ally body in the lane did not gate the shot")
	_check(arrow_max_x >= pass_x,
		"arrow flew past the ally (max x %.0f)" % arrow_max_x)


## Blind close-in under a strafing player. Regression for the playtest
## zig-zag and far tours: closing on the player's position must hold one
## heading through the drift retargets, never flip the approach side each
## player step or path toward far walkable points.
func _stage_drift_close_in() -> void:
	_tee("  stage: blind approach under player drift holds one heading")
	var archer := await _spawn_enemy(ARCHER_SCENE, Vector2(40, 88))
	# 190 px out with the candle blocking the row: the archer closes ~90 px
	# blind while the target strafes, so several drift retargets land before
	# any firing solution.
	_player.global_position = Vector2(230, 88)
	_force_chase(archer)
	var fired := false
	var reversals := 0
	var max_gap := 0.0
	var last_heading := 0.0
	var sample_clock := 0.0
	var drift_up := false
	var clock := 0.0
	while clock < 10.0:
		await get_tree().physics_frame
		var step := get_physics_process_delta_time()
		clock += step
		# 36 px/s bounce across y 64..112: a strafing target, so drift
		# retargets fire every path interval like a real fight.
		if drift_up:
			_player.global_position.y = minf(_player.global_position.y + 36.0 * step, 112.0)
			if _player.global_position.y >= 112.0:
				drift_up = false
		else:
			_player.global_position.y = maxf(_player.global_position.y - 36.0 * step, 64.0)
			if _player.global_position.y <= 64.0:
				drift_up = true
		max_gap = maxf(max_gap,
				_player.global_position.distance_to(archer.global_position))
		if _current_state(archer) is EnemyAttack:
			fired = true
			break
		sample_clock += step
		if sample_clock >= 0.25:
			sample_clock = 0.0
			var heading := signf(archer.velocity.x)
			if heading != 0.0 and last_heading != 0.0 and heading != last_heading:
				reversals += 1
			if heading != 0.0:
				last_heading = heading
	_check(fired, "blind archer fired under player drift (%.1fs)" % clock)
	_check(reversals <= 3, "approach held one heading (x reversals %d)" % reversals)
	_check(max_gap <= 260.0,
			"blind approach stayed local (max gap %.0f px)" % max_gap)


func _stage_press(skeleton_position: Vector2, label: String) -> void:
	_tee("  stage: %s approach press" % label)
	var skeleton := await _spawn_enemy(SKELETON_SCENE, skeleton_position)
	_player.global_position = Vector2(200, 120)
	var chase_node := _chase_state(skeleton)
	chase_node.navigation_agent.velocity_computed.connect(_note_safe)
	_last_safe = Vector2.INF
	_force_chase(skeleton)
	var clock := 0.0
	var band_delta_y := 999.0
	var min_gap := 999.0
	var ticks := 0
	while clock < 4.0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		ticks += 1
		min_gap = minf(min_gap,
				_player.global_position.distance_to(skeleton.global_position))
		if ticks % 15 == 0:
			var delta_v: Vector2 = _player.global_position - skeleton.global_position
			_tee("    [tick %d] %s gap %.1f v_ag %s v_bd %s v_sf %s fl %s/%s/%s/%s sl %d" % [
				ticks, _current_state(skeleton).name, delta_v.length(),
				chase_node.navigation_agent.velocity, skeleton.velocity, _last_safe,
				skeleton.attacking, skeleton.is_hit, skeleton.stunned, skeleton.is_dead,
				skeleton.get_slide_collision_count()])
		if _current_state(skeleton) is EnemyAttack:
			band_delta_y = absf(_player.global_position.y - skeleton.global_position.y)
			break
	chase_node.navigation_agent.velocity_computed.disconnect(_note_safe)
	if band_delta_y > 900.0:
		_tee("    [diag] min gap %.1f px, path finished %s" % [
			min_gap,
			_chase_state(skeleton).navigation_agent.is_navigation_finished()])
	_check(_current_state(skeleton) is EnemyAttack,
			"skeleton swung from the %s approach (%.1fs)" % [label, clock])
	_check(band_delta_y <= 6.0,
			"swing resolved inside the level band (|dy| %.1f)" % band_delta_y)


func _stage_no_lean_arrival() -> void:
	_tee("  stage: pacifist arrival stands without RVO lean")
	var slime := await _spawn_enemy(SLIME_SCENE, Vector2(152, 120))
	_player.global_position = Vector2(200, 120)
	var chase: EnemyChase = _chase_state(slime)
	_force_chase(slime)
	var settled := await _wait_until(
		func() -> bool: return chase.navigation_agent.is_navigation_finished(),
		5.0)
	if not settled:
		_tee("    [diag] final gap %.1f px, finished %s" % [
			_player.global_position.distance_to(slime.global_position),
			chase.navigation_agent.is_navigation_finished()])
	_check(settled, "pacifist chased to arrival")
	if not settled:
		return
	var start := slime.global_position
	var worst := 0.0
	var clock := 0.0
	while clock < 1.0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		worst = maxf(worst, start.distance_to(slime.global_position))
	_check(worst < 1.5, "no lean at a finished path (worst drift %.2f px)" % worst)
	_check(chase.navigation_agent.velocity == Vector2.ZERO, "agent velocity zeroed at arrival")

func _stage_path_commitment() -> void:
	_tee("  stage: path commitment under player drift")
	var slime := await _spawn_enemy(SLIME_SCENE, Vector2(48, 120))
	_player.global_position = Vector2(200, 120)
	var chase: EnemyChase = _chase_state(slime)
	_force_chase(slime)
	var moving := await _wait_until(
		func() -> bool: return slime.velocity.length() > 5.0,
		2.0)
	_check(moving, "pacifist took the route")
	if not moving:
		return
	var held_target: Vector2 = chase.navigation_agent.target_position
	_player.global_position = Vector2(208, 120)
	await _wait_seconds(1.3)
	var kept := chase.navigation_agent.target_position.distance_to(held_target) < 0.5
	_check(kept, "8 px drift kept the loaded path")
	_player.global_position = Vector2(248, 120)
	var requeried := await _wait_until(
		func() -> bool:
			return chase.navigation_agent.target_position.distance_to(held_target) >= 24.0,
		2.0)
	_check(requeried, "40 px drift re-queried the route")


func _stage_rvo_separation() -> void:
	_tee("  stage: overlapping chasers part instead of welding")
	var s1 := await _spawn_enemy(SLIME_SCENE, Vector2(196, 112))
	var s2 := await _spawn_enemy(SLIME_SCENE, Vector2(204, 128))
	_player.global_position = Vector2(248, 120)
	_force_chase(s1)
	_force_chase(s2)
	var clock := 0.0
	var min_gap := INF
	while clock < 4.0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		min_gap = minf(min_gap, s1.global_position.distance_to(s2.global_position))
	_check(min_gap >= 11.0,
			"chasers queued instead of welding (min gap %.1f px)" % min_gap)


func _stage_arrow_reaim() -> void:
	_tee("  stage: projectile re-aims at the strafing player")
	var archer := await _spawn_enemy(ARCHER_SCENE, Vector2(40, 136))
	_player.global_position = Vector2(168, 136)
	_force_chase(archer)
	var clock := 0.0
	var strafing := false
	var arrow: Node2D = null
	while clock < 5.0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		if not strafing and _current_state(archer) is EnemyAttack:
			strafing = true
		if strafing:
			# Strafe AWAY from the cover candle: a northward strafe sweeps
			# the re-aimed shot line across the candle's aim clearance and
			# the sight gate holds fire for wind-ups landing in that window.
			_player.global_position.y += 200.0 * get_physics_process_delta_time()
		arrow = _find_arrow()
		if arrow != null:
			break
	if arrow == null:
		var final_state := _current_state(archer)
		_tee("    [diag] state %s attacking %s can_attack %s enemy-group %d" % [
				final_state.name if final_state != null else "null",
				archer.attacking, archer.can_attack(),
				get_tree().get_nodes_in_group("Enemies").size()])
		_check(false, "archer fired an arrow at all")
		return
	var expected := (_player.global_position - arrow.global_position).angle()
	var error := absf(angle_difference(arrow.rotation, expected))
	_check(_player.global_position.y > 142.0, "player had strafed before the shot")
	_check(error <= deg_to_rad(10.0),
			"arrow tracks the live player line (error %.1f deg)" % rad_to_deg(error))


func _find_arrow() -> Node2D:
	for node in get_tree().get_nodes_in_group("Enemies"):
		var script: Script = node.get_script()
		if script != null and script.resource_path == ARROW_SCRIPT_PATH:
			return node
	return null


func _note_flush(_safe_velocity: Vector2) -> void:
	_flush_count += 1


func _note_safe(safe_velocity: Vector2) -> void:
	_last_safe = safe_velocity

func _spawn_player() -> void:
	var stub: CharacterBody2D = preload("res://tests/stub_player_body.gd").new()
	add_child(stub)
	stub.global_position = Vector2(200, 88)
	_player = stub


func _spawn_enemy(scene_path: String, spawn_position: Vector2) -> BaseEnemy:
	var enemy: BaseEnemy = (load(scene_path) as PackedScene).instantiate()
	add_child(enemy)
	enemy.global_position = spawn_position
	_stage_actors.append(enemy)
	await get_tree().physics_frame
	return enemy

func _chase_state(enemy: BaseEnemy) -> EnemyChase:
	var control: StateControl = enemy.get_node("State Control")
	for state in control.states:
		if state is EnemyChase:
			return state
	push_error("no EnemyChase state under %s" % enemy.name)
	return null


func _force_chase(enemy: BaseEnemy) -> void:
	var chase := _chase_state(enemy)
	if chase != null:
		enemy.get_node("State Control").transition_to(chase)


func _current_state(enemy: BaseEnemy) -> State:
	var control: StateControl = enemy.get_node("State Control")
	return control.current_state


func _teardown() -> void:
	for actor in _stage_actors:
		if is_instance_valid(actor):
			actor.queue_free()
	_stage_actors.clear()
	for arrow in get_tree().get_nodes_in_group("Enemies"):
		var script: Script = arrow.get_script()
		if script != null and script.resource_path == ARROW_SCRIPT_PATH:
			arrow.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame


func _clear_walls() -> void:
	for y in ROOM_ROWS:
		_walls_layer.erase_cell(Vector2i(WALL_COLUMN, y))
	if is_instance_valid(_wall_body):
		_wall_body.queue_free()


func _remove_bake_artifacts() -> void:
	for node_name in [NavBaker.GENERATED_LAYER_NAME, NavBaker.GENERATED_REGION_NAME]:
		var node := get_node_or_null(NodePath(node_name))
		if node != null:
			node.queue_free()


func _place_cover() -> void:
	var candle := StaticBody2D.new()
	candle.collision_layer = BLOCKER_MASK
	candle.collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 5.0
	shape_node.shape = shape
	candle.add_child(shape_node)
	add_child(candle)
	# On the approach row between the west spawn and the player: the direct
	# approach starts blind; closing past the candle clears the ray.
	candle.position = Vector2(120, 86)
	_cover_body = candle


func _remove_cover() -> void:
	if is_instance_valid(_cover_body):
		_cover_body.queue_free()


## Alcove fixture: grid-aligned 8 px unit cells ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â structurally identical to
## NavBaker's own tile obstruction outlines (adjacent cells, fully shared
## edges) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â forming a pocket whose west mouth channel is 8 px wide. The
## channel is narrower than twice the bake's agent radius, so the pocket
## seals: the player inside is unreachable and level points on both sides
## of them land off-mesh, forcing the press through flip and guard.
func _place_alcove() -> void:
	_alcove_body = StaticBody2D.new()
	_alcove_body.collision_layer = BLOCKER_MASK
	_alcove_body.collision_mask = 0
	var cells: Array[Vector2] = []
	for x in range(184, 240, 8):
		cells.append(Vector2(x, 104))
		cells.append(Vector2(x, 128))
	for y in range(112, 128, 8):
		cells.append(Vector2(184, y))
		cells.append(Vector2(232, y))
	cells.erase(Vector2(184, 120))  # the mouth channel
	for cell_origin in cells:
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(8, 8)
		shape_node.shape = shape
		shape_node.position = cell_origin + Vector2(4, 4)
		_alcove_body.add_child(shape_node)
	_alcove_body.position = Vector2.ZERO
	add_child(_alcove_body)


func _stage_sealed_melee_guard() -> void:
	_tee("  stage: melee press flips sides then guards a sealed pocket")
	var skeleton := await _spawn_enemy(SKELETON_SCENE, Vector2(168, 120))
	_player.global_position = Vector2(198, 120)
	var chase: EnemyChase = _chase_state(skeleton)
	_force_chase(skeleton)
	var flipped := false
	var guard_seen := false
	var guard_anchor := Vector2.ZERO
	var guard_drift := 0.0
	var clock := 0.0
	while clock < 6.0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		flipped = flipped or chase._press_flipped
		if chase._guarding:
			if not guard_seen:
				guard_seen = true
				guard_anchor = skeleton.global_position
			guard_drift = maxf(guard_drift,
					skeleton.global_position.distance_to(guard_anchor))
		if Engine.get_physics_frames() % 15 == 0:
			var final_point: Vector2 = chase.navigation_agent.get_final_position()
			var server_path := NavigationServer2D.map_get_path(
					get_viewport().get_world_2d().navigation_map,
					skeleton.global_position, _player.global_position, true)
			var same_island := NavigationServer2D.map_get_path(
					get_viewport().get_world_2d().navigation_map,
					skeleton.global_position, Vector2(100, 120), true)
			_tee("    [t %.1f] state %s has_player %s target %s fin %s final (%.0f,%.0f)" % [
					clock, _current_state(skeleton).name, chase.player != null,
					chase.navigation_agent.target_position,
					chase.navigation_agent.is_navigation_finished(),
					final_point.x, final_point.y])
			_tee("      server_pts %d same_island %d pos (%.0f,%.0f) flip %s guard %s clock %.2f" % [
					server_path.size(), same_island.size(),
					skeleton.global_position.x, skeleton.global_position.y,
					chase._press_flipped, chase._guarding, chase._press_clock])
	_check(flipped, "press flipped to the opposite level point on stall")
	_check(guard_seen, "press guarded after both sides stalled")
	_check(guard_drift <= 6.0,
			"guard holds the pocket mouth (max drift %.1f px)" % guard_drift)
	_check(skeleton.get_node("Sprite2D").scale.x > 0.0,
			"guarding skeleton faces the player through the wall")
	# Reveal: the player steps out of the pocket into the swing box.
	_player.global_position = Vector2(170, 120)
	var reveal_clock := 0.0
	var swung := false
	while reveal_clock < 1.5:
		await get_tree().physics_frame
		reveal_clock += get_physics_process_delta_time()
		if _current_state(skeleton) is EnemyAttack:
			swung = true
			break
	_check(swung, "guard swings the moment the box opens (%.2fs)" % reveal_clock)

## NPC-pocket fixture: a body-sized circular blocker (blacksmith-like)
## against a full-height wall column with a three-brick cap, leaving a
## player-sized gap the bake seals off-mesh: the player inside is
## unreachable and shadowed from every approach line.
func _place_npc_pocket() -> void:
	_pocket_body = StaticBody2D.new()
	_pocket_body.collision_layer = BLOCKER_MASK
	_pocket_body.collision_mask = 0
	var cells: Array[Vector2] = []
	for y in range(0, 120, 8):
		cells.append(Vector2(152, y))
	for x in range(168, 192, 8):
		cells.append(Vector2(x, 64))
	for cell_origin in cells:
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(8, 8)
		shape_node.shape = shape
		shape_node.position = cell_origin + Vector2(4, 4)
		_pocket_body.add_child(shape_node)
	var npc_circle := CollisionShape2D.new()
	var npc_shape := CircleShape2D.new()
	npc_shape.radius = 6.0
	npc_circle.shape = npc_shape
	npc_circle.position = Vector2(172, 86)
	_pocket_body.add_child(npc_circle)
	add_child(_pocket_body)


## The player tucks beside a body-sized blocker in a sealed pocket: no
## firing line exists and the mesh cannot deliver the archer, so the
## finished path must guard the mouth. A radial press at the player
## instead orbits the blocker body (slide reads as travel, so the stall
## watchdog never seals); arc travel around the blocker discriminates.
func _stage_npc_pocket_guard() -> void:
	_tee("  stage: archer guards the NPC-shadowed pocket instead of orbiting")
	_player.global_position = Vector2(163, 86)
	var archer := await _spawn_enemy(ARCHER_SCENE, Vector2(40, 88))
	var chase: EnemyChase = _chase_state(archer)
	_force_chase(archer)
	var npc := Vector2(172, 86)
	var arrived := false
	var clock := 0.0
	while clock < 6.0 and not arrived:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		arrived = chase.navigation_agent.is_navigation_finished()
	_check(arrived, "archer reached the pocket mouth")
	if not arrived:
		return
	var blind_seen := false
	var attacked := false
	var arc := 0.0
	var min_gap := INF
	var last_angle := (archer.global_position - npc).angle()
	clock = 0.0
	while clock < 2.5:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		blind_seen = blind_seen or chase._blind_now
		attacked = attacked or _current_state(archer) is EnemyAttack
		if Engine.get_physics_frames() % 15 == 0:
			_tee("    [g t=%.1f] state %s fin %s pos %s dNPC %.1f dPl %.1f blind %s" % [
			clock, _current_state(archer).get_class(),
			str(chase.navigation_agent.is_navigation_finished()),
			archer.global_position, (archer.global_position - npc).length(),
			(_player.global_position - archer.global_position).length(),
			chase._blind_now])
		var angle := (archer.global_position - npc).angle()
		arc += absf(angle_difference(angle, last_angle)) \
				* archer.global_position.distance_to(npc)
		last_angle = angle
	min_gap = minf(min_gap, (_player.global_position
		- archer.global_position).length())
	_check(blind_seen, "pocket shadow reads as blind")
	_check(not attacked, "no firing solution existed inside the shadow")
	_check(arc <= 20.0, "archer held the mouth (arc travel %.0f px)" % arc)
	_check(min_gap >= 17.0, "archer holds the rim, no press (min gap %.1f px)" % min_gap)
	_player.global_position = Vector2(168, 140)
	var fired := false
	clock = 0.0
	while clock < 2.0 and not fired:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		fired = _current_state(archer) is EnemyAttack
	_check(fired, "guard fired when the shadow cleared")

## L-corner fixture: 8px unit cells fencing the room's southeast quadrant
## off behind a 16px channel east of the horizontal arm — the tightest
## planned-path turn pair the mesh offers.
func _place_corner_wall() -> void:
	_corner_body = StaticBody2D.new()
	_corner_body.collision_layer = BLOCKER_MASK
	_corner_body.collision_mask = 0
	var cells: Array[Vector2] = []
	for x in range(120, 240, 8):
		cells.append(Vector2(x, 96))
	for y in range(104, 160, 8):
		cells.append(Vector2(120, y))
	for cell_origin in cells:
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(8, 8)
		shape_node.shape = shape
		shape_node.position = cell_origin + Vector2(4, 4)
		_corner_body.add_child(shape_node)
	_corner_body.position = Vector2.ZERO
	add_child(_corner_body)

## Corner-rounding regression: early waypoint switching cuts the corner
## chord inside the bake margin and the body grinds the tile apex — the
## playtest "catches on obstacle blocks". The run must hold the corridor
## line past both apices, never stall, and reach the attack gate.
func _stage_corner_round() -> void:
	_tee("  stage: solo archer rounds the block corner without grinding")
	var archer := await _spawn_enemy(ARCHER_SCENE, Vector2(56, 88))
	_player.global_position = Vector2(170, 130)
	_force_chase(archer)
	var apices := [Vector2(240, 96), Vector2(240, 104)]
	var min_apex_clearance := INF
	var stalled := false
	var window_start := 0.0
	var window_pos := archer.global_position
	var clock := 0.0
	var attacked := false
	while clock < 10.0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		if _current_state(archer) is EnemyAttack:
			attacked = true
			break
		for apex in apices:
			min_apex_clearance = minf(min_apex_clearance,
			archer.global_position.distance_to(apex))
		if clock - window_start >= 0.6:
			stalled = stalled or archer.global_position.distance_to(window_pos) < 2.0
			window_start = clock
			window_pos = archer.global_position
	_check(attacked, "corner route reached the attack gate (%.1fs)" % clock)
	_check(not stalled, "no stall window while rounding (0.6s probes)")
	_check(min_apex_clearance >= 4.5,
		"body held the corridor line past the apices (min %.1f px)" % min_apex_clearance)

## Pair squeeze at the same corner: RVO separation smaller than the summed
## body radii lets archers shove each other into the turn (the playtest
## "catches near another enemy"). Both must round cleanly, keeping real
## body separation, and reach the attack gate.
func _stage_corner_pair() -> void:
	_tee("  stage: archer pair rounds the corner without body contact")
	var first := await _spawn_enemy(ARCHER_SCENE, Vector2(48, 80))
	var second := await _spawn_enemy(ARCHER_SCENE, Vector2(24, 96))
	_player.global_position = Vector2(170, 130)
	_force_chase(first)
	_force_chase(second)
	var min_gap := INF
	var window_start := 0.0
	var window_first := first.global_position
	var window_second := second.global_position
	var clock := 0.0
	var both_attacked := false
	while clock < 12.0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		min_gap = minf(min_gap,
			first.global_position.distance_to(second.global_position))
		if _current_state(first) is EnemyAttack and _current_state(second) is EnemyAttack:
			both_attacked = true
			break
		if clock - window_start >= 0.8:
			var progressed := (first.global_position.distance_to(window_first) >= 2.0
				or second.global_position.distance_to(window_second) >= 2.0)
			if not progressed:
				break
			window_start = clock
			window_first = first.global_position
			window_second = second.global_position
	_check(both_attacked, "both archers reached the attack gate (%.1fs)" % clock)
	_check(min_gap >= 13.6,
		"pair kept separation past the corner (min %.1f px)" % min_gap)

func _build_room() -> void:
	var tile_set := _build_plain_tile_set()
	_floor_layer = _make_layer("Floor", tile_set, true)
	_walls_layer = _make_layer("Walls", tile_set, false)
	for x in ROOM_COLUMNS:
		for y in ROOM_ROWS:
			_floor_layer.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
	for y in ROOM_ROWS:
		_walls_layer.set_cell(Vector2i(WALL_COLUMN, y), 0, Vector2i.ZERO)
	# Physical wall body: carves its outline into bake #1 and blocks the
	# aim ray for the blind-orbit stage.
	_wall_body = StaticBody2D.new()
	_wall_body.collision_layer = BLOCKER_MASK
	_wall_body.collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(CELL_SIZE, ROOM_ROWS * CELL_SIZE)
	shape_node.shape = shape
	_wall_body.add_child(shape_node)
	add_child(_wall_body)
	_wall_body.position = Vector2(
		(WALL_COLUMN + 0.5) * CELL_SIZE,
		ROOM_ROWS * CELL_SIZE / 2.0)


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


func _wait_until(predicate: Callable, budget: float) -> bool:
	var clock := 0.0
	while clock < budget:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		if predicate.call():
			return true
	return false


func _wait_seconds(duration: float) -> void:
	var clock := 0.0
	while clock < duration:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
