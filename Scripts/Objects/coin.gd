extends Node2D

var player: CharacterBody2D	

func _on_interaction_area_body_entered(body):
	player = get_tree().get_first_node_in_group("Player")
	if body == player:
		player.addCoin(1)
		queue_free()
	
