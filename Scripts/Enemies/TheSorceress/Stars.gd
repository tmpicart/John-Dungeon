extends State

@export var enemy: CharacterBody2D
@export var projectile: PackedScene = null
@export var rayCast: RayCast2D
@export var amount := 7
@export var delay = .3
var player: Node2D

func Enter():
	print("Stars")
	if enemy.phase2:
		enemy.velocity = Vector2.ZERO
		player = get_tree().get_first_node_in_group("Player")
		await enemy.cast()
		if projectile:
			for i in range(amount):
				update_raycast()
				await launch_projectile()
	ChangeState.emit(self, "Cast")

func update_raycast():
	# Point the raycast towards the player
	var direction = (player.global_position - enemy.global_position).normalized()
	rayCast.rotation = direction.angle()

func launch_projectile():
	var proj = projectile.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.add_to_group("Enemies")
	proj.global_position = enemy.global_position 
	proj.rotation = rayCast.rotation  # Set local rotation to match rayCast rotation

	# Start the projectile's animation and movement
	proj.velocity = Vector2.RIGHT.rotated(proj.rotation) * proj.speed
	proj._ready()
	
	await get_tree().create_timer(delay).timeout
