extends State
class_name EnemyChase

## Shared pathfinding chase. Per-enemy behavior (proximity retreat, hit-triggered
## retreat, line-of-sight gating, attack range shape and summon rolls) is
## configured through exports instead of override states.

enum AttackRangeShape { RADIAL, AXIS_BOX }

## Box-press offset: a level point just inside the swing box (width 15) that
## the player's body slides the press into the level band from.
const MELEE_LEVEL_OFFSET := 10.0
## Fraction of speed * press_stall_window a press must cover per window;
## less means its level point is sealed and the press reacts (side flip,
## then guard hold) instead of grinding the wall forever.
const PRESS_PROGRESS_FRACTION := 0.25
## Seconds the outcome gate must stay closed before the closure routes to
## the reposition state. The clearance predicate reads per-pixel near
## band edges, so an unconfirmed handover thrashes reposition/chase on a
## body drifting across the boundary; genuine burials hold continuously
## and confirm within a handful of physics ticks.
const REPOSITION_GATE_CONFIRM := 0.1
## Seconds the player must hold inside retreat_range before the proximity
## flight triggers — same boundary logic as REPOSITION_GATE_CONFIRM: a
## body straddling the radius edge must not flap retreat/chase.
const PROXIMITY_RETREAT_CONFIRM := 0.1
## Shuffle steps never come tighter than this, so a retarget landing next
## to the body cannot re-roll the drift direction almost every tick.
const SHUFFLE_MIN_STEP := 8.0
## Drift speed as a fraction of chase speed: a live-looking wander that
## still reads as holding the stance.
const SHUFFLE_SPEED_FRACTION := 0.75

@export var navigation_agent: NavigationAgent2D
@export var idle_state: State
## Unassigned attack_state marks a pacifist chaser (e.g. the green slime).
@export var attack_state: State
@export var retreat_state: State
@export var summon_state: State
## Optional firing-solution reposition state (EnemyRetreat, FIRING
## desire): takes the outcome-gate handover when the closure is not
## line-of-sight — closing on the player cannot unbury a spawn band.
## Unwired enemies keep the blind close-in.
@export var reposition_state: State
## Pathfinding speed in px/s (physics-tick independent).
@export var speed := 33
## Distance at which the chase is dropped back to idle.
@export var chase_drop_distance := 200
## Seconds the player must stay beyond chase_drop_distance before dropping.
## Straight-line distance spikes mid-detour (rounding a wall), so an instant
## gate would abort routes that are still making progress.
@export var chase_drop_time := 0.75
@export var attempt_attack_range := 15
## Height of the attack box in AXIS_BOX shape; the width is attempt_attack_range.
@export var attack_range_y := 5.0
@export var attack_range_shape: AttackRangeShape = AttackRangeShape.RADIAL
## Proximity retreat; 0 disables retreating when the player gets close.
@export var retreat_range := 0.0
## Retreat after taking a hit (consumes the enemy's retreat_requested flag).
@export var retreat_on_hit := false
## Requires an unobstructed aim ray before entering attack range.
@export var require_line_of_sight := false
@export var aim_ray_cast: RayCast2D
## Chance per in-range tick to summon instead of attacking; requires summon_state.
@export var summon_chance := 0.0
## Close-range panic summon: entering attack range with the player this
## close always summons (roll bypassed, summon cooldown respected)
## instead of attacking. Requires an EnemySummon state; 0 disables.
@export var proximity_summon_state: State
@export var proximity_summon_range := 0.0
## Standoff hold shuffle: micro-drift inside shuffle_radius at reduced
## speed instead of the statue hold, facing pinned to the player.
@export var standoff_shuffle := false
## Shuffle drift radius around the hold position, in px.
@export var shuffle_radius := 12.0
## Seconds between shuffle retargets (randomized in the interval).
@export var shuffle_interval_min := 0.8
@export var shuffle_interval_max := 1.5
@export var path_update_interval := 0.5
## New-path commitment: a re-query while the player merely drifts flips the
## route to the other side of a small obstruction (candle, chest) and the
## chaser U-turns mid-approach. The loaded path is kept until it finishes or
## the fresh target lands this far from the target the path was built for.
@export var retarget_distance := 24.0
## Radial distance within which a finished path presses straight at the
## player: navmesh arrival tolerance (12px) exceeds a melee attacker's
## level-check height, so a diagonal approach otherwise lands "arrived but
## not in line" and the swing gate never resolves. 0 disables. The window
## is widened by the arrival tolerance for every chaser: navmesh arrival
## can strand any of them a waypoint short of the player.
## Ranged chasers set 0: their gate fires from anywhere in range, and a
## straight press at a player shadowed beside a body-sized blocker only
## orbits the body: slide reads as travel, so the stall never seals.
@export var melee_press_range := 20.0
## Seconds a melee press may make sub-threshold body progress before its
## level point reads as sealed (side flip, then guard hold). See
## _finish_or_press.
@export var press_stall_window := 0.6

var player: CharacterBody2D
var time_since_last_path := 0.0
var enemy: BaseEnemy
var _over_drop_distance := 0.0
var _pathed_target := Vector2.ZERO
## Probe seam: the chase battery samples this flag to verify blind behavior.
var _blind_now := false
## Press delivery writes the body directly: the avoidance flush emits zero
## for agents whose path has finished (probe-verified on Godot 4.7.2), so
## the solver result must not own the body while pressing.
var _bypass_flush := false
## Melee press steering: +1/-1 lateral side of the player's level point;
## 0 until the first press tick seeds it from the approach vector.
var _press_side := 0.0
## Press stall watchdog: seconds accumulated in the current window and the
## body position the window started from.
var _press_clock := 0.0
var _press_reference := Vector2.ZERO
## True once the press already flipped sides on a stall; a stall on the
## flipped side too means both level points are sealed — guard.
var _press_flipped := false
## Guard hold: sealed geometry on every press approach — stand, face the
## player, let the attack-range gate swing when the box opens.
var _guarding := false
## Final-position distance captured at guard engagement: the hold releases
## only when a fresh path end beats it by WAYPOINT_REACH_DISTANCE, so
## per-repath mesh noise on a still-sealed mouth cannot churn the guard.
var _guard_final_distance := 0.0
## Countdown set by EnemyRetreat on a cornered exit: geometry offered no
## escape, so both retreat triggers stand down while it decays.
var _retreat_suppressed := 0.0
## Continuous seconds the outcome gate has read closed on this stance
## (see REPOSITION_GATE_CONFIRM).
var _gate_closed_for := 0.0
## Continuous seconds the player has held inside retreat_range (see
## PROXIMITY_RETREAT_CONFIRM).
var _retreat_trigger_for := 0.0
## Standoff shuffle drift target and seconds until the next retarget.
var _shuffle_target := Vector2.ZERO
var _shuffle_clock := 0.0

func _ready() -> void:
	enemy = actor

func enter() -> void:
	player = Global.player as CharacterBody2D
	navigation_agent.path_desired_distance = NavBaker.PATH_SWITCH_DISTANCE
	navigation_agent.target_position = player.global_position
	_pathed_target = player.global_position
	_over_drop_distance = 0.0
	_bypass_flush = false
	_press_side = 0.0
	_press_clock = 0.0
	_press_flipped = false
	_guarding = false
	_gate_closed_for = 0.0
	_retreat_trigger_for = 0.0
	_shuffle_clock = 0.0
	# RVO steering runs only while a movement state owns the agent; the
	# signal keeps emitting while avoidance is enabled, so leave it clean.
	navigation_agent.velocity_computed.connect(_on_velocity_computed)

func exit() -> void:
	enemy.facing_pinned = false
	navigation_agent.velocity_computed.disconnect(_on_velocity_computed)

func validate_exports() -> void:
	# Nullable states (attack/retreat/summon) are validated against their
	# enabling configuration instead of the base assigned-check, which would
	# reject every optional export.
	if navigation_agent == null:
		push_error("%s: navigation_agent is not assigned" % get_path())
	if idle_state == null:
		push_error("%s: idle_state is not assigned" % get_path())
	if attack_state == null and attempt_attack_range > 0.0:
		push_error("%s: attempt_attack_range set but attack_state is not assigned" % get_path())
	if attack_state != null and attempt_attack_range <= 0.0:
		push_error("%s: attack_state assigned but attempt_attack_range is 0" % get_path())
	if retreat_range > 0.0 and retreat_state == null:
		push_error("%s: retreat_range set but retreat_state is not assigned" % get_path())
	if retreat_on_hit and retreat_state == null:
		push_error("%s: retreat_on_hit set but retreat_state is not assigned" % get_path())
	if require_line_of_sight and aim_ray_cast == null:
		push_error("%s: require_line_of_sight set but aim_ray_cast is not assigned" % get_path())
	if summon_state != null and summon_chance <= 0.0:
		push_error("%s: summon_state assigned but summon_chance is 0" % get_path())
	if proximity_summon_range > 0.0 and proximity_summon_state == null:
		push_error("%s: proximity_summon_range set without a proximity_summon_state" % get_path())

func physics_update(delta: float) -> void:
	if not navigation_agent or not player:
		return

	var to_player = player.global_position - enemy.global_position
	var distance = to_player.length()

	# Drop to Idle only after the player has stayed out of reach for a beat;
	# see chase_drop_time.
	if distance > chase_drop_distance:
		_over_drop_distance += delta
		if _over_drop_distance >= chase_drop_time:
			transition_to(idle_state)
			return
	else:
		_over_drop_distance = 0.0

	if _retreat_suppressed > 0.0:
		_retreat_suppressed = maxf(_retreat_suppressed - delta, 0.0)

	var blind := _line_to_player_blocked()
	_blind_now = blind
	# The panic summon outranks the proximity flight — the trigger radius
	# sits outside it, so the close-range set bursts before the body
	# breaks away — and the check runs here rather than in the in-range
	# branch, so it also fires on ticks the other branches own.
	var summon := proximity_summon_state as EnemySummon
	if summon != null and proximity_summon_range > 0.0 \
			and distance <= proximity_summon_range and summon.is_ready():
		transition_to(proximity_summon_state)
		return
	var want_flight := not blind and retreat_range > 0.0 \
			and distance < retreat_range \
			and not _has_ready_shot(to_player, distance)
	_retreat_trigger_for = _retreat_trigger_for + delta \
			if want_flight else 0.0
	if _should_retreat(blind):
		return

	if attack_state != null and _in_attack_range(to_player, distance):
		_handle_in_range(delta, to_player, blind)
		return

	_follow_path(delta, to_player)

## `blind` (LOS required and blocked) suppresses the proximity retreat:
## retreating from a player the enemy cannot see breaks the blind close-in
## into retreat-chase pacing. A ready firing solution also outranks it:
## sight can open only inside retreat_range (NPC-shadowed pockets), and
## fleeing from that shot starves the attack gate entirely. Hit-triggered
## retreat always applies.
func _should_retreat(blind: bool) -> bool:
	if retreat_state == null:
		return false

	# Cornered latch from EnemyRetreat: geometry offered no escape, so
	# stand and fight instead of re-entering flight (both triggers hold).
	if _retreat_suppressed > 0.0:
		return false

	if not blind and _retreat_trigger_for >= PROXIMITY_RETREAT_CONFIRM:
		transition_to(retreat_state)
		return true

	if retreat_on_hit and enemy.retreat_requested and not enemy.is_hit:
		enemy.retreat_requested = false
		transition_to(retreat_state)
		return true

	return false

## Point-blank shot availability: sighted (callers gate on not blind),
## in attack range, and off cooldown. The kite runs between shots.
func _has_ready_shot(to_player: Vector2, distance: float) -> bool:
	return attack_state != null and enemy.can_attack() \
		and _in_attack_range(to_player, distance)

## Cornered handoff from EnemyRetreat: hold ground for `duration`.
func suppress_retreat(duration: float) -> void:
	_retreat_suppressed = duration


## The in-range gate. Sight-blocked enemies keep closing: travel is what
## opens the aim ray. Outcome-blocked enemies (buried muzzles, whiffed
## volley) hand the closure to the reposition state when one is wired —
## approaching cannot unbury a spawn band — and a cornered latch from
## that state holds the stance until geometry or the whiff retry window
## reopens the gate. A ready stance on cooldown holds the standoff
## instead of bouncing the attack handover every tick (the bounce
## re-rolled the summon chance on every cooldown frame).
func _handle_in_range(delta: float, to_player: Vector2, blind: bool) -> void:
	var attack := attack_state as EnemyAttack
	var gate_open := attack == null or attack.fire_gate_open()
	_gate_closed_for = 0.0 if gate_open else _gate_closed_for + delta
	if blind or not gate_open:
		if not blind and reposition_state != null:
			if _retreat_suppressed <= 0.0 \
					and _gate_closed_for >= REPOSITION_GATE_CONFIRM:
				transition_to(reposition_state)
			else:
				_bounded_close_in(delta, to_player)
			return
		_follow_path(delta, to_player)
		return
	if not enemy.can_attack() and melee_press_range <= 0.0:
		# Ranged standoff hold: on cooldown in range, hold the stance
		# instead of bouncing the attack handover every tick (the bounce
		# re-rolled the summon chance on every cooldown frame). Melee
		# pressers keep the handover — its press is the grind that
		# re-ticks contact damage through the cooldown.
		_hold_ground(delta)
		return
	_enter_attack()


## Standoff hold: zero both velocities (the avoidance server keeps
## re-emitting the last desired vector, so the body would lean on it) and
## pin facing to the player. With standoff_shuffle the body micro-drifts
## inside shuffle_radius at reduced speed — a live stance beats a statue
## — under the same facing pin.
func _hold_ground(delta: float) -> void:
	enemy.face_toward(player.global_position)
	enemy.facing_pinned = true
	if not standoff_shuffle:
		_bypass_flush = false
		enemy.velocity = Vector2.ZERO
		navigation_agent.velocity = Vector2.ZERO
		return
	_shuffle_clock -= delta
	var to_target := _shuffle_target - enemy.global_position
	if _shuffle_clock <= 0.0 or to_target.length() < SHUFFLE_MIN_STEP:
		var step := randf_range(SHUFFLE_MIN_STEP, shuffle_radius)
		_shuffle_target = enemy.global_position \
				+ Vector2.from_angle(randf() * TAU) * step
		_shuffle_clock = randf_range(shuffle_interval_min, shuffle_interval_max)
		to_target = _shuffle_target - enemy.global_position
	# The flush only delivers while a path is active; at the standoff the
	# path has finished and the server emits zero, so the drift writes the
	# body directly (same contract as the melee press) while the vector
	# still feeds the agent for the neighbors' avoidance.
	_bypass_flush = true
	navigation_agent.velocity = to_target.normalized() \
			* speed * SHUFFLE_SPEED_FRACTION
	enemy.velocity = to_target.normalized() * speed * SHUFFLE_SPEED_FRACTION


## Outcome-blocked closure after a cornered reposition (the fan offered
## no firing stance): travel instead of dead-standing. Closing can
## unbury a band pressed into wall geometry behind the body, feeds the
## whiff retry's travel requirement, and stays alive while the cornered
## cooldown throttles re-handovers. The press is bounded at half the
## attack range so a never-opening gate cannot park the body in the
## player's face.
func _bounded_close_in(delta: float, to_player: Vector2) -> void:
	if to_player.length() > attempt_attack_range * 0.5:
		_follow_path(delta, to_player)
	else:
		_hold_ground(delta)

func _in_attack_range(to_player: Vector2, distance: float) -> bool:
	if attack_range_shape == AttackRangeShape.AXIS_BOX:
		return abs(to_player.x) <= attempt_attack_range and abs(to_player.y) <= attack_range_y
	return distance <= attempt_attack_range

## True when the enemy requires line of sight and the aim line is
## obstructed. The ray node stays the single aim transform (EnemyAttack
## spawns from it); the gate itself is the width-aware clearance check —
## a thin ray passes corners the projectile body clips. Bodies on the
## character layers — the player, other enemies, NPCs — never block aim,
## and the line ends at the player, so a wall behind them must not read
## as blocked sight. Zeroes velocity so a blocked gate at a finished path
## means standing still, not drifting on the previous tick.
func _line_to_player_blocked() -> bool:
	if not require_line_of_sight:
		return false
	enemy.velocity = Vector2.ZERO
	navigation_agent.velocity = Vector2.ZERO
	aim_ray_cast.global_rotation = _angle_to_player_from_ray()
	return not enemy.aim_line_clear(
			aim_ray_cast.global_position, player.global_position)

func _enter_attack() -> void:
	if summon_state != null and randf() < summon_chance:
		transition_to(summon_state)
		return

	transition_to(attack_state)

func _angle_to_player_from_ray() -> float:
	var offset = player.global_position - enemy.to_global(aim_ray_cast.position)
	return offset.angle()

## Every chaser paths straight to the player's position: the mesh's optimal
## route around cover is the sight-regaining route, and the in-range gate
## stops and fires the moment the aim line opens, so blind close-in reads
## exactly like the melee close-in.
func _follow_path(delta: float, to_player: Vector2) -> void:
	# Recalculate path if needed
	time_since_last_path += delta
	if time_since_last_path >= path_update_interval:
		# Commit to the loaded route: re-querying on drift alone lets the
		# navpoint hop between the sides of small obstructions.
		if navigation_agent.is_navigation_finished() \
				or player.global_position.distance_to(_pathed_target) >= retarget_distance:
			time_since_last_path = 0.0
			_pathed_target = player.global_position
			navigation_agent.target_position = player.global_position

	if navigation_agent.is_navigation_finished():
		_finish_or_press(to_player, delta)
		return

	# A sealed-mouth guard outlives its seal once the route opens under it
	# (door passage, moved blocker): the held latch would stand the enemy
	# off a now-reachable player. A reachable path ends at the player, an
	# unreachable one at the sealing geometry, so the release demands a
	# solid improvement on the distance the guard was engaged at — a
	# still-sealed mouth re-queries to within noise of the same endpoint
	# and must keep the hold.
	if _guarding and navigation_agent.get_final_position().distance_to(
			player.global_position) \
			< _guard_final_distance - NavBaker.WAYPOINT_REACH_DISTANCE:
		_guarding = false
		_press_flipped = false
		_press_side = 0.0
		_press_clock = 0.0

	# Tight waypoint switching rounds corners without grinding the tile
	# apices; the final leg keeps the loose finish so standoffs at
	# unreachable targets (sealed mouths, body-shadow pockets) hold their
	# tuned arrival distance.
	var remaining_points: int = navigation_agent.get_current_navigation_path().size() \
		- navigation_agent.get_current_navigation_path_index()
	navigation_agent.path_desired_distance = NavBaker.PATH_SWITCH_DISTANCE \
		if remaining_points >= 2 else NavBaker.WAYPOINT_REACH_DISTANCE
	var next_position = navigation_agent.get_next_path_position()
	if next_position.is_zero_approx():
		# Cached empty path: the first query raced a bake's region-to-map
		# sync and the agent kept nothing. Re-set the loaded target to
		# re-dirty the agent's query instead of staying bricked.
		navigation_agent.target_position = _pathed_target
		return

	var direction = (next_position - enemy.global_position).normalized()
	# Desired velocity feeds the RVO avoidance flush; the safe result lands
	# on the body through _on_velocity_computed before move_and_slide.
	_bypass_flush = false
	navigation_agent.velocity = direction * speed

## Arrival handling. Navmesh arrival tolerance (12px) exceeds a melee
## attacker's level-check height, so a diagonal approach can land "arrived
## but not in line": box attackers press at a level point beside the player
## (a straight press grinds vertically against their body and never enters
## the swing band), radial attackers press straight. A press making no body
## progress reads as a sealed level point: the box press flips to the other
## lateral side once, then guards — hold ground, face the player, and let
## the range gate swing the moment geometry opens. Otherwise stand —
## zeroing the agent velocity matters, since the avoidance server keeps
## re-emitting the last desired vector and the body would lean on it into
## props.
func _finish_or_press(to_player: Vector2, delta: float) -> void:
	# No chaser stands idle at a finished path near the player: navmesh
	# arrival can stop it a waypoint short (sealed pocket mouths), which is
	# exactly where the press or the guard must act.
	var press_ceiling := melee_press_range + NavBaker.WAYPOINT_REACH_DISTANCE
	if attack_state == null or melee_press_range <= 0.0 \
			or to_player.length() > press_ceiling:
		_bypass_flush = false
		_guarding = false
		_press_flipped = false
		_press_clock = 0.0
		navigation_agent.velocity = Vector2.ZERO
		enemy.face_toward(player.global_position)
		return

	if _guarding:
		# Both level points sealed: hold the mouth. The in-range gate in
		# physics_update fires the swing as soon as the box opens.
		_bypass_flush = false
		enemy.velocity = Vector2.ZERO
		navigation_agent.velocity = Vector2.ZERO
		enemy.face_toward(player.global_position)
		return

	var press_direction := to_player.normalized()
	var box_press := attack_range_shape == AttackRangeShape.AXIS_BOX
	if box_press:
		if _press_side == 0.0:
			_press_side = signf(to_player.x)
			if _press_side == 0.0:
				_press_side = signf(enemy.last_velocity_x) \
						if enemy.last_velocity_x != 0.0 else 1.0
		press_direction = (_press_level_point() - enemy.global_position).normalized()
	if _press_clock == 0.0:
		_press_reference = enemy.global_position
	_press_clock += delta
	if _press_clock >= press_stall_window:
		var travelled := enemy.global_position.distance_to(_press_reference)
		if travelled < speed * press_stall_window * PRESS_PROGRESS_FRACTION:
			if box_press and not _press_flipped:
				# The near level point is sealed: press the opposite side.
				_press_flipped = true
				_press_side = -_press_side
				press_direction = (_press_level_point()
						- enemy.global_position).normalized()
			else:
				_guarding = true
				_guard_final_distance = navigation_agent.get_final_position() \
						.distance_to(player.global_position)
		_press_clock = 0.0
		_press_reference = enemy.global_position
	# The flush only delivers while a path is active; at a finished path the
	# avoidance server emits zero, so the press writes the body directly. The
	# same vector still feeds the agent: neighbors' avoidance reads the press
	# intent and parts around it instead of pathing straight through.
	_bypass_flush = true
	navigation_agent.velocity = press_direction * speed
	enemy.velocity = press_direction * speed


func _press_level_point() -> Vector2:
	return player.global_position + Vector2(-_press_side * MELEE_LEVEL_OFFSET, 0.0)


## RVO safe velocity from the navigation server's avoidance flush.
func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if enemy == null or enemy.is_dead or enemy.is_hit or enemy.attacking or enemy.stunned:
		return
	if _bypass_flush:
		return
	enemy.velocity = safe_velocity

