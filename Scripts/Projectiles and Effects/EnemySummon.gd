extends State
class_name EnemySummonNecromancer

@export var enemy: CharacterBody2D
@export var summoned_creature: PackedScene = null
@export var summon_effect: PackedScene = null

var tilemap_layer: TileMapLayer
var can_summon := true
var positions := []
const DEG_TO_RAD = PI / 180

@export var summon_radius: int = 5  # In tiles

func _ready():
	tilemap_layer = find_tilemap_node()
	if tilemap_layer == null:
		print("Error: TileMapLayer not found in the scene!")

func Enter():
	if can_summon and not enemy.is_dead:
		await enemy.summon()
		can_summon = false
		$summon_cooldown.start()

	ChangeState.emit(self, "EnemyChase")

func spawn_enemies():
	positions = _get_valid_summon_positions(3, tilemap_layer)
	
	# Ensure we handle the case where fewer than 3 positions are found
	var number_of_positions = positions.size()
	
	if number_of_positions < 3:
		print("Warning: Found only ", number_of_positions, " valid summon positions.")
	
	# Ensure we use all available positions even if fewer than requested
	for position in positions:
		if position != Vector2.INF:
			var effect = summon_effect.instantiate()
			get_tree().current_scene.add_child(effect)
			effect.global_position = position

			var skeleton = summoned_creature.instantiate()
			get_tree().current_scene.add_child(skeleton)
			skeleton.global_position = position


func _get_valid_summon_positions(max_count: int, tilemap: TileMapLayer) -> Array:
	var all_valid_positions = []
	var summon_radius_px: float = float(summon_radius * tilemap.tile_set.tile_size.x)
	var summon_radius_sq = summon_radius_px * summon_radius_px
	var summoner_pos: Vector2 = enemy.global_position

	var used_cells: Array[Vector2i] = tilemap.get_used_cells()

	for cell in used_cells:
		var tile_data: TileData = tilemap.get_cell_tile_data(cell)
		if tile_data == null:
			continue

		# Check for custom summonable flag
		var is_summonable = tile_data.get_custom_data("is_summonable")
		if not is_summonable:
			continue

		var cell_world_pos: Vector2 = tilemap.map_to_local(cell)

		if summoner_pos.distance_squared_to(cell_world_pos) <= summon_radius_sq:
			all_valid_positions.append(cell_world_pos)

	# Shuffle the list to make selection random
	all_valid_positions.shuffle()

	# Return only the number of positions we want
	return all_valid_positions.slice(0, min(max_count, all_valid_positions.size()))

func find_tilemap_node() -> TileMapLayer:
	var parent = get_tree().current_scene
	for child in parent.get_children():
		if child is TileMapLayer:
			return child

	return null

func _on_summon_cooldown_timeout():
	can_summon = true

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Summon":
		spawn_enemies()
