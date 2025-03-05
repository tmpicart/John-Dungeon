extends State

@export var enemy : CharacterBody2D
@export var curse_glyph: PackedScene = null

var player : CharacterBody2D

func Enter():
	print("Curse")
	enemy.velocity = Vector2.ZERO
	await enemy.cast()
	if curse_glyph:
		player = get_tree().get_first_node_in_group("Player")
		var glyph = curse_glyph.instantiate()
		get_tree().current_scene.add_child(glyph)
		glyph.global_position = player.global_position
	
	ChangeState.emit(self, "Cast")
