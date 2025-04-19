extends Node2D

@onready var anim = $AnimationPlayer
@onready var shield = $"../PlayerCombat/Shield"
@onready var weapon = $"../PlayerCombat/Weapon"
@onready var player = get_parent()

var is_dashing = false

func update_animation(velocity: Vector2):
	if is_dashing:
		return  # Block animation updates while dashing

	if velocity.length() < 1:
		play_idle()
	else:
		play_walk()

func play_idle():
	var dir = get_mouse_facing()
	match dir:
		"right":
			shield.right()
			anim.play("Right")
		"left":
			shield.left()
			anim.play("Left")
		"down":
			shield.down()
			anim.play("Down")
		_:
			shield.up()
			anim.play("Up")

func play_walk():
	var dir = get_mouse_facing()
	match dir:
		"right":
			shield.right()
			anim.play("Right_Move")
		"left":
			shield.left()
			anim.play("Left_Move")
		"down":
			shield.down()
			anim.play("Down_Move")
		_:
			shield.up()
			anim.play("Up_Move")

func get_mouse_facing() -> String:
	var mouse_pos = get_global_mouse_position()
	var dir = mouse_pos - player.global_position
	var angle = dir.angle()

	if abs(angle) < PI / 4:
		return "right"
	elif abs(angle) > 3 * PI / 4:
		return "left"
	elif angle > 0:
		return "down"
	else:
		return "up"

func play_dash_animation(direction: Vector2) -> void:
	is_dashing = true
	
	shield.hide()
	weapon.hide()
	
	var anim_name = ""
	if direction.x > 0:
		anim_name = "Right_Dash"
	elif direction.x < 0:
		anim_name = "Left_Dash"
	elif direction.y > 0:
		anim_name = "Down_Dash"
	else:
		anim_name = "Up_Dash"

	anim.play(anim_name)
	await wait_for_animation(anim_name)

	shield.show()
	weapon.show()

	is_dashing = false

func play_hit():
	var hit_anim_player: AnimationPlayer = $"../PlayerCombat/OnHitPlayer"
	await get_tree().process_frame
	hit_anim_player.play("OnHit")
	await wait_for_animation("OnHit", hit_anim_player)
	#$"../PlayerCombat".is_hit = false

func play_death():
	weapon.hide()
	shield.hide()

	anim.play("Death_Roll")
	await wait_for_animation("Death_Roll")
	
	anim.play("Death")
	await wait_for_animation("Death")
	
func wait_for_animation(anim_name: String, anim_player: AnimationPlayer = anim) -> void:
	if not anim_player.has_animation(anim_name):
		return

	if anim_player.current_animation != anim_name:
		return  # Skip waiting if animation didn't start properly

	while true:
		var finished_anim = await anim_player.animation_finished
		if finished_anim == anim_name:
			break
