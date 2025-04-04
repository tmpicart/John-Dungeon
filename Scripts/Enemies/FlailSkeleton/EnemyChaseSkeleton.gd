extends EnemyChase
class_name EnemyChaseSkeleton

func _attack_logic():
	# Custom attack logic: change to EnemyAttack state when in range
	if player.global_position.x < enemy.global_position.x:
		ChangeState.emit(self, "EnemyAttack")
