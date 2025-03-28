extends CharacterBody2D

@export var HP: int = 1
@export var damage: int = 1

@onready var walk_sfx = $walk_sfx if has_node("walk_sfx") else null
@onready var attack_sfx = $attack_sfx if has_node("attack_sfx") else null
@onready var ouch_sfx = $ouch_sfx if has_node("ouch_sfx") else null
@onready var death_sfx = $death_sfx if has_node("death_sfx") else null

var attacking = false
var is_dead = false
var is_hit = false

func _physics_process(_delta):
	if is_dead or is_hit or attacking:
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
	
	$Sprite2D.flip_h = velocity.x < 0

func take_damage(dmg: int):
	if is_dead or is_hit:
		return

	is_hit = true
	if ouch_sfx:
		ouch_sfx.play()
	if HP - dmg <= 0:
		kill()
	else:
		if $AnimationPlayer.has_animation("OnHit"):
			$AnimationPlayer.play("OnHit")
		await wait_for_animation()
		HP = max(HP - dmg, 0)
		is_hit = false

func kill():
	if is_dead:
		return

	is_dead = true
	if $AnimationPlayer.has_animation("Death"):
		$AnimationPlayer.play("Death")
	if death_sfx:
		death_sfx.play()
	await wait_for_animation()
	queue_free()

func attack():
	if attacking or is_dead or is_hit:
		return

	attacking = true
	if $AnimationPlayer.has_animation("Attack"):
		$AnimationPlayer.play("Attack")
	if attack_sfx:
		attack_sfx.play()
	await wait_for_animation()
	attacking = false

func wait_for_animation():
	await get_tree().create_timer($AnimationPlayer.current_animation_length).timeout
