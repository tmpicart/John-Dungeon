extends EnemyChase
class_name EnemyChaseNecromancer

@export var rayCast: RayCast2D
@export var summon_chance := 0.25  # 25% chance to summon instead of attack

func Physics_Update(delta: float):
	if not navigation_agent or not player:
		return

	var to_player = player.global_position - enemy.global_position
	var distance = to_player.length()

	# ✅ Retreat override
	if enemy.retreat and not enemy.is_hit:
		ChangeState.emit(self, "EnemyRetreat")
		return

	# ✅ Drop out of chase if too far
	if distance > chase_drop_distance:
		ChangeState.emit(self, "EnemyIdle")
		return

	# ✅ Attack / Summon if in range and has vision
	if distance <= attempt_attack_range:
		enemy.velocity = Vector2.ZERO

		var angle_to_player = to_player.angle()
		rayCast.global_rotation = angle_to_player

		if rayCast.is_colliding() and rayCast.get_collider() == player:
			if randf() < summon_chance:
				ChangeState.emit(self, "EnemySummon")
			else:
				ChangeState.emit(self, "EnemyAttack")
		return

	# ✅ Otherwise: path toward player
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
