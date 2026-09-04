extends EnemyAttack
class_name EnemyAttackArcaneArcher

@export var projectile: PackedScene = null
@export var ray_cast: RayCast2D

func enter() -> void:
	enemy.velocity = Vector2.ZERO
	if not enemy.can_attack():
		transition_to("EnemyChase")
		return

	var completed: bool = await enemy.attack()
	if not completed:
		return

	if projectile and not enemy.is_hit and not enemy.is_dead:
		spawn_projectile()

	transition_to("EnemyChase")

func spawn_projectile():
	var arrow = projectile.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.add_to_group("Enemies")

	arrow.global_position = ray_cast.global_position
	arrow.global_rotation = ray_cast.global_rotation

