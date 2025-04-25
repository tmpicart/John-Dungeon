extends State
class_name EnemyRetreat

@export var enemy: CharacterBody2D
@export var navigation_agent: NavigationAgent2D
@export var speed := 2500
@export var retreat_distance := 100
@export var wall_avoid_distance := 25
@export var retreat_time_limit := 2.0  # New time limit for retreating
@export var path_update_interval := 0.2
@export var rayCast: RayCast2D

var player: CharacterBody2D
var time_since_last_path := 0.0
var retreat_direction := Vector2.ZERO
var retreat_timer := 0.0  # Timer for retreating duration

func Enter():
	player = get_tree().get_first_node_in_group("Player")
	time_since_last_path = 0.0
	retreat_timer = 0.0  # Reset timer when entering retreat state

	# Calculate the direction directly away from the player
	var from_player = enemy.global_position - player.global_position
	retreat_direction = from_player.normalized()  # Directly opposite of the player

	# Set the initial target to a point far enough away
	var updated_target = enemy.global_position + retreat_direction * retreat_distance
	navigation_agent.target_position = updated_target

func Physics_Update(delta: float):
	if not navigation_agent or not player:
		return

	# Update retreat timer
	retreat_timer += delta

	# Check if the retreat time exceeds the time limit, and switch to chase state if so
	if retreat_timer >= retreat_time_limit:
		ChangeState.emit(self, "EnemyChase")
		return

	var current_distance = (enemy.global_position - player.global_position).length()
	if current_distance >= retreat_distance:
		ChangeState.emit(self, "EnemyChase")
		return

	# Aim ray in the retreat direction and check for wall
	rayCast.global_rotation = retreat_direction.angle()
	rayCast.force_raycast_update()

	if rayCast.is_colliding():
		var collision_point = rayCast.get_collision_point()
		var distance_to_collision = (enemy.global_position - collision_point).length()

		if distance_to_collision <= wall_avoid_distance:
			# Wall avoidance logic: Find a new direction
			# Rotate retreat direction randomly within a 90 degree range to avoid the wall
			retreat_direction = retreat_direction.rotated(deg_to_rad(90))
			rayCast.global_rotation = retreat_direction.angle()
			rayCast.force_raycast_update()

	# Update retreat target if path time expired
	time_since_last_path += delta
	if time_since_last_path >= path_update_interval:
		time_since_last_path = 0.0

		# Update the target only if a wall is in the way or pathfinding needs an update
		var updated_target = enemy.global_position + retreat_direction * retreat_distance
		navigation_agent.target_position = updated_target

	# Handle the navigation path
	if navigation_agent.is_navigation_finished():
		return

	var next_position = navigation_agent.get_next_path_position()
	if next_position.is_zero_approx():
		return

	var path_direction = (next_position - enemy.global_position).normalized()
	enemy.velocity = path_direction * speed * delta
