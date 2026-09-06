extends ShopItem
class_name MaxHpItem

## Raises max HP. The setter on PlayerCombat.max_hp emits max_hp_changed, so
## the heart bar resizes; no heal is granted, matching the legacy behavior.

@export var amount: int = 1


func grant(player: Node2D) -> void:
	player.combat.max_hp += amount
