extends CharacterBody2D

@export var HP:int = 3
@onready var bow = $AudioStreamPlayer

var attacking = false
var is_dead = false
var is_hit = false

func _physics_process(_delta):
	
	if is_dead || is_hit || attacking:
		return
		
	move_and_slide()
		
	if velocity.length() > 0:
		$AnimationPlayer.play("Walk")
	else:
		$AnimationPlayer.play("Idle")
		
	if velocity.x >= 0:
		$Sprite2D.set_scale(Vector2(1,1))
	else:
		flip()

func flip():
	if is_dead:
		return
	$Sprite2D.set_scale(Vector2(-1,1))

func attack():

	if not is_hit and not attacking and not is_dead:
		attacking = true
		$AnimationPlayer.play("Attack")
		var attack_duration = $AnimationPlayer.current_animation_length + .1
		await get_tree().create_timer(attack_duration).timeout
		bow.play()
		attacking = false
	
func take_damage(dmg:int):
	if is_dead:
		return
		
	is_hit = true
	$AnimationPlayer.play("OnHit")
	var stun_duration = $AnimationPlayer.current_animation_length
	await get_tree().create_timer(stun_duration).timeout
	set_hp(HP - dmg)
	is_hit = false
	
	print("EXIT DMG")
func set_hp(newHP):
	if newHP <= 0:
		HP = 0
		kill()
	else:
		HP = newHP

func kill():
	if is_dead:
		return

	is_dead = true
	$AnimationPlayer.play("Death")
	var death_duration = $AnimationPlayer.current_animation_length
	await get_tree().create_timer(death_duration).timeout
	queue_free() # This will delete the node after the animation completes
