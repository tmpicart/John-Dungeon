extends Node2D

@onready var interaction_area: Interactable = $InteractionArea
@onready var player = get_tree().get_first_node_in_group("Player")


func _ready() -> void:
	interaction_area.interacted.connect(_on_interact)
	get_node("NPC Dialog").textFile = "res://systems/dialogue/smith_dialog_1.txt"
	get_node("Shop2").cost1 = 1
	get_node("Shop2").cost2 = 5
	get_node("Shop2").item1 = "Bomb"
	get_node("Shop2").item2 = "Sword lvl+"
	get_node("Shop2").imgfile = "res://assets/items/bomb_placeholder.png"
	get_node("Shop2").imgfile2 = "res://assets/items/weapons.png"
	get_node("Shop2").max1 = 4


func items1() -> void:
	player.inventory.add_bomb(1)


func items2() -> void:
	player.combat.upgrade_weapon()


func _on_interact() -> void:
	if get_node("NPC Dialog").spoke == false:
		get_node("NPC Dialog").talk()
	else:
		get_node("Shop2").openShop()