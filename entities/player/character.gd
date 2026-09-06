extends CharacterBody2D

## Modal-freeze flag: gates state input routing while a shop/dialogue menu
## is open (see set_input_locked).
var input_locked := false

# --- State Machine Controller ---
@onready var state_machine = $"State Control"
@onready var dead_state: State = $"State Control/DeadState"

# --- Modular Subsystems ---
@onready var movement = $PlayerMovement
@onready var combat = $PlayerCombat
@onready var inventory = $PlayerInventory
@onready var animation = $PlayerAnimation

# --- Optional HUD or Death Indicator ---
@onready var death_label = $Label

func _input(event):
	if input_locked:
		return
	if state_machine.current_state:
		state_machine.current_state.handle_input(event)

## Freeze hook for modals (shop, dialogue): gates input-driven state changes
## and disables combat while open. Movement stays live so walk-away closing
## works; combat-disabled also shields the player while shopping.
func set_input_locked(value: bool) -> void:
	input_locked = value
	combat.set_disabled(value)


func on_player_death():
	state_machine.transition_to(dead_state)
