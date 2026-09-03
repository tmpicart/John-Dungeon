extends State

@export var enemy : CharacterBody2D

func _ready():
	randomize()

func enter() -> void:
	
	if enemy.HP <= enemy.transition_hp and not enemy.phase2:
			transition_to("Intervention")
	else:
		var random = randi_range(1,4)
		match random:
			1:
				transition_to("SlideInto")
			2:
				transition_to("Melee")
			3:
				transition_to("Cast")
			4: 
				transition_to("SlideAway")
