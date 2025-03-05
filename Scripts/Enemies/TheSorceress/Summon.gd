extends State

@export var enemy : CharacterBody2D
@export var summoned_creature1: PackedScene = null
@export var summoned_creature2: PackedScene = null
@export var summoned_creature3: PackedScene = null
@export var summoned_creature4: PackedScene = null
@export var summon_effect: PackedScene = null

@onready var tilemap_parent = get_tree().current_scene

func Enter():
	print("Summon")
	enemy.velocity = Vector2.ZERO
	await enemy.big_cast()
	if enemy.phase2 == false:
		summon_enemies(3, summoned_creature1)
		summon_enemies(2, summoned_creature2) 
	else:
		var rand = randi_range(1,2)
		if rand == 1:
			summon_enemies(3, summoned_creature3)
			summon_enemies(2, summoned_creature4)
		else:
			summon_enemies(7, summoned_creature3)
	ChangeState.emit(self, "Cast")
	
func detect_tilemap() -> TileMap:
	var summoner_pos = enemy.global_position
	var min_distance = 1e9
	var closest_tilemap = null

	for child in tilemap_parent.get_children():
		if child.get_child_count() != 0:
			var valid_child = child.get_child(0)
			
			if valid_child is TileMap:
				var tilemap = valid_child
				var tile_size = tilemap.tile_set.tile_size  # Access the tile size from the TileSet
				var used_rect = tilemap.get_used_rect()
				
				print(child)
				print(tilemap)
				
				for x in range(used_rect.position.x, used_rect.position.x + used_rect.size.x):
					for y in range(used_rect.position.y, used_rect.position.y + used_rect.size.y):
						var cell_pos = Vector2i(x, y)
						var cell_local_pos = tilemap.local_to_map(cell_pos)
						var cell_world_pos = tilemap.to_global(cell_local_pos)

						var distance = summoner_pos.distance_to(cell_world_pos)
				
						if distance < min_distance:
							min_distance = distance
							closest_tilemap = tilemap
	return closest_tilemap
	

func find_empty_cells(tilemap: TileMap) -> Array:
	var empty_cells = []
	var all_cells = tilemap.get_used_cells(0)  # Get all used cells in layer 0
	var collision_cells = tilemap.get_used_cells(1)  # Get used cells in layer 1
	
	for cell in all_cells:
		if !collision_cells.has(cell):
			empty_cells.append(cell)
	
	print(all_cells.size())
	print(collision_cells.size())
	print(empty_cells.size())
	return empty_cells

func summon_enemies(amount: int, enemy_scene: PackedScene):
	var tilemap = detect_tilemap()
	if tilemap:
		var empty_cells = find_empty_cells(tilemap)
		var num_empty_cells = empty_cells.size()
		var num_to_summon = min(amount, num_empty_cells)
		var chosen_cells = []

		# Randomly select cells without replacement
		while chosen_cells.size() < num_to_summon:
			var random_index = randi() % num_empty_cells
			var random_cell = empty_cells[random_index]
			if random_cell not in chosen_cells:
				chosen_cells.append(random_cell)

		for cell_pos in chosen_cells:
			var cell_local_pos = tilemap.map_to_local(cell_pos)
			var cell_world_pos = tilemap.to_global(cell_local_pos)
			summon_enemy_at_position(cell_world_pos, enemy_scene)
			
func summon_enemy_at_position(position: Vector2, enemy_scene: PackedScene):
	if summon_effect:
		var effect = summon_effect.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = position
	
	if enemy_scene:
		var enemy_instance = enemy_scene.instantiate()
		get_tree().current_scene.add_child(enemy_instance)
		enemy_instance.global_position = position
			
		print("Enemy summoned at position: ", position)
	else:
		print("Failed to instantiate enemy")
