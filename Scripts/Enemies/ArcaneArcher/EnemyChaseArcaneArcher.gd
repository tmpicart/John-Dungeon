extends EnemyChase
class_name EnemyChaseArcaneArcher

@export var rayCast: RayCast2D
@export var retreat_range := 50  

# Override the Physics_Update method to add the unique behavior for the Arcane Archer
func Physics_Update(delta: float):
	var direction = player.global_position - enemy.global_position
	var angle_to_player = direction.angle()
	rayCast.global_rotation = angle_to_player
	
	# Handle approaching the player
	if direction.length() > attempt_attack_range:
		enemy.velocity = direction.normalized() * speed * delta
		#print("APPROACH")
		
	# Handle retreating from the player
	elif direction.length() < retreat_range:
		#print("RETREAT")
		direction = (enemy.global_position - player.global_position).normalized()
		enemy.velocity = direction * speed * delta
		
	# Handle attack logic
	else:
		#print("ATTACK")
		if rayCast.is_colliding() and rayCast.get_collider() == player:
			ChangeState.emit(self, "EnemyAttack")
	
	# Drop out of chase state if the player is too far away
	if direction.length() > chase_drop_distance:
		ChangeState.emit(self, "EnemyIdle")
