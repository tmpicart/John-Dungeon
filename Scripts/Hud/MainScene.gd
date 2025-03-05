extends Node2D

@onready var health_bar = $CanvasLayer/HeartBar
@onready var item_bar = $CanvasLayer/ItemBar
@onready var player = $Character

func _ready():
	Global.player = player
	health_bar.setMaxHealth(player.maxHP)
	health_bar.update(player.HP)
	player.maxHp_changed.connect(health_bar.setMaxHealth)
	player.hp_changed.connect(health_bar.update)
	#Items
	item_bar.update_bomb(player.bombs)
	item_bar.update_key(player.keys)
	item_bar.update_potion(player.potions)
	item_bar.update_coin(player.coins)
	# Item Signals
	player.bomb_changed.connect(item_bar.update_bomb)
	player.key_changed.connect(item_bar.update_key)
	player.potion_changed.connect(item_bar.update_potion)
	player.coin_changed.connect(item_bar.update_coin)
