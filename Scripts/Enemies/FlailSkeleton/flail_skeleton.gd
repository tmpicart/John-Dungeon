extends "res://Scripts/Enemies/BaseEnemy.gd"

func attack():
	if attacking or is_dead or is_hit or stunned:
		return

	attacking = true
	if animation_player.has_animation("Attack"):
		animation_player.play("Attack")
	
	# No attack_sfx played here
	await wait_for_animation("Attack")
	attacking = false
