extends VBoxContainer

@export var BombSprite:CompressedTexture2D = null
@export var KeySprite:CompressedTexture2D = null
@export var CoinSprite:CompressedTexture2D = null
@export var PotionSprite:CompressedTexture2D = null

@onready var Bomb = $Bomb
@onready var Key = $Key
@onready var Coin = $Coin
@onready var Potion = $Potions

func changeSprite(sprite2D:Sprite2D,sprite:CompressedTexture2D):
	sprite2D.texture = sprite
	
func _ready(): #Hard Coded Stuff for now
	# Bomb
	var sprite:Sprite2D = Bomb.get_node("Sprite2D")
	changeSprite(sprite,BombSprite)
	#Key
	sprite = Key.get_node("Sprite2D")
	changeSprite(sprite,KeySprite)
	#Coin
	sprite = Coin.get_node("Sprite2D")
	changeSprite(sprite,CoinSprite)
	#Potion
	sprite = Potion.get_node("Sprite2D")
	changeSprite(sprite,PotionSprite)


func update_coin(num:int):
	Coin.get_node("Label").text = "x"+str(num)
	
func update_bomb(num:int):
	Bomb.get_node("Label").text = "x"+str(num)
	
func update_key(num:int):
	Key.get_node("Label").text = "x"+str(num)
	
func update_potion(num:int):
	Potion.get_node("Label").text = "x"+str(num)
