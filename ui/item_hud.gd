extends VBoxContainer

## Item HUD: count boxes for bombs/keys/coins/potions and a boss-key box that
## is visible only while the key is held.

@export var bomb_sprite: Texture2D = null
@export var key_sprite: Texture2D = null
@export var coin_sprite: Texture2D = null
@export var potion_sprite: Texture2D = null
@export var boss_key_sprite: Texture2D = null

@onready var _bomb = $Bomb
@onready var _key = $Key
@onready var _coin = $Coin
@onready var _potion = $Potions
@onready var _boss_key = $BossKey


func _ready() -> void:
	_set_icon(_bomb, bomb_sprite)
	_set_icon(_key, key_sprite)
	_set_icon(_coin, coin_sprite)
	_set_icon(_potion, potion_sprite)
	_set_icon(_boss_key, boss_key_sprite)
	_boss_key.get_node("Label").visible = false


func update_coins(amount: int) -> void:
	_coin.get_node("Label").text = "x" + str(amount)


func update_bombs(amount: int) -> void:
	_bomb.get_node("Label").text = "x" + str(amount)


func update_keys(amount: int) -> void:
	_key.get_node("Label").text = "x" + str(amount)


func update_potions(amount: int) -> void:
	_potion.get_node("Label").text = "x" + str(amount)


func update_boss_key(has_key: bool) -> void:
	_boss_key.visible = has_key


func _set_icon(box, texture: Texture2D) -> void:
	box.get_node("Sprite2D").texture = texture
