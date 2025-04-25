extends CharacterBody2D

# --- State Machine Controller ---
@onready var state_machine = $"State Control"

# --- Modular Subsystems ---
@onready var movement = $PlayerMovement
@onready var combat = $PlayerCombat
@onready var inventory = $PlayerInventory
@onready var animation = $PlayerAnimation

# --- Optional HUD or Death Indicator ---
@onready var death_label = $Label

func _input(event):
	if state_machine.current_state.has_method("handle_input"):
		state_machine.current_state.handle_input(event)

func _physics_process(delta):
	state_machine._physics_process(delta)

func _process(delta):
	state_machine._process(delta)

func on_player_death():
	state_machine.state_change(state_machine.current_state, "DeadState")
