extends Node
class_name StateControl

@export var initial_state: State

var states: Array[State] = []
var current_state: State

func _enter_tree() -> void:
	# Register before any state's _ready runs so states can rely on `actor`.
	for child in get_children():
		_register_state(child)

func _register_state(node: Node) -> void:
	if node is State:
		states.append(node)
		node.actor = get_parent()
		node.transition_requested.connect(_on_transition_requested)
	for child in node.get_children():
		_register_state(child)

func _ready() -> void:
	# Deferred: exported node references resolve later in the ready cascade.
	validate_states.call_deferred()

	if initial_state == null:
		push_error("%s: initial_state is not assigned" % get_path())
		return

	current_state = initial_state
	current_state.enter()

func validate_states() -> void:
	for state in states:
		state.validate_exports()

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

## Programmatic transition (e.g. death, external triggers).
func transition_to(to_state: State) -> void:
	_enter_state(to_state)

func _on_transition_requested(from_state: State, to_state: State) -> void:
	if from_state != current_state:
		return
	_enter_state(to_state)

func _enter_state(to_state: State) -> void:
	if to_state == null:
		push_error("%s: transition target is not assigned" % get_path())
		return

	if current_state:
		current_state.exit()

	current_state = to_state
	current_state.enter()
