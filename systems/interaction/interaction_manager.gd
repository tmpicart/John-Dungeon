extends Node2D

## Interaction registry + screen-space prompt. Interactables register on
## player contact; the nearest enabled area wins and is triggered by the
## `interact` action. Nearest is re-resolved only when the registry changes
## or on input — no per-frame scans. The label lives on a high CanvasLayer:
## the active area's world anchor is re-projected every frame while shown,
## so bobbing, animated, or rotating owners are followed and the prompt can
## never be occluded by world rendering.

const PROMPT_FALLBACK := "[?] "
const INTERACT_ACTION := "interact"
## Screen-space gap between the projected anchor point and the prompt.
const PROMPT_MARGIN := 12.0

var _active_areas: Array[Interactable] = []
var _best_area: Interactable = null
var _locked := false

@onready var label: Label = $PromptLayer/InteractionText


func _process(_delta: float) -> void:
	if label.visible:
		_position_prompt()


func register_area(area: Interactable) -> void:
	if _active_areas.has(area):
		return
	_active_areas.append(area)
	_select_best()


func unregister_area(area: Interactable) -> void:
	_active_areas.erase(area)
	if _best_area == area:
		_best_area = null
		_select_best()


## Freeze hook for modals (dialogue, shop) and cutscene-style flows.
func set_locked(value: bool) -> void:
	_locked = value
	_update_prompt()


## Re-renders the prompt when an active Interactable changes its `prompt`
## outside a registry event (e.g. a door flashing a locked message).
func refresh_prompt() -> void:
	_update_prompt()


func _select_best() -> void:
	_active_areas = _active_areas.filter(is_instance_valid)
	_best_area = null
	var best_distance := INF
	var player: Node2D = Global.player
	if player == null:
		_update_prompt()
		return
	for area in _active_areas:
		var distance := player.global_position.distance_to(area.global_position)
		if distance < best_distance:
			best_distance = distance
			_best_area = area
	_update_prompt()


func _update_prompt() -> void:
	if _locked or _best_area == null or _best_area.prompt.is_empty():
		label.hide()
		return
	label.text = _prompt_prefix() + _best_area.prompt
	label.reset_size()
	_position_prompt()
	label.show()


## Projects the active area's world anchor onto the screen layer and centers
## the label above it, plus the area's screen-space nudge. Called from
## _process while shown, so the prompt tracks its owner continuously.
func _position_prompt() -> void:
	if _best_area == null:
		return
	var screen := get_viewport().get_canvas_transform() \
			* _best_area.prompt_anchor_position()
	label.position = screen + Vector2(
		-label.size.x / 2.0,
		-PROMPT_MARGIN - label.size.y,
	) + _best_area.prompt_offset


func _prompt_prefix() -> String:
	var events := InputMap.action_get_events(INTERACT_ACTION)
	if events.is_empty():
		return PROMPT_FALLBACK
	var event: InputEvent = events[0]
	var key_text := ""
	if event is InputEventKey:
		var key: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
		key_text = OS.get_keycode_string(key)
	else:
		key_text = event.as_text()
	return "[%s] " % key_text


func _input(event: InputEvent) -> void:
	if _locked or not event.is_action_pressed(INTERACT_ACTION):
		return
	_select_best()
	if _best_area != null:
		_best_area.try_interact()