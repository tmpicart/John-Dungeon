extends State

@export var enemy : CharacterBody2D


func activate():
	Global.door.show()
	transition_to("Engage")
