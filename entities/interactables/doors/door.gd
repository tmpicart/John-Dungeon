extends Node2D

## Unified door. `lock_type` selects the lock behavior; the "open" animation
## drives the flow and its Call Method track calls `_set_passable()` to drop
## the blocking collision at the authored frame.

enum LockType { NONE, KEY, BOSS_KEY }

const MESSAGE_TIME := 1.0

@export var lock_type: LockType = LockType.NONE

var _open := false

@onready var interaction_area: Interactable = $InteractionArea
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var static_collision: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var warning: Label = get_node_or_null("Label")
@onready var open_sfx: AudioStreamPlayer2D = get_node_or_null("AudioStreamPlayer2D")


func _ready() -> void:
	interaction_area.interacted.connect(_on_interact)
	if warning:
		warning.hide()


## Call Method track target in the "open" animation.
func _set_passable() -> void:
	# Fires during animation processing, possibly inside a physics flush - defer the change.
	static_collision.set_deferred("disabled", true)
	interaction_area.enabled = false


func _on_interact() -> void:
	if _open:
		return
	match lock_type:
		LockType.KEY:
			if not Global.player.inventory.consume_key():
				_show_warning()
				return
		LockType.BOSS_KEY:
			if not Global.player.inventory.use_boss_key():
				_show_warning()
				return
	_open = true
	animation.play("open")
	if open_sfx:
		open_sfx.play()


func _show_warning() -> void:
	if warning == null:
		return
	warning.show()
	await get_tree().create_timer(MESSAGE_TIME).timeout
	warning.hide()