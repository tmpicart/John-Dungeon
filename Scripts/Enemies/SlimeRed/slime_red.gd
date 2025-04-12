extends "res://Scripts/Enemies/BaseEnemy.gd"

func _physics_process(_delta):
	if is_dead or is_hit:
		return
	
	move_and_slide()  # Godot's move_and_slide already accounts for delta internally
	
	if get_slide_collision_count() > 0 and attacking:
		explode()
		
	handle_animations()

func explode():
	is_dead = true
	# Start explosion logic
	remove_from_group("Enemies")
	velocity = Vector2.ZERO
	$explode_sfx.play()
	$AnimationPlayer.play("Death")  # Uses attack sound for explosion if desired

	# Wait for the animation to finish before continuing
	await wait_for_animation()  # This waits for the animation to finish before calling queue_free
	queue_free()  # Free the object after the animation

func stun():
	kill()
	
func take_damage(_num):
	kill()
