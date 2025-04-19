extends "res://Scripts/Enemies/BaseEnemy.gd"

func attack():
	if attacking or is_dead or stunned:
		return

	attacking = true
	if $AnimationPlayer.has_animation("Attack"):
		$AnimationPlayer.play("Attack")	
	await get_tree().create_timer($AnimationPlayer.current_animation_length).timeout
	attacking = false
