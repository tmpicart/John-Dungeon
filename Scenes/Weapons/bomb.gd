extends Node2D

@onready var player: CharacterBody2D
@onready var explostion = $AudioStreamPlayer
var damage:int = 3

func _on_animation_finished(anim_name):
	print(anim_name)
	if anim_name == "explosion":
		queue_free()

func explode():
	$AnimationPlayer.play("explosion")
	explostion.play()
	
	
func _ready():
	# Connect to the animation finished signal
	$AnimationPlayer.connect("animation_finished", self._on_animation_finished)
	
func _exit_tree():
	$AnimationPlayer.disconnect("animation_finished", self._on_animation_finished)
