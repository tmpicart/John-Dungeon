extends Node2D
class_name Weapon

@export var weaponName: String = "Sword"
@export var damage: int = 1
@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var animPlayer: AnimationPlayer = $AnimationPlayer
@onready var swing = $AudioStreamPlayer

var Direction = Global.Direction

var current_direction: int = Direction.RIGHT
var is_foreground: bool = true
var enabled: bool = true:
	set(value):
		enabled = value
		visible = value

func set_foreground(foreground: bool = true) -> void:
	if not enabled:
		return

	z_index = Global.player.z_index + 1 if foreground else Global.player.z_index - 1

func enable_hitbox() -> void:
	hitbox.disabled = false
	swing.play()

func disable_hitbox() -> void:
	hitbox.disabled = true
	
func upgrade() -> void:
	if sprite.frame < 3:
		damage += 1
		sprite.frame += 1
		hitbox.scale += Vector2(0.05, 0.05)
