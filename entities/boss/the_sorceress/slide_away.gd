extends State

@export var enemy: CharacterBody2D
@export var speed := 1.75
@export var duration := 1.5

var player: CharacterBody2D
var direction

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")
	enemy.is_glide = true
	direction = player.global_position - enemy.global_position
	await get_tree().create_timer(duration).timeout
	enemy.is_glide = false
	transition_to("Cast")
	
func physics_update(delta: float) -> void:
	enemy.velocity = direction * speed	
	
	
