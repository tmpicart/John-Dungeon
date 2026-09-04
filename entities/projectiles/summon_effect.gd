extends Sprite2D

## Spawn flourish: frees itself when the arise animation completes.

func _ready() -> void:
	$AnimationPlayer.play("Arise")
	await $AnimationPlayer.animation_finished
	queue_free()