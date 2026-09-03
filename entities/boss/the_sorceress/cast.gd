extends State

@export var enemy: CharacterBody2D
@export var speed := .5
@export var cast_range := 75
@export var rayCast: RayCast2D

var player: CharacterBody2D

func _ready():
	randomize()

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")

func physics_update(delta: float) -> void:
	var direction = player.global_position - enemy.global_position
	var angle_to_player = direction.angle()
	rayCast.global_rotation = angle_to_player
	
	if direction.length() > cast_range:
		enemy.velocity = direction * speed
	else:
		if enemy.HP <= enemy.transition_hp and not enemy.phase2:
			transition_to("Intervention")
			
		if rayCast.is_colliding() and rayCast.get_collider() == player and enemy.attacking == false:
			var random = randi_range(1, 10)
			match random:
				1:
					transition_to("Summon")
				2:
					transition_to("Magic Missile")
				3:
					transition_to("Force Current")
				4:
					transition_to("Curse")
				5:
					transition_to("Beam")
				6:
					transition_to("Stars")
				7:
					transition_to("SlideAway")
				_:
					transition_to("Engage")
