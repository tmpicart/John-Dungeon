extends Sprite2D
class_name Shield

var can_block: bool = true

func Left():
	$AnimationPlayer.play("Left")

func Right():
	$AnimationPlayer.play("Right")

func Up():
	$AnimationPlayer.play("Backward")

func Down():
	$AnimationPlayer.play("Forward")

func Block():
	if can_block:
		$block_sfx.play()
		$BlockPlayer.play("Block")
		var block_duration = $BlockPlayer.current_animation_length
		await get_tree().create_timer(block_duration).timeout
		can_block = false
		$CooldownTimer.start()

func _on_cooldown_timer_timeout() -> void:
	can_block = true
