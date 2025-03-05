extends CharacterBody2D

@export var HP:int = 8

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
	if attacking or is_dead:
		return
		
	attacking = true
	$AnimationPlayer.play("Attack")
	var attack_duration = $AnimationPlayer.current_animation_length +.1
	await get_tree().create_timer(attack_duration).timeout
	attacking = false

func summon():
	if attacking or is_dead:
		return
			
	attacking = true
	$AnimationPlayer.play("Summon")
	var attack_duration = $AnimationPlayer.current_animation_length +.1
	await get_tree().create_timer(attack_duration).timeout
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
