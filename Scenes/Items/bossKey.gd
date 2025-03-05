extends Node2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var key = $Key
@onready var message = $Label
@onready var sprite = $Sprite2D
@onready var inter = $InteractionArea


func _ready():
	interaction_area.interact = Callable(self, "_on_interact")
	message.hide()
	
	
func _on_interact():
	Global.hasBossKey = true
	sprite.hide()
	await Global.time_in_seconds
	message.show()
	await Global.time_in_seconds
	inter.queue_free()
	
	
