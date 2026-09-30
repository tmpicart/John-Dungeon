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
## a partial-gain route only counts within one flight length. When no
## candidate qualifies, geometry has cornered the enemy: it hands back
## to chase under a retreat-suppression latch and fights.

const ESCAPE_FAN_DEGREES: Array[float] = [
	0.0, 30.0, -30.0, 60.0, -60.0, 90.0, -90.0, 120.0, -120.0, 150.0, -150.0,
]
## First path step pointing this much toward the player rejects a route:
## it rounds an obstacle through them instead of opening distance.
const DOUBLETBACK_DOT_LIMIT := -0.2
## Fraction of retreat_distance a route must realize to count as escape;
## shorter routes squeeze into the nearest reachable spot, not out.
const ESCAPE_ROOM_FRACTION := 0.6
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

var player: CharacterBody2D
var enemy: BaseEnemy
var time_since_last_path := 0.0
var retreat_timer := 0.0
var _progress_clock := 0.0
var _progress_reference := Vector2.ZERO


func _ready() -> void:
	enemy = actor


func enter() -> void:
	player = Global.player as CharacterBody2D
	navigation_agent.path_desired_distance = NavBaker.PATH_SWITCH_DISTANCE
	time_since_last_path = 0.0
	retreat_timer = 0.0
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

	retreat_timer += delta

	# Comfort reached: kite satisfied, chase resumes (and attacks while
	# the player stays inside its range).
	if _gap() >= retreat_distance:
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
	if next_position.is_zero_approx():
		return

	var path_direction = (next_position - enemy.global_position).normalized()
	# Desired velocity feeds the RVO avoidance flush; the safe result lands
	# on the body through _on_velocity_computed before move_and_slide.
	navigation_agent.velocity = path_direction * speed


func _gap() -> float:
	return enemy.global_position.distance_to(player.global_position)


## Scores the escape fan (see class doc) and retargets the agent. The
## shortest comfort route wins; a partial-gain route only counts within
## one flight length; no qualifier means cornered geometry: disengage
## and fight.
func _pick_escape_route() -> void:
	var away := (enemy.global_position - player.global_position).normalized()
	var map: RID = enemy.get_world_2d().navigation_map
	var comfort_target := Vector2.ZERO
	var comfort_length := INF
	var partial_target := Vector2.ZERO
	var partial_length := INF
	for offset_degrees in ESCAPE_FAN_DEGREES:
		var direction := away.rotated(deg_to_rad(offset_degrees))
		var candidate := enemy.global_position + direction * retreat_distance
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
		return
	if partial_length < INF:
		navigation_agent.target_position = partial_target
		return
	_disengage()


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

