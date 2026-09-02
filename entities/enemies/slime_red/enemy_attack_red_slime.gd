extends EnemyAttack
class_name EnemyAttackRedSlime

@export var pounce_duration = 3
@export var pounce_speed := 10000

var player: CharacterBody2D
var direction_normalized: Vector2

func Enter():
	player = get_tree().get_first_node_in_group("Player")
	
	# Calculate direction towards the player and normalize it
	var direction = player.global_position - enemy.global_position
	direction_normalized = direction.normalized()
	
	# Mark the enemy as attacking
	enemy.attacking = true
	
	# Wait for the pounce duration
	await get_tree().create_timer(pounce_duration).timeout
	
	# Stop the attack
	enemy.attacking = false
	
	# Change state to EnemyChase after the pounce
	ChangeState.emit(self, "EnemyChase")

func Physics_Update(delta: float):
	# Move the enemy towards the player during the pounce
	if not enemy.is_dead:
		enemy.velocity = direction_normalized * pounce_speed * delta
