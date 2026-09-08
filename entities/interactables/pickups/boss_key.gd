extends PickupItem

## Boss key pickup: grants the key and, the first time, plays the floor
## boss's taunt through the shared dialogue box. The taunt's stage
## consumption (under its own npc_id) keeps it a once-per-boss event; each
## floor's key instance points at its boss's DialogueData.

const DIALOG_SCENE := preload("res://systems/dialogue/npc_dialog.tscn")

@export var boss_taunt: DialogueData


func _ready() -> void:
	super()
	interaction_area.interacted.connect(_on_interact)


func _on_interact() -> void:
	Global.player.inventory.give_boss_key()
	_play_taunt()
	queue_free()


func _play_taunt() -> void:
	if boss_taunt == null:
		return
	var player := Global.player
	if player == null:
		return
	# The key frees itself below, so the box lives in the current scene.
	var dialog: CanvasLayer = DIALOG_SCENE.instantiate()
	get_tree().current_scene.add_child(dialog)
	if not dialog.open(boss_taunt, player.global_position):
		dialog.queue_free()