
extends Area2D
class_name Hurtbox

func _init():
	collision_layer = 0
	collision_mask = 2

func _ready():
	connect("area_entered", self._on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if _is_valid_hit(area):
		var hitbox = area as Hitbox
		var hurtOwner = self.get_owner()
		print(hitbox.owner.name + " hit: " + self.get_parent().name)
		
		if hurtOwner.is_in_group("Player"):
			if hurtOwner.blocking == true:
				if hitbox.get_parent().has_method("reflect"):
					print("player reflected")
					hitbox.owner.reflect()
					if hurtOwner.blocking == true:
						hurtOwner.parry()
				else:
					hitbox.owner.take_damage(0)
			else:
				hurtOwner.take_damage(hitbox.owner.damage)
		else:
			hurtOwner.take_damage(hitbox.owner.damage)

func _is_valid_hit(area: Area2D) -> bool:
	if area is Hitbox:
		var hitbox = area as Hitbox
		var hitboxGroup = hitbox.get_owner().get_groups()
		var hurtboxGroup = self.get_owner().get_groups()
		return hitboxGroup != hurtboxGroup and hitbox.owner != self.get_parent() and not self.get_parent().is_ancestor_of(hitbox)
	return false
