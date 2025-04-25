extends State
class_name EnemyRetreatNecromancer

@export var enemy: CharacterBody2D
@export var navigation_agent: NavigationAgent2D
@export var speed := 6000
@export var retreat_duration := 2.5
@export var path_update_interval := 0.2

var player: CharacterBody2D
var retreat_timer := 0.0
var time_since_last_path := 0.0
var retreat_target := Vector2.ZERO

func Enter():
	player = get_tree().get_first_node_in_group("Player")
	retreat_timer = 0.0
	time_since_last_path = 0.0

	# Pick a fixed direction to run in — directly away from the player
	var from_player = enemy.global_position - player.global_position

	# Add slight randomness to avoid running into walls in a straight line
	var angle_offset = deg_to_rad(randf_range(-20, 20))
	var retreat_direction = from_player.normalized().rotated(angle_offset)


	# Calculate how far we can travel during the retreat duration
	var retreat_distance = speed * retreat_duration
	retreat_target = enemy.global_position + retreat_direction * retreat_distance

	# Start navigating to the calculated target
	navigation_agent.target_position = retreat_target

func Physics_Update(delta: float):
	if not navigation_agent or not player:
		return

	retreat_timer += delta
	if retreat_timer >= retreat_duration:
		enemy.retreat = false
		ChangeState.emit(self, "EnemyChase")
		return

	# Optionally update path periodically (not strictly needed since target is fixed)
	time_since_last_path += delta
	if time_since_last_path >= path_update_interval:
		time_since_last_path = 0.0
		navigation_agent.target_position = retreat_target

	if navigation_agent.is_navigation_finished():
		return

	var next_position = navigation_agent.get_next_path_position()
	if next_position.is_zero_approx():
		return

	var retreat_direction = (next_position - enemy.global_position).normalized()
	enemy.velocity = retreat_direction * speed * delta
