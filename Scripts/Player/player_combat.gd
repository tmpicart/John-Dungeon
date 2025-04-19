extends Node2D

# Signals
signal hp_changed(current_hp: int)
signal max_hp_changed(max_hp: int)

# Combat-related nodes
@onready var weapon: Node = $Weapon
@onready var shield: Node = $Shield
@onready var reflect_sfx: AudioStreamPlayer = $"../reflect_sfx"
@onready var ouch_sfx: AudioStreamPlayer = $"../ouch_sfx"
@onready var animation = $"../PlayerAnimation"

# Combat state
var damage: int = 0
var blocking: bool = false
var is_hit: bool = false
var is_dead: bool = false
var disabled: bool = false

# Health state
@export var max_hp: int = 3:
	set(value):
		max_hp = value
		max_hp_changed.emit(value)

var hp: int = 3

# Grab Camera2D node from the scene tree
@onready var camera: Camera2D = $"../Camera2D"


func _ready():
	damage = weapon.damage
	hp = max_hp
	max_hp_changed.emit(max_hp)
	hp_changed.emit(hp)

# --- Combat ---
func attack():
	if is_dead or disabled:
		return
	weapon.attack()

func block():
	if blocking or is_dead or disabled:
		return
	blocking = true
	await shield.block()
	blocking = false

func parry():
	if not disabled:
		reflect_sfx.play()

# --- Health / Damage ---
func take_damage(dmg: int):
	if is_hit or is_dead or disabled:
		return

	is_hit = true
	ouch_sfx.play()

	hp -= dmg
	hp_changed.emit(hp)
	
	if hp > 0:
		camera.frame_freeze(dmg)  # Call frame freeze on Camera2D
		await animation.play_hit()
	else:
		camera.frame_freeze(dmg*2)  # Call frame freeze on Camera2D
		kill()
	
	is_hit = false	
	
func heal(amount: int):
	if is_dead or disabled:
		return
	hp = clamp(hp + amount, 0, max_hp)
	hp_changed.emit(hp)

# --- Death ---
func kill():
	is_dead = true
	weapon.hide()
	shield.hide()
	animation.play_death()
	get_parent().on_player_death()

# --- Other ---
func set_disabled(value: bool):
	disabled = value
