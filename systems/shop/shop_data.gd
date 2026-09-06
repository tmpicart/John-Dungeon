extends Resource
class_name ShopData

## What a shop sells: a title plus an ordered list of purchasable entries.
## Any Interactable owner (NPC, altar) attaches one and hands it to the
## shared shop UI on open.

@export var title: String = "Shop"
@export var entries: Array[ShopItem] = []
