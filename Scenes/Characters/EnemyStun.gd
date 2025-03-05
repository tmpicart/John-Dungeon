extends State
class_name EnemyStun

@export var enemy: CharacterBody2D

func Enter():
	print("Stunned")
	enemy.velocity = Vector2.ZERO
	await enemy.stun()
	ChangeState.emit(self, "EnemyChase")
