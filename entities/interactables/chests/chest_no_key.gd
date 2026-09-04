extends Node2D

@export var drop_scene: PackedScene = null
@export var loot_table: LootTable = null
@export var loot_value := 0
@export var scatter_strength := 20.0

@onready var interaction_area: Interactable = $InteractionArea
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	interaction_area.interacted.connect(_on_interact)


func _on_interact() -> void:
	sprite.frame = 2
	_drop_key()
	_drop_loot()


func _drop_key() -> void:
	if drop_scene == null:
		return
	_spawn(drop_scene)


func _drop_loot() -> void:
	if loot_table == null or loot_value <= 0:
		return
	for scene in loot_table.roll(loot_value):
		_spawn(scene)


func _spawn(scene: PackedScene) -> void:
	var item: PickupItem = scene.instantiate()
	owner.add_child(item)
	item.global_position = global_position + Vector2(0, 15)
	item.scatter(scatter_strength)