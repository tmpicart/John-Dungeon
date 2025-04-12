extends Sprite2D
class_name Shield

# Variable to track if blocking is allowed
var can_block: bool = true

# Play animations based on shield direction
func left():
	$AnimationPlayer.play("Left")

func right():
	$AnimationPlayer.play("Right")

func up():
	$AnimationPlayer.play("Backward")

func down():
	$AnimationPlayer.play("Forward")

# Handle the blocking action
func block():
	if can_block:
		$block_sfx.play()  # Play block sound effect
		$BlockPlayer.play("Block")  # Play block animation
		
		# Get the block duration based on the animation's length
		var block_duration = $BlockPlayer.current_animation_length
		
		# Wait for the block animation to finish
		await get_tree().create_timer(block_duration).timeout
		
		can_block = false  # Disable blocking
		$CooldownTimer.start()  # Start the cooldown timer

# Reset the blocking state after cooldown
func _on_cooldown_timer_timeout() -> void:
	can_block = true
