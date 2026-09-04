extends "res://entities/enemies/base_enemy.gd"

func _physics_process(_delta):
	if is_dead or is_hit:
		return

	move_and_slide()  # Godot's move_and_slide already accounts for delta internally

	if get_slide_collision_count() > 0 and attacking:
		explode()

	handle_animations()

func explode():
	is_dead = true
	velocity = Vector2.ZERO
	$explode_sfx.play()
	$AnimationPlayer.play("Death")
	await $AnimationPlayer.animation_finished
	queue_free()

func stun() -> void:
	kill()

func take_damage(_dmg: int, _from_position: Vector2 = Vector2.INF) -> void:
	kill()

