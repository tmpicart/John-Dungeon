extends State

## Closes to melee range, swings, and (in phase 2) follows the swing with a
## three-wave spread.

@export var engage_state: State
@export var projectile: PackedScene
## Damped approach: velocity = raw direction * speed, easing in near the player.
@export var speed := 0.5
## Approach stop distance in px.
@export var attempt_attack_range := 50.0
@export var projectile_offset := Vector2(0, -40)

var player: CharacterBody2D
var boss  # TheSorceress (phase gate)

func _ready() -> void:
	boss = actor

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")

func physics_update(_delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		if player == null:
			return
	var direction = player.global_position - boss.global_position
	if direction.length() > attempt_attack_range:
		boss.velocity = direction * speed
		return

	if await boss.run_action_animation("Melee"):
		if boss.phase2 and projectile:
			_spawn_spread()
		transition_to(engage_state)
	# Interrupted or lethal flows route themselves; nothing to do here.

func _spawn_spread() -> void:
	var rotation_offset := 0.0
	for i in 3:
		var proj = projectile.instantiate()
		get_tree().current_scene.add_child(proj)
		proj.add_to_group("Enemies")
		proj.global_position = boss.global_position + projectile_offset
		proj.global_rotation = boss.global_rotation + deg_to_rad(rotation_offset)
		rotation_offset += 120.0