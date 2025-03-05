extends Node2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var player = get_tree().get_first_node_in_group("Player")

func _ready():
	interaction_area.interact = Callable(self, "_on_interact")
	get_node("NPC Dialog").textFile = "res://Scripts/Dialogue/Tutorial.txt"
	
func _on_interact():
	get_node("NPC Dialog").talk()
		
