extends PickupItem

@onready var coin_sfx: AudioStreamPlayer2D = $coin_sfx
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	super()
	interaction_area.interacted.connect(_on_interact)
	sprite.play("default")


func _on_interact() -> void:
	coin_sfx.play()
	sprite.hide()
	Global.player.inventory.add_coin(1)
	await coin_sfx.finished
	queue_free()