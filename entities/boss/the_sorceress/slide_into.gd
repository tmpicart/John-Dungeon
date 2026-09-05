extends State

## Glide along the captured direction for a fixed duration, then hand off to
## the melee approach.

@export var melee_state: State
## Body-length attack surface, live only while gliding.
@export var slide_hitbox: EnemyHitbox
## Damped glide: velocity = captured direction * speed.
@export var speed := 1.75
@export var duration := 1.5

var player: CharacterBody2D
var boss  # TheSorceress (is_glide flag)
var direction: Vector2

func _ready() -> void:
	boss = actor

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")
	if player == null:
		transition_to(melee_state)
		return
	boss.is_glide = true
	slide_hitbox.set_active(true)
	direction = player.global_position - boss.global_position
	await get_tree().create_timer(duration).timeout
	boss.is_glide = false
	slide_hitbox.set_active(false)
	transition_to(melee_state)

func exit() -> void:
	# A stagger mid-glide must not leave the slide surface live or the flag set.
	boss.is_glide = false
	slide_hitbox.set_active(false)

func physics_update(_delta: float) -> void:
	boss.velocity = direction * speed