extends CanvasLayer

## Shared dialogue box: plays a DialogueData's one-shot stages — falling back
## to the greeting — page by page beside the speaker's portrait. Opening
## freezes player actions and interaction (shop-freeze pattern; movement
## stays live so walking away still closes). Finishing the last page emits
## `finished`; Esc or walking away aborts without it.

signal finished

const WALK_AWAY_DISTANCE := 140.0
## Typewriter speed in seconds per revealed character.
const SECONDS_PER_CHAR := 0.02

var _active := false
var _data: DialogueData
var _stage_index := -1
var _pages: Array[String] = []
var _page := 0
var _anchor := Vector2.ZERO
## Frame at which the opening `interact` press stops counting as an advance.
var _armed_frame := 0
var _typing_tween: Tween

@onready var _box: Panel = $Box
@onready var _portrait: TextureRect = $Box/portrait
@onready var _text: RichTextLabel = $Box/text
@onready var _continue_hint: Label = $Box/hint


func _process(_delta: float) -> void:
	if not _active:
		return
	_continue_hint.visible = not _is_typing()
	var walker: Node2D = Global.player
	if walker == null or walker.global_position.distance_to(_anchor) > WALK_AWAY_DISTANCE:
		_close(false)


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("quit"):
		_close(false)
	elif Engine.get_process_frames() > _armed_frame \
			and event.is_action_pressed("interact"):
		_advance()


## Opens the box on the speaker's next content: the first unconsumed stage
## whose gate passes, or the greeting. Returns false when there is nothing
## to play. `anchor_position` is the owner's world position, used for the
## walk-away close.
func open(data: DialogueData, anchor_position: Vector2) -> bool:
	if _active:
		return false
	if data == null:
		push_warning("Dialogue opened without DialogueData")
		return false
	var stage_index := _next_stage_index(data)
	if stage_index == -2:
		push_warning("DialogueData \"%s\" has no playable stages or greeting" % data.npc_id)
		return false
	var stage: DialogueStage = data.greeting if stage_index == -1 else data.stages[stage_index]
	_active = true
	_data = data
	_stage_index = stage_index
	_pages.assign(stage.pages)
	_page = 0
	_anchor = anchor_position
	_armed_frame = Engine.get_process_frames() + 1
	_portrait.texture = data.portrait
	_portrait.visible = data.portrait != null
	_show_page()
	_box.visible = true
	_set_frozen(true)
	return true


## Reveals the current page with the typewriter effect.
func _show_page() -> void:
	_text.text = _pages[_page]
	_kill_typing()
	_text.visible_characters = 0
	_typing_tween = _text.create_tween()
	_typing_tween.tween_property(_text, "visible_characters",
			_text.get_total_character_count(), _text.text.length() * SECONDS_PER_CHAR)


func _kill_typing() -> void:
	if _typing_tween != null and _typing_tween.is_valid():
		_typing_tween.kill()
	_typing_tween = null


func _is_typing() -> bool:
	return _text.visible_characters >= 0 \
			and _text.visible_characters < _text.get_total_character_count()


func _advance() -> void:
	if _is_typing():
		_kill_typing()
		_text.visible_characters = -1
		return
	_page += 1
	if _page >= _pages.size():
		_complete()
		return
	_show_page()


## Applies the stage's bookkeeping (flags, consumption) and closes as
## finished. Greeting plays (-1) leave no progress trace.
func _complete() -> void:
	if _stage_index >= 0:
		var speaker: Node = _speaker_progress()
		if speaker != null:
			var stage: DialogueStage = _data.stages[_stage_index]
			if stage.set_flag != "":
				speaker.set_flag(StringName(stage.set_flag))
			speaker.set_stage(_data.npc_id, _stage_index + 1)
	_close(true)


func _close(did_finish: bool) -> void:
	if not _active:
		return
	_active = false
	_kill_typing()
	_box.visible = false
	_set_frozen(false)
	if did_finish:
		finished.emit()
	_data = null
	_pages.clear()


## -1 selects the greeting, -2 means nothing is playable.
func _next_stage_index(data: DialogueData) -> int:
	var speaker: Node = _speaker_progress()
	var current := 0
	if speaker != null:
		current = speaker.get_stage(data.npc_id)
	for i in range(current, data.stages.size()):
		var stage: DialogueStage = data.stages[i]
		if stage != null and not stage.pages.is_empty() and _gate_open(speaker, stage):
			return i
	if data.greeting != null and not data.greeting.pages.is_empty():
		return -1
	return -2


func _gate_open(speaker: Node, stage: DialogueStage) -> bool:
	return stage.requires_flag == "" \
			or (speaker != null and speaker.has_flag(StringName(stage.requires_flag)))


func _speaker_progress() -> Node:
	var player := Global.player
	return player.get("progress") if player != null else null


func _set_frozen(locked: bool) -> void:
	var player := Global.player
	if player != null and player.has_method("set_input_locked"):
		player.set_input_locked(locked)
	InteractionManager.set_locked(locked)

