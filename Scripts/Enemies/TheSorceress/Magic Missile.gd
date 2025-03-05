extends State

@export var enemy: CharacterBody2D
@export var projectile: PackedScene = null
@export var rayCast: RayCast2D
@export var delay_between_rounds = 2

func Enter():
	print("Magic Missile")
	enemy.velocity = Vector2.ZERO
	var rounds = 1
	if enemy.phase2:
		rounds = 3
	await enemy.cast()
	if projectile:
		for i in rounds:
			var offsets = [Vector2(-30, -70), Vector2(-15, -75), Vector2(0, -80), Vector2(15, -75),  Vector2(30, -70)]
			for offset in offsets:
				var proj = projectile.instantiate()
				get_tree().current_scene.add_child(proj)
				proj.add_to_group("Enemies")
				proj.scale = Vector2(1.25, 1.25)
				proj.global_position = enemy.global_position + offset
				proj.global_rotation = rayCast.global_rotation
			await get_tree().create_timer(delay_between_rounds).timeout	
	ChangeState.emit(self, "Cast")
