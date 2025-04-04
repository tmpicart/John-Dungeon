# Example from your chase state
extends State
class_name EnemyChase

@export var enemy: CharacterBody2D
@export var speed := 2000
@export var chase_drop_distance := 500
@export var attempt_attack_range := 15

var player: CharacterBody2D

func Enter():
	player = get_tree().get_first_node_in_group("Player")

func Physics_Update(delta: float):
	var direction = player.global_position - enemy.global_position
	var direction_normalized = direction.normalized()

	# Use delta to ensure frame-rate independent movement
	enemy.velocity = direction_normalized * speed * delta
	
	# Attack logic and idle state transition remain the same
	if direction.length() > chase_drop_distance:
		ChangeState.emit(self, "EnemyIdle")
	elif direction.length() <= attempt_attack_range:
		ChangeState.emit(self, "EnemyAttack")
