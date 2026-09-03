extends Node

# Post-R-20 constants: single state tick per physics frame; rates scale with
# the doubled velocity range so input responsiveness matches the old feel.
@export var acceleration: int = 1000
@export var max_speed: int = 100
@export var dash_speed: int = 200

var friction: float = max_speed * 8
var decay_factor: float = 800
var velocity: Vector2 = Vector2.ZERO
var mov_direction: Vector2 = Vector2.ZERO
var dash_direction: Vector2 = Vector2.ZERO

var is_dashing: bool = false
var can_dash: bool = true
var disabled: bool = false

@onready var dash_cooldown_timer = $"Dash Cooldown"
@onready var parent: CharacterBody2D = get_parent()
@onready var dash_sfx = $"../dash_sfx"

func set_disabled(value: bool):
	disabled = value

func move(delta):
	if disabled:
		parent.velocity = Vector2.ZERO
		return

	mov_direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	).normalized()

	if not is_dashing:
		if velocity.length() > max_speed:
			velocity = velocity.move_toward(mov_direction * max_speed, decay_factor * delta)
		else:
			if mov_direction != Vector2.ZERO:
				velocity = velocity.move_toward(mov_direction * max_speed, acceleration * delta)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	parent.velocity = velocity
	parent.move_and_slide()

func dash():
	if can_dash and mov_direction != Vector2.ZERO:
		can_dash = false
		is_dashing = true
		dash_direction = mov_direction

		velocity = dash_direction * dash_speed
		parent.velocity = velocity
		parent.move_and_slide()

		dash_sfx.play()
		await $"../PlayerAnimation".play_dash_animation(dash_direction)

		is_dashing = false
		dash_cooldown_timer.start()

func _on_dash_cooldown_timeout() -> void:
	can_dash = true
