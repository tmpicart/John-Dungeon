extends CharacterBody2D

@export var HP: int = 1
@export var damage: int = 1

@onready var walk_sfx = $walk_sfx
@onready var attack_sfx = $attack_sfx
@onready var ouch_sfx = $ouch_sfx
@onready var death_sfx = $death_sfx

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
		$AnimationPlayer.play("Walk")
		if not walk_sfx.playing:
			walk_sfx.play()
	else:
		$AnimationPlayer.play("Idle")
	
	$Sprite2D.set_scale(Vector2(1, 1) if velocity.x >= 0 else Vector2(-1, 1))

func take_damage(dmg: int):
	if is_dead or is_hit:
		return

	is_hit = true
	ouch_sfx.play()
	5
	if HP-dmg <= 0:
		kill()
	else:
		$AnimationPlayer.play("OnHit")
		await wait_for_animation()
		HP = max(HP - dmg, 0)
		is_hit = false

func kill():
	if is_dead:
		return

	is_dead = true
	$AnimationPlayer.play("Death")
	death_sfx.play()
	await wait_for_animation()
	queue_free()

func attack():
	if attacking or is_dead or is_hit:
		return

	attacking = true
	$AnimationPlayer.play("Attack")
	attack_sfx.play()
	await wait_for_animation()
	attacking = false

func wait_for_animation():
	await get_tree().create_timer($AnimationPlayer.current_animation_length).timeout
