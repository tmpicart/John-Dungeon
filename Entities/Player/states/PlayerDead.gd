extends State

func Enter():
	Global.player.movement.set_disabled(true)
	Global.player.combat.set_disabled(true)

	await get_tree().create_timer(1.0).timeout
	$"../../Label".show()
	
