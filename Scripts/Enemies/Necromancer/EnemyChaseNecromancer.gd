extends EnemyChase
class_name EnemyChaseNecromancer

@export var rayCast: RayCast2D
@export var summon_chance := 0.25  # 25% chance to summon instead of attack

func Physics_Update(delta: float):
	# Get direction to the player
	var direction = player.global_position - enemy.global_position
	var angle_to_player = direction.angle()
	
	# Ensure rayCast rotates towards the player
	rayCast.global_rotation = angle_to_player  

	# Call base movement logic
	super.Physics_Update(delta)  

	# Only attempt attack if raycast sees the player
	if rayCast.is_colliding() and rayCast.get_collider() == player:
		if randf() < summon_chance:
			ChangeState.emit(self, "EnemySummon")  # Summon minions
		else:
			ChangeState.emit(self, "EnemyAttack")  # Normal attack
