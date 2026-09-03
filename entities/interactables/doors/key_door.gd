extends Node2D

const LOCK_OPEN_DELAY := 0.5
const MESSAGE_TIME := 1.0

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var animation = $AnimationPlayer
@onready var warning = $Label
var open = false


func _ready():
	interaction_area.interact = Callable(self, "_on_interact")
	warning.hide()
	
	
func _on_interact():
	if open:
		return
	if not Global.player.inventory.consume_key():
		warning.show()
		await get_tree().create_timer(MESSAGE_TIME).timeout
		warning.hide()
		return
	open = true
	animation.play("open")
	$AudioStreamPlayer2D.play()
	await get_tree().create_timer(LOCK_OPEN_DELAY).timeout
	get_node("StaticBody2D/CollisionShape2D").disabled = true
	get_node("InteractionArea/CollisionShape2D").disabled = true

