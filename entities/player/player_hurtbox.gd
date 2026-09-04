
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


	var unblockable = hitbox.get("unblockable") or hitbox.owner.get("unblockable")
	if player.combat.blocking and abs(angle_between) <= 90 and not unblockable:
		player.combat.shield.parry()
		if hitbox.owner.has_method("reflect"):
			hitbox.owner.reflect()
		elif hitbox.owner.has_method("stun"):
			hitbox.owner.stun()
	else:
		# Scripted hitboxes carry their own damage; plain areas fall back to
		# the owning body's value.
		var hit_damage = hitbox.get("damage")
		if hit_damage == null:
			hit_damage = hitbox.owner.damage
		player.combat.take_damage(hit_damage)
