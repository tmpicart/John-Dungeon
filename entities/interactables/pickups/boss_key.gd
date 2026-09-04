extends PickupItem

const MESSAGE_TIME := 1.0

@onready var message: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
	interaction_area.interacted.connect(_on_interact)
	message.hide()


func _on_interact() -> void:
	Global.has_boss_key = true
	sprite.hide()
	await get_tree().create_timer(MESSAGE_TIME).timeout
	message.show()
	await get_tree().create_timer(MESSAGE_TIME).timeout
	interaction_area.queue_free()