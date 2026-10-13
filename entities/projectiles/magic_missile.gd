extends Node2D

## Hybrid missile flight: direct-seek homing arcs wherever the line to the
## player is clear; while cover blocks that line the missile paths through
## the runtime-baked mesh at the same turn cap, so volleys round cover
## instead of splatting on it. Reflected missiles never route — their
## targets are enemies in the open — and keep the reflect homing.

## Environment bit: the only geometry the mode check treats as blocking
## (walls and prop bodies, per the aim-gate convention).
const BLOCKING_MASK := 1 << 2

## Lateral clearance the routing-exit lanes sweep: the body runs about
## ±2 px off its spine, so an exit gate as ray-thin as the entry check
## releases the missile onto arcs that clip corners the line only grazes.
const EXIT_CLEARANCE_PX := 3.0

@export var speed := 85
@export var damage: int = 1
@export var leniency_threshold = 25
@export var track_resume_delay = .5
@export var turn_speed = 3
## Launches the reflect this many degrees wide of the aim line (random side)
## so the homing visibly arcs onto the lock.
@export var reflect_arc_deg := 75.0
## Seconds between blocked-line checks while flying direct arcs.
@export var route_check_interval := 0.1
## Seconds between path re-queries while routing around cover.
@export var repath_interval := 0.35
## Consecutive clear seconds required to leave route mode; absorbs the
## flip-flopping at cover edges.
@export var clear_hysteresis := 0.2
## Waypoint switch radius. Distance-based because plane tests are
## lateral-blind: when a repath's clamped path start falls behind the
## missile, "past the plane" cascades through far waypoints and the missile
## aims at the player instead of the route (probe-verified). 18.0 gives the
## fast arc more slack than the followers' 12px reach and covers the +12px
## forward hitbox.
@export var waypoint_reach := 18.0

var reflected = false
var passed = false
var direction: Vector2
var player: CharacterBody2D
var target: Node2D
var launch_angle := 0.0
## Volley outcome telemetry, assigned by the spawner (see VolleyReport).
var volley_report: VolleyReport

## Route mode: the direct line is blocked; steering follows baked-mesh
## waypoints until the line has been clear for the hysteresis window.
var _routing := false
var _route_points: PackedVector2Array = []
var _route_index := 0
var _check_clock := 0.0
var _repath_clock := 0.0
var _clear_clock := 0.0


func _ready() -> void:
	player = Global.player as CharacterBody2D


## Volley bookkeeping: leaving the flight (any free path) retires the shot
## from its volley's live count.
func _exit_tree() -> void:
	if volley_report != null:
		volley_report.retire()


func _physics_process(delta: float) -> void:
	if reflected:
		_steer_reflected(delta)
	elif _routing:
		_steer_routed(delta)
	else:
		if not passed:
			_steer_direct(delta)
			_check_clock += delta
			if _check_clock >= route_check_interval:
				_check_clock = 0.0
				if not _line_to_player_clear():
					_enter_route()

	global_position += direction * speed * delta

	var distance_to_player = global_position.distance_to(player.global_position)
	if not passed and not reflected and not _routing \
			and distance_to_player < leniency_threshold:
		passed = true
		_resume_tracking_later()

	# Arrival telemetry runs in every flight mode — a routed missile that
	# rounds cover and reaches the player's area is the volley succeeding —
	# but never after reflection, when the shot belongs to the player.
	if volley_report != null and not volley_report.arrived \
			and not reflected and distance_to_player < volley_report.arrival_radius:
		volley_report.settle_arrived()

	$AnimationPlayer.play("Track")


## Direct-seek homing — the pre-routing flight, unchanged: wherever the line
## to the player is clear, the missile keeps today's arc character.
func _steer_direct(delta: float) -> void:
	var target_direction = (player.global_position - global_position).normalized()
	var target_angle = target_direction.angle()

	# Smooth rotation toward target angle
	rotation = lerp_angle(rotation, target_angle, delta * turn_speed)
	direction = Vector2.RIGHT.rotated(rotation)



## Cover routing: the same turn cap steers at mesh waypoints, so routed
## flight keeps the arc character. Waypoints switch by closing within
## waypoint_reach of them; the aim point rides the current-to-next leg
## midpoint so the turn rounds the inside of the corridor instead of the
## boundary vertices.
func _steer_routed(delta: float) -> void:
	_check_clock += delta
	if _check_clock >= route_check_interval:
		_check_clock = 0.0
		if _lane_clear_wide():
			_clear_clock += route_check_interval
			if _clear_clock >= clear_hysteresis:
				_routing = false
				return
		else:
			_clear_clock = 0.0

	_repath_clock += delta
	if _repath_clock >= repath_interval:
		_repath_clock = 0.0
		_route_points = _query_route()
		_route_index = 0

	if _route_points.size() < 2:
		# An empty or point path (region-to-map sync race, disconnected
		# geometry) falls back to direct arcs instead of wedging.
		_routing = false
		return

	_route_index = _advance_route_index()
	var aim_point: Vector2 = _route_points[_route_index]
	if _route_index < _route_points.size() - 1:
		aim_point = aim_point.lerp(_route_points[_route_index + 1], 0.5)

	var target_angle := (aim_point - global_position).normalized().angle()
	rotation = lerp_angle(rotation, target_angle, delta * turn_speed)
	direction = Vector2.RIGHT.rotated(rotation)


## Advances past waypoints the missile has closed within waypoint_reach of
## and returns the settled index.
func _advance_route_index() -> int:
	while _route_index < _route_points.size() - 1 \
			and global_position.distance_to(_route_points[_route_index]) \
					<= waypoint_reach:
		_route_index += 1
	return _route_index


func _enter_route() -> void:
	_route_points = _query_route()
	_route_index = 0
	_repath_clock = 0.0
	_clear_clock = 0.0
	_routing = _route_points.size() >= 2


## Paths through the runtime-baked mesh. Both endpoints are clamped to the
## mesh: a target hugging geometry often sits off the polygons, and an
## off-mesh endpoint queries to an empty path. optimize=false keeps the
## server's corridor untouched — the raw path runs through the corridor's
## interior — while mesh postprocessing corner-cuts tile-navmesh paths
## (engine fact).
func _query_route() -> PackedVector2Array:
	var map := get_world_2d().get_navigation_map()
	var from := NavigationServer2D.map_get_closest_point(map, global_position)
	var to := NavigationServer2D.map_get_closest_point(map, player.global_position)
	return NavigationServer2D.map_get_path(map, from, to, false)


## Entry-side lane check (Environment only), throttled by the caller.
## Ray-thin on purpose: eager routing engages sooner, and a genuine
## sidestep leaves the line clear at any width — the crash it produces on
## tight outmaneuvers is the tuning this projectile ships with. The exit
## side is width-aware (see _lane_clear_wide).
func _line_to_player_clear() -> bool:
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
			global_position, player.global_position, BLOCKING_MASK)
	query.hit_from_inside = true
	return space.intersect_ray(query).is_empty()


## Exit-side lane check: the aim-gate center-plus-parallels sweep at
## EXIT_CLEARANCE_PX. Routing releases onto direct arcs only when every
## lane reads clear for the full hysteresis window — a center ray that
## merely grazes a corner must not hand a turning missile an arc that
## clips it. The entry check stays ray-thin by design.
func _lane_clear_wide() -> bool:
	var space := get_world_2d().direct_space_state
	var lateral := (player.global_position - global_position).normalized().orthogonal()
	for side: float in [0.0, 1.0, -1.0]:
		var shift := lateral * (EXIT_CLEARANCE_PX * side)
		var query := PhysicsRayQueryParameters2D.create(
				global_position + shift, player.global_position + shift,
				BLOCKING_MASK)
		# Same rule as the aim gate: an origin pressed into a blocker's
		# face counts as blocked, never clear-through.
		query.hit_from_inside = true
		if not space.intersect_ray(query).is_empty():
			return false
	return true


## Reflected homing: the chase never gives up — targetless missiles keep
## polling the player's aim (this is the physics step) and settle onto
## the aim line between locks; only contact ends them.
func _steer_reflected(delta: float) -> void:
	if not is_instance_valid(target):
		target = player.combat.get_aim_target()
	var desired_angle := launch_angle
	if target != null:
		desired_angle = (target.global_position - global_position).normalized().angle()
	rotation = lerp_angle(rotation, desired_angle, delta * turn_speed)
	direction = Vector2.RIGHT.rotated(rotation)


## Pauses homing briefly after passing the player; one timer per pass instead
## of one per frame.
func _resume_tracking_later() -> void:
	await get_tree().create_timer(track_resume_delay).timeout
	passed = false

func reflect():
	reflected = true

	# The shot now belongs to the player: leave the shooter's volley so its
	# verdict settles on the pre-reflection flight only.
	if volley_report != null:
		volley_report.retire()
		volley_report = null

	# The single surface now pairs with enemy hurtboxes and self-frees on
	# enemy bodies and walls — reflected missiles no longer pierce.
	var hitbox = $Hitbox
	hitbox.collision_layer = 1 << 5             # Layer 6 (PlayerHitbox)
	hitbox.collision_mask = (1 << 1) | (1 << 2) # Collides with Layers 2 and 3

	var sprite = $Sprite2D  # Replace with your actual node path
	var shader_material := sprite.material as ShaderMaterial

	# Set flash color to #0076e3 (RGB: 0, 118, 227)
	shader_material.set_shader_parameter("flash_color", Color8(0, 118, 227))

	# Set flash value to max (fully show the flash color)
	shader_material.set_shader_parameter("flash_value", 0.60)

	$PointLight2D.color = Color.html("#0076e3")

	var mouse_direction: Vector2 = (get_global_mouse_position() - global_position).normalized()
	launch_angle = mouse_direction.angle()
	rotation = launch_angle + deg_to_rad(reflect_arc_deg) * (1.0 if randf() < 0.5 else -1.0)

func _on_hitbox_body_entered(body: Node2D) -> void:
	# If it's the player and the player is not blocking, or it's another object, destroy the missile
	if body != player or (body == player and not player.combat.blocking):
		queue_free()
