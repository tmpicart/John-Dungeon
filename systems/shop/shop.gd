extends CanvasLayer

## Shared shop menu: builds one card per `ShopData` entry, buys on click and
## shows the live coin count. Closes on Esc (quit action) or walking away
## from the owner. While open, player actions and interaction are frozen —
## movement stays live so the walk-away close remains reachable.

const WALK_AWAY_DISTANCE := 140.0
const MAX_COLUMNS := 4
const CARD_SCENE := preload("res://systems/shop/shop_card.tscn")

var _open := false
var _owner_position := Vector2.ZERO
var _entries: Array[ShopItem] = []
var _cards: Array = []
var _purchases := {}

@onready var _title: Label = $Root/Panel/Margin/VBox/Title
@onready var _grid: GridContainer = $Root/Panel/Margin/VBox/Grid
@onready var _coin_count: Label = $Root/Panel/Margin/VBox/CoinBar/CoinRow/Count


func _process(_delta: float) -> void:
	if not _open:
		return
	var player: Node2D = Global.player
	if player == null or player.global_position.distance_to(_owner_position) > WALK_AWAY_DISTANCE:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if _open and event.is_action_pressed("quit"):
		close()


## Opens the menu for the given stock. `from_position` is the owner's world
## position, used for the walk-away close.
func open(data: ShopData, from_position: Vector2) -> void:
	if _open:
		return
	_open = true
	_owner_position = from_position
	_purchases.clear()
	_build(data)
	visible = true
	_refresh_cards()
	_connect_wallet(true)
	var player := Global.player
	if player != null:
		player.set_input_locked(true)
	InteractionManager.set_locked(true)


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	_connect_wallet(false)
	var player := Global.player
	if player != null:
		player.set_input_locked(false)
	InteractionManager.set_locked(false)


func _build(data: ShopData) -> void:
	_title.text = data.title
	_entries.clear()
	_cards.clear()
	for child in _grid.get_children():
		child.queue_free()
	_grid.columns = clampi(data.entries.size(), 1, MAX_COLUMNS)
	for item in data.entries:
		var card := CARD_SCENE.instantiate()
		_grid.add_child(card)
		card.setup(item, _coins(), _purchases.get(item, 0))
		card.purchase_requested.connect(_on_purchase_requested)
		_entries.append(item)
		_cards.append(card)


func _on_purchase_requested(item: ShopItem) -> void:
	if item.max_purchases > 0 and _purchases.get(item, 0) >= item.max_purchases:
		return
	if not Global.player.inventory.spend_coins(item.cost):
		_refresh_cards()
		return
	item.grant(Global.player)
	_purchases[item] = _purchases.get(item, 0) + 1
	_refresh_cards()


func _refresh_cards() -> void:
	for i in _cards.size():
		_cards[i].refresh(_coins(), _purchases.get(_entries[i], 0))
	_coin_count.text = str(_coins())


func _coins() -> int:
	var player := Global.player
	return 0 if player == null else player.inventory.coins


func _connect_wallet(connect_it: bool) -> void:
	var player := Global.player
	if player == null:
		return
	var inventory = player.inventory
	if connect_it and not inventory.coins_changed.is_connected(_on_coins_changed):
		inventory.coins_changed.connect(_on_coins_changed)
	elif not connect_it and inventory.coins_changed.is_connected(_on_coins_changed):
		inventory.coins_changed.disconnect(_on_coins_changed)


func _on_coins_changed(_new_count: int) -> void:
	_refresh_cards()
