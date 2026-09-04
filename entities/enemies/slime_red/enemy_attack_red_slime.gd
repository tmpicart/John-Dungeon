extends EnemyAttack
class_name EnemyAttackRedSlime

@export var pounce_duration: float = 3.0
## Pounce speed in px/s (physics-tick independent).
@export var pounce_speed := 133

var player: CharacterBody2D
var direction_normalized: Vector2

func enter() -> void:
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

	if enemy.is_dead:
		return

	# Change state to EnemyChase after the pounce
	transition_to("EnemyChase")

func physics_update(_delta: float) -> void:
	# Move the enemy towards the player during the pounce
	if not enemy.is_dead:
		enemy.velocity = direction_normalized * pounce_speed

