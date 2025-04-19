
# PlayerInventory.gd
extends Node2D

signal potions_changed
signal bombs_changed
signal coins_changed
signal keys_changed

@export var coins: int = 0
@export var bombs: int = 3
@export var potions: int = 3
@export var keys: int = 0
@onready var bomb_scene = preload("res://Scenes/Weapons/bomb.tscn")

func use_potion():
	if potions > 0:
		$"../PlayerCombat".heal(1)
		potions -= 1
		potions_changed.emit(potions)

func use_bomb():
	if bombs > 0:
		var bomb = bomb_scene.instantiate()
		get_tree().current_scene.add_child(bomb)
		bomb.global_position = get_parent().global_position
		bomb.explode()
		bombs -= 1
		bombs_changed.emit(bombs)
