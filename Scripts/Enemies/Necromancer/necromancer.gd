extends "res://Scripts/Enemies/BaseEnemy.gd"

var retreat = false

func summon():
	if attacking or is_dead:
		return

	attacking = true
	$AnimationPlayer.play("Summon")
	$summon_sfx.play() # Uses attack_sfx for summoning sounds
	await wait_for_animation("Summon")
	attacking = false

func take_damage(num):
	super.take_damage(num)
	retreat = true
