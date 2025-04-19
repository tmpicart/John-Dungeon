
extends Area2D
class_name PlayerHurtbox

func _ready():
	connect("area_entered", self._on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	var hitbox = area
	var player = self.get_owner()
	
	var mouse_pos = get_global_mouse_position()
	var shield_dir = mouse_pos - player.global_position
	var hit_direction = (hitbox.global_position - player.global_position).normalized()
	
	# Check angle between player's facing and hitbox direction
	var angle_between = rad_to_deg(shield_dir.angle_to(hit_direction))
	
	#print("Angle between: ", angle_between)
	#print("Facing: ", shield_dir, " | Incoming: ", hit_direction)

	
	if player.combat.blocking and abs(angle_between) <= 90:  # 90° cone in front
		player.combat.parry()
		if hitbox.get_owner().has_method("reflect"):
			#print("player reflected")
			hitbox.owner.reflect()
		else:
			hitbox.get_owner().stun()
	else:
		player.combat.take_damage(hitbox.owner.damage)
		#print(hitbox.get_owner().name + " hit: " + self.get_parent().name)
