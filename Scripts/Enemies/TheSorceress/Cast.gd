extends State

@export var enemy: CharacterBody2D
@export var speed := .5
@export var cast_range := 75
@export var rayCast: RayCast2D

var player: CharacterBody2D

func _ready():
	randomize()

func Enter():
	player = get_tree().get_first_node_in_group("Player")
	print("CAST MODE")

func Physics_Update(delta: float):
	var direction = player.global_position - enemy.global_position
	var angle_to_player = direction.angle()
	rayCast.global_rotation = angle_to_player
	
	if direction.length() > cast_range:
		enemy.velocity = direction * speed
	else:
		if enemy.HP <= enemy.transition_hp and not enemy.phase2:
			ChangeState.emit(self, "Intervention")
			
		if rayCast.is_colliding() and rayCast.get_collider() == player and enemy.attacking == false:
			var random = randi_range(1, 10)
			match random:
				1:
					ChangeState.emit(self, "Summon")
				2:
					ChangeState.emit(self, "Magic Missile")
				3:
					ChangeState.emit(self, "Force Current")
				4:
					ChangeState.emit(self, "Curse")
				5:
					ChangeState.emit(self, "Beam")
				6:
					ChangeState.emit(self, "Stars")
				7:
					ChangeState.emit(self, "SlideAway")
				_:
					ChangeState.emit(self, "Engage")
