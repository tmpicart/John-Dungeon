extends Node2D
class_name Shield

@onready var blockplayer = $BlockPlayer
@onready var sound = $block_sfx
@onready var cooldown_timer = $CooldownTimer
@onready var sprite = $Sprite2D

var Direction = Global.Direction

var can_block: bool = true
var enabled: bool = true:
	set(value):
		enabled = value
		visible = value

var current_direction: int = Direction.RIGHT
var is_foreground: bool = true

# Set the direction of the shield and its appearance (frame and z-index)
func set_direction(direction: int, foreground: bool = true) -> void:
	if not enabled:
		return

	current_direction = direction
	is_foreground = foreground

	# Update the shield's sprite frame based on direction
	match direction:
		Direction.LEFT:
			sprite.frame = 1  # Shield facing left
		Direction.RIGHT:
			sprite.frame = 2  # Shield facing right
		Direction.UP:
			sprite.frame = 3  # Shield facing up (away from camera)
		Direction.DOWN:
			sprite.frame = 0  # Shield facing down (toward the camera)

	# Update the z-index based on whether it's in the foreground or background
	sprite.z_index = Global.player.z_index + 1 if is_foreground else Global.player.z_index - 1

# Block function to handle shield's blocking action
func block() -> void:
	if not can_block or not enabled:
		return

	# Play block sound and animation
	sound.play()
	blockplayer.play("Block")

	blockplayer.play("Block")
	await blockplayer.animation_finished

	# Start cooldown and disable blocking until cooldown is done
	can_block = false
	cooldown_timer.start()

# Cooldown reset when cooldown timer finishes
func _on_cooldown_timer_timeout() -> void:
	can_block = true
