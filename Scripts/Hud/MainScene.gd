extends Node2D

@onready var health_bar = $CanvasLayer/HeartBar
@onready var item_bar = $CanvasLayer/ItemBar
@onready var player = $Character

func _ready():
	# Set the global player reference for other scripts to access
	Global.player = player
	
	# Set the initial values for the health bar and update it
	health_bar.set_max_health(player.combat.max_hp)
	health_bar.update(player.combat.hp)
	
	# Connect signals for health changes
	player.combat.max_hp_changed.connect(health_bar.set_max_health)
	player.combat.hp_changed.connect(health_bar.update)
	
	# Update item bar with initial values
	item_bar.update_bombs(player.inventory.bombs)
	item_bar.update_keys(player.inventory.keys)
	item_bar.update_potions(player.inventory.potions)
	item_bar.update_coins(player.inventory.coins)
	
	# Connect signals for item changes
	player.inventory.bombs_changed.connect(item_bar.update_bombs)
	player.inventory.keys_changed.connect(item_bar.update_keys)
	player.inventory.potions_changed.connect(item_bar.update_potions)
	player.inventory.coins_changed.connect(item_bar.update_coins)
