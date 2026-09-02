extends VBoxContainer

# Exported variables for item sprites
@export var BombSprite: CompressedTexture2D = null
@export var KeySprite: CompressedTexture2D = null
@export var CoinSprite: CompressedTexture2D = null
@export var PotionSprite: CompressedTexture2D = null

# Onready variables to get references to the item containers
@onready var Bomb = $Bomb
@onready var Key = $Key
@onready var Coin = $Coin
@onready var Potion = $Potions

# Helper function to change sprite textures
func change_sprite(sprite2D: Sprite2D, sprite: CompressedTexture2D):
	sprite2D.texture = sprite

# Called when the node is ready
func _ready(): 
	# Change sprites for each item (Bomb, Key, Coin, Potion)
	change_sprite(Bomb.get_node("Sprite2D"), BombSprite)
	change_sprite(Key.get_node("Sprite2D"), KeySprite)
	change_sprite(Coin.get_node("Sprite2D"), CoinSprite)
	change_sprite(Potion.get_node("Sprite2D"), PotionSprite)

# Update functions to reflect the current number of items
func update_coins(num: int):
	Coin.get_node("Label").text = "x" + str(num)

func update_bombs(num: int):
	Bomb.get_node("Label").text = "x" + str(num)

func update_keys(num: int):
	Key.get_node("Label").text = "x" + str(num)

func update_potions(num: int):
	Potion.get_node("Label").text = "x" + str(num)
