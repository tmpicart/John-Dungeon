extends "res://Scripts/Enemies/BaseEnemy.gd"

func _physics_process(_delta):
	if is_dead or is_hit:
		return
	
	move_and_slide()
	
	if get_slide_collision_count() > 0 and attacking:
		explode()
		
	handle_animations()

func explode():
	remove_from_group("Enemies")
	velocity = Vector2.ZERO
	$AnimationPlayer.play("Explode")
	attack_sfx.play() # Uses attack sound for explosion if desired
	await wait_for_animation()
	queue_free()

func kill():
	explode() # Red slime always "kills" itself by exploding
