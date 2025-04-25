extends Node

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var door = get_tree().get_first_node_in_group("door")

enum Direction {
	RIGHT,
	LEFT,
	DOWN,
	UP
}

var hasBossKey = false
