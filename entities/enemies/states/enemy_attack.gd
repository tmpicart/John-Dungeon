extends State
class_name EnemyAttack

## Shared attack: plays the enemy's attack flow, then optionally fires a
## configured projectile set before returning to chase.

@export var chase_state: State
## Projectile fired after a completed attack; unassigned = melee attack.
@export var projectile: PackedScene
## Node sourcing the projectile rotation (and the single-spawn position).
@export var aim_ray_cast: RayCast2D
## Extra spawn offsets relative to the enemy body; each spawns one projectile.
@export var projectile_offsets: Array[Vector2] = []
## Whiff-triggered repositioning: after a settled volley that never reached
## the player's area, the chase handover gate stays closed until the body
## has moved whiff_reposition_distance from the fire position or
## whiff_retry_seconds have lapsed. Opt-in — off keeps every other enemy's
## behavior unchanged (see fire_gate_open).
@export var reposition_after_whiff := false
## Radius around the player that counts as the volley having arrived (see
## VolleyReport.arrival_radius).
@export var whiff_arrival_radius := 32.0
## Distance the body must travel from a whiffed volley's fire position
## before the gate reopens.
@export var whiff_reposition_distance := 48.0
## Seconds after a whiffed volley's launch the gate reopens even without
## movement: a cornered attacker is not permanently disarmed.
@export var whiff_retry_seconds := 4.0

var enemy: BaseEnemy
## Outcome of the most recent volley (see VolleyReport) plus where/when it
## was fired — the whiff gate's memory.
var _last_volley: VolleyReport
var _last_fire_position := Vector2.ZERO
var _last_fire_msec := 0

func _ready() -> void:
	enemy = actor

func validate_exports() -> void:
	# aim_ray_cast is only required with a projectile; the base assigned-check
	# would reject the melee configuration.
	if chase_state == null:
		push_error("%s: chase_state is not assigned" % get_path())
	if projectile != null and aim_ray_cast == null:
		push_error("%s: projectile set but aim_ray_cast is not assigned" % get_path())

func enter() -> void:
	enemy.velocity = Vector2.ZERO
	if not enemy.can_attack():
		transition_to(chase_state)
		return
	_face_target()
	if await enemy.attack():
		_spawn_projectiles()
		transition_to(chase_state)
	# Interrupted flows (hit/stun/death) route themselves to their states.


## The chase handover consults this before entering the attack flow (same
## role as the chase's line-of-sight gate, fed by outcome instead of rays).
## A settled volley that never reached the player proves the firing
## position bad: the gate stays closed until the body has repositioned the
## configured distance or the retry window lapses. An in-flight volley has
## no verdict yet and never closes the gate.
func fire_gate_open() -> bool:
	if not reposition_after_whiff or _last_volley == null:
		return true
	if _last_volley.arrived or not _last_volley.is_whiffed():
		return true
	var moved := enemy.global_position.distance_to(_last_fire_position)
	var elapsed := (Time.get_ticks_msec() - _last_fire_msec) / 1000.0
	return moved >= whiff_reposition_distance or elapsed >= whiff_retry_seconds

func _spawn_projectiles() -> void:
	if projectile == null or enemy.is_hit or enemy.is_dead:
		return

	# The aim rotation froze at the last chase tick; the player strafes
	# during the attack wind-up, so re-aim or the shot flies the stale
	# line into cover.
	var player = Global.player as Node2D
	if player != null:
		aim_ray_cast.global_rotation = (
			player.global_position - aim_ray_cast.global_position
		).angle()

	var volley := VolleyReport.new()
	volley.arrival_radius = whiff_arrival_radius
	if projectile_offsets.is_empty():
		_spawn_projectile(aim_ray_cast.global_position, volley)
	else:
		for offset in projectile_offsets:
			_spawn_projectile(enemy.global_position + offset, volley)
	_last_volley = volley
	_last_fire_position = enemy.global_position
	_last_fire_msec = Time.get_ticks_msec()

func _spawn_projectile(spawn_position: Vector2, volley: VolleyReport) -> void:
	# The re-aimed line was never sight-gated: firing along it can cut a
	# corner the gated line cleared. Sight-gated chasers hold fire instead;
	# the chase blind handling repositions for the next shot. Checked per
	# spawn against that spawn's muzzle line (offsets share the aim ray
	# rotation, so the result is identical per shot).
	var player = Global.player as Node2D
	if player != null and _requires_sight() \
			and not enemy.aim_line_clear(spawn_position, player.global_position):
		return
	# A projectile born inside cover dies on its first contact tick, before
	# any flight logic runs: the volley offsets sit fixed relative to the
	# body, so an overhang over the origin buries that muzzle. Skip buried
	# spawns instead of clamping — the mesh's closest point can snap
	# through a thin wall to the far side.
	if not enemy.spawn_point_clear(spawn_position):
		return
	var proj = projectile.instantiate()
	if volley != null:
		proj.volley_report = volley
		volley.register()
	get_tree().current_scene.add_child(proj)
	proj.add_to_group("Enemies")
	proj.global_position = spawn_position
	proj.global_rotation = aim_ray_cast.global_rotation

## Pins facing to the target for the whole attack flow (see
## BaseEnemy.face_toward for why movement flipping cannot own this).
func _face_target() -> void:
	var player = Global.player as Node2D
	if player != null:
		enemy.face_toward(player.global_position)

## The paired chase's sight gate also owns the shot line (see
## _spawn_projectile); enemies without LOS gating fire blind.
func _requires_sight() -> bool:
	var chase := chase_state as EnemyChase
	return chase != null and chase.require_line_of_sight


