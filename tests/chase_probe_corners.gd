extends RefCounted

## Corner-navigation stages for chase_probe, extracted to keep the probe
## under the pinned 1000-line lint cap. Stage runners receive the probe
## and drive its harness (spawn, force-chase, state, checks, tee, player).

const ARCHER_SCENE := "res://entities/enemies/arcane_archer/arcane_archer.tscn"
const NECROMANCER_SCENE := "res://entities/enemies/necromancer/necromancer.tscn"
## Travel budget: pocket exit needs ~17-20 px of closure (the right
## muzzle's 10 px spawn disc clears the wall face near x=103); the
## bounded close-in floor (half of this range) must sit well below the
## initial 112 px gap or the cornered body holds at once.
const POCKET_ATTACK_RANGE := 180.0



## Solo rounding regression: early waypoint switching cuts the corner
## chord inside the bake margin and the body grinds the tile apex — the
## playtest "catches on obstacle blocks". The run must hold the corridor
## line past both apices, never stall, and reach the attack gate.
static func stage_round(probe) -> void:
	probe._tee("  stage: solo archer rounds the block corner without grinding")
	var archer: BaseEnemy = await probe._spawn_enemy(ARCHER_SCENE, Vector2(56, 88))
	probe._player.global_position = Vector2(170, 130)
	probe._force_chase(archer)
	var apices := [Vector2(240, 96), Vector2(240, 104)]
	var min_apex_clearance := INF
	var stalled := false
	var window_start := 0.0
	var window_pos := archer.global_position
	var clock := 0.0
	var attacked := false
	while clock < 10.0:
		await probe.get_tree().physics_frame
		clock += probe.get_physics_process_delta_time()
		if probe._current_state(archer) is EnemyAttack:
			attacked = true
			break
		for apex in apices:
			min_apex_clearance = minf(min_apex_clearance,
				archer.global_position.distance_to(apex))
		if clock - window_start >= 0.6:
			stalled = stalled or archer.global_position.distance_to(window_pos) < 2.0
			window_start = clock
			window_pos = archer.global_position
	probe._check(attacked, "corner route reached the attack gate (%.1fs)" % clock)
	probe._check(not stalled, "no stall window while rounding (0.6s probes)")
	probe._check(min_apex_clearance >= 4.5,
		"body held the corridor line past the apices (min %.1f px)" % min_apex_clearance)


## Pair squeeze at the same corner: RVO separation smaller than the summed
## body radii lets archers shove each other into the turn (the playtest
## "catches near another enemy"). Both must round cleanly, keeping real
## body separation, and reach the attack gate. Attack latches per archer:
## standoff volleys from two cadences need not overlap at a sampled frame.
static func stage_pair(probe) -> void:
	probe._tee("  stage: archer pair rounds the corner without body contact")
	var first: BaseEnemy = await probe._spawn_enemy(ARCHER_SCENE, Vector2(48, 80))
	var second: BaseEnemy = await probe._spawn_enemy(ARCHER_SCENE, Vector2(24, 96))
	probe._player.global_position = Vector2(170, 130)
	probe._force_chase(first)
	probe._force_chase(second)
	var min_gap := INF
	var window_start := 0.0
	var window_first := first.global_position
	var window_second := second.global_position
	var clock := 0.0
	var first_attacked := false
	var second_attacked := false
	while clock < 18.0:
		await probe.get_tree().physics_frame
		clock += probe.get_physics_process_delta_time()
		min_gap = minf(min_gap, first.global_position.distance_to(second.global_position))
		if probe._current_state(first) is EnemyAttack:
			first_attacked = true
		if probe._current_state(second) is EnemyAttack:
			second_attacked = true
		if first_attacked and second_attacked:
			break
		if clock - window_start >= 0.8:
			var progressed := first.global_position.distance_to(window_first) >= 2.0 \
					or second.global_position.distance_to(window_second) >= 2.0
			if not progressed:
				break
			window_start = clock
			window_first = first.global_position
			window_second = second.global_position
	probe._check(first_attacked and second_attacked,
		"both archers reached the attack gate (%.1fs)" % clock)
	probe._check(min_gap >= 13.6,
		"pair kept separation past the corner (min %.1f px)" % min_gap)


## Wall-pocket reposition regression: a gate-closed ranged kit (muzzle
## band buried against the wall column) must not dead-stand. The FIRING
## fan offers no stance in the pocket - along-wall stances stay buried,
## in-wall goals clamp back to the body - so the chase takes the
## cornered latch, and the latch must TRAVEL until the band unburied,
## then fire. The playtest failure was a permanent stand.
static func stage_wall_pocket(probe) -> void:
	probe._tee("  stage: wall-pocket necromancer travels out of a buried band and fires")
	var player_anchor: Vector2 = probe._player.global_position
	var necromancer: BaseEnemy = await probe._spawn_enemy(
			NECROMANCER_SCENE, Vector2(120, 40))
	probe._player.global_position = Vector2(8, 40)
	var attack: EnemyAttack = necromancer.get_node("State Control/EnemyAttack")
	probe._check(not attack.band_clear_at(necromancer.global_position),
			"park buries the volley band")
	var chase: EnemyChase = probe._chase_state(necromancer)
	chase.attempt_attack_range = POCKET_ATTACK_RANGE
	probe._force_chase(necromancer)
	var latch_seen := false
	var attacked := false
	var start := necromancer.global_position
	var window_start := 0.0
	var window_pos := start
	var clock := 0.0
	while clock < 8.0:
		await probe.get_tree().physics_frame
		clock += probe.get_physics_process_delta_time()
		latch_seen = latch_seen or chase._retreat_suppressed > 0.0
		var state: State = probe._current_state(necromancer)
		attacked = state is EnemyAttack or state is EnemySummon
		if attacked:
			break
		if clock - window_start >= 2.0:
			if necromancer.global_position.distance_to(window_pos) < 2.0:
				break
			window_start = clock
			window_pos = necromancer.global_position
	var traveled := necromancer.global_position.distance_to(start)
	probe._check(latch_seen, "gate closure cornered through the firing reposition")
	probe._check(traveled >= 10.0,
			"cornered closure traveled out of the pocket (%.1f px)" % traveled)
	probe._check(attacked, "band unburied into an offensive action (%.1fs)" % clock)
	probe._player.global_position = player_anchor
