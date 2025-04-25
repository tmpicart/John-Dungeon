extends Node

@export var acceleration: int = 200
@export var max_speed: int = 55
@export var dash_speed_mult: float = 1.75

@onready var dash_cooldown_timer = $"Dash Cooldown"
@onready var parent: CharacterBody2D = get_parent()
@onready var dash_sfx = $"../dash_sfx"

var friction: float = max_speed * .8
var velocity: Vector2 = Vector2.ZERO
var mov_direction: Vector2 = Vector2.ZERO
var dash_direction: Vector2 = Vector2.ZERO

var is_dashing: bool = false
var can_dash: bool = true
var disabled: bool = false

func set_disabled(value: bool):
	disabled = value
	velocity = Vector2.ZERO

func move(delta):
	if disabled:
		parent.velocity = Vector2.ZERO
		return

	mov_direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	).normalized()

	if is_dashing:
		velocity = dash_direction * dash_speed_mult * max_speed
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
	
		dash_sfx.play()
		await $"../PlayerAnimation".play_dash_animation(dash_direction)

		is_dashing = false
		dash_cooldown_timer.start()

func _on_dash_cooldown_timeout() -> void:
	can_dash = true
