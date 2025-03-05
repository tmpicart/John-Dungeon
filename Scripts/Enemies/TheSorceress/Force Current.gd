extends State

@export var enemy: CharacterBody2D
@export var projectile: PackedScene = null
@export var rayCast: RayCast2D
@export var rounds = 5
@export var phase2_rounds = 7

func Enter():
	print("Force Current")
	enemy.velocity = Vector2.ZERO
	await enemy.cast()
	if enemy.phase2:
		rounds = phase2_rounds
	if projectile:
		var rotation_offset = 0
		var delay_between_rounds = .75  # Adjust this value as needed
		for round in range(rounds):
			for i in range(3):  # Send out 4 projectiles per round
				var rotation = rayCast.global_rotation + rotation_offset
				var proj = projectile.instantiate()
				get_tree().current_scene.add_child(proj)
				proj.add_to_group("Enemies")
				proj.global_position = enemy.global_position + Vector2(0, -40)
				proj.global_rotation = rotation
				rotation_offset += 90  # Increase rotation offset for next projectile
			await get_tree().create_timer(delay_between_rounds).timeout
			rotation_offset += 45
		ChangeState.emit(self, "Cast")
