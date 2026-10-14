extends State
class_name EnemyRetreat

## Desire-based retreat: keeps the player at arm's length along
## navmesh-validated escape routes. Each repath tick scores a fan of
## candidate directions around the live away-vector with synchronous
## NavigationServer2D.map_get_path queries. A route qualifies when it
## realizes most of the requested flight length, its endpoint gains
## distance from the player, and its first step does not double back
## toward them. Among qualifiers the shortest route to comfort wins —
## flight is a backpedal to arm's length, not a tour around cover — and
## a partial-gain route only counts within one flight length. When the
## opening fan finds no candidate, geometry has cornered the enemy: it
## hands back to chase under a retreat-suppression latch and fights. A
## mid-flight repath with no qualifiers keeps the current route instead —
## no better escape exists from here, but the body is already flying a
## validated one.
##
## Two desires share the fan machinery. ESCAPE (default) scores endpoints
## by distance gained from the player. FIRING scores endpoints by firing
## stance: the whole volley muzzle band must spawn clear at the candidate
## position, with in-band endpoints outranking clear-but-out-of-band ones
## — the chase hands over a blocked fire gate (buried muzzles, whiffed
## volley) instead of closing on a player it cannot shoot.

enum Desire { ESCAPE, FIRING }

const ESCAPE_FAN_DEGREES: Array[float] = [
	0.0, 30.0, -30.0, 60.0, -60.0, 90.0, -90.0, 120.0, -120.0, 150.0, -150.0,
]
## First path step pointing this much toward the player rejects a route:
## it rounds an obstacle through them instead of opening distance.
const DOUBLETBACK_DOT_LIMIT := -0.2
## Fraction of retreat_distance a route must realize to count as escape;
## shorter routes squeeze into the nearest reachable spot, not out.
const ESCAPE_ROOM_FRACTION := 0.6
## Reach fractions the FIRING fan probes at. Unburying a muzzle band
## usually needs a small shuffle off the burial geometry, not a full
## flight: at a wall every full-length endpoint lands inside the tiles
## and the scorer would come up empty.
const FIRING_REACH_FRACTIONS: Array[float] = [1.0, 0.65, 0.35]
## Fraction of speed * progress_window the body must travel per window;
## less means it is snagged on something the navmesh does not model.
const PROGRESS_FRACTION := 0.25

@export var navigation_agent: NavigationAgent2D
@export var chase_state: State
## Retreat speed in px/s (physics-tick independent).
@export var speed := 42
## Comfort distance: flight ends once the player is this far away.
@export var retreat_distance := 100
## Seconds between escape re-scorings and target updates.
@export var path_update_interval := 0.2
## Distance-from-player gain (px) a route must promise; the best fan
## result below this reads as cornered geometry.
@export var escape_gain_min := 12.0
## Seconds the chase retreat gates stay suppressed after a cornered
## exit, so the enemy engages instead of re-entering flight.
@export var cornered_cooldown := 2.0
## Body-progress sampling window for the snag failsafe.
@export var progress_window := 1.0
## Hard flight cap against degenerate loops (probe determinism).
@export var retreat_time_limit := 6.0
## What the fan scores. ESCAPE: distance gained from the player. FIRING:
## a stance the volley band spawns clear from (see attack_state).
@export var desire: Desire = Desire.ESCAPE
## FIRING only: the attack state owning the volley offsets — candidate
## endpoints must pass its stance clearance check.
@export var attack_state: EnemyAttack
## Panic-summon reflex: the player inside this range during a flight
## hands the body to the close-range summon state (its own cooldown
## respected). 0 disables; state + range mirror the chase trigger so the
## reflex also runs while a flight owns the body.
@export var proximity_summon_state: State
@export var proximity_summon_range := 0.0
## FIRING only: preferred engagement band around the player, in px;
## in-band endpoints outrank clear-but-out-of-band ones. A 0 max
## disables the band preference.
@export var band_min := 0.0
@export var band_max := 0.0
## FIRING only: a stance qualifies when the mesh path from it to the
## player runs no longer than this multiple of the straight line — the
## same mesh the volleys route through. Longer detours read as stances
## the shots cannot actually follow to the player.
@export var max_detour_ratio := 1.8

var player: CharacterBody2D
var enemy: BaseEnemy
var time_since_last_path := 0.0
var retreat_timer := 0.0
## Whether the escape scorer currently holds a validated target: the
## cornered contract disengages on an empty opening fan, while a
## mid-flight empty fan keeps the route already being flown.
var _has_escape_target := false
var _progress_clock := 0.0
var _progress_reference := Vector2.ZERO


func _ready() -> void:
	enemy = actor


func validate_exports() -> void:
	if desire == Desire.FIRING and attack_state == null:
		push_error("%s: FIRING desire requires attack_state" % get_path())


func enter() -> void:
	player = Global.player as CharacterBody2D
	navigation_agent.path_desired_distance = NavBaker.PATH_SWITCH_DISTANCE
	time_since_last_path = 0.0
	retreat_timer = 0.0
	_has_escape_target = false
	_progress_clock = 0.0
	_progress_reference = enemy.global_position
	# RVO steering runs only while a movement state owns the agent; the
	# signal keeps emitting while avoidance is enabled, so leave it clean.
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	_pick_escape_route()


func exit() -> void:
	navigation_agent.velocity_computed.disconnect(_on_velocity_computed)

func physics_update(delta: float) -> void:
	if not navigation_agent or not player:
		return

	# Panic-summon reflex (see the exports): fires on both desires, so a
	# flee or a reposition under pursuit bursts the close-range set
	# instead of running empty-handed.
	if _panic_summon_due():
		transition_to(proximity_summon_state)
		return

	retreat_timer += delta

	# Flight done — comfort for ESCAPE, a firing stance for FIRING:
	# chase resumes and attacks while the player stays inside its range.
	if _flight_satisfied():
		if desire == Desire.FIRING and attack_state != null:
			attack_state.whiff_satisfied()
		transition_to(chase_state)
		return

	# Hard cap: flight must not outlive degenerate geometry loops.
	if retreat_timer >= retreat_time_limit:
		_disengage()
		return

	# The route promised distance but the body stopped traveling: snagged
	# on something the navmesh does not model — treat as cornered.
	_progress_clock += delta
	if _progress_clock >= progress_window:
		var traveled := enemy.global_position.distance_to(_progress_reference)
		if traveled < speed * progress_window * PROGRESS_FRACTION:
			_disengage()
			return
		_progress_clock = 0.0
		_progress_reference = enemy.global_position

	time_since_last_path += delta
	if time_since_last_path >= path_update_interval:
		time_since_last_path = 0.0
		_pick_escape_route()

	if navigation_agent.is_navigation_finished():
		# The avoidance flush emits zero for finished-path agents, but
		# park both velocities explicitly so a stalled flush cannot lean
		# the body on the last safe vector.
		navigation_agent.velocity = Vector2.ZERO
		enemy.velocity = Vector2.ZERO
		return

	var next_position = navigation_agent.get_next_path_position()
	if not next_position.is_zero_approx():
		# Desired velocity feeds the RVO avoidance flush; the safe result
		# lands on the body through _on_velocity_computed before
		# move_and_slide. A zero next position means no usable step this
		# tick, so the last velocity stands instead of feeding the flush
		# a degenerate direction.
		var path_direction = (next_position - enemy.global_position).normalized()
		navigation_agent.velocity = path_direction * speed


func _gap() -> float:
	return enemy.global_position.distance_to(player.global_position)


## True when the player stands inside the panic-summon trigger and the
## close-range summon state is off cooldown (see the exports).
func _panic_summon_due() -> bool:
	if proximity_summon_state == null or proximity_summon_range <= 0.0:
		return false
	var summon := proximity_summon_state as EnemySummon
	return summon != null and summon.is_ready() \
			and player.global_position.distance_to(enemy.global_position) \
			<= proximity_summon_range


## Flight exit condition. ESCAPE: comfort — the player is back at arm's
## length. FIRING: the flight has arrived at the stance the scorer chose
## and it spawns the whole volley band clear — requiring arrival keeps
## the body from satisfying on a boundary pixel it was handed over on,
## which would let the standoff shuffle oscillate the handover.
func _flight_satisfied() -> bool:
	if desire == Desire.FIRING and attack_state != null \
			and navigation_agent.is_navigation_finished() \
			and attack_state.band_clear_at(enemy.global_position):
		return true
	return _gap() >= retreat_distance


## Scores the fan (see class doc) and retargets the agent. ESCAPE: the
## shortest comfort route wins; a partial-gain route only counts within
## one flight length. FIRING: the shortest route to a band-clear stance
## wins, in-band endpoints outranking out-of-band ones. No qualifier
## means cornered geometry: disengage and fight.
func _pick_escape_route() -> void:
	if desire == Desire.FIRING:
		_pick_firing_route()
		return
	var away := (enemy.global_position - player.global_position).normalized()
	var map: RID = enemy.get_world_2d().navigation_map
	var comfort_target := Vector2.ZERO
	var comfort_length := INF
	var partial_target := Vector2.ZERO
	var partial_length := INF
	for offset_degrees in ESCAPE_FAN_DEGREES:
		var direction := away.rotated(deg_to_rad(offset_degrees))
		# An off-mesh endpoint queries to an empty path (the mesh holds no
		# route to it), so every candidate clamps to the mesh first: a
		# full-length flight through open space stays itself, one into a
		# wall folds onto the reachable face and the route filters judge it.
		var candidate := NavigationServer2D.map_get_closest_point(map,
				enemy.global_position + direction * retreat_distance)
		var path := NavigationServer2D.map_get_path(
				map, enemy.global_position, candidate, true)
		if path.size() < 2:
			continue
		var first_step := (path[1] - path[0]).normalized()
		if first_step.dot(away) < DOUBLETBACK_DOT_LIMIT:
			continue
		var route_length := 0.0
		for i in path.size() - 1:
			route_length += path[i].distance_to(path[i + 1])
		# Too short = squeezing into the nearest reachable spot, not out.
		if route_length < retreat_distance * ESCAPE_ROOM_FRACTION:
			continue
		var endpoint: Vector2 = path[path.size() - 1]
		var gain := endpoint.distance_to(player.global_position) - _gap()
		if gain < escape_gain_min:
			continue
		# Iteration runs straightest-first; strict < keeps the most direct
		# escape among equal lengths.
		if endpoint.distance_to(player.global_position) >= retreat_distance:
			if route_length < comfort_length:
				comfort_length = route_length
				comfort_target = candidate
		elif route_length <= retreat_distance:
			# Partial gain is only worth a hop of at most one flight
			# length: longer detours read as touring around cover.
			if route_length < partial_length:
				partial_length = route_length
				partial_target = candidate

	# Comfort outranks partial regardless of length.
	if comfort_length < INF:
		navigation_agent.target_position = comfort_target
		_has_escape_target = true
		return
	if partial_length < INF:
		navigation_agent.target_position = partial_target
		_has_escape_target = true
		return
	# A mid-flight fan that comes up empty means no better route from
	# here, not cornered geometry: the body is already flying a validated
	# escape, so keep it. Cornered stays an entry contract — with no
	# target at all, hand back to the suppression latch and fight.
	if _has_escape_target and not navigation_agent.is_navigation_finished():
		return
	_disengage()


## FIRING scorer: band-clear stances only. In-band beats out-of-band
## regardless of length, then the shortest route wins. The escape
## scorer's route floor and gain minimum do not apply — a reposition is
## about the stance it lands on, not the distance it opens, so a short
## lateral hop to open space qualifies. The first-step double-back
## rejection stays: a firing solution stepped into the player's face is
## not a solution. A stance must also connect: its mesh path to the
## player stays within max_detour_ratio of the straight line, with
## connectable in-band stances outranking connectable clear ones and a
## bare band-clear stance the volleys could not follow as the last
## resort. Endpoints score at the path's clamped end: an
## unreachable goal folds onto the nearest reachable point and that
## folded stance is the one the body actually lands on. A fold back to
## the current spot self-rejects — the gate is closed, so the stance
## here cannot spawn the band clear. A current stance that already
## spawns the band clear and connects satisfies the whiff memory and
## hands straight back to chase.
func _pick_firing_route() -> void:
	if attack_state.band_clear_at(enemy.global_position) \
			and _stance_connectable(enemy.global_position):
		attack_state.whiff_satisfied()
		transition_to(chase_state)
		return
	var away := (enemy.global_position - player.global_position).normalized()
	var map: RID = enemy.get_world_2d().navigation_map
	var in_band_target := Vector2.ZERO
	var in_band_length := INF
	var clear_target := Vector2.ZERO
	var clear_length := INF
	var fallback_target := Vector2.ZERO
	var fallback_length := INF
	for offset_degrees in ESCAPE_FAN_DEGREES:
		var direction := away.rotated(deg_to_rad(offset_degrees))
		for reach in FIRING_REACH_FRACTIONS:
			var candidate := enemy.global_position \
					+ direction * retreat_distance * reach
			var path := NavigationServer2D.map_get_path(
					map, enemy.global_position, candidate, true)
			if path.size() < 2:
				continue
			var first_step := (path[1] - path[0]).normalized()
			if first_step.dot(away) < DOUBLETBACK_DOT_LIMIT:
				continue
			var stance: Vector2 = path[path.size() - 1]
			if not attack_state.band_clear_at(stance):
				continue
			var route_length := 0.0
			for i in path.size() - 1:
				route_length += path[i].distance_to(path[i + 1])
			var connectable := _stance_connectable(stance)
			if _candidate_in_band(stance) and connectable:
				if route_length < in_band_length:
					in_band_length = route_length
					in_band_target = stance
			elif connectable:
				if route_length < clear_length:
					clear_length = route_length
					clear_target = stance
			elif route_length < fallback_length:
				fallback_length = route_length
				fallback_target = stance
	# Connectable in-band outranks connectable clear, which outranks a
	# bare band-clear stance.
	if in_band_length < INF:
		navigation_agent.target_position = in_band_target
		return
	if clear_length < INF:
		navigation_agent.target_position = clear_target
		return
	if fallback_length < INF:
		navigation_agent.target_position = fallback_target
		return
	_disengage()


## True when the candidate sits inside the preferred engagement band
## around the player. A 0 band_max accepts any distance at or beyond
## band_min.
func _candidate_in_band(candidate: Vector2) -> bool:
	var gap := candidate.distance_to(player.global_position)
	if gap < band_min:
		return false
	return band_max <= 0.0 or gap <= band_max


## A stance connects when the mesh path from it to the player runs no
## longer than max_detour_ratio times the straight line. Queries mirror
## the volley's own routing (closest-point clamped, optimize=false): a
## stance the shots could not follow is not a firing solution.
func _stance_connectable(stance: Vector2) -> bool:
	var map: RID = enemy.get_world_2d().navigation_map
	var from := NavigationServer2D.map_get_closest_point(map, stance)
	var to := NavigationServer2D.map_get_closest_point(
			map, player.global_position)
	var path := NavigationServer2D.map_get_path(map, from, to, false)
	if path.size() < 2:
		return false
	var route_length := 0.0
	for i in path.size() - 1:
		route_length += path[i].distance_to(path[i + 1])
	return route_length <= from.distance_to(to) * max_detour_ratio


## Cornered exit: chase regains control with its retreat triggers
## suppressed, so the enemy stands its ground and fights instead of
## re-entering flight on the next tick (ready shots still fire first:
## the chase proximity gate yields to them).
func _disengage() -> void:
	if chase_state is EnemyChase:
		chase_state.suppress_retreat(cornered_cooldown)
	transition_to(chase_state)


## RVO safe velocity from the navigation server's avoidance flush.
func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if enemy == null or enemy.is_dead or enemy.is_hit or enemy.attacking or enemy.stunned:
		return
	enemy.velocity = safe_velocity

