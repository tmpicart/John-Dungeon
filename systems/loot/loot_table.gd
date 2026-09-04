extends Resource
class_name LootTable

## A tier's eligible item scenes. roll(budget) picks random affordable
## entries until the budget is spent — a value-1 entry (coins) in the table
## guarantees the sum matches exactly.

@export var tier := 1
@export var entries: Array[PackedScene] = []


## Returns item scenes whose loot_value sums to `budget`. Values are read
## from throwaway instances so the item scene stays the single source of
## truth for pricing.
func roll(budget: int) -> Array[PackedScene]:
	var result: Array[PackedScene] = []
	while budget > 0:
		var affordable := _affordable(budget)
		if affordable.is_empty():
			break
		var picked: PackedScene = affordable.pick_random()
		budget -= _loot_value(picked)
		result.append(picked)
	return result


func _affordable(budget: int) -> Array[PackedScene]:
	var affordable: Array[PackedScene] = []
	for scene in entries:
		if _loot_value(scene) <= budget:
			affordable.append(scene)
	return affordable


func _loot_value(scene: PackedScene) -> int:
	var item: Node = scene.instantiate()
	var value: int = item.loot_value
	item.free()
	return value