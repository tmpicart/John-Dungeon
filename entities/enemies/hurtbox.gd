extends Area2D
class_name Hurtbox

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	var target = get_owner()
	# Player-side contract (player_hurtbox.gd): scripted hitboxes carry
	# their own damage; plain areas fall back to the owning body's value.
	var hit_damage = area.get("damage")
	if hit_damage == null:
		hit_damage = area.owner.damage
	target.take_damage(hit_damage, area.global_position)

