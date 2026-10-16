extends State
class_name EnemyIdle

## Wanders randomly until the player enters detection range.

@export var speed := 8
@export var detection_range := 100
@export var chase_state: State

var wander_direction: Vector2
var duration: float
var player: CharacterBody2D
var enemy: BaseEnemy

func _ready() -> void:
	enemy = actor

func randomized_stroll():
	# A stroll is a short commitment — re-rolling every 1–4 s reads as idle
	# rather than patrol — with one roll in three holding still.
	duration = randf_range(1, 4)

	var still = randi_range(1, 3)

	if still == 1:
		wander_direction = Vector2()
	else:
		wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")
	randomized_stroll()

func physics_update(delta: float) -> void:
	if duration > 0:
		duration -= delta
	else:
		randomized_stroll()

	# Use the speed directly — move_and_slide applies the tick delta internally
	if enemy:
		enemy.velocity = wander_direction * speed

	if player == null:
		return

	# Check if the player is within detection range
	var direction = player.global_position - enemy.global_position
	if direction.length() < detection_range:
		transition_to(chase_state)

