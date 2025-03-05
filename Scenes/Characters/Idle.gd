extends State

@export var enemy : CharacterBody2D


func activate():
	Global.door.show()
	print(Global.door)
	ChangeState.emit(self, "Engage")
