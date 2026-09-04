extends State
class_name EnemyIdle

@export var enemy : CharacterBody2D
## Wander speed in px/s (physics-tick independent).
@export var speed := 8
@export var detection_range := 100

var wander_direction : Vector2
var duration : float

var player: CharacterBody2D

func randomized_stroll():
	# Set a new wander duration
	duration = randf_range(1, 4)

	var still = randi_range(1, 3)

	if still == 1:
		wander_direction = Vector2()
	else:
		wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1))

func enter() -> void:
	# On enter, get the player and set the wander direction
	player = get_tree().get_first_node_in_group("Player")
	randomized_stroll()

func physics_update(delta: float) -> void:
	# Handle wander direction and update it based on the elapsed time (duration)
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
		transition_to("EnemyChase")
