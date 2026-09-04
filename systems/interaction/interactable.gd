extends Area2D
class_name Interactable

## Proximity interaction surface. Registers with the InteractionManager while
## the player overlaps it and `enabled` is true; the manager prompts for and
## triggers the nearest one. With `auto_pickup` the `interacted` signal fires
## on contact itself (no prompt, no keypress).

signal interacted

@export var prompt: String = ""
@export var enabled: bool = true:
	set(value):
		enabled = value
		_refresh_registration()
@export var one_shot: bool = false
@export var auto_pickup: bool = false

var _in_range := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func try_interact() -> bool:
	if not enabled:
		return false
	if one_shot:
		enabled = false
	interacted.emit()
	return true


func _refresh_registration() -> void:
	if not enabled or not _in_range:
		InteractionManager.unregister_area(self)
	elif auto_pickup:
		# Re-check on enable: an item may settle on a standing player after
		# body_entered already fired while collection was gated.
		try_interact()
	else:
		InteractionManager.register_area(self)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	_in_range = true
	if auto_pickup:
		try_interact()
	else:
		_refresh_registration()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	_in_range = false
	_refresh_registration()


func _exit_tree() -> void:
	InteractionManager.unregister_area(self)
