extends Area2D
class_name Hurtbox

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	var hitbox = area
	var target = get_owner()
	target.take_damage(hitbox.owner.damage, hitbox.global_position)

