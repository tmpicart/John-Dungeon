extends Node

## Headless regression probe for the desire-based EnemyRetreat. Run:
## Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/retreat_probe.tscn
## Exits 0 on pass, 1 on failure. Real enemy scenes are driven through their
## state machines against a stub player body on a synthetic baked room. The
## stages cover open-field kiting (flight opens distance under pressure and
## exits through comfort instead of the hard cap), cornered geometry (a
## dead-end corridor leaves no qualifying escape route, so the archer
## disengages into the chase suppression latch and fights instead of
## grinding the back wall), obstacle-backed flight (a wall at the archer's
## back keeps the flight local — hop to comfort or cornered stand, never
## a tour — with the width-aware aim gate and attack facing pinned against
## the same wall), and the necromancer hit-triggered retreat.

const CELL_SIZE := 16
const ROOM_COLUMNS := 16
const ROOM_ROWS := 10
## Environment layer: blocker bodies carve their outlines into the bake.
const BLOCKER_MASK := 1 << 2
const FRAMES_TO_SETTLE := 5
const ARCHER_SCENE := "res://entities/enemies/arcane_archer/arcane_archer.tscn"
const NECROMANCER_SCENE := "res://entities/enemies/necromancer/necromancer.tscn"
## Kite-stage press speed: light pressure, so flight must open distance on
## its own merits instead of merely outrunning the press.
const KITE_PLAYER_SPEED := 12.0
## Corridor-stage press speed: deliberate, so the cornered cycle has time
## to repeat inside the window.
const CORNER_PLAYER_SPEED := 40.0
## Corner-stage stand-off: the press halts here, so the collisionless stub
## never body-grinds the archer off the pocket geometry; cornering is a
## scoring-level contract, not a shoving contest.
const CORNER_STAND_OFF := 40.0
## Obstacle-stage press speed: brisk, so the hop must resolve under real
## pressure inside the window.
const HOP_PLAYER_SPEED := 30.0

var _failures := 0
var _completed := false
var _log: FileAccess
var _floor_layer: TileMapLayer
var _player: CharacterBody2D
var _stage_actors: Array[Node] = []


func _ready() -> void:
	var result_path := ProjectSettings.globalize_path("res://retreat_probe_result.txt")
	_log = FileAccess.open(result_path, FileAccess.WRITE)
	_tee("retreat_probe: start")
	await _run()
	_check(_completed, "probe reached the end of the stage list")
	_tee("retreat_probe: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
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
		_log.flush()


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

	await _stage_kite()
	await _teardown()
	await _stage_cornered()
	await _teardown()
	await _stage_obstacle_hop()
	await _teardown()
	await _stage_hit_retreat()
	_completed = true


## Open field: under light pressure flight must open real distance, reach
## comfort (not ride the hard cap), and settle without flapping.
func _stage_kite() -> void:
	_tee("  stage: open-field kite opens distance")
	var archer := await _spawn_enemy(ARCHER_SCENE, Vector2(128, 80))
	_player.global_position = Vector2(68, 80)
	_force_chase(archer)
	var retreat_entries := 0
	var was_retreat := false
	var comfort_seen := false
	var max_gap := 0.0
	var clock := 0.0
	while clock < 6.0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		_player.global_position = _player.global_position.move_toward(
				archer.global_position, KITE_PLAYER_SPEED * get_physics_process_delta_time())
		var in_retreat := _current_state(archer) is EnemyRetreat
		if in_retreat and not was_retreat:
			retreat_entries += 1
		was_retreat = in_retreat
		var gap := _player.global_position.distance_to(archer.global_position)
		max_gap = maxf(max_gap, gap)
		if gap >= 95.0:
			comfort_seen = true
	_check(retreat_entries >= 1, "archer entered retreat under pressure (%d)" % retreat_entries)
	_check(retreat_entries <= 3, "no retreat/chase flapping (%d entries)" % retreat_entries)
	_check(comfort_seen, "flight reached comfort distance (max gap %.1f px)" % max_gap)


## Dead-end corridor sealed at both ends: every escape candidate resolves
## to a short route or doubles back through the player, so retreat must
## disengage into the suppression latch (repeating as it decays) and the
## archer must fight instead of grinding the back wall.
func _stage_cornered() -> void:
	_tee("  stage: cornered archer disengages and fights")
	_build_corridor()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_remove_bake_artifacts()
	var nav_layer: TileMapLayer = NavBaker.bake(self)
	_check(nav_layer != null, "rebake with corridor walls")
	if nav_layer == null:
		return
	for i in FRAMES_TO_SETTLE:
		await get_tree().physics_frame

	var archer := await _spawn_enemy(ARCHER_SCENE, Vector2(50, 80))
	_player.global_position = Vector2(220, 80)
	var chase := _chase_state(archer)
	_force_chase(archer)
	var latch_rises := 0
	var was_latched := false
	var max_latch := 0.0
	var retreat_frames := 0
	var attack_seen := false
	var clock := 0.0
	while clock < 8.0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		if _player.global_position.distance_to(archer.global_position) \
				> CORNER_STAND_OFF:
			_player.global_position = _player.global_position.move_toward(
					archer.global_position,
					CORNER_PLAYER_SPEED * get_physics_process_delta_time())
		if _current_state(archer) is EnemyAttack:
			attack_seen = true
		if _current_state(archer) is EnemyRetreat:
			retreat_frames += 1
		var latched: bool = chase._retreat_suppressed > 0.0
		if latched and not was_latched:
			latch_rises += 1
		max_latch = maxf(max_latch, chase._retreat_suppressed)
		was_latched = latched
	_check(latch_rises >= 1,
			"cornered flight disengaged into the latch (%d rises)" % latch_rises)
	# The latch decay is plain arithmetic; what the probe pins is that the
	# cornered handoff carried the configured cooldown. A same-tick
	# re-latch can hide the zero crossing from a per-frame sampler, so the
	# decay is not observable and not asserted.
	var retreat: EnemyRetreat = archer.get_node("State Control/EnemyRetreat")
	_check(is_equal_approx(max_latch, retreat.cornered_cooldown),
			"cornered latch carried the configured cooldown (%.1f s)" % max_latch)
	var retreat_seconds := retreat_frames * get_physics_process_delta_time()
	_check(retreat_seconds <= 0.8,
			"cornered retreat did not grind (%.2f s total)" % retreat_seconds)
	_check(attack_seen, "cornered archer fought instead of freezing")


## Wall at the archer's back with hop room past both ends: flight must
## stay local and keep firing. Either resolving outcome is valid — the
## short hop to comfort, or a cornered stand-and-fight when the wall
## geometry denies a route — never a tour around cover. Also pins the
## width-aware aim gate and attack facing against this geometry.
func _stage_obstacle_hop() -> void:
	_tee("  stage: obstacle-backed flight stays local")
	var wall := StaticBody2D.new()
	wall.collision_layer = BLOCKER_MASK
	wall.collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(8.0, 80.0)
	shape_node.shape = shape
	wall.add_child(shape_node)
	add_child(wall)
	wall.position = Vector2(80.0, 80.0)
	_stage_actors.append(wall)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_remove_bake_artifacts()
	var nav_layer: TileMapLayer = NavBaker.bake(self)
	_check(nav_layer != null, "rebake with back wall")
	if nav_layer == null:
		return
	for i in FRAMES_TO_SETTLE:
		await get_tree().physics_frame

	var archer := await _spawn_enemy(ARCHER_SCENE, Vector2(128.0, 80.0))
	var sprite: Sprite2D = archer.get_node("Sprite2D")
	var chase := _chase_state(archer)
	var attack_state: EnemyAttack = null
	var control: StateControl = archer.get_node("State Control")
	for state in control.states:
		if state is EnemyAttack:
			attack_state = state
	_player.global_position = Vector2(220.0, 80.0)
	_force_chase(archer)
	var comfort_seen := false
	var attack_seen := false
	var facing_broke := false
	var latch_rises := 0
	var was_latched := false
	var max_gap := 0.0
	var max_displacement := 0.0
	var start := archer.global_position
	var clock := 0.0
	while clock < 6.0:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		_player.global_position = _player.global_position.move_toward(
				archer.global_position,
				HOP_PLAYER_SPEED * get_physics_process_delta_time())
		if _current_state(archer) is EnemyAttack:
			attack_seen = true
			var to_player_x := _player.global_position.x - archer.global_position.x
			if absf(to_player_x) > 10.0 \
					and (sprite.scale.x > 0.0) != (to_player_x > 0.0):
				facing_broke = true
		var latched: bool = chase._retreat_suppressed > 0.0
		if latched and not was_latched:
			latch_rises += 1
		was_latched = latched
		max_gap = maxf(max_gap,
				_player.global_position.distance_to(archer.global_position))
		max_displacement = maxf(max_displacement,
				start.distance_to(archer.global_position))
		if max_gap >= 95.0:
			comfort_seen = true
	_check(max_displacement <= 170.0,
			"flight stayed local instead of touring (%.0f px)" % max_displacement)
	_check(comfort_seen or latch_rises >= 1,
			"flight resolved to comfort or a cornered fight (comfort=%s, latches=%d, max gap %.1f)" % [
					str(comfort_seen), latch_rises, max_gap])
	_check(attack_seen, "archer fired around the obstacle")
	_check(not facing_broke, "attack facing tracked the player")

	# Width-aware aim gate against the wall under test: a lane that
	# clears the wall top by 1 px reads blocked (the 2 px clearance
	# parallel sweeps the wall face), while a fully clear lane stays
	# clear — a thin center ray alone would pass both.
	_check(not archer.aim_line_clear(Vector2(128.0, 39.0), Vector2(30.0, 39.0)),
			"corner-grazing aim line reads blocked")
	_check(archer.aim_line_clear(Vector2(128.0, 20.0), Vector2(30.0, 20.0)),
			"clear aim lane reads clear")

	# A muzzle line through the wall swallows the shot: no projectile
	# joins the group across the synchronous spawn call.
	_player.global_position = Vector2(220.0, 80.0)
	var projectiles_before := get_tree().get_nodes_in_group("Enemies").size()
	attack_state._spawn_projectile(Vector2(30.0, 39.0))
	var projectiles_after := get_tree().get_nodes_in_group("Enemies").size()
	_check(projectiles_after == projectiles_before,
			"grazing muzzle line swallowed the shot")


## Hit-triggered retreat (necromancer): a hit must route into flight,
## open real distance along the navmesh, and return through comfort.
func _stage_hit_retreat() -> void:
	_tee("  stage: necromancer hit-retreat opens distance")
	_remove_bake_artifacts()
	var nav_layer: TileMapLayer = NavBaker.bake(self)
	_check(nav_layer != null, "rebake open room")
	if nav_layer == null:
		return
	for i in FRAMES_TO_SETTLE:
		await get_tree().physics_frame

	var necro := await _spawn_enemy(NECROMANCER_SCENE, Vector2(128, 80))
	_player.global_position = Vector2(148, 80)
	_force_chase(necro)
	await _wait_seconds(0.3)
	var gap_before := _player.global_position.distance_to(necro.global_position)
	necro.take_damage(1, _player.global_position)
	var retreat_seen := await _wait_until(
			func() -> bool: return _current_state(necro) is EnemyRetreat, 2.0)
	_check(retreat_seen, "hit routed into retreat")
	var max_gap := gap_before
	var clock := 0.0
	while clock < 2.5:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		max_gap = maxf(max_gap,
				_player.global_position.distance_to(necro.global_position))
	_check(max_gap > gap_before + 40.0,
			"flight opened real distance (%.0f -> %.0f px)" % [gap_before, max_gap])
	var back_to_chase := await _wait_until(
			func() -> bool: return _current_state(necro) is EnemyChase, 3.0)
	_check(back_to_chase, "comfort exit returned to chase")


func _build_corridor() -> void:
	# Sealed flight pocket: a full-height west wall plus north/south walls
	# spanning to the room's east edge leave a 48 px dead-end band — no
	# leak around the west end into the outer strips.
	var specs := [
		[Vector2(28.0, 80.0), Vector2(8.0, 160.0)],
		[Vector2(138.0, 52.0), Vector2(236.0, 8.0)],
		[Vector2(138.0, 108.0), Vector2(236.0, 8.0)],
	]
	for spec in specs:
		var wall := StaticBody2D.new()
		wall.collision_layer = BLOCKER_MASK
		wall.collision_mask = 0
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = spec[1]
		shape_node.shape = shape
		wall.add_child(shape_node)
		add_child(wall)
		wall.position = spec[0]
		_stage_actors.append(wall)


func _teardown() -> void:
	for actor in _stage_actors:
		if is_instance_valid(actor):
			actor.queue_free()
	_stage_actors.clear()
	for projectile in get_tree().get_nodes_in_group("Enemies"):
		var script: Script = projectile.get_script()
		if script != null and (script.resource_path.ends_with("arcane_arrow.gd")
				or script.resource_path.ends_with("magic_missile.gd")):
			projectile.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame


func _remove_bake_artifacts() -> void:
	for node_name in [NavBaker.GENERATED_LAYER_NAME, NavBaker.GENERATED_REGION_NAME]:
		var node := get_node_or_null(NodePath(node_name))
		if node != null:
			# Detach now, free deferred: NavBaker reuses same-named nodes, so
			# a bare queue_free lets the next bake repaint the doomed node
			# and the frame-end free silently empties the nav map.
			remove_child(node)
			node.queue_free()


func _build_room() -> void:
	var tile_set := _build_plain_tile_set()
	_floor_layer = _make_layer("Floor", tile_set, true)
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
	var source := TileSetAtlasSource.new()
	var image := Image.create_empty(CELL_SIZE, CELL_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = Vector2i(CELL_SIZE, CELL_SIZE)
	source.create_tile(Vector2i.ZERO)
	tile_set.add_source(source, 0)
	return tile_set


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

