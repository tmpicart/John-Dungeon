extends EnemyChase
class_name EnemyChaseArcaneArcher

@export var rayCast: RayCast2D
@export var retreat_range := 50  

func Physics_Update(delta: float):
	if not navigation_agent or not player:
		return

	var to_player = player.global_position - enemy.global_position
	var distance = to_player.length()

	if distance > chase_drop_distance:
		ChangeState.emit(self, "EnemyIdle")
		return

	if distance < retreat_range:
		ChangeState.emit(self, "EnemyRetreat")
		return

	if distance <= attempt_attack_range:
		var ray_origin = enemy.to_global(rayCast.position)
		var offset_to_player = player.global_position - ray_origin
		rayCast.global_rotation = offset_to_player.angle()

		enemy.velocity = Vector2.ZERO

		if rayCast.is_colliding() and rayCast.get_collider() == player:
			ChangeState.emit(self, "EnemyAttack")
		return

	time_since_last_path += delta
	if time_since_last_path >= path_update_interval:
		time_since_last_path = 0.0

		var direction_to_player = to_player.normalized()
		var stop_distance = attempt_attack_range * 0.9
		var target_position = player.global_position - direction_to_player * stop_distance
		navigation_agent.target_position = target_position

	if navigation_agent.is_navigation_finished():
		return

	var next_position = navigation_agent.get_next_path_position()
	if next_position.is_zero_approx():
		return

	var path_direction = (next_position - enemy.global_position).normalized()
	enemy.velocity = path_direction * speed * delta
