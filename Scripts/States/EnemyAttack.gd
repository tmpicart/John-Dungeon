extends State
class_name EnemyAttack

@export var enemy: CharacterBody2D

func Enter():
	enemy.velocity = Vector2.ZERO
	await enemy.attack()
	ChangeState.emit(self, "EnemyChase")
