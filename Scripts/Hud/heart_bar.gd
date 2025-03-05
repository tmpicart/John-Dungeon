extends HBoxContainer

@onready var heart_scene = preload("res://Hud/heart.tscn")

func add_MaxHealth():
	var heart = heart_scene.instantiate()
	add_child(heart)
	
func setMaxHealth(max: int):
	var hearts = get_children().size() + 1 #since indexes at 0
	var need = max - hearts
	
	for hp in max:
		if hp > need:
			print(hp)
			print(hearts)
			return
		add_MaxHealth()
	
func update(current_hp: int):
	var hearts = get_children()
	for hp_index in current_hp:
		hearts[hp_index].update(true)
 
	for hp_index in range(current_hp, hearts.size()):
		hearts[hp_index].update(false)
