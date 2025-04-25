extends State

func Enter():
	
	await Global.player.combat.block() 
	ChangeState.emit(self, "MoveState")

func Physics_Update(delta: float):
	# Handle movement with PlayerMovement script
	Global.player.movement.move(delta)
	
	# Update the animation state (idle or walking)
	Global.player.animation.update_animation(Global.player.movement.velocity)
