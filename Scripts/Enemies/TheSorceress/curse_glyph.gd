extends Area2D

@export var duration = 10
@export var acceleration_division_factor = 6

var player: CharacterBody2D	
var default_acceleration = 60
var restored_acceleration

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	restored_acceleration = max(player.acceleration, default_acceleration)
	$AnimationPlayer.play("Play")
	await get_tree().create_timer(duration).timeout
	destroy()

func destroy():
	queue_free()

func _on_body_entered(body):
	if body == player:
		#print("ENTERED")
		player.acceleration /= acceleration_division_factor

func _on_body_exited(body):
	if body == player:
		#print("ENTERED")
		player.acceleration = restored_acceleration
