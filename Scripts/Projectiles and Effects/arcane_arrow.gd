extends Node2D

@export var speed := 350
@export var damage:int = 1

func _physics_process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	global_position += speed * direction * delta

func _on_collider_body_entered(body: Node2D) -> void:
	var body_layer = body.collision_layer

	# Check if the body has the blocking method
	var is_player = (body_layer & (1 << 0)) != 0
	if is_player and body.has_method("block") and body.blocking:
		# Don't destroy if it's the player and they are blocking
		return
	
	queue_free()

func reflect():
	var hitbox = $Hitbox
	var collider = $Collider
	
	# hitbox: belongs to layer 6, collides with layer 9
	hitbox.collision_layer = 1 << 5             # Layer 6
	hitbox.collision_mask = 1 << 8              # Collides with Layer 9
	
	# collider: collides with layers 2 and 3
	collider.collision_mask = (1 << 1) | (1 << 2)  # Collides with Layer 2 and 3
	
	var sprite = $Sprite2D  # Replace with your actual node path
	var material := sprite.material as ShaderMaterial
	
	# Set flash color to #0076e3 (RGB: 0, 118, 227)
	material.set_shader_parameter("flash_color", Color8(0, 118, 227))
	
	# Set flash value to max (fully show the flash color)
	material.set_shader_parameter("flash_value", 0.60)
	
	var mouseDirection: Vector2 = (get_global_mouse_position() - global_position).normalized()
	rotation = mouseDirection.angle()
	
