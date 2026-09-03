extends Node

enum Direction {
	RIGHT,
	LEFT,
	DOWN,
	UP
}

var has_boss_key := false

var _player: Node
var _door: Node

## Service-locator access. Re-resolves from the group when the cached reference
## is missing or freed (the autoload ready() runs before the main scene loads).
var player: Node:
	get:
		if not is_instance_valid(_player):
			_player = get_tree().get_first_node_in_group("Player")
		return _player
	set(value):
		_player = value

var door: Node:
	get:
		if not is_instance_valid(_door):
			_door = get_tree().get_first_node_in_group("door")
		return _door
	set(value):
		_door = value
