extends State
class_name EnemyIdle

@export var enemy : CharacterBody2D
@export var speed := 20
@export var detection_range := 200

var wander_direction : Vector2
var duration : float

var player: CharacterBody2D

func randomized_stroll():
	duration = randf_range(1,4)
	
	var still = randi_range(1,3) 
	
	if still == 1:
		wander_direction = Vector2()
	else:
		wander_direction = Vector2(randf_range(-1,1), randf_range(-1,1))
	
func Enter():
	#print("Idle")
	player = get_tree().get_first_node_in_group("Player")
	randomized_stroll()
	
func Update(delta:float):
	if duration > 0:
		duration -= delta
	
	else:
		randomized_stroll()
		
func Physics_Update(delta:float):
	if enemy:
		enemy.velocity = wander_direction * speed
		
	var direction = player.global_position - enemy.global_position
	
	if direction.length() < detection_range:
		ChangeState.emit(self, "EnemyChase")
