extends CharacterBody2D

@export var HP: int = 1
@export var damage: int = 1

@onready var walk_sfx = $walk_sfx if has_node("walk_sfx") else null
@onready var attack_sfx = $attack_sfx if has_node("attack_sfx") else null
@onready var ouch_sfx = $ouch_sfx if has_node("ouch_sfx") else null
@onready var death_sfx = $death_sfx if has_node("death_sfx") else null
@onready var animation_player = $AnimationPlayer

var attacking = false
var stunned = false
var is_dead = false
var is_hit = false

const FLIP_THRESHOLD := 0.1
var last_velocity_x := 0.0

func _physics_process(_delta):
	if is_dead or is_hit or attacking or stunned:
		return
	move_and_slide()
	handle_animations()

func handle_animations():
	if velocity.length() > 0:
		if animation_player.has_animation("Walk"):
			animation_player.play("Walk")
		if walk_sfx and not walk_sfx.playing:
			walk_sfx.play()
	else:
		if animation_player.has_animation("Idle"):
			animation_player.play("Idle")

	if abs(velocity.x) > FLIP_THRESHOLD:
		if velocity.x < 0:
			$Sprite2D.scale.x = -1
		else:
			$Sprite2D.scale.x = 1

		last_velocity_x = velocity.x

func take_damage(dmg: int):
	if is_dead or is_hit:
		return

	is_hit = true  # Immediately mark hit to prevent overlap

	if stunned:
		dmg *= 2

	if ouch_sfx:
		ouch_sfx.play()

	# Apply damage immediately
	HP = max(HP - dmg, 0)

	# Handle death right away
	if HP == 0:
		kill()
		return

	# Play animation if still alive
	if animation_player.has_animation("OnHit"):
		await get_tree().process_frame
		animation_player.stop()
		animation_player.play("OnHit")
		await wait_for_animation("OnHit")

	is_hit = false  # Only clear after animation is finished


func stun():
	stunned = true
	attacking = false
	if animation_player.has_animation("stun"):
		await get_tree().process_frame
		animation_player.stop()
		animation_player.play("stun")
		await wait_for_animation("stun")
	stunned = false

func kill():
	if is_dead:
		return

	is_dead = true
	if animation_player.has_animation("Death"):
		animation_player.play("Death")
	if death_sfx:
		death_sfx.play()
	await wait_for_animation("Death")
	queue_free()

func attack():
	if attacking or is_dead or is_hit or stunned:
		return

	attacking = true
	if animation_player.has_animation("Attack"):
		animation_player.play("Attack")
	if attack_sfx:
		attack_sfx.play()
	await wait_for_animation("Attack")
	attacking = false

func wait_for_animation(anim_name: String) -> void:
	if animation_player.current_animation != anim_name:
		return

	while true:
		var finished_anim = await animation_player.animation_finished
		if finished_anim == anim_name or is_dead or is_hit:
			break
