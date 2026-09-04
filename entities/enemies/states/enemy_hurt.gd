extends State
class_name EnemyHurt

## Hit-stun state: plays OnHit and returns to chase once recovery finishes.
## `is_hit` is cleared here (on exit) so overlapping damage is ignored during
## recovery, and any interrupting state takes over cleanly.

@export var chase_state: State

var enemy: BaseEnemy

func _ready() -> void:
	enemy = actor

func enter() -> void:
	enemy.velocity = Vector2.ZERO
	await enemy.play_interrupt_animation("OnHit")
	if enemy.is_dead:
		return
	transition_to(chase_state)

func exit() -> void:
	enemy.is_hit = false

