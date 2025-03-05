extends Node2D
class_name Projectile

@export var speed := 10
@export var damage:int = 1

var player: CharacterBody2D	

func _physics_process(_delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	global_position += speed * direction 

func destroy():
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	destroy()

func _on_arcane_arrow_body_entered(body):
	player = get_tree().get_first_node_in_group("Player")
	if body.get_groups() != self.get_groups() and player.blocking == false:
		destroy()

func reflect():
	var mouseDirection:Vector2 = (get_global_mouse_position() - global_position).normalized()
	rotation = mouseDirection.angle()
	self.remove_from_group("Enemies")
	self.add_to_group("Player")
