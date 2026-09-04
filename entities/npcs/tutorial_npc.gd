extends Node2D

@onready var interaction_area: Interactable = $InteractionArea


func _ready() -> void:
	interaction_area.interacted.connect(_on_interact)
	get_node("NPC Dialog").textFile = "res://systems/dialogue/tutorial.txt"


func _on_interact() -> void:
	get_node("NPC Dialog").talk()