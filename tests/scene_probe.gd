extends SceneTree

## Headless gate for the enemies' body colliders. Run:
## Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/scene_probe.gd
## The navmesh keeps routes AGENT_RADIUS clear of obstruction cells measured
## from each enemy's feet origin, so every pathing enemy must collide with the
## world through a feet-centered disc that fits inside that clearance — a
## larger or offset body snags on walls the route calls safe ("the nav is at
## their feet"). Hurt/attack contact uses each Hurtbox/Hitbox area and must
## stay independent of the body disc; the probe asserts the Hurtbox survives.

const NAV_BAKER := preload("res://systems/nav/nav_baker.gd")
## One world pixel of slack under the bake clearance.
const MAX_WORLD_RADIUS: float = NAV_BAKER.AGENT_RADIUS - 1.0
const MIN_WORLD_RADIUS := 3.0

const ENEMY_SCENES: Array[String] = [
	"res://entities/enemies/arcane_archer/arcane_archer.tscn",
	"res://entities/enemies/flail_skeleton/flail_skeleton.tscn",
	"res://entities/enemies/necromancer/necromancer.tscn",
	"res://entities/enemies/slime_green/slime_green.tscn",
	"res://entities/enemies/slime_red/slime_red.tscn",
]

var _failures := 0


func _initialize() -> void:
	for scene_path in ENEMY_SCENES:
		_probe_scene(scene_path)
	if _failures > 0:
		print("SCENE PROBE: %d failure(s)" % _failures)
		quit(1)
	else:
		print("SCENE PROBE PASSED")
		quit(0)


func _probe_scene(scene_path: String) -> void:
	var packed := load(scene_path) as PackedScene
	_check(packed != null, "%s loads" % scene_path.get_file())
	if packed == null:
		return
	var enemy := packed.instantiate() as Node
	_check(enemy != null, "%s instantiates" % scene_path.get_file())
	if enemy == null:
		return
	if enemy is CharacterBody2D:
		_probe_body(enemy, scene_path)
		_probe_hurtbox(enemy, scene_path)
	else:
		_check(false, "%s root is a CharacterBody2D" % scene_path.get_file())
	enemy.free()


func _probe_body(enemy: Node, scene_path: String) -> void:
	var body_nodes: Array[Node] = []
	for child in enemy.get_children():
		if child is CollisionShape2D:
			body_nodes.append(child)
	_check(
		body_nodes.size() == 1,
		"%s has exactly one direct body CollisionShape2D" % scene_path.get_file()
	)
	if body_nodes.size() != 1:
		return
	var shape_node := body_nodes[0] as CollisionShape2D
	var circle := shape_node.shape as CircleShape2D
	_check(circle != null, "%s body collider is a CircleShape2D" % scene_path.get_file())
	if circle == null:
		return
	_check(
		shape_node.position == Vector2.ZERO and shape_node.scale == Vector2.ONE,
		"%s body disc centered on the feet origin" % scene_path.get_file()
	)
	var root_scale: Vector2 = enemy.scale
	var world_radius := circle.radius * root_scale.x
	# Epsilon: local radii are rounded to 5 decimals, so 6/0.7 lands a hair over.
	_check(
		world_radius <= MAX_WORLD_RADIUS + 0.01 and world_radius >= MIN_WORLD_RADIUS,
		"%s body disc world radius %.2f within [%.1f, %.1f]"
		% [scene_path.get_file(), world_radius, MIN_WORLD_RADIUS, MAX_WORLD_RADIUS]
	)


func _probe_hurtbox(enemy: Node, scene_path: String) -> void:
	var hurtbox := enemy.get_node_or_null("Hurtbox") as Area2D
	_check(hurtbox != null, "%s keeps its Hurtbox area" % scene_path.get_file())
	if hurtbox == null:
		return
	var shape_node := hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_check(
		shape_node != null and shape_node.shape != null,
		"%s Hurtbox keeps a combat shape" % scene_path.get_file()
	)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: " + label)
	else:
		_failures += 1
		print("  FAIL: " + label)