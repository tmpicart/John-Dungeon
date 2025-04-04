extends EnemyAttack
class_name EnemyAttackNecromancer

@export var projectile: PackedScene = null
@export var rayCast: RayCast2D

func Enter():
	# Common attack behavior from base class
	await enemy.attack()
	spawn_projectiles()
	ChangeState.emit(self, "EnemyChase")
	# Unique behavior for Necromancer attack (spawning multiple projectiles)
	spawn_projectiles()

func spawn_projectiles():
	if projectile:
		var offsets = [Vector2(-15, -25), Vector2(0, -30), Vector2(15, -25)]
		for offset in offsets:
			var proj = projectile.instantiate()
			get_tree().current_scene.add_child(proj)
			proj.add_to_group("Enemies")
			proj.global_position = enemy.global_position + offset
			proj.global_rotation = rayCast.global_rotation
