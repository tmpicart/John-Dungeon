extends State
class_name EnemyAttack

@export var enemy: CharacterBody2D

func enter() -> void:
	enemy.velocity = Vector2.ZERO
	if not enemy.can_attack():
		transition_to("EnemyChase")
		return
	if await enemy.attack():
		transition_to("EnemyChase")
	# Interrupted flows (hit/stun/death) route themselves to their states.

