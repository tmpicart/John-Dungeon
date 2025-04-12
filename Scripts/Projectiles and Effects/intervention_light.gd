extends Node2D

@export var damage:int = 5

var shooter: CharacterBody2D = null
var player: CharacterBody2D	

func destroy():
	queue_free()

func _ready():
	$AnimationPlayer.play("Play")
	var duration = $AnimationPlayer.current_animation_length
	await get_tree().create_timer(duration).timeout
	destroy()
