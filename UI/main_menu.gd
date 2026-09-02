extends Control

const TITLE_TEXTURES: Array[Texture2D] = [
	preload("res://Assets/hud/title_1.png"),
	preload("res://Assets/hud/title_2.png")
]

func _ready() -> void:
	$TitleCard.texture = TITLE_TEXTURES.pick_random()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Levels/floor_1.tscn")

func _on_button_2_pressed() -> void:
	get_tree().quit()
