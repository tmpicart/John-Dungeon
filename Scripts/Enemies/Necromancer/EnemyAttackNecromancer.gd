extends State
class_name EnemyAttackNecromancer

@export var enemy: CharacterBody2D
@export var projectile: PackedScene = null
@export var rayCast: RayCast2D

func Enter():
	#print("Attack")
	enemy.velocity = Vector2.ZERO
	await enemy.attack()
	ChangeState.emit(self, "EnemyRetreat")

func _on_animation_player_animation_finished(animation):
	if animation == "Attack":
		if projectile:
			var offsets = [Vector2(-15, -25), Vector2(0, -30), Vector2(15, -25)]
			for offset in offsets:
				var proj = projectile.instantiate()
				get_tree().current_scene.add_child(proj)
				proj.add_to_group("Enemies")
				proj.global_position = enemy.global_position + offset
				proj.global_rotation = rayCast.global_rotation
