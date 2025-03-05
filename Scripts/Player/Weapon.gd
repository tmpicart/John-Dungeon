extends Node2D
class_name Weapon
#Exports
@export var weaponName:String = "Sword"
@export var damage:int = 1
#OnReady
@onready var weapon:Node2D =  get_node("Node2D")
@onready var sprite:Sprite2D = weapon.get_node("Sprite2D")
@onready var hitbox:Hitbox = weapon.get_node("Hitbox")
@onready var animPlayer:AnimationPlayer = weapon.get_node("AnimationPlayer")
@onready var swing = $AudioStreamPlayer

func upgrade():
	if sprite.frame < 3:
		damage += 1
		sprite.frame += 1
		hitbox.scale += Vector2(.05,.05)

func ATTACK():
	if not animPlayer.is_playing():
		swing.play()
		animPlayer.play("Swing")

func _process(_delta):
	#if self.get_parent().is_in_group("Players"):
		#Update Rotation of weapon
		var mouseDirection:Vector2 = (get_global_mouse_position() - global_position).normalized()
		if mouseDirection.x > 0 and sprite.flip_h:
			sprite.flip_h = false
		elif mouseDirection.x < 0 and not sprite.flip_h:
			sprite.flip_h = true

		weapon.rotation = mouseDirection.angle()
		# Attack change this to the player
	#attack()
