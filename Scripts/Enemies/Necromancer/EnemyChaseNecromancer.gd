extends EnemyChase
class_name EnemyChaseNecromancer

@export var rayCast: RayCast2D
@export var summon_chance := 0.25  # 25% chance to summon instead of attack

func Physics_Update(delta: float):
	var direction = player.global_position - enemy.global_position
	var angle_to_player = direction.angle()
	rayCast.global_rotation = angle_to_player

	# Handle forced retreat state
	if enemy.retreat and not enemy.is_hit:
		ChangeState.emit(self, "EnemyRetreat")
		return
	
	# Approach the player if not in range
	if direction.length() > attempt_attack_range:
		enemy.velocity = direction.normalized() * speed * delta
	# Stay and act when in range
	else:
		enemy.velocity = Vector2.ZERO
		if rayCast.is_colliding() and rayCast.get_collider() == player:
			if randf() < summon_chance:
				ChangeState.emit(self, "EnemySummon")
			else:
				ChangeState.emit(self, "EnemyAttack")

	# Drop out of chase state if the player is too far away
	if direction.length() > chase_drop_distance:
		ChangeState.emit(self, "EnemyIdle")
