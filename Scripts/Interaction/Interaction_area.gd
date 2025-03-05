extends Area2D
class_name InteractionArea

@export var action_name: String = "Interact"

var interact: Callable = func():
	pass


func _on_body_entered(body):
	if body.is_in_group("Player"):
		InteractionManager.register_area(self)


func _on_body_exited(body):
	if body.is_in_group("Player"):
		InteractionManager.unregister_area(self)
