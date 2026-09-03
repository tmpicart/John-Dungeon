extends Node2D

const MESSAGE_TIME := 1.0

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var key = $Key
@onready var message = $Label
@onready var sprite = $Sprite2D
@onready var inter = $InteractionArea


func _ready():
	interaction_area.interact = Callable(self, "_on_interact")
	message.hide()
	
	
func _on_interact():
	Global.has_boss_key = true
	sprite.hide()
	await get_tree().create_timer(MESSAGE_TIME).timeout
	message.show()
	await get_tree().create_timer(MESSAGE_TIME).timeout
	inter.queue_free()