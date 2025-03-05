extends CharacterBody2D

@export var HP:int = 2
@export var damage:int = 2

var is_hit = false
var attacking = false

func _physics_process(_delta):
	
	if is_hit:
		return
		
	move_and_slide()
	
	if get_slide_collision_count() > 0 and attacking:
		explode()
		
	if velocity.length() > 0:
		$AnimationPlayer.play("Bounce")
		
	if velocity.x > 0:
		$Sprite2D.set_scale(Vector2(1,1))
	else:
		$Sprite2D.set_scale(Vector2(-1,1))

func explode():
	remove_from_group("Enemies")
	velocity = Vector2.ZERO
	$AnimationPlayer.play("Explode")
	var attack_duration = $AnimationPlayer.current_animation_length
	await get_tree().create_timer(attack_duration).timeout
	queue_free()

func take_damage(dmg:int):
	if is_hit:
		return
	
	is_hit = true
	$AnimationPlayer.play("OnHit")
	var stun_duration = $AnimationPlayer.current_animation_length
	await get_tree().create_timer(stun_duration).timeout
	set_hp(HP - dmg)
	is_hit = false
	
func set_hp(newHP):
	if newHP <= 0:
		HP = 0
		kill()
	else:
		HP = newHP

func kill():
	explode()
