
extends Area2D
class_name Hurtbox

func _ready():
	connect("area_entered", self._on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	var hitbox = area
	print(hitbox.owner.name + " hit: " + self.get_parent().name)
	self.get_owner().take_damage(hitbox.owner.damage)
