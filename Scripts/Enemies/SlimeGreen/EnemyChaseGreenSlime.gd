extends State
class_name EnemyChaseGreenSlime

@export var enemy: CharacterBody2D
@export var speed := .75
@export var chase_drop_distance := 100
@export var attempt_attack_range := 0

var player: CharacterBody2D

func Enter():
	#print("Follow")
	player = get_tree().get_first_node_in_group("Player")
	#print(player.name)
	
func Physics_Update(delta:float):
	var direction = player.global_position - enemy.global_position 
	#print(direction)
	if direction.length() > attempt_attack_range:
		enemy.velocity = direction * speed
	else:	
		ChangeState.emit(self, "EnemyAttack")

	if direction.length() > chase_drop_distance:
		ChangeState.emit(self, "EnemyIdle")
