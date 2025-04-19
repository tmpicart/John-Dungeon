extends EnemyChase
class_name EnemyChaseSkeleton

@export var position_snap_tolerance: float = 1.0
@export var fallback_attack_time: float = 1.2

var time_near_player: float = 0.0
var favor_right_flank: bool = true  # Toggle for flanking side

func Physics_Update(delta: float):
	if not navigation_agent or not player:
		return

	var enemy_pos = enemy.global_position
	var player_pos = player.global_position
	var to_player = player_pos - enemy_pos
	var distance = to_player.length()

	# Give up if player is too far
	if distance > chase_drop_distance:
		ChangeState.emit(self, "EnemyIdle")
		time_near_player = 0.0
		return

	var horizontal_gap = abs(to_player.x)
	var vertical_gap = abs(to_player.y)

	# Occasionally flip flanking side
	if randf() < 0.05:
		favor_right_flank = !favor_right_flank

	var flank_side = 1 if favor_right_flank else -1
	var flank_offset = Vector2(attempt_attack_range, 0)
	var target_position = player_pos + flank_offset * flank_side

	# Adjust vertical position to approach side-on more reliably
	var max_vertical_correction = attempt_attack_range * 0.75

	if abs(to_player.y) > attempt_attack_range * 2:
		target_position.y = player_pos.y  # Snap directly when misaligned heavily
	elif abs(to_player.y) > attempt_attack_range:
		target_position.y = enemy_pos.y + clamp(to_player.y, -max_vertical_correction, max_vertical_correction)
	else:
		target_position.y = player_pos.y

	# Conditions for attacking
	var horizontally_aligned = horizontal_gap <= attempt_attack_range
	var vertically_aligned = vertical_gap <= attempt_attack_range + position_snap_tolerance
	var aligned_for_attack = horizontally_aligned and vertically_aligned
	var reached_flank_position = enemy_pos.distance_to(target_position) <= position_snap_tolerance

	if horizontally_aligned:
		time_near_player += delta
	else:
		time_near_player = 0.0

	if reached_flank_position or (aligned_for_attack and time_near_player >= fallback_attack_time):
		ChangeState.emit(self, "EnemyAttack")
		time_near_player = 0.0
		favor_right_flank = !favor_right_flank
		return

	# Navigation/pathing
	time_since_last_path += delta
	if time_since_last_path >= path_update_interval:
		time_since_last_path = 0.0
		navigation_agent.target_position = target_position

	# Move enemy
	if not navigation_agent.is_navigation_finished():
		var next_path_point = navigation_agent.get_next_path_position()
		var move_direction = next_path_point - enemy_pos
		if move_direction.length_squared() > 0.01:
			enemy.velocity = move_direction.normalized() * speed * delta
