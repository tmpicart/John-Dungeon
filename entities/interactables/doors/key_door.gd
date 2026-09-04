extends Node2D

const LOCK_OPEN_DELAY := 0.5
const MESSAGE_TIME := 1.0

var open := false

@onready var interaction_area: Interactable = $InteractionArea
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var warning: Label = $Label
@onready var open_sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var static_collision: CollisionShape2D = $StaticBody2D/CollisionShape2D


func _ready() -> void:
	interaction_area.interacted.connect(_on_interact)
	warning.hide()


func _on_interact() -> void:
	if open:
		return
	if not Global.player.inventory.consume_key():
		warning.show()
		await get_tree().create_timer(MESSAGE_TIME).timeout
		warning.hide()
		return
	open = true
	animation.play("open")
	open_sfx.play()
	await get_tree().create_timer(LOCK_OPEN_DELAY).timeout
	static_collision.disabled = true
	interaction_area.enabled = false