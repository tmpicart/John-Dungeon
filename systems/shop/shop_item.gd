extends Resource
class_name ShopItem

## One purchasable entry in a `ShopData` list. Data fields drive the generated
## card UI; subclasses implement the grant (what the buyer receives).

@export var display_name: String = ""
@export var cost: int = 1
@export var icon: Texture2D
## Purchases allowed for this entry per shop session; 0 = unlimited.
@export_range(0, 99) var max_purchases: int = 0


## Applies the purchase to the buyer. Subclasses override.
func grant(_player: Node2D) -> void:
	push_warning("ShopItem.grant() not implemented by %s" % resource_name)


## Extra availability gate beyond cost and max_purchases.
func can_grant(_player: Node2D) -> bool:
	return true
