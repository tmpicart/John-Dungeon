extends Node2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var animation = $AnimationPlayer
@onready var label = $Label
@onready var Inv = []
@export var Path: PackedScene = null

func _ready():
	interaction_area.interact = Callable(self, "_on_interact")
	label.hide()
	
	
func _on_interact():
	if Global.player.keys != 0:
		get_node("InteractionArea/CollisionShape2D").disabled = true
		animation.play("Open")
		if Path:
			var item = Path.instantiate()
			owner.add_child(item)
			item.global_position = self.global_position + Vector2(0, 15)
		print(Global.Keys)
		Global.player.useKey()
		print(Global.Keys)
	else:
		label.show()
		await get_tree().create_timer(Global.time_in_seconds).timeout
		label.hide()
		

