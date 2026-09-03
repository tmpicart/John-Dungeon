extends State

@export var next_state: State

## Velocity fraction kept per 60 Hz physics tick (parity with the legacy double-applied 0.75 decay).
@export var velocity_retention := 0.5625

var player: Node

func _ready() -> void:
	player = actor

func enter() -> void:

	await player.combat.block()
	transition_to(next_state)

func physics_update(delta: float) -> void:
	# Handle movement with PlayerMovement script
	player.movement.move(delta)

	player.movement.velocity *= pow(velocity_retention, delta * 60.0)

	# Update the animation state (idle or walking)
	player.animation.update_animation(player.movement.velocity)
