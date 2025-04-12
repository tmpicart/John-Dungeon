extends Node2D

@export var speed := 85
@export var damage: int = 1

var reflected = false
var passed = false
var leniency_threshold = 15
var direction: Vector2
var player: CharacterBody2D
var track_resume_delay = .25
var turn_speed = 3

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
		# After reflection, keep moving in the current rotated direction
		direction = Vector2.RIGHT.rotated(rotation)

	global_position += direction * speed * delta

	if global_position.distance_to(player.global_position) < leniency_threshold:
		passed = true
		await get_tree().create_timer(track_resume_delay).timeout
		passed = false

	$AnimationPlayer.play("Track")

func reflect():
	print("REFLECTING")
	reflected = true
	
	var hitbox = $Hitbox
	var collider = $Collider
	
	# hitbox: belongs to layer 6, collides with layer 9
	hitbox.collision_layer = 1 << 5             # Layer 6
	hitbox.collision_mask = 1 << 8              # Collides with Layer 9
	
	# collider: collides with layers 2 and 3
	collider.collision_mask = (1 << 2)  # Collides with Layer 3
	
	var sprite = $Sprite2D  # Replace with your actual node path
	var shader_material := sprite.material as ShaderMaterial
	
	# Set flash color to #0076e3 (RGB: 0, 118, 227)
	shader_material.set_shader_parameter("flash_color", Color8(0, 118, 227))
	
	# Set flash value to max (fully show the flash color)
	shader_material.set_shader_parameter("flash_value", 0.60)
	
	$PointLight2D.color = Color.html("#0076e3")
	
	var mouseDirection: Vector2 = (get_global_mouse_position() - global_position).normalized()
	rotation = mouseDirection.angle()

func _on_collider_body_entered(body: Node2D) -> void:
	# If it's the player and the player is not blocking, or it's another object, destroy the missile
	if body != player or (body == player and not player.blocking):
		queue_free()
