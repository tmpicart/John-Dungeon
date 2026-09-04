extends EnemyAttack
class_name EnemyAttackNecromancer

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

	spawn_projectiles()

	transition_to("EnemyChase")

func spawn_projectiles():
	if projectile == null or enemy.is_dead:
		return

	var offsets = [Vector2(-15, -25), Vector2(0, -30), Vector2(15, -25)]
	for offset in offsets:
		var proj = projectile.instantiate()
		get_tree().current_scene.add_child(proj)
		proj.add_to_group("Enemies")
		proj.global_position = enemy.global_position + offset
		proj.global_rotation = ray_cast.global_rotation

