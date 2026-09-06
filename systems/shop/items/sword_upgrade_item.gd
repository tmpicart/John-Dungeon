extends ShopItem
class_name SwordUpgradeItem

## Raises the weapon one level (resyncs combat damage). The weapon caps its
## tiers internally; max_purchases mirrors that cap on the card.


func grant(player: Node2D) -> void:
	player.combat.upgrade_weapon()
