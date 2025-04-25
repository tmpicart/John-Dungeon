extends State

# Handle player input related to movement
func handle_input(event: InputEvent):
	# Dash input
	if event.is_action_pressed("dash") and Global.player.movement.can_dash:
		ChangeState.emit(self, "DashState")
		
	if event.is_action_pressed("attack"):
		ChangeState.emit(self, "AttackState")
		
	if event.is_action_pressed("block"):
		ChangeState.emit(self,"BlockState")
		
	if event.is_action_pressed("bomb"):
		Global.player.inventory.use_bomb()
		
	if event.is_action_pressed("potion"):
		Global.player.inventory.use_potion()

# Called every physics frame (movement is handled here)
func Physics_Update(delta: float):
	# Handle movement with PlayerMovement script
	Global.player.movement.move(delta)
	
	# Update the animation state (idle or walking)
	Global.player.animation.update_animation(Global.player.movement.velocity)
