extends State
class_name EnemyAttackRedSlime

@export var pounce_duration = 3
@export var enemy: CharacterBody2D

func Enter():
	print("Attack")
	enemy.attacking = true
	await get_tree().create_timer(pounce_duration).timeout
	enemy.attacking = false

