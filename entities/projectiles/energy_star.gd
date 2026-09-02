extends CharacterBody2D

@export var speed := 1
@export var damage:int = 1
@export var duration:int = 5

var shooter: CharacterBody2D = null

func _ready():
	# Initialize the velocity based on the current rotation
	$AnimationPlayer.play("Play")
	velocity = Vector2.RIGHT.rotated(rotation) * speed

func _physics_process(delta):
	
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if enemy is PhysicsBody2D:
			add_collision_exception_with(enemy)
	
	for player in get_tree().get_nodes_in_group("Player"):
		if player is PhysicsBody2D:
			add_collision_exception_with(player)
		
	var collision = move_and_collide(velocity)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		
	global_position += velocity
	await get_tree().create_timer(duration).timeout
	queue_free()

func reflect():
	var mouse_direction: Vector2 = (get_global_mouse_position() - global_position).normalized()
	rotation = mouse_direction.angle()
	velocity = mouse_direction * speed
	self.remove_from_group("Enemies")
