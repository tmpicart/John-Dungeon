extends State
class_name EnemyRetreat

@export var enemy: CharacterBody2D
@export var speed := 2000
@export var retreat_range := 100
@export var retreat_duration := 1

var player: CharacterBody2D

func Enter():
	player = get_tree().get_first_node_in_group("Player")
	await get_tree().create_timer(retreat_duration).timeout
	enemy.retreat = false
	
func Physics_Update(delta:float):
	var direction = enemy.global_position - player.global_position
	if direction.length() < retreat_range:
		enemy.velocity = direction.normalized() * speed * delta
		await get_tree().create_timer(retreat_duration).timeout
		ChangeState.emit(self, "EnemyChase")
