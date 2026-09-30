extends CharacterBody2D

## Chase-probe player stub: a static layer-1 disc with the minimal combat
## surface projectiles read (`combat.blocking`). Radius 4 keeps body-contact
## distance (~9 px with an enemy's 5 px feet disc) inside the 12 px arrival
## tolerance so `is_navigation_finished()` resolves against a stationary
## stub. Enough for press slides, arrow hits, and D-9's
## `Global.player as CharacterBody2D` without the full player scene.

var combat := {"blocking": false}


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	shape_node.shape = shape
	add_child(shape_node)
