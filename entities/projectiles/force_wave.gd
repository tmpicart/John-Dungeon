extends Node2D

## Straight force wave: constant px/s drift; destroys on leaving the screen or
## on touching the player's hurtbox. Unblockable — shields never stop it.

@export var speed := 60.0
@export var damage: int = 3

## PlayerHurtbox skips its parry branch for this surface.
var unblockable := true

var shooter: CharacterBody2D = null

@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	hitbox.area_entered.connect(_on_hitbox_area_entered)

func _physics_process(delta: float) -> void:
	global_position += Vector2.RIGHT.rotated(rotation) * speed * delta
	$AnimationPlayer.play("Play")

func destroy() -> void:
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	destroy()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is PlayerHurtbox:
		destroy()