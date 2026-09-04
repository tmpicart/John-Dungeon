extends "res://entities/enemies/base_enemy.gd"

## Base attack flow without attack_sfx — this skeleton's swing sound is
## triggered by an animation value track, not by code.

func attack() -> bool:
	if not can_attack():
		return false
	var completed := await run_action_animation("Attack")
	if completed:
		start_attack_cooldown()
	return completed

