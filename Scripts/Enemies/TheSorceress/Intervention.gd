extends State

@export var enemy: CharacterBody2D
@export var intervention_light: PackedScene = null
@export var glyph: PackedScene = null
@export var force_wave: PackedScene = null
@export var duration = 3

func Enter():
	print("Intervention")
	enemy.velocity = Vector2.ZERO
	enemy.is_glide = true
	if glyph:
		var warning = glyph.instantiate()
		warning.scale = Vector2(4,4)
		get_tree().current_scene.add_child(warning)
		warning.add_to_group("Enemies")
		warning.global_position = enemy.global_position + Vector2(-5, -5)
	
	await get_tree().create_timer(3).timeout

	if intervention_light:
		var light = intervention_light.instantiate()
		get_tree().current_scene.add_child(light)
		light.add_to_group("Enemies")
		light.global_position = enemy.global_position + Vector2(0, -40)
	
	enemy.is_glide = false
	await get_tree().create_timer(.5).timeout
	
	if force_wave:
		var rounds = 15
		var rotation_offset = 0
		var delay_between_rounds = .3  # Adjust this value as needed
		for round in range(rounds):
			for i in range(3):  # Send out 4 projectiles per round
				var rotation = rotation_offset
				var proj = force_wave.instantiate()
				get_tree().current_scene.add_child(proj)
				proj.add_to_group("Enemies")
				proj.scale = Vector2(2,2)
				proj.global_position = enemy.global_position + Vector2(0, 0)
				proj.global_rotation = rotation
				rotation_offset += 90  # Increase rotation offset for next projectile
			await get_tree().create_timer(delay_between_rounds).timeout
			rotation_offset += 45
		enemy.phase2 = true
		ChangeState.emit(self, "Cast")
