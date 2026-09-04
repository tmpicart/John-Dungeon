extends Area2D
class_name EnemyHitbox

## Scripted enemy attack surface: carries a per-surface damage value that
## hurtboxes resolve over the owner's, and code-driven activation for moves
## without animation-track gating (slides).

@export var damage := 1

func set_active(active: bool) -> void:
	($CollisionShape2D as CollisionShape2D).set_deferred("disabled", not active)
