extends State

@export var enemy: CharacterBody2D
@export var speed := 1.75
@export var duration := 1.5

var player: CharacterBody2D
var direction

func Enter():
	print("SlideAway")
	player = get_tree().get_first_node_in_group("Player")
	enemy.is_glide = true
	direction = player.global_position - enemy.global_position
	await get_tree().create_timer(duration).timeout
	enemy.is_glide = false
	ChangeState.emit(self, "Cast")
	
func Physics_Update(delta:float):
	enemy.velocity = direction * speed	
	
	
