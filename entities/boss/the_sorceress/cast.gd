extends State

## Ranged picker: closes to cast range while aiming, then rolls the attack
## table on an unobstructed aim. The phase gate routes to Intervention first.

@export var ray_cast: RayCast2D
@export var intervention_state: State
@export var summon_state: State
@export var magic_missile_state: State
@export var force_current_state: State
@export var curse_state: State
@export var beam_state: State
@export var stars_state: State
@export var slide_away_state: State
@export var engage_state: State
## Approach stop distance in px.
@export var cast_range := 75.0
## Damped approach: velocity = raw direction * speed, easing in near the player.
@export var speed := 0.5

var player: CharacterBody2D
var boss  # TheSorceress (phase gate)

func _ready() -> void:
	boss = actor

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")

func physics_update(_delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		if player == null:
			return
	var direction = player.global_position - boss.global_position
	ray_cast.global_rotation = direction.angle()

	if direction.length() > cast_range:
		boss.velocity = direction * speed
		return

	if boss.should_transition_phase():
		transition_to(intervention_state)
		return

	if ray_cast.is_colliding() and ray_cast.get_collider() == player:
		_roll_attack()

func _roll_attack() -> void:
	match randi_range(1, 10):
		1:
			transition_to(summon_state)
		2:
			transition_to(magic_missile_state)
		3:
			transition_to(force_current_state)
		4:
			transition_to(curse_state)
		5:
			transition_to(beam_state)
		6:
			transition_to(stars_state)
		7:
			transition_to(slide_away_state)
		_:
			transition_to(engage_state)