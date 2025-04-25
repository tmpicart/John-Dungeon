extends Node2D

var picked_up := false

func _on_interaction_area_body_entered(body):
	var player = Global.player
	if body == player:
		$coin_sfx.play()
		$AnimatedSprite2D.hide()

		$InteractionArea/CollisionShape2D.set_deferred("disabled", true)  # Prevent duplicate pickups

		player.inventory.add_coin(1)
		await $coin_sfx.finished
		queue_free()


func _ready():
	$AnimatedSprite2D.play("default")
