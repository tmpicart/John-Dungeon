
extends Area2D
class_name PlayerHurtbox

func _ready():
	connect("area_entered", self._on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	var hitbox = area
	var player = self.get_owner()
	var shield_direction = player.get_facing_direction()
	var hit_direction = (hitbox.global_position - player.global_position).normalized()
	
	# Check angle between player's facing and hitbox direction
	var angle_between = rad_to_deg(shield_direction.angle_to(hit_direction))
	
	print("Angle between: ", angle_between)
	print("Facing: ", shield_direction, " | Incoming: ", hit_direction)

	
	if player.blocking and abs(angle_between) <= 90:  # 90° cone in front
		player.parry()
		if hitbox.get_owner().has_method("reflect"):
			print("player reflected")
			hitbox.owner.reflect()
		else:
			hitbox.get_owner().stun()
	else:
		player.take_damage(hitbox.owner.damage)
		print(hitbox.get_owner().name + " hit: " + self.get_parent().name)
