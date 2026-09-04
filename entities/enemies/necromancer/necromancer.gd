extends "res://entities/enemies/base_enemy.gd"

var retreat = false

func summon() -> bool:
	return await run_action_animation("Summon", $summon_sfx)

func take_damage(dmg: int, from_position: Vector2 = Vector2.INF) -> void:
	super.take_damage(dmg, from_position)
	retreat = true

