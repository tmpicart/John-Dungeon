extends State
class_name EnemyRetreat

@export var enemy: CharacterBody2D
@export var speed := 1.2
@export var retreat_range := 70
@export var retreat_duration := 1

var player: CharacterBody2D

func Enter():
	print("RUN")
	player = get_tree().get_first_node_in_group("Player")

func Physics_Update(delta:float):
	var direction = enemy.global_position - player.global_position
	if direction.length() < retreat_range:
		enemy.velocity = direction * speed
		await get_tree().create_timer(retreat_duration).timeout
		ChangeState.emit(self, "EnemyChase")
