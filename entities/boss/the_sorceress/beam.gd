extends State

## Tracked beam: charges, locks on, and drains while the duration timer runs,
## then hides through recovery before handing back to Cast.

@export var beam_cast: RayCast2D
@export var beam_line: Line2D
@export var beam_particles: GPUParticles2D
@export var cast_state: State
@export var rotation_speed := 6.0
@export var beam_damage := 2
@export var beam_recovery := 5.0

var player  # Player root (combat subsystem access)
var boss  # velocity + action flow
var sprite: Sprite2D
var target_rotation := 0.0
var current_rotation := 0.0

@onready var charge_sfx: AudioStreamPlayer = $charge_sfx
@onready var beam_duration: Timer = $beam_duration

func _ready() -> void:
	boss = actor
	sprite = boss.get_node("Sprite2D")
	beam_duration.timeout.connect(_on_beam_duration_timeout)

func enter() -> void:
	for body in get_tree().get_nodes_in_group("Enemies"):
		if body is CharacterBody2D:
			beam_cast.add_exception(body)

	player = get_tree().get_first_node_in_group("Player")
	boss.velocity = Vector2.ZERO
	charge_sfx.play()
	await get_tree().process_frame
	boss.run_action_animation("Beam")
	beam_cast.enabled = true
	beam_line.visible = true
	_appear()
	beam_duration.start()

func physics_update(delta: float) -> void:
	if not is_instance_valid(player):
		return

	# Staff-side origin: mirrors with her sprite flip (x only).
	var offset := Vector2(15.0 * signf(sprite.scale.x), -80.0)
	beam_cast.position = offset
	var raycast_start = boss.global_position + offset
	var direction = (player.global_position - raycast_start).normalized()
	target_rotation = direction.angle()
	var weight = rotation_speed * delta
	current_rotation = lerp_angle(current_rotation, target_rotation, weight)
	beam_cast.global_rotation = current_rotation
	_update_laser()

func _update_laser() -> void:
	beam_particles.emitting = beam_cast.is_colliding()
	if beam_cast.is_colliding():
		var collision_point = beam_cast.get_collision_point()
		beam_line.points = [Vector2.ZERO, beam_cast.to_local(collision_point)]
		beam_particles.global_rotation = beam_cast.get_collision_normal().angle()
		beam_particles.position = collision_point
		if beam_cast.get_collider() == player:
			player.combat.take_damage(beam_damage)
	else:
		# Nothing in reach: draw to the ray's end instead of stale points.
		beam_line.points = [Vector2.ZERO, beam_cast.target_position]

func _on_beam_duration_timeout() -> void:
	beam_cast.enabled = false
	_disappear()
	# The recovery window is her vulnerable punish window.
	boss.begin_exposure(beam_recovery)
	await get_tree().create_timer(beam_recovery).timeout
	beam_line.visible = false
	transition_to(cast_state)

func _appear() -> void:
	var tween = create_tween()
	tween.tween_property(beam_line, "width", 10.0, 2.0)

func _disappear() -> void:
	var tween = create_tween()
	tween.tween_property(beam_line, "width", 0.0, 1.0)