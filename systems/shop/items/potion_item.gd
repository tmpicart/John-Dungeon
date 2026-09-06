extends ShopItem
class_name PotionItem

## Grants potions to the buyer's inventory.

@export var amount: int = 1


func grant(player: Node2D) -> void:
	player.inventory.add_potion(amount)
