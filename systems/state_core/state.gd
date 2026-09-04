extends Node
class_name State

signal transition_requested(from_state: State, to_state: State)

## The entity this state machine belongs to, injected by StateControl.
var actor: Node

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass

## Requests a transition from this state to `to_state`.
func transition_to(to_state: State) -> void:
	transition_requested.emit(self, to_state)

## Fails fast if any exported node property was left unassigned in the Inspector.
func validate_exports() -> void:
	var script_properties = get_script().get_script_property_list()
	if script_properties == null:
		return
	for prop in script_properties:
		if prop.type == TYPE_OBJECT and prop.hint == PROPERTY_HINT_NODE_TYPE \
				and prop.usage & PROPERTY_USAGE_EDITOR:
			if get(prop.name) == null:
				push_error("%s: exported node property '%s' is not assigned" % [get_path(), prop.name])
