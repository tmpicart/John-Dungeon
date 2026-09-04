extends State
class_name EnemyStun

## Parry-stun state: entered via BaseEnemy.stun() when a melee hit is parried.
## Damage taken while `stunned` is doubled.

@export var chase_state: State

var enemy: BaseEnemy

func _ready() -> void:
	enemy = actor

func enter() -> void:
	enemy.velocity = Vector2.ZERO
	enemy.stunned = true
	await enemy.play_interrupt_animation("stun")
	if enemy.is_dead:
		return
	transition_to(chase_state)

func exit() -> void:
	enemy.stunned = false


