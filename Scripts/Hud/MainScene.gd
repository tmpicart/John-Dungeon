extends Node2D

@onready var health_bar = $CanvasLayer/HeartBar
@onready var item_bar = $CanvasLayer/ItemBar
@onready var player = $Character

func _ready():
	# Set the global player reference for other scripts to access
	Global.player = player
	
	# Set the initial values for the health bar and update it
	health_bar.set_max_health(player.max_hp)
	health_bar.update(player.hp)
	
	# Connect signals for health changes
	player.max_hp_changed.connect(health_bar.set_max_health)
	player.hp_changed.connect(health_bar.update)
	
	# Update item bar with initial values
	item_bar.update_bombs(player.bombs)
	item_bar.update_keys(player.keys)
	item_bar.update_potions(player.potions)
	item_bar.update_coins(player.coins)
	
	# Connect signals for item changes
	player.bombs_changed.connect(item_bar.update_bombs)
	player.keys_changed.connect(item_bar.update_keys)
	player.potions_changed.connect(item_bar.update_potions)
	player.coins_changed.connect(item_bar.update_coins)
