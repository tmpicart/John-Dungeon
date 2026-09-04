extends Node2D

const OPEN_TIME := 1.0

var open := false

@onready var interaction_area: Interactable = $InteractionArea
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var static_collision: CollisionShape2D = $StaticBody2D/CollisionShape2D


func _ready() -> void:
	interaction_area.interacted.connect(_on_interact)


func _on_interact() -> void:
	if open:
		return
	open = true
	animation.play("open")
	await get_tree().create_timer(OPEN_TIME).timeout
	static_collision.disabled = true
	interaction_area.enabled = false