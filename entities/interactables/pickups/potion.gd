extends PickupItem


func _ready() -> void:
	super()
	interaction_area.interacted.connect(_on_interact)


func _on_interact() -> void:
	Global.player.inventory.add_potion(1)
	queue_free()