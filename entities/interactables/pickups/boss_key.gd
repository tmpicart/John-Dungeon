extends PickupItem


func _ready() -> void:
	super()
	interaction_area.interacted.connect(_on_interact)


func _on_interact() -> void:
	Global.player.inventory.give_boss_key()
	queue_free()