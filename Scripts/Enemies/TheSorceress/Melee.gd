extends State

@export var enemy: CharacterBody2D
@export var speed := .5
@export var attempt_attack_range := 50
@export var projectile: PackedScene = null

var player: CharacterBody2D

func Enter():
	print("Melee")
	player = get_tree().get_first_node_in_group("Player")
	
func Physics_Update(delta:float):
	var direction = player.global_position - enemy.global_position 
	#print(direction)
	if direction.length() > attempt_attack_range:
		enemy.velocity = direction * speed
	else:
		await enemy.melee()
		if enemy.phase2 == true:
			if projectile:
				var rotation_offset = 0
				for i in range(3):  # Send out 4 projectiles per round
					var rotation = enemy.global_rotation + rotation_offset
					var proj = projectile.instantiate()
					get_tree().current_scene.add_child(proj)
					proj.add_to_group("Enemies")
					proj.global_position = enemy.global_position + Vector2(0, -40)
					proj.global_rotation = rotation
					rotation_offset += 90  # Increase rotation offset for next projectile

		ChangeState.emit(self, "Engage")

