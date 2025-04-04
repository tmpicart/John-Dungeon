extends State
class_name EnemyIdle

@export var enemy : CharacterBody2D
@export var speed := 500
@export var detection_range := 300

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
	
func Enter():
	# On enter, get the player and set the wander direction
	player = get_tree().get_first_node_in_group("Player")
	randomized_stroll()

func Physics_Update(delta: float):
	# Handle wander direction and update it based on the elapsed time (duration)
	if duration > 0:
		duration -= delta
	else:
		randomized_stroll()

	# Use delta to ensure smooth and frame-rate independent movement
	if enemy:
		enemy.velocity = wander_direction * speed * delta
	
	# Check if the player is within detection range
	var direction = player.global_position - enemy.global_position
	if direction.length() < detection_range:
		ChangeState.emit(self, "EnemyChase")
