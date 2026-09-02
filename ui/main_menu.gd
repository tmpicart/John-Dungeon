extends Control

const TITLE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/hud/title_1.png"),
	preload("res://assets/hud/title_2.png")
]

func _ready() -> void:
	$TitleCard.texture = TITLE_TEXTURES.pick_random()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/floor_1.tscn")

func _on_button_2_pressed() -> void:
	get_tree().quit()
