extends State
class_name EnemyAttackArcaneArcher

@export var enemy: CharacterBody2D
@export var projectile: PackedScene = null
@export var rayCast: RayCast2D

func Enter():
	#print("Attack")
	enemy.velocity = Vector2.ZERO
	await enemy.attack()
	ChangeState.emit(self, "EnemyChase")

func _on_animation_player_animation_finished(animation):
	if animation == "Attack":
		if projectile:
			var arrow = projectile.instantiate()
			get_tree().current_scene.add_child(arrow)
			arrow.add_to_group("Enemies")
			
			arrow.global_position = rayCast.global_position
			arrow.global_rotation = rayCast.global_rotation
