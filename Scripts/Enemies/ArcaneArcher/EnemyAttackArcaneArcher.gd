extends EnemyAttack
class_name EnemyAttackArcaneArcher

@export var projectile: PackedScene = null
@export var rayCast: RayCast2D

func Enter():
	# Common attack behavior from base class
	await enemy.attack()
	spawn_projectile()
	ChangeState.emit(self, "EnemyChase")
	# Unique behavior for Arcane Archer attack

func spawn_projectile():
	if projectile and not enemy.is_hit:
		print("ARROW")
		var arrow = projectile.instantiate()
		get_tree().current_scene.add_child(arrow)
		arrow.add_to_group("Enemies")
		
		arrow.global_position = rayCast.global_position
		arrow.global_rotation = rayCast.global_rotation
