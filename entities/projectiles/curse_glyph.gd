extends Area2D

## Slowing glyph: halves the player's top and dash speed while they stand
## inside it.

@export var duration := 10
@export var speed_division_factor := 2

var player  # Player root (movement subsystem access)
var applied := false
var restored_speed := 0
var restored_dash_speed := 0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	var animation_player: AnimationPlayer = $AnimationPlayer
	animation_player.play("Play")
	await animation_player.animation_finished
	animation_player.play("Flash")
	await get_tree().create_timer(duration).timeout
	destroy()

func destroy() -> void:
	if applied and is_instance_valid(player):
		player.movement.max_speed = restored_speed
		player.movement.dash_speed = restored_dash_speed
	queue_free()

func _on_body_entered(body):
	if body == player and not applied:
		applied = true
		restored_speed = player.movement.max_speed
		restored_dash_speed = player.movement.dash_speed
		player.movement.max_speed /= speed_division_factor
		player.movement.dash_speed /= speed_division_factor

func _on_body_exited(body):
	if body == player and applied:
		applied = false
		player.movement.max_speed = restored_speed
		player.movement.dash_speed = restored_dash_speed