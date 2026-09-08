extends Node2D

## Dialogue NPC: opens its DialogueData on interact; owners with a shop also
## open it when a dialogue finishes normally (Esc/walk-away aborts skip it).

@export var dialogue: DialogueData
@export var shop_data: ShopData

@onready var interaction_area: Interactable = $InteractionArea
@onready var dialog: CanvasLayer = $"NPC Dialog"
@onready var shop: CanvasLayer = get_node_or_null("Shop")


func _ready() -> void:
	interaction_area.interacted.connect(_on_interact)
	if shop != null and shop_data != null:
		dialog.finished.connect(_on_dialogue_finished)


func _on_interact() -> void:
	dialog.open(dialogue, global_position)


func _on_dialogue_finished() -> void:
	shop.open(shop_data, global_position)