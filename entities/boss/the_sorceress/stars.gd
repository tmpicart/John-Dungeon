extends State

## Phase-2 star volley: launches stars one by one toward the player's current
## position.

@export var cast_state: State
@export var projectile: PackedScene
@export var ray_cast: RayCast2D
@export var amount := 7
@export var delay := 0.3

var player: Node2D
var boss  # TheSorceress (phase gate)

func _ready() -> void:
	boss = actor

func enter() -> void:
	if not boss.phase2:
		transition_to(cast_state)
		return

	boss.velocity = Vector2.ZERO
	player = get_tree().get_first_node_in_group("Player")
	if await boss.run_action_animation("Cast"):
		for i in amount:
			_update_raycast()
			await _launch_projectile()
	transition_to(cast_state)

func _update_raycast() -> void:
	var direction = (player.global_position - boss.global_position).normalized()
	ray_cast.rotation = direction.angle()

func _launch_projectile() -> void:
	if projectile == null:
		return
	var proj = projectile.instantiate()
	proj.rotation = ray_cast.rotation
	get_tree().current_scene.add_child(proj)
	proj.add_to_group("Enemies")
	proj.global_position = boss.global_position + Vector2(0, -40)  # chest height
	await get_tree().create_timer(delay).timeout