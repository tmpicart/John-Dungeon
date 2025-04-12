extends "res://Scripts/Enemies/BaseEnemy.gd"

func attack():
	if attacking or is_dead or is_hit or stunned:
		return

	attacking = true
	if $AnimationPlayer.has_animation("Attack"):
		$AnimationPlayer.play("Attack")	
	await wait_for_animation()
	attacking = false
