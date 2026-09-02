extends Sprite2D

func _ready():
	$AnimationPlayer.play("Arise")
	var duration = $AnimationPlayer.current_animation_length +.1
	await get_tree().create_timer(duration).timeout
	queue_free()
