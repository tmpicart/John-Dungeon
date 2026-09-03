extends State

var player: Node

func _ready() -> void:
	player = actor

func enter() -> void:
	player.movement.set_disabled(true)
	player.combat.set_disabled(true)

	await get_tree().create_timer(1.0).timeout
	player.death_label.show()

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	
