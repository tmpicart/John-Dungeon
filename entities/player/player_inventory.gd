extends Node2D
class_name PlayerInventory
## Public inventory API for coins, bombs, potions and keys.
## Callers change counts only through these methods, so the matching
## `*_changed` signal fires and the HUD stays in sync.

signal potions_changed
signal bombs_changed
signal coins_changed
signal keys_changed
signal boss_key_changed

@export var coins: int = 0
@export var bombs: int = 3
@export var potions: int = 3
@export var keys: int = 0

var has_boss_key := false

@onready var bomb_scene = preload("res://entities/projectiles/bomb.tscn")
@onready var combat = $"../PlayerCombat"

## Drinks a potion when one is held and HP is below max.
func use_potion():
	if potions > 0 and combat.hp != combat.max_hp:
		combat.heal(3)
		potions -= 1
		potions_changed.emit(potions)

## Throws a bomb when one is held.
func use_bomb():
	if bombs > 0:
		var bomb = bomb_scene.instantiate()
		get_tree().current_scene.add_child(bomb)
		bomb.global_position = get_parent().global_position
		bombs -= 1
		bombs_changed.emit(bombs)

## Adds a key (pickup).
func add_key():
	keys += 1
	keys_changed.emit(keys)

## Consumes one key atomically; returns false when none is held.
func consume_key() -> bool:
	if keys == 0:
		return false
	keys -= 1
	keys_changed.emit(keys)
	return true


## Grants the floor's boss key (at most one exists).
func give_boss_key() -> void:
	has_boss_key = true
	boss_key_changed.emit(has_boss_key)


## Consumes the boss key atomically; returns false when not held.
func use_boss_key() -> bool:
	if not has_boss_key:
		return false
	has_boss_key = false
	boss_key_changed.emit(has_boss_key)
	return true

## Adds coins (pickups, rewards).
func add_coin(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)

## Spends coins atomically; returns false when unaffordable.
func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	return true

## Adds potions (shops, pickups).
func add_potion(amount: int = 1) -> void:
	potions += amount
	potions_changed.emit(potions)

## Adds bombs (shops, pickups).
func add_bomb(amount: int = 1) -> void:
	bombs += amount
	bombs_changed.emit(bombs)
