extends EnemyChase
class_name EnemyChaseArcaneArcher

@export var rayCast: RayCast2D
@export var retreat_range := 50  

func Physics_Update(delta: float):
	if not navigation_agent or not player:
		return

	var to_player = player.global_position - enemy.global_position
	var distance = to_player.length()
	var direction = to_player.normalized()

	# ✅ Drop out of chase state if too far
	if distance > chase_drop_distance:
		ChangeState.emit(self, "EnemyIdle")
		return

	# ✅ Retreat if too close
	if distance < retreat_range:
		var retreat_direction = (enemy.global_position - player.global_position).normalized()
		enemy.velocity = retreat_direction * speed * delta
		return

	# ✅ Attack if within attack range and ray hits player
	if distance <= attempt_attack_range:
		var angle_to_player = to_player.angle()
		rayCast.global_rotation = angle_to_player

		if rayCast.is_colliding() and rayCast.get_collider() == player:
			ChangeState.emit(self, "EnemyAttack")
			return

	# ✅ Otherwise: navigate using pathfinding
	time_since_last_path += delta
	if time_since_last_path >= path_update_interval:
		time_since_last_path = 0.0
		navigation_agent.target_position = player.global_position

	if navigation_agent.is_navigation_finished():
		return

	var next_position = navigation_agent.get_next_path_position()
	if next_position.is_zero_approx():
		return

	var path_direction = (next_position - enemy.global_position).normalized()
	enemy.velocity = path_direction * speed * delta
