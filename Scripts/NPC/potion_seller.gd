extends Node2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var player = get_tree().get_first_node_in_group("Player")

func _ready():
	interaction_area.interact = Callable(self, "_on_interact")
	get_node("NPC Dialog").textFile = "res://Scripts/Dialogue/healDialog1.txt"
	get_node("Shop2").cost1 = 2
	get_node("Shop2").cost2 = 3
	get_node("Shop2").item1 = "Potion"
	get_node("Shop2").item2 = "Max HP+"
	get_node("Shop2").imgfile = "res://Assets/2D Pixel Dungeon Asset Pack/items and trap_animation/flasks/flasks_1_1.png"
	get_node("Shop2").imgfile2 = "res://Assets/plus.png"
	get_node("Shop2").max1 = 7
	
func items1():
	player.addPotion()
	
func items2():
	player.set_maxHP(player.maxHP + 1)
	
func _on_interact():
	if get_node("NPC Dialog").spoke == false:
		get_node("NPC Dialog").talk()
	else:
		get_node("Shop2").openShop()
		
