extends State
class_name EnemyChase

## Shared pathfinding chase. Per-enemy behavior (proximity retreat, hit-triggered
## retreat, line-of-sight gating, attack range shape, approach stop distance and
## summon rolls) is configured through exports instead of override states.

enum AttackRangeShape { RADIAL, AXIS_BOX }

@export var navigation_agent: NavigationAgent2D
@export var idle_state: State
## Unassigned attack_state marks a pacifist chaser (e.g. the green slime).
@export var attack_state: State
@export var retreat_state: State
@export var summon_state: State
## Pathfinding speed in px/s (physics-tick independent).
@export var speed := 33
## Distance at which the chase is dropped back to idle.
@export var chase_drop_distance := 200
@export var attempt_attack_range := 15
## Height of the attack box in AXIS_BOX shape; the width is attempt_attack_range.
@export var attack_range_y := 5.0
@export var attack_range_shape: AttackRangeShape = AttackRangeShape.RADIAL
## Proximity retreat; 0 disables retreating when the player gets close.
@export var retreat_range := 0.0
## Retreat after taking a hit (consumes the enemy's retreat_requested flag).
@export var retreat_on_hit := false
## Requires an unobstructed aim ray before entering attack range.
@export var require_line_of_sight := false
@export var aim_ray_cast: RayCast2D
## Fraction of attempt_attack_range the chaser stops short at; 1.0 closes in.
@export var approach_stop_factor := 1.0
## Chance per in-range tick to summon instead of attacking; requires summon_state.
@export var summon_chance := 0.0
@export var path_update_interval := 0.5

var player: CharacterBody2D
var time_since_last_path := 0.0
var enemy: BaseEnemy

func _ready() -> void:
	enemy = actor

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")
	navigation_agent.target_position = player.global_position

func validate_exports() -> void:
	# Nullable states (attack/retreat/summon) are validated against their
	# enabling configuration instead of the base assigned-check, which would
	# reject every optional export.
	if navigation_agent == null:
		push_error("%s: navigation_agent is not assigned" % get_path())
	if idle_state == null:
		push_error("%s: idle_state is not assigned" % get_path())
	if attack_state == null and attempt_attack_range > 0.0:
		push_error("%s: attempt_attack_range set but attack_state is not assigned" % get_path())
	if attack_state != null and attempt_attack_range <= 0.0:
		push_error("%s: attack_state assigned but attempt_attack_range is 0" % get_path())
	if retreat_range > 0.0 and retreat_state == null:
		push_error("%s: retreat_range set but retreat_state is not assigned" % get_path())
	if retreat_on_hit and retreat_state == null:
		push_error("%s: retreat_on_hit set but retreat_state is not assigned" % get_path())
	if require_line_of_sight and aim_ray_cast == null:
		push_error("%s: require_line_of_sight set but aim_ray_cast is not assigned" % get_path())
	if summon_state != null and summon_chance <= 0.0:
		push_error("%s: summon_state assigned but summon_chance is 0" % get_path())

func physics_update(delta: float) -> void:
	if not navigation_agent or not player:
		return

	var to_player = player.global_position - enemy.global_position
	var distance = to_player.length()

	# Transition to Idle if the player is too far
	if distance > chase_drop_distance:
		transition_to(idle_state)
		return

	if _should_retreat(distance):
		return

	if attack_state != null and _in_attack_range(to_player, distance):
		_enter_attack()
		return

	_follow_path(delta, to_player)

func _should_retreat(distance: float) -> bool:
	if retreat_state == null:
		return false

	if retreat_range > 0.0 and distance < retreat_range:
		transition_to(retreat_state)
		return true

	if retreat_on_hit and enemy.retreat_requested and not enemy.is_hit:
		enemy.retreat_requested = false
		transition_to(retreat_state)
		return true

	return false

func _in_attack_range(to_player: Vector2, distance: float) -> bool:
	if attack_range_shape == AttackRangeShape.AXIS_BOX:
		return abs(to_player.x) <= attempt_attack_range and abs(to_player.y) <= attack_range_y
	return distance <= attempt_attack_range

func _enter_attack() -> void:
	if require_line_of_sight:
		enemy.velocity = Vector2.ZERO
		aim_ray_cast.global_rotation = _angle_to_player_from_ray()
		if not (aim_ray_cast.is_colliding() and aim_ray_cast.get_collider() == player):
			return

	if summon_state != null and randf() < summon_chance:
		transition_to(summon_state)
		return

	transition_to(attack_state)

func _angle_to_player_from_ray() -> float:
	var offset = player.global_position - enemy.to_global(aim_ray_cast.position)
	return offset.angle()

func _follow_path(delta: float, to_player: Vector2) -> void:
	# Recalculate path if needed
	time_since_last_path += delta
	if time_since_last_path >= path_update_interval:
		time_since_last_path = 0.0
		var target_position = player.global_position
		if approach_stop_factor < 1.0:
			var direction_to_player = to_player.normalized()
			var stop_distance = attempt_attack_range * approach_stop_factor
			target_position = player.global_position - direction_to_player * stop_distance
		navigation_agent.target_position = target_position

	if navigation_agent.is_navigation_finished():
		return

	var next_position = navigation_agent.get_next_path_position()
	if next_position.is_zero_approx():
		return

	var direction = (next_position - enemy.global_position).normalized()
	enemy.velocity = direction * speed

