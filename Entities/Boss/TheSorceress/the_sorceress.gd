extends CharacterBody2D

@export var HP:int = 150
@export var transition_hp:int = 75
@export var damage:int = 1
@export var phase2 = false

var attacking = false
var is_dead = false
var is_hit = false
var is_glide = false
var is_active = false


func _physics_process(_delta):
	if is_dead or is_hit or attacking:
		return
		
	move_and_slide()
	
	if is_glide:
		$AnimationPlayer.play("Move")
	else:
		if velocity.length() > 0:
			$AnimationPlayer.play("Idle")

func perform_action(animation_name: String):
	if attacking or is_dead:
		return
	
	attacking = true
	$AnimationPlayer.stop()
	$AnimationPlayer.play(animation_name)
	var attack_duration = $AnimationPlayer.current_animation_length + .01
	await get_tree().create_timer(attack_duration).timeout
	attacking = false

func melee():
	perform_action("Melee")
	
func cast():
	perform_action("Cast")

func big_cast():
	perform_action("Cast2")

func beam():
	perform_action("Beam")
	
func move():
	perform_action("Move")
	
func take_damage(dmg: int):
	if is_dead or is_hit:
		return
		
	is_hit = true
	$OnHitPlayer.play("OnHit")
	if not is_active:
		is_active = true
		$"State Control/Idle".activate()
	set_hp(HP - dmg)
	is_hit = false

func set_hp(newHP: int):
	if newHP <= 0:
		HP = 0
		kill()
	else:
		HP = newHP

func kill():
	if is_dead:
		return
	
	is_dead = true
	$AudioStreamPlayer2D.play()
	$AnimationPlayer.play("Death")
	var death_duration = $AnimationPlayer.current_animation_length
	await get_tree().create_timer(death_duration).timeout
	queue_free() # This will delete the node after the animation completes
