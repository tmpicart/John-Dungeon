extends Control

var Images = [
	"res://Assets/Title1.png",
	"res://Assets/Title2.png"
]

func _onready():
	var rand = randi_range(0,1)
	print(rand)
	$"John Duoungeon GUy".texture = Images[rand]
	
func _on_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Levels/Floor1.tscn")
func _on_button_2_pressed():
	get_tree().quit()
