extends State

func Enter():
	
	await Global.player.movement.dash() 
	ChangeState.emit(self, "MoveState")

func Physics_Update(delta: float):
	# Handle movement with PlayerMovement script
	Global.player.movement.move(delta)
