extends State

func handle_input(_event: InputEvent):
	if _event is InputEventKey:
		if _event.pressed:
			# Check for movement input
			if Input.is_action_pressed("right") or Input.is_action_pressed("left") or Input.is_action_pressed("up") or Input.is_action_pressed("down"):
				# Transition to the MoveState
				ChangeState.emit(self,"MoveState")
			
			# Check for attack input
			elif Input.is_action_just_pressed("attack"):
				# Transition to the AttackState
				ChangeState.emit(self,"AttackState")
			
			# Check for block input (if applicable)
			elif Input.is_action_just_pressed("block"):
				# Transition to the BlockState
				ChangeState.emit(self,"BlockState")
