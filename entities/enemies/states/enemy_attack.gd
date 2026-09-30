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

var enemy: BaseEnemy

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

	if projectile_offsets.is_empty():
		_spawn_projectile(aim_ray_cast.global_position)
	else:
		for offset in projectile_offsets:
			_spawn_projectile(enemy.global_position + offset)

func _spawn_projectile(spawn_position: Vector2) -> void:
	# The re-aimed line was never sight-gated: firing along it can cut a
	# corner the gated line cleared. Sight-gated chasers hold fire instead;
	# the chase blind handling repositions for the next shot. Checked per
	# spawn against that spawn's muzzle line (offsets share the aim ray
	# rotation, so the result is identical per shot).
	var player = Global.player as Node2D
	if player != null and _requires_sight() \
			and not enemy.aim_line_clear(spawn_position, player.global_position):
		return
	var proj = projectile.instantiate()
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


