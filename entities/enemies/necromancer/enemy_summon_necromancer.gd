extends State
class_name EnemySummonNecromancer

@export var enemy: CharacterBody2D
@export var summoned_creature: PackedScene = null
@export var summon_effect: PackedScene = null

@export var summon_radius: int = 5  # In tiles
@export var min_summons: int = 2
@export var max_summons: int = 5
## Seconds before the necromancer may summon again.
@export var summon_cooldown_duration := 10.0

var tilemap_layer: TileMapLayer
var positions := []

var _summon_cooldown: Timer

func _ready():
	tilemap_layer = find_tilemap_node()
	if tilemap_layer == null:
		push_error("TileMapLayer not found in the scene!")

	_summon_cooldown = Timer.new()
	_summon_cooldown.one_shot = true
	add_child(_summon_cooldown)

func enter() -> void:
	if _summon_cooldown.is_stopped() and not enemy.is_dead:
		var completed: bool = await enemy.summon()
		if completed:
			spawn_enemies()
		_summon_cooldown.start(summon_cooldown_duration)

	transition_to("EnemyChase")

func spawn_enemies():
	var summon_count = randi_range(min_summons, max_summons)
	positions = _get_valid_summon_positions(summon_count, tilemap_layer)

	var number_of_positions = positions.size()
	if number_of_positions < summon_count:
		push_warning("Found only %d valid summon positions." % number_of_positions)

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

		var is_summonable = tile_data.get_custom_data("is_summonable")
		if not is_summonable:
			continue

		var cell_world_pos: Vector2 = tilemap.map_to_local(cell)
		if summoner_pos.distance_squared_to(cell_world_pos) <= summon_radius_sq:
			all_valid_positions.append(cell_world_pos)

	all_valid_positions.shuffle()
	return all_valid_positions.slice(0, min(max_count, all_valid_positions.size()))

func find_tilemap_node() -> TileMapLayer:
	var parent = get_tree().current_scene
	for child in parent.get_children():
		if child is TileMapLayer:
			return child
	return null

