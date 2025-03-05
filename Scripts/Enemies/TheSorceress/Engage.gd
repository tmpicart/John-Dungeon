extends State

@export var enemy : CharacterBody2D

func _ready():
	randomize()

func Enter():
	print("ENGAGE MODE")
	
	if enemy.HP <= enemy.transition_hp and not enemy.phase2:
			ChangeState.emit(self, "Intervention")
	else:
		var random = randi_range(1,4)
		match random:
			1:
				ChangeState.emit(self, "SlideInto")
			2:
				ChangeState.emit(self, "Melee")
			3:
				ChangeState.emit(self, "Cast")
			4: 
				ChangeState.emit(self, "SlideAway")
