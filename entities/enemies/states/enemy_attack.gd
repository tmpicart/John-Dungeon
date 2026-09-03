extends State
class_name EnemyAttack

@export var enemy: CharacterBody2D

func enter() -> void:
	enemy.velocity = Vector2.ZERO
	await enemy.attack()
	transition_to("EnemyChase")
