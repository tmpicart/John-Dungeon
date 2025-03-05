extends Node2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var upgraded = 1

func _ready():
	interaction_area.interact = Callable(self, "_on_interact")
	get_node("NPC Dialog").textFile = "res://Scripts/Dialogue/smithDialog1.txt"
	get_node("Shop2").cost1 = 1
	get_node("Shop2").cost2 = 5
	get_node("Shop2").item1 = "Bomb"
	get_node("Shop2").item2 = "Sword lvl+"
	get_node("Shop2").imgfile = "res://Assets/bombPlaceholder.png"
	get_node("Shop2").imgfile2 = "res://Assets/WEAPONS.png"
	get_node("Shop2").max1 = 4
	
func items1():
	player.bombs += 1
	
func items2():
		player.upgradeWeapon()
	
func _on_interact():
	if get_node("NPC Dialog").spoke == false:
		get_node("NPC Dialog").talk()
	else:
		get_node("Shop2").openShop()
		
