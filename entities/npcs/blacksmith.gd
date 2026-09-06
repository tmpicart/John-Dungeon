extends Node2D

## Blacksmith shopkeeper: opens his dialogue first, then his shop.

@export var shop_data: ShopData

@onready var interaction_area: Interactable = $InteractionArea
@onready var shop = $Shop


func _ready() -> void:
	interaction_area.interacted.connect(_on_interact)
	get_node("NPC Dialog").textFile = "res://systems/dialogue/smith_dialog_1.txt"


func _on_interact() -> void:
	var dialog = get_node("NPC Dialog")
	if not dialog.spoke:
		dialog.talk()
	else:
		shop.open(shop_data, global_position)
