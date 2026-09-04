extends State

## Melee-range picker: phase gate first, then a uniform roll across the
## engage moves.

@export var intervention_state: State
@export var slide_into_state: State
@export var melee_state: State
@export var cast_state: State
@export var slide_away_state: State

var boss  # TheSorceress (phase gate)

func _ready() -> void:
	boss = actor

func enter() -> void:
	if boss.should_transition_phase():
		transition_to(intervention_state)
		return

	match randi_range(1, 4):
		1:
			transition_to(slide_into_state)
		2:
			transition_to(melee_state)
		3:
			transition_to(cast_state)
		4:
			transition_to(slide_away_state)