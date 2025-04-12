extends State
class_name EnemyChase

@export var enemy: CharacterBody2D
@export var navigation_agent: NavigationAgent2D
@export var speed := 2000
@export var chase_drop_distance := 200
@export var attempt_attack_range := 15
@export var path_update_interval := 0.5

var player: CharacterBody2D
var time_since_last_path := 0.0

func Enter():
	player = get_tree().get_first_node_in_group("Player")
	navigation_agent.target_position = player.global_position

func Physics_Update(delta: float):
	if not navigation_agent or not player:
		return

	var to_player = player.global_position - enemy.global_position
	var distance = to_player.length()

	# ✅ Transition to Idle if player is too far
	if distance > chase_drop_distance:
		ChangeState.emit(self, "EnemyIdle")
		return
	
	# ✅ Transition to Attack if in range
	if distance <= attempt_attack_range:
		ChangeState.emit(self, "EnemyAttack")
		return

	# ✅ Recalculate path if needed
	time_since_last_path += delta
	if time_since_last_path >= path_update_interval:
		time_since_last_path = 0.0
		navigation_agent.target_position = player.global_position

	if navigation_agent.is_navigation_finished():
		return

	var next_position = navigation_agent.get_next_path_position()
	if next_position.is_zero_approx():
		return

	var direction = (next_position - enemy.global_position).normalized()
	enemy.velocity = direction * speed * delta
