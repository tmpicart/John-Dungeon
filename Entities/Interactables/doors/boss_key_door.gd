extends Node2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var animation = $AnimationPlayer
@onready var warning = $Label
var open = false


func _ready():
	interaction_area.interact = Callable(self, "_on_interact")
	warning.hide()
	
	
func _on_interact():
	if Global.hasBossKey:
		if !open:
			Global.hasBossKey = false
			open = true
			animation.play("open")
			$AudioStreamPlayer2D.play()
			await get_tree().create_timer(Global.time_in_seconds-.5).timeout
			get_node("StaticBody2D/CollisionShape2D").disabled = open
			get_node("InteractionArea/CollisionShape2D").disabled = open
	else:
		warning.show()
		await get_tree().create_timer(Global.time_in_seconds).timeout
		warning.hide()

