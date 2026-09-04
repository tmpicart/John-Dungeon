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
	if await enemy.attack():
		_spawn_projectiles()
		transition_to(chase_state)
	# Interrupted flows (hit/stun/death) route themselves to their states.

func _spawn_projectiles() -> void:
	if projectile == null or enemy.is_hit or enemy.is_dead:
		return

	if projectile_offsets.is_empty():
		_spawn_projectile(aim_ray_cast.global_position)
	else:
		for offset in projectile_offsets:
			_spawn_projectile(enemy.global_position + offset)

func _spawn_projectile(spawn_position: Vector2) -> void:
	var proj = projectile.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.add_to_group("Enemies")
	proj.global_position = spawn_position
	proj.global_rotation = aim_ray_cast.global_rotation


