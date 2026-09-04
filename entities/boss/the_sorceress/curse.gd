extends State

## Plants a slowing glyph at the player's predicted position once the cast
## lands.

@export var cast_state: State
@export var curse_glyph: PackedScene
## Seconds of the player's velocity used to plant the glyph ahead of them;
## tuned to the glyph's 0.4s arm delay.
@export var lead_time := 0.5

var boss  # velocity control

func _ready() -> void:
	boss = actor

func enter() -> void:
	boss.velocity = Vector2.ZERO
	if await boss.run_action_animation("Cast"):
		var player = get_tree().get_first_node_in_group("Player")
		var glyph = curse_glyph.instantiate()
		get_tree().current_scene.add_child(glyph)
		# Cap the lead at walk speed: a mid-dash sample must not fling the
		# glyph across the room.
		var lead = player.movement.velocity * lead_time
		var max_lead = player.movement.max_speed * lead_time
		glyph.global_position = player.global_position + lead.limit_length(max_lead)
	transition_to(cast_state)