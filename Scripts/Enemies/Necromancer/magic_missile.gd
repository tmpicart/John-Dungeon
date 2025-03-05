extends Node2D
class_name TrackingProjectile

@export var speed := .75
@export var damage:int = 1
@export var projectile_immunity_duration:int = 1

var shooter: CharacterBody2D = null
var first_collision = true
var reflected = false

var player: CharacterBody2D

func _ready():
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(_delta):
	#print(reflected)
	var direction
	if reflected == false:
		direction = (player.global_position - global_position).normalized()
		rotation = direction.angle()
	else: 
		direction = Vector2.RIGHT.rotated(rotation)
	global_position += speed * direction 
	$AnimationPlayer.play("Track")
	await get_tree().create_timer(projectile_immunity_duration).timeout
	first_collision = false

func destroy():
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	destroy()

func reflect():
	print("REFLECTING")
	reflected = true
	var mouseDirection:Vector2 = (get_global_mouse_position() - global_position).normalized()
	rotation = mouseDirection.angle()
	self.remove_from_group("Enemies")
	self.add_to_group("Player")

func _on_hitbox_body_entered(body):
	if !first_collision and body.get_groups() != self.get_groups() or body == player:
		if not(body == player and player.blocking):
			destroy()
