extends CharacterBody2D

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
	if state_machine.current_state:
		state_machine.current_state.handle_input(event)

func on_player_death():
	state_machine.transition_to(dead_state)
