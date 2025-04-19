extends Node

@export var acceleration: int = 600
@export var max_speed: int = 100
@export var dash_speed: float = 175
@export var deceleration := 150
const FRICTION: float = 200

@onready var dash_cooldown_timer = $"Dash Cooldown"
@onready var parent: CharacterBody2D = get_parent()

var velocity: Vector2 = Vector2.ZERO
var mov_direction: Vector2 = Vector2.ZERO
var dash_direction: Vector2 = Vector2.ZERO

var is_dashing: bool = false
var can_dash: bool = true
var disabled: bool = false
var was_dashing: bool = false

func set_disabled(value: bool):
	disabled = value
	velocity = Vector2.ZERO

func move(delta):
	if disabled:
		parent.velocity = Vector2.ZERO
		return

	if not parent.talking and not is_dashing:
		mov_direction = Vector2(
			Input.get_action_strength("right") - Input.get_action_strength("left"),
			Input.get_action_strength("down") - Input.get_action_strength("up")
		).normalized()

	if is_dashing:
		# Lock the player into the initial dash direction
		velocity = dash_direction * dash_speed
		was_dashing = true
	else:
		if mov_direction != Vector2.ZERO:
			velocity = velocity.move_toward(mov_direction * max_speed, acceleration * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

		if was_dashing:
			if velocity.length() > max_speed:
				velocity = velocity.move_toward(velocity.normalized() * max_speed, deceleration * delta)
			else:
				was_dashing = false

	parent.velocity = velocity
	parent.move_and_slide()

func dash():
	if can_dash and mov_direction != Vector2.ZERO:
		can_dash = false
		is_dashing = true
		dash_direction = mov_direction # Lock dash direction
	
		$"../dash_sfx".play()
		await $"../PlayerAnimation".play_dash_animation(dash_direction)

		is_dashing = false
		dash_cooldown_timer.start()

func _on_dash_cooldown_timeout() -> void:
	can_dash = true
