extends CharacterBody2D

## Bouncing star: constant px/s drift with ricochets for a fixed lifetime.
## Unblockable — shields never stop it.

@export var speed := 120.0
@export var damage: int = 1
@export var duration := 5.0

## PlayerHurtbox skips its parry branch for this surface.
var unblockable := true

var shooter: CharacterBody2D = null

func _ready() -> void:
	$AnimationPlayer.play("Play")
	for body in get_tree().get_nodes_in_group("Enemies"):
		if body is PhysicsBody2D and body != self:
			add_collision_exception_with(body)
	for body in get_tree().get_nodes_in_group("Player"):
		if body is PhysicsBody2D:
			add_collision_exception_with(body)
	velocity = Vector2.RIGHT.rotated(rotation) * speed
	get_tree().create_timer(duration).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())