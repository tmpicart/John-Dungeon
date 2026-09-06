extends Node2D

## Inanimate shop owner (shrine/altar): no dialogue, straight to the shop.

@export var shop_data: ShopData

@onready var interaction_area: Interactable = $InteractionArea
@onready var shop = $Shop


func _ready() -> void:
	interaction_area.interacted.connect(_on_interact)


func _on_interact() -> void:
	shop.open(shop_data, global_position)
