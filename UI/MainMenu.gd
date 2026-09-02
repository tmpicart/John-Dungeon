extends Control

const TITLE_TEXTURES: Array[Texture2D] = [
	preload("res://Assets/Hud/Title1.png"),
	preload("res://Assets/Hud/Title2.png")
]

func _ready() -> void:
	$TitleCard.texture = TITLE_TEXTURES.pick_random()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Levels/Floor1.tscn")

func _on_button_2_pressed() -> void:
	get_tree().quit()
