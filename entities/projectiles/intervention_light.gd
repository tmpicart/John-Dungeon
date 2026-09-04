extends Node2D

## Falling pillar of light: destroys itself when its animation ends.
## Unblockable — shields never stop it.

@export var damage: int = 5

## PlayerHurtbox skips its parry branch for this surface.
var unblockable := true

var shooter: CharacterBody2D = null
var player: CharacterBody2D

func destroy():
	queue_free()

func _ready():
	$AnimationPlayer.play("Play")
	var duration = $AnimationPlayer.current_animation_length
	await get_tree().create_timer(duration).timeout
	destroy()
