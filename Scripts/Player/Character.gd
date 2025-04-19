extends CharacterBody2D

@onready var movement = $PlayerMovement
@onready var combat = $PlayerCombat
@onready var inventory = $PlayerInventory
@onready var animation = $PlayerAnimation

var is_dead := false
var talking := false

func _physics_process(delta):
	if not is_dead:
		movement.move(delta)
		animation.update_animation(movement.velocity)

func _input(event):
	if is_dead:
		if event.is_action_pressed("quit"):
			get_tree().change_scene_to_file("res://Scenes/Hud/MainMenu.tscn")
		return

	if event.is_action_pressed("attack"):
		combat.attack()
	if event.is_action_pressed("block"):
		combat.block()
	if event.is_action_pressed("potion"):
		inventory.use_potion()
	if event.is_action_pressed("bomb"):
		inventory.use_bomb()
	if event.is_action_pressed("dash"):
		movement.dash()

# Called by PlayerHealth on death
func on_player_death():
	is_dead = true
	movement.set_disabled(true)
	combat.set_disabled(true)
	$Label.show()
