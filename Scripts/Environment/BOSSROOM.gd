extends Node2D

@onready var door = $Door
# Called when the node enters the scene tree for the first time.
func _ready():
	Global.door = door
	Global.door.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
