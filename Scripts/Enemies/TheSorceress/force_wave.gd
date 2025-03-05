extends Node2D

@export var speed := 1
@export var damage:int = 3

var shooter: CharacterBody2D = null
var player: CharacterBody2D	

func _physics_process(_delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	global_position += speed * direction 
	$AnimationPlayer.play("Play")

func destroy():
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	destroy()

func _on_hitbox_body_entered(body):
	player = get_tree().get_first_node_in_group("Player")
	if body != shooter and body.get_groups() != self.get_groups() and player.blocking == false:
		destroy()
		
func reflect():
	player = get_tree().get_first_node_in_group("Player")
	player.blocking = false
	player.take_damage(damage)
