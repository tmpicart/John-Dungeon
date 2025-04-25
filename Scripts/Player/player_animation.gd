extends Node2D

@onready var anim = $AnimationPlayer
@onready var onHitPlayer = $"../PlayerCombat/OnHitPlayer"
@onready var shield = $"../PlayerCombat/Shield"
@onready var weapon = $"../PlayerCombat/Weapon"
@onready var player = get_parent()

var is_dashing := false
var is_attacking := false
var is_blocking := false
var Direction = Global.Direction

func update_animation(velocity: Vector2):
	if is_dashing or is_attacking or is_blocking:
		return

	var dir = get_mouse_facing_enum()
	if velocity.length() < 1:
		play_animation("Idle", dir)
	else:
		play_animation("Move", dir)

func play_animation(action: String, dir: int):
	anim.play("%s_%s" % [get_direction_string(dir), action])

func play_attack():
	is_attacking = true
	weapon.show()

	var dir = get_mouse_facing_enum()
	update_equipment_layers(dir)
	play_animation("Attack", dir)

	await wait_for_animation(anim.current_animation)
	weapon.hide()
	is_attacking = false

func play_block():
	is_blocking = true

	var dir = get_mouse_facing_enum()
	update_equipment_layers(dir)
	play_animation("Block", dir)

	await shield.block()
	is_blocking = false

func play_dash_animation(direction: Vector2) -> void:
	is_dashing = true
	var anim_name = "%s_Dash" % get_direction_string_from_vector(direction)
	anim.play(anim_name)
	await wait_for_animation(anim_name)
	is_dashing = false

func play_hit():
	onHitPlayer.play("OnHit")
	await wait_for_animation("OnHit", onHitPlayer)

func play_death():
	weapon.hide()
	shield.hide()
	
	anim.play("Death_Roll")
	await wait_for_animation("Death_Roll")
	
	anim.play("Death")
	await wait_for_animation("Death")

func update_equipment_layers(dir: int):
	var weapon_foreground: bool

	if dir == Direction.DOWN or dir == Direction.LEFT:
		weapon_foreground = true
	else:
		weapon_foreground = false

	weapon.set_foreground(weapon_foreground)
	shield.set_direction(dir, weapon_foreground)

func get_direction_string(dir: int) -> String:
	var directions = ["Right", "Left", "Down", "Up"]
	if dir >= 0 and dir < directions.size():
		return directions[dir]
	return "Right"  # Default fallback


func get_mouse_facing_enum() -> int:
	var delta = get_global_mouse_position() - player.global_position
	var angle = delta.angle()

	if angle >= -PI/4 and angle < PI/4:
		return Direction.RIGHT
	elif angle >= PI/4 and angle < 3 * PI/4:
		return Direction.DOWN
	elif angle >= -3 * PI/4 and angle < -PI/4:
		return Direction.UP
	else:
		return Direction.LEFT


func get_direction_string_from_vector(vec: Vector2) -> String:
	if abs(vec.x) > abs(vec.y):
		return "Right" if vec.x > 0 else "Left"
	else:
		return "Down" if vec.y > 0 else "Up"

func wait_for_animation(anim_name: String, anim_player: AnimationPlayer = anim) -> void:
	if not anim_player.has_animation(anim_name) or anim_player.current_animation != anim_name:
		return

	while true:
		if await anim_player.animation_finished == anim_name:
			break
