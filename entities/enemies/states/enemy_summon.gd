extends State
class_name EnemySummon

## Shared summon state: plays the summoner's action animation, then spawns
## creatures on summonable tiles connected to the summoner's position
## (flood-fill bounded by summon_radius, so summons stay in the same room).
## Composition — creature, effect, counts, cooldown, animation, sfx — is
## configured per summoner. R-43 room markers supersede tile scanning.

const CELL_NEIGHBORS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

@export var chase_state: State
@export var summoned_creature: PackedScene
@export var summon_effect: PackedScene
## Seconds the materialize effect plays before the creature appears, so the
## spawn is telegraphed instead of instant.
@export var spawn_delay := 0.5
## Search radius around the summoner, in tiles.
@export var summon_radius := 5
@export var min_summons := 2
@export var max_summons := 5
## Seconds before this summoner may summon again; 0 disables the cooldown
## (roll-gated summoners such as the boss).
@export var summon_cooldown_duration := 10.0
@export var summon_animation := "Summon"
@export var summon_sfx: AudioStreamPlayer2D

var enemy: BaseEnemy
var _summon_cooldown: Timer

func _ready() -> void:
	enemy = actor
	_summon_cooldown = Timer.new()
	_summon_cooldown.one_shot = true
	add_child(_summon_cooldown)

func validate_exports() -> void:
	# summon_sfx is optional; the rest is mandatory, checked here because the
	# base assigned-check would also reject the optional sfx.
	if chase_state == null:
		push_error("%s: chase_state is not assigned" % get_path())
	if summoned_creature == null:
		push_error("%s: summoned_creature is not assigned" % get_path())
	if summon_effect == null:
		push_error("%s: summon_effect is not assigned" % get_path())

func enter() -> void:
	if _summon_cooldown.is_stopped() and not enemy.is_dead:
		if await enemy.run_action_animation(summon_animation, summon_sfx):
			_spawn_creatures()
		if summon_cooldown_duration > 0.0:
			_summon_cooldown.start(summon_cooldown_duration)

	transition_to(chase_state)

func _spawn_creatures() -> void:
	var tilemap_layer = _find_tilemap_layer()
	if tilemap_layer == null:
		push_error("%s: no TileMapLayer found for summon placement" % get_path())
		return

	var summon_count = randi_range(min_summons, max_summons)
	var positions = _get_valid_summon_positions(summon_count, tilemap_layer)

	if positions.size() < summon_count:
		push_warning("Found only %d valid summon positions." % positions.size())

	for position in positions:
		_spawn_summon(position, summoned_creature)

## Spawns the materialize effect, then the creature after spawn_delay.
## Fire-and-forget coroutine: callers schedule whole sets at once while each
## creature materializes after its own telegraph. A dead summoner cancels.
func _spawn_summon(position: Vector2, creature: PackedScene) -> void:
	if summon_effect:
		var effect = summon_effect.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = position

	await get_tree().create_timer(spawn_delay).timeout
	if enemy.is_dead:
		return

	var instance = creature.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = position

## Flood-fills from the summoner's cell through connected summonable tiles,
## bounded by the summon radius, so spawns cannot land across walls.
func _get_valid_summon_positions(max_count: int, tilemap: TileMapLayer) -> Array:
	var radius_px := float(summon_radius * tilemap.tile_set.tile_size.x)
	var radius_sq := radius_px * radius_px
	var start: Vector2i = tilemap.local_to_map(tilemap.to_local(enemy.global_position))
	var visited := {start: true}
	var frontier: Array[Vector2i] = [start]
	var valid_positions: Array = []

	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_front()
		if _is_summonable_cell(cell, tilemap):
			var cell_world_pos: Vector2 = tilemap.map_to_local(cell)
			if enemy.global_position.distance_squared_to(cell_world_pos) <= radius_sq:
				valid_positions.append(cell_world_pos)
				_enqueue_neighbors(cell, visited, frontier)
		elif cell == start:
			# The summoner may stand on a non-summonable cell; explore outward anyway.
			_enqueue_neighbors(cell, visited, frontier)

	valid_positions.shuffle()
	return valid_positions.slice(0, mini(max_count, valid_positions.size()))

func _enqueue_neighbors(cell: Vector2i, visited: Dictionary, frontier: Array[Vector2i]) -> void:
	for offset in CELL_NEIGHBORS:
		var next: Vector2i = cell + offset
		if not visited.has(next):
			visited[next] = true
			frontier.append(next)

func _is_summonable_cell(cell: Vector2i, tilemap: TileMapLayer) -> bool:
	# Tilesets without the layer (e.g. the boss room until its remake) skip cleanly.
	var tile_set = tilemap.tile_set
	if tile_set == null or tile_set.get_custom_data_layer_by_name("is_summonable") == -1:
		return false
	var tile_data: TileData = tilemap.get_cell_tile_data(cell)
	return tile_data != null and tile_data.get_custom_data("is_summonable")

func _find_tilemap_layer() -> TileMapLayer:
	var scene_root = get_tree().current_scene
	for child in scene_root.get_children():
		if child is TileMapLayer:
			return child
		# Legacy TileMap wrappers (R-40 debt) hold the layers one level deeper.
		for grandchild in child.get_children():
			if grandchild is TileMapLayer:
				return grandchild
	return null
