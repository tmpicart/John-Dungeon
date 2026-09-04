extends State

## Rotating three-wave salvos aimed along the aim ray; more rounds in phase 2.

@export var cast_state: State
@export var projectile: PackedScene
@export var ray_cast: RayCast2D
@export var rounds := 5
@export var phase2_rounds := 7
@export var delay_between_rounds := 0.75
@export var spawn_offset := Vector2(0, -40)

var boss  # TheSorceress (phase gate)

func _ready() -> void:
	boss = actor

func enter() -> void:
	boss.velocity = Vector2.ZERO
	var round_count = rounds
	if boss.phase2:
		round_count = phase2_rounds

	if await boss.run_action_animation("Cast"):
		var rotation_offset := 0.0
		for i in round_count:
			_fire_salvo(rotation_offset)
			await get_tree().create_timer(delay_between_rounds).timeout
			rotation_offset += 45.0
	transition_to(cast_state)

func _fire_salvo(base_offset_degrees: float) -> void:
	if projectile == null:
		return
	for i in 3:
		var proj = projectile.instantiate()
		get_tree().current_scene.add_child(proj)
		proj.add_to_group("Enemies")
		proj.global_position = boss.global_position + spawn_offset
		proj.global_rotation = ray_cast.global_rotation + deg_to_rad(base_offset_degrees + i * 120.0)