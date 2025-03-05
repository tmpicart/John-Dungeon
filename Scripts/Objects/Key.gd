extends Node2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var key = $Key


func _ready():
	interaction_area.interact = Callable(self, "_on_interact")
	
	
func _on_interact():
	Global.player.addKey()
	queue_free()
	
