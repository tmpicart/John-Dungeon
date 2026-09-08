extends Node2D

## Smoke-test stub: minimal player surface (progress holder + freeze hook)
## so modal flows can run headless without the full character scene.

var progress: Node
var locked := false


func set_input_locked(value: bool) -> void:
	locked = value