extends Node2D

@export var speed := 85
@export var damage: int = 1
@export var leniency_threshold = 25
@export var track_resume_delay = .5
@export var turn_speed = 3
## Launches the reflect this many degrees wide of the aim line (random side)
## so the homing visibly arcs onto the lock.
@export var reflect_arc_deg := 75.0

var reflected = false
var passed = false
var direction: Vector2
var player: CharacterBody2D
var target: Node2D
var launch_angle := 0.0

func _ready():
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta):
	if not reflected:
		if not passed:
			var target_direction = (player.global_position - global_position).normalized()
			var target_angle = target_direction.angle()

			# Smooth rotation toward target angle
			rotation = lerp_angle(rotation, target_angle, delta * turn_speed)
			direction = Vector2.RIGHT.rotated(rotation)
	else:
		# After reflection the chase never gives up: targetless missiles keep
		# polling the player's aim (this is the physics step) and settle onto
		# the aim line between locks; only contact ends them.
		if not is_instance_valid(target):
			target = player.combat.get_aim_target()
		var desired_angle := launch_angle
		if target != null:
			desired_angle = (target.global_position - global_position).normalized().angle()
		rotation = lerp_angle(rotation, desired_angle, delta * turn_speed)
		direction = Vector2.RIGHT.rotated(rotation)

	global_position += direction * speed * delta

	var distance_to_player = global_position.distance_to(player.global_position)
	if not passed and not reflected and distance_to_player < leniency_threshold:
		passed = true
		_resume_tracking_later()

	$AnimationPlayer.play("Track")

## Pauses homing briefly after passing the player; one timer per pass instead
## of one per frame.
func _resume_tracking_later() -> void:
	await get_tree().create_timer(track_resume_delay).timeout
	passed = false

func reflect():
	reflected = true

	# The single surface now pairs with enemy hurtboxes and self-frees on
	# enemy bodies and walls — reflected missiles no longer pierce.
	var hitbox = $Hitbox
	hitbox.collision_layer = 1 << 5             # Layer 6 (PlayerHitbox)
	hitbox.collision_mask = (1 << 1) | (1 << 2) # Collides with Layers 2 and 3

	var sprite = $Sprite2D  # Replace with your actual node path
	var shader_material := sprite.material as ShaderMaterial

	# Set flash color to #0076e3 (RGB: 0, 118, 227)
	shader_material.set_shader_parameter("flash_color", Color8(0, 118, 227))

	# Set flash value to max (fully show the flash color)
	shader_material.set_shader_parameter("flash_value", 0.60)

	$PointLight2D.color = Color.html("#0076e3")

	var mouse_direction: Vector2 = (get_global_mouse_position() - global_position).normalized()
	launch_angle = mouse_direction.angle()
	rotation = launch_angle + deg_to_rad(reflect_arc_deg) * (1.0 if randf() < 0.5 else -1.0)

func _on_hitbox_body_entered(body: Node2D) -> void:
	# If it's the player and the player is not blocking, or it's another object, destroy the missile
	if body != player or (body == player and not player.combat.blocking):
		queue_free()
