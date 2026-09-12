extends Node2D
## Deterministic regression: loot scattered straight into obstacle bricks
## must settle on free ground, never inside an occupied cell. Seeded
## sweep over several scatter rolls in one process. Exit 0 = pass.

const SCATTER_STRENGTH := 60.0
const ITERATIONS := 6
const SEED_VALUE := 20260912
const MAX_SETTLE_FRAMES := 150
const MAX_SYNC_FRAMES := 30


func _ready() -> void:
	seed(SEED_VALUE)
	var room: Node2D = load("res://levels/test_room.tscn").instantiate()
	add_child(room)
	var obstacles: TileMapLayer = room.get_node("Obstacles")
	var cells := obstacles.get_used_cells()
	if cells.is_empty():
		print("PROBE FAIL: no obstacle cells painted")
		get_tree().quit(1)
		return
	# Spawn three cells above the first brick with free air, drop straight in.
	var spawn := Vector2i(-1, -1)
	for candidate in cells:
		var above := candidate + Vector2i(0, -3)
		if obstacles.get_cell_source_id(above) == -1:
			spawn = above
			break
	if spawn == Vector2i(-1, -1):
		print("PROBE FAIL: no free spawn cell above bricks")
		get_tree().quit(1)
		return
	var brick := spawn + Vector2i(0, 3)
	var spawn_pos := obstacles.to_global(Vector2(spawn) * 16.0 + Vector2(8.0, 8.0))
	var brick_pos := obstacles.to_global(Vector2(brick) * 16.0 + Vector2(8.0, 8.0))
	var item: PickupItem = load("res://entities/interactables/pickups/coin.tscn").instantiate()
	room.add_child(item)
	item.global_position = spawn_pos
	# TileMapLayer registers its collision quadrants a few frames after
	# entering the tree: poll until the space actually reports the target
	# brick before scattering, so the validation sees real geometry.
	var waited := 0
	while item._is_free(brick_pos) and waited < MAX_SYNC_FRAMES:
		await get_tree().physics_frame
		waited += 1
	if waited >= MAX_SYNC_FRAMES:
		print("PROBE FAIL: space never reported the brick")
		get_tree().quit(1)
		return
	for i in ITERATIONS:
		item.global_position = spawn_pos
		item.scatter(SCATTER_STRENGTH, PI * 0.5, 0.0)
		var frames := 0
		while item._flying and frames < MAX_SETTLE_FRAMES:
			await get_tree().physics_frame
			frames += 1
		if item._flying:
			print("PROBE FAIL: roll ", i, " never settled")
			get_tree().quit(1)
			return
		var landing := obstacles.local_to_map(obstacles.to_local(item.global_position))
		if obstacles.get_cell_source_id(landing) != -1:
			print("PROBE FAIL: roll ", i, " settled inside cell ", landing)
			get_tree().quit(1)
			return
	print("PROBE PASS: all ", ITERATIONS, " scattered rolls settled on free ground")
	get_tree().quit(0)
