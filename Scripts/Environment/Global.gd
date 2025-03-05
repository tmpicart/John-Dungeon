extends Node

var Keys = 0
var potionHealing = 3
var hasBossKey = false
@onready var time_in_seconds = 1
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var door = get_tree().get_first_node_in_group("door")
