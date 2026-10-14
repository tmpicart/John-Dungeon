extends Node

## Headless regression probe for the hybrid-routing magic missile. Run:
## Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/missile_probe.tscn
## Exits 0 on pass, 1 on failure. A real missile scene is flown against a stub
## player body on a synthetic baked room. The stages cover the untouched direct
## arc (contact kill on a clear lane), cover rounding (the missile crosses a
## walled column through its open rows and converges on the shadowed stub
## instead of dying on the wall), convergence while the stub drifts behind
## cover (repath while blocked), spawn clearance (a necromancer volley parked
## under an overhang fires only from the muzzle that is not buried; muzzles
## hanging past a thin strip of cover and muzzles centered in a physically
## open slot under spanning wall art are skipped by the clearance margin),
## the muzzle band (a stance with any buried or unreachable muzzle closes
## the chase handover before the attack flow starts; a clear stance opens
## it), the
## width-aware routing exit (a tangent-clear center ray with a clipping wide
## lane holds the route), the whiff gate at a muzzle-clear park (settled
## volleys that never reached the player close the chase handover until the
## body repositions or the retry window lapses; in-flight volleys and
## arrivals never close it), and the reflect pairing set (a reflected torso
## pass deals one damage and dies on the hurtbox that took it, a shin graze
## passes under with neither, a blocked back-hit still consumes, and a
## parried shot survives its own reflect flush). The cone-seek set covers
## the reworked reflect: an empty cone settles straight, an in-cone enemy
## is acquired and consumed, an enemy dead behind the launch line stays
## excluded, a live lock suppresses acquisition until freed, and a launch
## buried into a slab still rounds the cover onto its no-line-of-sight
## target.

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
## Buried-volley stage: a two-cell shelf buries the necromancer's left and
## top muzzles ((-15,-25) and (0,-30) at this park position); only the
## right shoulder (15,-25) is in the open, with enough standoff past the
## shelf face to satisfy the spawn-clearance disc.
const NECRO_SCENE := "res://entities/enemies/necromancer/necromancer.tscn"
const NECRO_PARK := Vector2(4.9, 6.5)
const NECRO_SHELF_CELLS: Array[Vector2i] = [Vector2i(3, 4), Vector2i(4, 4)]
const NECRO_CLEAR_MUZZLE := Vector2(93.4, 79.0)
## Whiff-gate stage park: all three muzzles clear of the wall column and
## the volley-stage cells, so only volley outcomes move the handover gate.
const NECRO_WHIFF_PARK := Vector2(11.5, 6.5)
## Whiff-stage stub spot: every muzzle sits far outside the arrival radius,
## so a fired volley only settles whiffed when its shots are retired.
const WHIFF_STUB_AT := Vector2(2.0, 2.0)
## Through-wall stage: a one-cell strip between the body and the muzzle
## band. Every muzzle point stays in open space above the strip, but each
## body-to-muzzle line crosses it.
const NECRO_STRIP_CELLS: Array[Vector2i] = [
	Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5)]
## Wide-exit stage: the block's bottom-right corner passes ~1 px under the
## spawn-to-stub line — center ray clear, block-side lane clipping it.
const GATE_MISSILE_AT := Vector2(6.0, 9.0)
const GATE_STUB_AT := Vector2(14.0, 7.5)
const GATE_BLOCK_CENTER := Vector2(10.0, 7.5)
## Reflected-pairing stages: an inline necromancer-shaped target (feet body
## disc at 6.5,5.0 with a torso hurtbox capsule reaching up to row 4.25)
## west of the wall column. The torso lane crosses the hurtbox 12 px above
## the feet disc — the geometry that used to split damage from consumption;
## the shin lane at row 5.75 clears both surfaces. Homing locks sit far
## downrange so no flight reaches its target inside the measurement window.
const REFLECT_ENEMY_AT := Vector2(6.5, 5.0)
const REFLECT_TORSO_MARK := Vector2(6.5, 4.25)
const REFLECT_MISSILE_AT := Vector2(4.5, 4.25)
const REFLECT_SHIN_MISSILE_AT := Vector2(4.5, 5.75)
const CONTACT_BUDGET := 10.0
const ROUTE_BUDGET := 14.0
## Cone-seek stages run east of the wall column or in the open bottom band.
const CONE_EMPTY_AT := Vector2(4.5, 8.75)
const CONE_EXCL_MISSILE_AT := Vector2(4.5, 8.75)
const CONE_ACQ_MISSILE_AT := Vector2(3.0, 8.75)
const CONE_ACQ_ENEMY_AT := Vector2(10.0, 8.5)
const CONE_EXCL_ENEMY_AT := Vector2(1.5, 8.75)
const CONE_RELEASE_MISSILE_AT := Vector2(3.0, 9.0)
const CONE_RELEASE_ENEMY_AT := Vector2(10.0, 9.0)
const CONE_TRICK_MISSILE_AT := Vector2(9.25, 3.375)
const CONE_TRICK_SLAB := Vector2(13.0, 3.0)
const CONE_TRICK_ENEMY_AT := Vector2(15.5, 8.0)

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
	await _stage_through_wall_muzzles()
	await _stage_hollow_slot_muzzles()
	await _stage_buried_volley()
	await _stage_band_gate()
	await _stage_wide_exit_gate()
	await _stage_whiff_gate()
	await _stage_reflected_torso_pairing()
	await _stage_reflected_shin_graze()
	await _stage_blocked_back_hit_pairing()
	await _stage_parry_keeps_the_shot()
	await _stage_cone_empty_flight()
	await _stage_cone_acquisition()
	await _stage_cone_exclusion()
	await _stage_cone_lock_release()
	await _stage_cone_around_cover()
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


## Through-wall muzzles: the strip sits between the body and the muzzle
## band, so every muzzle point hangs just past the cover face. Both spawn
## gates must refuse them — the clearance disc (the points sit inside the
## strip's standoff margin) and the body-to-muzzle reachability rays.
## Nothing may spawn on the player's side of the cover; the fully sealed
## volley registers zero, which the whiff gate reads as an immediate
## repositioning trigger.
func _stage_through_wall_muzzles() -> void:
	for cell in NECRO_STRIP_CELLS:
		_walls_layer.set_cell(cell, 0, Vector2i.ZERO)
	var strip := _make_block(Vector2(4.5, 5.5), Vector2i(3, 1))
	var stub := _spawn_stub(TARGET)
	var necro: Node2D = load(NECRO_SCENE).instantiate()
	add_child(necro)
	necro.global_position = NECRO_PARK * CELL_SIZE
	# Frozen like the whiff stage: exact muzzle geometry, no handover race.
	necro.process_mode = Node.PROCESS_MODE_DISABLED
	var attack_state: EnemyAttack = necro.get_node("State Control/EnemyAttack")
	await get_tree().physics_frame
	await get_tree().physics_frame
	var points_blocked := true
	var segments_blocked := true
	for offset in attack_state.projectile_offsets:
		var muzzle := necro.global_position + offset
		points_blocked = points_blocked \
				and not attack_state.enemy.spawn_point_clear(muzzle)
		segments_blocked = segments_blocked \
				and not attack_state.enemy.aim_line_clear(
						necro.global_position, muzzle)
	_check(points_blocked, "overhanging muzzles all read blocked by clearance")
	_check(segments_blocked, "sealed muzzles all read unreachable from the body")
	var spawned := _fire_and_diff(attack_state)
	_check(spawned.is_empty(),
			"through-wall volley spawns nothing on the player's side")
	_check(not attack_state.fire_gate_open(),
			"sealed volley closes the whiff gate for repositioning")
	for cell in NECRO_STRIP_CELLS:
		_walls_layer.erase_cell(cell)
	necro.queue_free()
	strip.queue_free()
	await _clear_stage_actors(stub)


## Hollow-slot muzzles: half-depth jamb blocks flank a physically open
## 16 px slot that wall art spans (the north-wall alcove-mouth defect). A
## muzzle centered in the slot passes a bare point check but clips a jamb
## within its first flight frames; the clearance disc must refuse it. All
## muzzles blocked, nothing spawns, the whiff gate closes.
func _stage_hollow_slot_muzzles() -> void:
	var left_jamb := _make_jamb(Vector2(66.4, 72.0))
	var right_jamb := _make_jamb(Vector2(90.4, 72.0))
	var stub := _spawn_stub(TARGET)
	var necro: Node2D = load(NECRO_SCENE).instantiate()
	add_child(necro)
	necro.global_position = NECRO_PARK * CELL_SIZE
	# Frozen like the whiff stage: exact muzzle geometry, no handover race.
	necro.process_mode = Node.PROCESS_MODE_DISABLED
	var attack_state: EnemyAttack = necro.get_node("State Control/EnemyAttack")
	await get_tree().physics_frame
	await get_tree().physics_frame
	var points_blocked := true
	for offset in attack_state.projectile_offsets:
		var muzzle := necro.global_position + offset
		points_blocked = points_blocked \
				and not attack_state.enemy.spawn_point_clear(muzzle)
	_check(points_blocked, "slot-centered and jamb-buried muzzles all read blocked")
	var spawned := _fire_and_diff(attack_state)
	_check(spawned.is_empty(), "hollow-slot volley spawns nothing inside the wall art")
	_check(not attack_state.fire_gate_open(),
			"sealed volley closes the whiff gate for repositioning")
	left_jamb.queue_free()
	right_jamb.queue_free()
	necro.queue_free()
	await _clear_stage_actors(stub)


## Spawn clearance: the necromancer parked under the shelf fires the volley
## directly (blind fire is this enemy's design — no LOS gate). The buried
## muzzles must be skipped by the spawn-clearance check, not clamped and
## not spawned inside the wall to die on contact.
func _stage_buried_volley() -> void:
	for cell in NECRO_SHELF_CELLS:
		_walls_layer.set_cell(cell, 0, Vector2i.ZERO)
	var shelf := _make_block(Vector2(4.0, 4.5), Vector2i(2, 1))
	var necro: Node2D = load(NECRO_SCENE).instantiate()
	add_child(necro)
	necro.global_position = NECRO_PARK * CELL_SIZE
	var stub := _spawn_stub(TARGET)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var group_before := get_tree().get_nodes_in_group("Enemies")
	var attack_state: EnemyAttack = necro.get_node("State Control/EnemyAttack")
	attack_state._spawn_projectiles()
	var spawned := get_tree().get_nodes_in_group("Enemies").filter(
			func(node: Node) -> bool: return not group_before.has(node))
	_check(spawned.size() == 1, "buried volley spawned only the clear muzzle")
	if spawned.size() == 1:
		var at_clear: bool = spawned[0].global_position.distance_to(
				NECRO_CLEAR_MUZZLE) < 0.5
		_check(at_clear, "survivor spawned at the right-shoulder muzzle")
		# The survivor then flies a normal route — on this geometry its
		# turn-capped corridor arc can later carry it into the wall column,
		# which is ordinary wall contact, not a spawn defect. The airborne
		# window only has to prove the spawn point itself was clear.
		var airborne := true
		for i in 12:
			await get_tree().physics_frame
			airborne = airborne and is_instance_valid(spawned[0])
		_check(airborne, "survivor airborne past its first flight ticks")
		if is_instance_valid(spawned[0]):
			spawned[0].queue_free()
	necro.queue_free()
	shelf.queue_free()
	await _clear_stage_actors(stub)


## Muzzle band: a stance with any buried or unreachable muzzle closes the
## chase handover before an attack flow starts (no partial volleys); with
## every muzzle in the open the gate defers to the whiff logic. The shelf
## cells from the buried stage bury the left and top muzzles here.
func _stage_band_gate() -> void:
	var necro: Node2D = load(NECRO_SCENE).instantiate()
	add_child(necro)
	necro.global_position = NECRO_PARK * CELL_SIZE
	necro.process_mode = Node.PROCESS_MODE_DISABLED
	var attack_state: EnemyAttack = necro.get_node("State Control/EnemyAttack")
	var shelf := _make_block(Vector2(4.0, 4.5), Vector2i(2, 1))
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(not attack_state.band_clear_at(necro.global_position),
			"a stance with buried muzzles reads band-blocked")
	_check(not attack_state.fire_gate_open(),
			"band-blocked stance closes the handover before any volley")
	# Clear the band: shelf cells plus the through-wall stage's strip cells,
	# then the block body — every muzzle back in the open.
	for cell in NECRO_SHELF_CELLS:
		_walls_layer.erase_cell(cell)
	for cell in NECRO_STRIP_CELLS:
		_walls_layer.erase_cell(cell)
	shelf.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(attack_state.band_clear_at(necro.global_position),
			"an all-muzzles-clear stance reads band-clear")
	_check(attack_state.fire_gate_open(),
			"band-clear stance with no whiff memory opens the handover")
	necro.queue_free()
	await get_tree().physics_frame


## Width-aware exit: with the block present the center ray to the stub is
## clear but the block-side lane clips the corner, so routing must not
## release (the ray-thin gate alone would). Freeing the block clears
## every lane.
func _stage_wide_exit_gate() -> void:
	var stub := _spawn_stub(GATE_STUB_AT)
	var missile := _spawn_missile(GATE_MISSILE_AT)
	var block := _make_block(GATE_BLOCK_CENTER, Vector2i(2, 1))
	await get_tree().physics_frame
	_check(missile.call("_line_to_player_clear"),
			"tangent corner: center ray reads clear")
	_check(not missile.call("_lane_clear_wide"),
			"tangent corner: wide exit lane reads blocked")
	block.queue_free()
	await get_tree().physics_frame
	_check(missile.call("_lane_clear_wide"),
			"no corner: every exit lane reads clear")
	missile.queue_free()
	await _clear_stage_actors(stub)


## Spawns one volley through the attack state and returns the newly added
## Enemies-group members (the probe reuses the group as its spawn ledger).
func _fire_and_diff(attack_state: EnemyAttack) -> Array:
	var before := get_tree().get_nodes_in_group("Enemies")
	attack_state._spawn_projectiles()
	return get_tree().get_nodes_in_group("Enemies").filter(
			func(node: Node) -> bool: return not before.has(node))


## Whiff-triggered repositioning at a muzzle-clear park: with the flag
## runtime-enabled, a settled volley that never reached the player closes
## the chase handover gate; the gate reopens on the configured travel, on
## the retry window lapsing, and it never closes for in-flight volleys or
## arrived ones. The default-off behavior is guarded first: without the
## flag a whiffed volley changes nothing. Volleys are settled by freeing
## their live shots (retirement without arrival).
func _stage_whiff_gate() -> void:
	var stub := _spawn_stub(WHIFF_STUB_AT)
	var necro: Node2D = load(NECRO_SCENE).instantiate()
	add_child(necro)
	necro.global_position = NECRO_WHIFF_PARK * CELL_SIZE
	# Freeze the enemy's own state machine: this stage drives the attack
	# state directly and must not race its live handover loop.
	necro.process_mode = Node.PROCESS_MODE_DISABLED
	var attack_state: EnemyAttack = necro.get_node("State Control/EnemyAttack")
	await get_tree().physics_frame
	await get_tree().physics_frame

	# The off guard pins the script default explicitly — the necromancer
	# scene ships enabled.
	attack_state.reposition_after_whiff = false
	await _fire_and_free(attack_state)
	_check(attack_state.fire_gate_open(),
			"default-off: a settled whiff leaves the gate open")
	attack_state.reposition_after_whiff = true
	await _fire_and_free(attack_state)
	_check(not attack_state.fire_gate_open(),
			"a settled volley that never arrived closes the gate")

	# Travel from the fire position reopens; returning re-closes only via
	# a fresh verdict.
	necro.global_position += Vector2(48.0, 0.0)
	_check(attack_state.fire_gate_open(),
			"repositioning the full distance reopens the gate")
	necro.global_position = NECRO_WHIFF_PARK * CELL_SIZE

	# A fresh in-flight volley has no verdict: gate open.
	var airborne := _fire_and_diff(attack_state)
	_check(airborne.size() == 3, "clear park spawns the full three-muzzle volley")
	_check(attack_state.fire_gate_open(),
			"a fresh in-flight volley never closes the gate")
	# An arrival settles the volley as succeeded: the gate stays open.
	if airborne.size() == 3:
		airborne[0].global_position = stub.global_position + Vector2(0.0, -10.0)
		await get_tree().physics_frame
		await get_tree().physics_frame
		_check(attack_state.fire_gate_open(), "arrival never closes the gate")
	for shot in airborne:
		if is_instance_valid(shot):
			shot.queue_free()
	await get_tree().physics_frame
	await _fire_and_free(attack_state)
	_check(not attack_state.fire_gate_open(),
			"a fresh whiff closes the gate again")
	attack_state.whiff_retry_seconds = 0.4
	# fire_gate_open reads wall time (Time.get_ticks_msec), so the wait must
	# be wall-time-bounded too — frame counts pace differently headless.
	var lapse_start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - lapse_start < 450:
		await get_tree().physics_frame
	_check(attack_state.fire_gate_open(),
			"retry-window lapse reopens the gate")
	necro.queue_free()
	await _clear_stage_actors(stub)


## Fires one volley and frees its shots the same tick, settling the volley
## whiffed (retirement without arrival) for the gate steps that follow.
func _fire_and_free(attack_state: EnemyAttack) -> void:
	for shot in _fire_and_diff(attack_state):
		shot.queue_free()
	await get_tree().physics_frame


## Reflected-pairing stages: an inline necromancer-shaped target (feet
## body disc, torso hurtbox area) west of the wall column. The torso pass
## crosses the hurtbox 12 px above the feet disc — the exact geometry that
## used to split damage from consumption after a reflect. The headless
## mouse is meaningless, so each stage pins launch_angle and rotation after
## reflect() and hands the missile a live lock node as its target (an
## invalid target would push it into the stub's missing aim API).
func _spawn_reflect_target(at: Vector2) -> Node2D:
	var enemy := Node2D.new()
	enemy.add_to_group("Enemies")
	var body := StaticBody2D.new()
	body.collision_layer = 1 << 1
	body.collision_mask = 0
	var body_shape := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = 6.67
	body_shape.shape = body_circle
	body.add_child(body_shape)
	enemy.add_child(body)
	var hurtbox := Area2D.new()
	hurtbox.collision_layer = 1 << 8
	hurtbox.collision_mask = 1 << 5
	var hurt_shape := CollisionShape2D.new()
	var hurt_capsule := CapsuleShape2D.new()
	hurt_capsule.radius = 8.0
	hurt_capsule.height = 24.0
	hurt_shape.shape = hurt_capsule
	hurt_shape.position = Vector2(0, -12)
	hurtbox.add_child(hurt_shape)
	enemy.add_child(hurtbox)
	enemy.set_meta("damage_count", 0)
	hurtbox.area_entered.connect(_count_reflect_damage.bind(enemy))
	add_child(enemy)
	enemy.global_position = at * CELL_SIZE
	return enemy


func _count_reflect_damage(_area: Area2D, enemy: Node2D) -> void:
	enemy.set_meta("damage_count", int(enemy.get_meta("damage_count")) + 1)


## The flight crosses the torso hurtbox a full 12 px above the feet disc:
## damage and consumption must pair on the hurtbox the old body-only
## consume let the shot pierce past.
func _stage_reflected_torso_pairing() -> void:
	var stub := _spawn_stub(TARGET)
	var enemy := _spawn_reflect_target(REFLECT_ENEMY_AT)
	# Downrange lock far past the assert stop: the flight must consume on the
	# hurtbox long before it could reach its homing target and orbit.
	var lock := Node2D.new()
	add_child(lock)
	lock.global_position = Vector2(12.5, 4.25) * CELL_SIZE
	var missile := _spawn_missile(REFLECT_MISSILE_AT)
	missile.reflect()
	missile.launch_angle = 0.0
	missile.rotation = 0.0
	missile.target = lock
	var freed := false
	var clock := 0.0
	var min_hurt := INF
	var last_pos: Vector2 = missile.global_position
	while clock < CONTACT_BUDGET:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		if not is_instance_valid(missile):
			freed = true
			break
		last_pos = missile.global_position
		min_hurt = minf(min_hurt,
				missile.global_position.distance_to(REFLECT_TORSO_MARK * CELL_SIZE))
		if missile.global_position.x > REFLECT_ENEMY_AT.x * CELL_SIZE + 24.0:
			break
	_tee("    torso flight end (%.0f, %.0f), hurtbox-center min %.1f px"
			% [last_pos.x, last_pos.y, min_hurt])
	_check(int(enemy.get_meta("damage_count")) == 1,
			"reflected torso pass deals exactly one damage")
	_check(freed, "reflected torso pass consumes on the hurtbox")
	enemy.queue_free()
	lock.queue_free()
	await _clear_stage_actors(stub)


## The lane clears both surfaces by ~1.8 px: the shot must fly under with
## no damage and no consume — the old shin-graze vanish, inverted.
func _stage_reflected_shin_graze() -> void:
	var stub := _spawn_stub(TARGET)
	var enemy := _spawn_reflect_target(REFLECT_ENEMY_AT)
	# Downrange lock far past the assert stop: a lock on the flight line gets
	# overshot, and the wrap-around U-turn orbits straight into the enemy.
	var lock := Node2D.new()
	add_child(lock)
	lock.global_position = Vector2(12.5, 5.75) * CELL_SIZE
	var missile := _spawn_missile(REFLECT_SHIN_MISSILE_AT)
	missile.reflect()
	missile.launch_angle = 0.0
	missile.rotation = 0.0
	missile.target = lock
	var passed_enemy := false
	var clock := 0.0
	var min_hurt := INF
	var last_pos: Vector2 = missile.global_position
	while clock < CONTACT_BUDGET:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		if not is_instance_valid(missile):
			break
		last_pos = missile.global_position
		min_hurt = minf(min_hurt,
				missile.global_position.distance_to(REFLECT_TORSO_MARK * CELL_SIZE))
		if missile.global_position.x > REFLECT_ENEMY_AT.x * CELL_SIZE + 16.0:
			passed_enemy = true
			break
	_tee("    shin flight end (%.0f, %.0f), hurtbox-center min %.1f px"
			% [last_pos.x, last_pos.y, min_hurt])
	_check(passed_enemy and is_instance_valid(missile),
			"reflected shin graze passes under with no consume")
	_check(int(enemy.get_meta("damage_count")) == 0,
			"reflected shin graze deals no damage")
	if is_instance_valid(missile):
		missile.queue_free()
	enemy.queue_free()
	lock.queue_free()
	await _clear_stage_actors(stub)


## A block held away from the hit still takes the damage without parrying;
## the tick sweep must consume the shot the old flush handler refused to
## free while blocking.
func _stage_blocked_back_hit_pairing() -> void:
	var stub := _spawn_stub(Vector2(4.0, 5.0))
	stub.combat.blocking = true
	var missile := _spawn_missile(Vector2(2.5, 5.0))
	var freed := false
	var clock := 0.0
	while clock < CONTACT_BUDGET:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		if not is_instance_valid(missile):
			freed = true
			break
	_check(freed, "blocked back-hit consumes on the player body")
	await _clear_stage_actors(stub)


## A frontal parry reflects in the same window the flush reports the body
## contact. The probe mirrors that ordering: physics_frame resumes before
## the shot's next _physics_process, so reflecting on the first tick the
## stub overlap is visible lands the parry before the tick sweep can read
## a pre-reflection contact. The shot must keep flying with the flag set.
func _stage_parry_keeps_the_shot() -> void:
	var stub := _spawn_stub(Vector2(4.0, 5.0))
	stub.combat.blocking = true
	var lock := Node2D.new()
	add_child(lock)
	lock.global_position = Vector2(1.5, 5.0) * CELL_SIZE
	var missile := _spawn_missile(Vector2(2.5, 5.0))
	var reflect_clock := -1.0
	var clock := 0.0
	while clock < CONTACT_BUDGET:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		if not is_instance_valid(missile):
			break
		if reflect_clock < 0.0:
			var hitbox: Area2D = missile.get_node("Hitbox")
			if hitbox.get_overlapping_bodies().has(stub):
				missile.reflect()
				missile.launch_angle = PI
				missile.rotation = PI
				missile.target = lock
				reflect_clock = clock
		elif clock - reflect_clock >= 0.4:
			break
	_check(reflect_clock >= 0.0, "parry reflect lands at the contact flush")
	_check(is_instance_valid(missile) and missile.reflected,
			"parried shot survives its reflect window")
	if is_instance_valid(missile):
		missile.queue_free()
	lock.queue_free()
	await _clear_stage_actors(stub)


## A parked necromancer: a real BaseEnemy behind the EnemyHurtbox. Freeze the
## brain's State Control, not the whole body — a PROCESS_MODE_DISABLED
## ancestor takes the hurtbox area out of space-query visibility.
func _spawn_cone_enemy(at: Vector2) -> Node2D:
	var necro: Node2D = load(NECRO_SCENE).instantiate()
	add_child(necro)
	necro.global_position = at * CELL_SIZE
	var brain: Node = necro.get_node_or_null("State Control")
	if brain != null:
		brain.process_mode = Node.PROCESS_MODE_DISABLED
	return necro


## Shared cone-stage flight: ticks until the missile frees or the budget
## lapses, tracking acquisition of `necro` and the last live position.
func _fly_cone(missile: Node2D, necro: Node2D, budget: float) -> Dictionary:
	var acquired := false
	var freed := false
	var clock := 0.0
	var last_pos: Vector2 = missile.global_position
	while clock < budget and not freed:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		if not is_instance_valid(missile):
			freed = true
		else:
			last_pos = missile.global_position
			acquired = acquired or (necro != null and missile.target == necro)
	return {"acquired": acquired, "freed": freed, "end": last_pos}


## Nothing alive inside the cone: the shot stays targetless and never
## bends off the launch line.
func _stage_cone_empty_flight() -> void:
	var stub := _spawn_stub(TARGET)
	var missile := _spawn_missile(CONE_EMPTY_AT)
	missile.reflect()
	missile.launch_angle = 0.0
	missile.rotation = 0.0
	var out := await _fly_cone(missile, null, 0.9)
	_check(not out.freed, "empty-cone flight survives the window")
	_check(not out.acquired, "empty-cone flight never acquires")
	_check(is_instance_valid(missile) and absf(missile.rotation) < 0.001,
			"empty-cone flight keeps the launch heading")
	if is_instance_valid(missile):
		missile.queue_free()
	await _clear_stage_actors(stub)


## A living enemy inside the cone is picked up while targetless and the
## shot converges onto the hurtbox.
func _stage_cone_acquisition() -> void:
	var stub := _spawn_stub(TARGET)
	var necro := _spawn_cone_enemy(CONE_ACQ_ENEMY_AT)
	var missile := _spawn_missile(CONE_ACQ_MISSILE_AT)
	missile.reflect()
	missile.launch_angle = 0.0
	missile.rotation = 0.0
	var out := await _fly_cone(missile, necro, CONTACT_BUDGET)
	_check(out.acquired, "cone acquisition picks the in-cone enemy")
	_check(out.freed, "cone acquisition consumes on the enemy hurtbox")
	if is_instance_valid(missile):
		missile.queue_free()
	necro.queue_free()
	await _clear_stage_actors(stub)


## In range but dead behind the launch heading (outside the half-angle):
## never acquired — the cone, not the range, gates the lock.
func _stage_cone_exclusion() -> void:
	var stub := _spawn_stub(TARGET)
	var necro := _spawn_cone_enemy(CONE_EXCL_ENEMY_AT)
	var missile := _spawn_missile(CONE_EXCL_MISSILE_AT)
	missile.reflect()
	missile.launch_angle = 0.0
	missile.rotation = 0.0
	var out := await _fly_cone(missile, necro, 0.8)
	_check(not out.freed, "cone exclusion survives the window")
	_check(not out.acquired, "an enemy dead behind the launch line is never acquired")
	_check(is_instance_valid(missile) and absf(missile.rotation) < 0.001,
			"cone exclusion flight stays on the launch line")
	if is_instance_valid(missile):
		missile.queue_free()
	necro.queue_free()
	await _clear_stage_actors(stub)


## Sticky lock: a handed lock suppresses acquisition entirely; freeing it
## hands the shot to the cone, which picks up the enemy it was ignoring.
func _stage_cone_lock_release() -> void:
	var stub := _spawn_stub(TARGET)
	var necro := _spawn_cone_enemy(CONE_RELEASE_ENEMY_AT)
	var lock := Node2D.new()
	add_child(lock)
	lock.global_position = Vector2(12.5, 9.0) * CELL_SIZE
	var missile := _spawn_missile(CONE_RELEASE_MISSILE_AT)
	missile.reflect()
	missile.launch_angle = 0.0
	missile.rotation = 0.0
	missile.target = lock
	for i in 3:
		await get_tree().physics_frame
	_check(is_instance_valid(missile) and missile.target == lock,
			"a live lock suppresses cone acquisition")
	lock.queue_free()
	var out := await _fly_cone(missile, necro, CONTACT_BUDGET)
	_check(out.acquired, "releasing the lock hands the shot to the cone")
	_check(out.freed, "re-acquired cone lock consumes on the enemy hurtbox")
	if is_instance_valid(missile):
		missile.queue_free()
	necro.queue_free()
	await _clear_stage_actors(stub)


## The trick shot: launched dead-straight INTO a slab, the shot acquires a
## target it has no line of sight to and swings under the slab corner to
## collect it — launch committed, steering earns the corner.
func _stage_cone_around_cover() -> void:
	var stub := _spawn_stub(TARGET)
	var slab := _make_block(CONE_TRICK_SLAB, Vector2i(1, 1))
	var necro := _spawn_cone_enemy(CONE_TRICK_ENEMY_AT)
	var missile := _spawn_missile(CONE_TRICK_MISSILE_AT)
	missile.reflect()
	missile.launch_angle = 0.0
	missile.rotation = 0.0
	var out := await _fly_cone(missile, necro, CONTACT_BUDGET)
	_tee("    trick flight end (%.0f, %.0f)" % [out.end.x, out.end.y])
	_check(out.acquired, "the buried launch still acquires through cover")
	_check(out.freed, "the trick shot ends in the enemy hurtbox")
	_check(out.freed and out.end.x > CONE_TRICK_SLAB.x * CELL_SIZE,
			"the trick shot rounds the slab instead of dying on it")
	slab.queue_free()
	necro.queue_free()
	await _clear_stage_actors(stub)


## Physical Environment block for the later stages: `center` in tile units,
## `cells` spans the rectangle, mirroring the wall column's body.
func _make_block(center: Vector2, cells: Vector2i) -> StaticBody2D:
	var block := StaticBody2D.new()
	block.collision_layer = 1 << 2
	block.collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(cells.x * CELL_SIZE, cells.y * CELL_SIZE)
	shape_node.shape = shape
	block.add_child(shape_node)
	add_child(block)
	block.position = center * CELL_SIZE
	return block


## Half-depth wall block (8 x 16 px): one arch-jamb half, mirroring the
## room tileset's jamb atoms.
func _make_jamb(center: Vector2) -> StaticBody2D:
	var jamb := StaticBody2D.new()
	jamb.collision_layer = 1 << 2
	jamb.collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(CELL_SIZE / 2.0, CELL_SIZE)
	shape_node.shape = shape
	jamb.add_child(shape_node)
	add_child(jamb)
	jamb.position = center
	return jamb


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