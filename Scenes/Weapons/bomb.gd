extends Node2D

@onready var player: CharacterBody2D
@onready var explostion = $AudioStreamPlayer
var damage:int = 3

# creating bomb is now handled in the CharacterScript
#func create_bomb():
	#player = get_tree().get_first_node_in_group("Player")
	#if Input.is_action_just_pressed("bomb"):
		#print(self.position)
		#self.position = player.position
		#$AnimationPlayer.play("explosion")

func _on_animation_finished(anim_name):
	print(anim_name)
	if anim_name == "explosion":
		queue_free()

func explode():
	self.position = player.position
	$AnimationPlayer.play("explosion")
	explostion.play()
	
	
func _ready():
	# Connect to the animation finished signal
	$AnimationPlayer.connect("animation_finished", self._on_animation_finished)
	
func _exit_tree():
	$AnimationPlayer.disconnect("animation_finished", self._on_animation_finished)
