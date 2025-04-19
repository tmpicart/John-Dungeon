extends CharacterBody2D

@export var HP: int = 1
@export var damage: int = 1

@onready var walk_sfx = $walk_sfx if has_node("walk_sfx") else null
@onready var attack_sfx = $attack_sfx if has_node("attack_sfx") else null
@onready var ouch_sfx = $ouch_sfx if has_node("ouch_sfx") else null
@onready var death_sfx = $death_sfx if has_node("death_sfx") else null

var attacking = false
var stunned = false
var is_dead = false
var is_hit = false

const FLIP_THRESHOLD := 0.1  # Minimum X velocity for flipping
var last_velocity_x := 0.0    # Tracks the last X velocity to detect direction change

func _physics_process(_delta):
	if is_dead or is_hit or attacking or stunned:
		return
	move_and_slide()
	handle_animations()

func handle_animations():
	if velocity.length() > 0:
		if $AnimationPlayer.has_animation("Walk"):
			$AnimationPlayer.play("Walk")
		if walk_sfx and not walk_sfx.playing:
			walk_sfx.play()
	else:
		if $AnimationPlayer.has_animation("Idle"):
			$AnimationPlayer.play("Idle")

	if abs(velocity.x) > FLIP_THRESHOLD:
		if velocity.x < 0:
			$Sprite2D.scale.x = -1
		else:
			$Sprite2D.scale.x = 1

		last_velocity_x = velocity.x

func take_damage(dmg: int):
	if is_dead or is_hit:
		return

	if stunned:
		dmg *= 2

	is_hit = true
	if ouch_sfx:
		ouch_sfx.play()

	if HP - dmg <= 0:
		kill()
	else:
		# Hard cancel any current animation and ensure a clean OnHit
		if $AnimationPlayer.has_animation("OnHit"):
			$AnimationPlayer.stop()
			$AnimationPlayer.play("OnHit")
			await wait_for_animation("OnHit")
			is_hit = false
			
	HP = max(HP - dmg, 0)

func stun():
	stunned = true
	attacking = false
	if $AnimationPlayer.has_animation("stun"):
		$AnimationPlayer.stop()
		$AnimationPlayer.play("stun")
		await wait_for_animation("stun")
	stunned = false

func kill():
	if is_dead:
		return

	is_dead = true
	if $AnimationPlayer.has_animation("Death"):
		$AnimationPlayer.play("Death")
	if death_sfx:
		death_sfx.play()
	await wait_for_animation("Death")
	queue_free()

func attack():
	if attacking or is_dead or is_hit or stunned:
		return

	attacking = true
	if $AnimationPlayer.has_animation("Attack"):
		$AnimationPlayer.play("Attack")
	if attack_sfx:
		attack_sfx.play()
	await wait_for_animation("Attack")
	attacking = false

# ✅ Helper function
func wait_for_animation(anim_name: String) -> void:
	if $AnimationPlayer.current_animation != anim_name:
		return  # Skip waiting if animation didn't start properly

	while true:
		var finished_anim = await $AnimationPlayer.animation_finished
		if finished_anim == anim_name or is_dead or is_hit:
			break
