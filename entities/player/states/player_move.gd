extends State

@export var attack_state: State
@export var block_state: State
@export var dash_state: State

var player: Node

func _ready() -> void:
	player = actor

# Handle player input related to movement
func handle_input(event: InputEvent):
	# Dash input
	if event.is_action_pressed("dash") and player.movement.can_dash:
		transition_to(dash_state)
		
	if event.is_action_pressed("attack"):
		transition_to(attack_state)
		
	if event.is_action_pressed("block"):
		transition_to(block_state)
		
	if event.is_action_pressed("bomb"):
		player.inventory.use_bomb()
		
	if event.is_action_pressed("potion"):
		player.inventory.use_potion()
		
	if event.is_action_pressed("quit"):
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")

# Called every physics frame (movement is handled here)
func physics_update(delta: float) -> void:
	# Handle movement with PlayerMovement script
	player.movement.move(delta)
	
	# Update the animation state (idle or walking)
	player.animation.update_animation(player.movement.velocity)
