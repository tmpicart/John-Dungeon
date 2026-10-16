extends "res://entities/enemies/base_enemy.gd"

## The red slime dies to any damage or parry and explodes on every death —
## pounce contact or damage; the Death track arms the explosion hitbox.

@export var pounce_state: EnemyPounce

func _ready() -> void:
	super()
	if pounce_state:
		pounce_state.pounce_contact.connect(explode)
	else:
		push_error("%s: pounce_state is not assigned" % get_path())

func explode():
	if is_dead:
		return

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


