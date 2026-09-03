extends State

@export var next_state: State

var player: Node

func _ready() -> void:
	player = actor

func enter() -> void:

	await player.movement.dash()
	transition_to(next_state)

func physics_update(delta: float) -> void:
	# Handle movement with PlayerMovement script
	player.movement.move(delta)
