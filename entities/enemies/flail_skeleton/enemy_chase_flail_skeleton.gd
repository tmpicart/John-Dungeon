extends EnemyChase
class_name EnemyChaseFlailSkeleton

# Internal variables to define the attack ranges
var attempt_attack_range_x: float = attempt_attack_range
var attempt_attack_range_y: float = attempt_attack_range / 3.0

func physics_update(delta: float) -> void:
	if not navigation_agent or not player:
		return

	var to_player = player.global_position - enemy.global_position
	var distance = to_player.length()

	# Transition to Idle if player is too far
	if distance > chase_drop_distance:
		transition_to("EnemyIdle")
		return

	# Use derived x and y attack ranges
	if abs(to_player.x) <= attempt_attack_range_x and abs(to_player.y) <= attempt_attack_range_y:
		transition_to("EnemyAttack")
		return

	# Recalculate path if needed
	time_since_last_path += delta
	if time_since_last_path >= path_update_interval:
		time_since_last_path = 0.0
		navigation_agent.target_position = player.global_position

	if navigation_agent.is_navigation_finished():
		return

	var next_position = navigation_agent.get_next_path_position()
	if next_position.is_zero_approx():
		return

	var direction = (next_position - enemy.global_position).normalized()
	enemy.velocity = direction * speed * delta
