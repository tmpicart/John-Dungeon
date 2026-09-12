extends Node2D

## Chest: opens on interact and scatters its loot table. The key chest
## consumes a key first; a failed unlock flashes the world-space
## interaction prompt, same as the doors.

const MESSAGE_TIME := 1.0
const SPAWN_WAVE_DELAY := 0.12
const LOCKED_PROMPT := "You Need a Key To Open!"

@export var requires_key := false
@export var loot_table: LootTable = null
@export var loot_value := 0
@export var scatter_strength := 20.0

var _open := false

@onready var interaction_area: Interactable = $InteractionArea
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	interaction_area.interacted.connect(_on_interact)


func _on_interact() -> void:
	if _open:
		return
	if requires_key and not Global.player.inventory.consume_key():
		_show_warning()
		return
	_open = true
	sprite.frame = 2
	interaction_area.enabled = false
	_drop_loot()


func _drop_loot() -> void:
	if loot_table == null or loot_value <= 0:
		return
	var launched := 0
	var wave := 0
	var wave_size := _next_wave_size()
	for scene in loot_table.roll(loot_value):
		_spawn(scene, wave)
		launched += 1
		if launched >= wave_size:
			launched = 0
			wave += 1
			wave_size = _next_wave_size()


func _spawn(scene: PackedScene, wave: int) -> void:
	var item: PickupItem = scene.instantiate()
	owner.add_child(item)
	item.global_position = global_position
	# Wave spew: items launch 2-3 at a time; queued ones stay hidden until
	# their wave fires.
	item.scatter(scatter_strength, PI * 0.5, PI, SPAWN_WAVE_DELAY * wave)


func _next_wave_size() -> int:
	return 2 + randi() % 2


func _show_warning() -> void:
	var prompt := interaction_area.prompt
	interaction_area.prompt = LOCKED_PROMPT
	InteractionManager.refresh_prompt()
	await get_tree().create_timer(MESSAGE_TIME).timeout
	# A second failed attempt inside the window already re-flashed; only clear
	# while the message is still showing.
	if interaction_area.prompt == LOCKED_PROMPT:
		interaction_area.prompt = prompt
		InteractionManager.refresh_prompt()
