extends Node2D

## Interaction registry + world-space prompt. Interactables register on player
## contact; the nearest enabled area wins and is triggered by the `interact`
## action. Nearest is re-resolved only when the registry changes or on input —
## no per-frame scans.

const PROMPT_FALLBACK := "[?] "
const INTERACT_ACTION := "interact"

var _active_areas: Array[Interactable] = []
var _best_area: Interactable = null
var _locked := false

@onready var label: Label = $InteractionText


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
	label.global_position = _best_area.global_position \
			+ Vector2(-label.size.x * label.scale.x / 2.0, -15)
	label.show()


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