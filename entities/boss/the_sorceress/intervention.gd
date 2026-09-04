extends State

## Phase transition cutscene: warning glyph, falling light, then a rotating
## wave barrage before phase 2 arms.

@export var cast_state: State
@export var intervention_light: PackedScene
@export var glyph: PackedScene
@export var force_wave: PackedScene
@export var warning_duration := 3.0
@export var light_linger := 0.5
@export var barrage_rounds := 15
@export var delay_between_rounds := 0.3

var boss  # TheSorceress (phase2 flag, is_glide)

func _ready() -> void:
	boss = actor

func enter() -> void:
	boss.velocity = Vector2.ZERO
	boss.is_glide = true

	if glyph:
		var warning = glyph.instantiate()
		warning.scale = Vector2(4, 4)
		get_tree().current_scene.add_child(warning)
		warning.add_to_group("Enemies")
		warning.global_position = boss.global_position + Vector2(-5, -5)

	await get_tree().create_timer(warning_duration).timeout

	if intervention_light:
		var light = intervention_light.instantiate()
		get_tree().current_scene.add_child(light)
		light.add_to_group("Enemies")
		light.global_position = boss.global_position + Vector2(0, -40)

	boss.is_glide = false
	await get_tree().create_timer(light_linger).timeout

	await _fire_barrage()
	boss.phase2 = true
	transition_to(cast_state)

func _fire_barrage() -> void:
	if force_wave == null:
		return

	var rotation_offset := 0.0
	for i in barrage_rounds:
		for wave_index in 3:
			var proj = force_wave.instantiate()
			get_tree().current_scene.add_child(proj)
			proj.add_to_group("Enemies")
			proj.scale = Vector2(2, 2)
			proj.global_position = boss.global_position
			proj.global_rotation = deg_to_rad(rotation_offset + wave_index * 120.0)
		await get_tree().create_timer(delay_between_rounds).timeout
		rotation_offset += 45.0