extends State
class_name EnemyStun

@export var enemy: CharacterBody2D

func enter() -> void:
	enemy.velocity = Vector2.ZERO
	await enemy.stun()
	transition_to("EnemyChase")
