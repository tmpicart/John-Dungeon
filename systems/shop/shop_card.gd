extends Panel

## Generated shop pane for one ShopItem: highlights on hover, buys on click.
## Greys out while unaffordable; a MAX note shows once the purchase cap is hit.
## Tints cascade (modulate) so the stone texture and border brighten together.

signal purchase_requested(item: ShopItem)

const NORMAL_TINT := Color(1.12, 1.12, 1.12)
const HOVER_TINT := Color(1.32, 1.3, 1.22)
const DISABLED_TINT := Color(0.52, 0.5, 0.54)

var _item: ShopItem
var _coins := 0
var _purchased := 0


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(item: ShopItem, coins: int, purchased: int) -> void:
	_item = item
	$Margin/VBox/Name.text = item.display_name
	$Margin/VBox/Icon.texture = item.icon
	$Margin/VBox/CostRow/Cost.text = str(item.cost)
	refresh(coins, purchased)


## Re-evaluates affordability and cap visuals; called on every wallet change.
func refresh(coins: int, purchased: int) -> void:
	_coins = coins
	_purchased = purchased
	var sold_out := _item.max_purchases > 0 and _purchased >= _item.max_purchases
	$Margin/VBox/Max.visible = sold_out
	if sold_out or _coins < _item.cost:
		modulate = DISABLED_TINT
	else:
		modulate = NORMAL_TINT


func _is_available() -> bool:
	return $Margin/VBox/Max.visible == false and _coins >= _item.cost


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
		purchase_requested.emit(_item)


func _on_mouse_entered() -> void:
	if _is_available():
		modulate = HOVER_TINT


func _on_mouse_exited() -> void:
	refresh(_coins, _purchased)
