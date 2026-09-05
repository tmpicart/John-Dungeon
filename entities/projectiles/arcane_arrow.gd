extends Node2D

@export var speed := 350
@export var damage: int = 1
## Missed shots self-clean even if they never leave the screen
## (e.g. spawned off-screen flying away).
@export var max_lifetime := 10.0

var _lifetime := 0.0

func _physics_process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	global_position += speed * direction * delta

	_lifetime += delta
	if _lifetime >= max_lifetime:
		queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is CollisionObject2D:
		var body_layer = body.collision_layer
		var is_player = (body_layer & (1 << 0)) != 0
		if is_player and body.combat.blocking:
			return

	queue_free()

func _on_screen_exited() -> void:
	queue_free()

func reflect():
	# The single surface now pairs with enemy hurtboxes and self-frees on
	# enemy bodies and walls.
	var hitbox = $Hitbox
	hitbox.collision_layer = 1 << 5             # Layer 6 (PlayerHitbox)
	hitbox.collision_mask = (1 << 1) | (1 << 2) # Collides with Layers 2 and 3

	var sprite = $Sprite2D  # Replace with your actual node path
	var shader_material := sprite.material as ShaderMaterial

	# Set flash color to #0076e3 (RGB: 0, 118, 227)
	shader_material.set_shader_parameter("flash_color", Color8(0, 118, 227))

	# Set flash value to max (fully show the flash color)
	shader_material.set_shader_parameter("flash_value", 0.60)

	var mouse_direction: Vector2 = (get_global_mouse_position() - global_position).normalized()
	rotation = mouse_direction.angle()
