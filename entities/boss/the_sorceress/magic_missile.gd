extends State

## Volley of homing missiles in an arc; more rounds in phase 2.

@export var cast_state: State
@export var projectile: PackedScene
@export var ray_cast: RayCast2D
@export var delay_between_rounds := 2.0
@export var phase2_rounds := 3

var boss  # TheSorceress (phase gate)

func _ready() -> void:
	boss = actor

func enter() -> void:
	boss.velocity = Vector2.ZERO
	var rounds = 1
	if boss.phase2:
		rounds = phase2_rounds

	if await boss.run_action_animation("Cast"):
		for i in rounds:
			_fire_volley()
			await get_tree().create_timer(delay_between_rounds).timeout
	transition_to(cast_state)

func _fire_volley() -> void:
	if projectile == null:
		return
	var offsets = [
		Vector2(-30, -70), Vector2(-15, -75), Vector2(0, -80), Vector2(15, -75), Vector2(30, -70),
	]
	for offset in offsets:
		var proj = projectile.instantiate()
		get_tree().current_scene.add_child(proj)
		proj.add_to_group("Enemies")
		proj.scale = Vector2(1.25, 1.25)
		proj.global_position = boss.global_position + offset
		proj.global_rotation = ray_cast.global_rotation