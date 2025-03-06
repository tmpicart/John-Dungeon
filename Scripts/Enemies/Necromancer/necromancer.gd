extends "res://Scripts/Enemies/BaseEnemy.gd"

func summon():
	if attacking or is_dead:
		return

	attacking = true
	$AnimationPlayer.play("Summon")
	attack_sfx.play() # Uses attack_sfx for summoning sounds
	await wait_for_animation()
	attacking = false
