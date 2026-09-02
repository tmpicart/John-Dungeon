extends Node2D

@onready var interaction_area: InteractionArea = $InteractionArea
@export var Path: PackedScene = null

func _ready():
	interaction_area.interact = Callable(self, "_on_interact")
	
func _drop_key():
	if Path:
		var item = Path.instantiate()
		owner.add_child(item)
		item.global_position = self.global_position + Vector2(0, 15)
	
func _on_interact():
		get_node("InteractionArea/CollisionShape2D").disabled = true
		$Sprite2D.frame = 2
		_drop_key()
