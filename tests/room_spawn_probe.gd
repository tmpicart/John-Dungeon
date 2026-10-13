extends Node

## Real-room spawn-gate diagnostic: parks the necromancer along the north
## wall of levels/test_room.tscn and evaluates every volley muzzle gate
## from BOTH call contexts the game uses — a physics-frame context (what
## missile_probe exercises) and an idle/process-frame context (what the
## live attack flow uses: enter() awaits the AnimationPlayer
## animation_finished signal, whose default callback mode is idle). Per
## position and context it logs the clearance verdict, the raw
## intersect_shape hits with collider class/name, the body-to-muzzle ray
## verdict, the volley spawn count, and first-frame survival, so a
## divergence between contexts or between the live tilemap physics and the
## synthetic StaticBody stages names the live defect directly. Run:
## Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/room_spawn_probe.tscn
## Diagnostic, not assertions: always exits 0 after writing the result.

const ROOM_SCENE := "res://levels/test_room.tscn"
const NECRO_SCENE := "res://entities/enemies/necromancer/necromancer.tscn"
const STUB_SCRIPT := "res://tests/stub_player_body.gd"
const ROOM_CELL := 16.0
## Park sweep: row 0 body centers along the north wall band, including the
## alcove mouth columns (8-9, x 128-160).
const PARK_Y := 8.0
const PARK_XS: Array[float] = [72.0, 104.0, 136.0, 144.0, 152.0, 168.0, 200.0]
const STUB_AT := Vector2(120.0, 200.0)
const SURVIVAL_FRAMES := 5

var _log: FileAccess
var _necro: Node2D
var _attack_state: EnemyAttack
var _stub: CharacterBody2D
var _query_shape: CircleShape2D


func _ready() -> void:
	var result_path := ProjectSettings.globalize_path(
			"res://room_spawn_probe_result.txt")
	_log = FileAccess.open(result_path, FileAccess.WRITE)
	_tee("room_spawn_probe: start")
	_query_shape = CircleShape2D.new()
	_query_shape.radius = BaseEnemy.SPAWN_CLEARANCE_PX
	await _run()
	_tee("room_spawn_probe: done")
	_log.close()
	get_tree().quit(0)


func _tee(line: String) -> void:
	print(line)
	if _log != null:
		_log.store_line(line)


func _run() -> void:
	var room: Node = (load(ROOM_SCENE) as PackedScene).instantiate()
	add_child(room)
	for i in 2:
		await get_tree().physics_frame
	_stub = load(STUB_SCRIPT).new()
	_stub.add_to_group("Player")
	add_child(_stub)
	_stub.global_position = STUB_AT
	for i in 2:
		await get_tree().physics_frame
	_necro = (load(NECRO_SCENE) as PackedScene).instantiate()
	add_child(_necro)
	# Frozen: this probe drives the volley state directly.
	_necro.process_mode = Node.PROCESS_MODE_DISABLED
	_attack_state = _necro.get_node("State Control/EnemyAttack") as EnemyAttack
	await get_tree().physics_frame
	for park_x in PARK_XS:
		await _probe_position(Vector2(park_x, PARK_Y))
	_necro.queue_free()
	_stub.queue_free()
	await get_tree().physics_frame


func _probe_position(at: Vector2) -> void:
	_necro.global_position = at
	await get_tree().physics_frame
	_tee("-- park %s --" % at)
	await _sweep("idle")
	await _sweep("physics")


## Mirrors the live call-context split: the attack flow resumes on the
## idle-frame animation_finished signal; missile_probe resumes on
## physics_frame.
func _sweep(context: String) -> void:
	if context == "idle":
		await get_tree().process_frame
	else:
		await get_tree().physics_frame
	var space := _necro.get_world_2d().direct_space_state
	var all_blocked := true
	for offset in _attack_state.projectile_offsets:
		var muzzle: Vector2 = _necro.global_position + offset
		var clear: bool = _attack_state.enemy.spawn_point_clear(muzzle)
		all_blocked = all_blocked and not clear
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = _query_shape
		query.transform = Transform2D(0.0, muzzle)
		query.collision_mask = BaseEnemy.AIM_BLOCKING_MASK
		var hits := space.intersect_shape(query, 4)
		var names: Array[String] = []
		for hit in hits:
			var collider: Object = hit.get("collider")
			if collider is Node:
				names.append("%s:%s" % [collider.get_class(), (collider as Node).name])
			else:
				names.append(str(collider))
		var ray_clear: bool = _attack_state.enemy.aim_line_clear(
				_necro.global_position, muzzle)
		var cell := Vector2i((muzzle / ROOM_CELL).floor())
		_tee("  [%s] cell %s clear=%s ray_clear=%s hits=[%s]"
				% [context, cell, clear, ray_clear, ", ".join(names)])
	var spawned := _fire_and_count()
	for i in SURVIVAL_FRAMES:
		await get_tree().physics_frame
	var survived := 0
	for node in spawned:
		if is_instance_valid(node):
			survived += 1
			node.queue_free()
	_tee("  [%s] all_muzzles_blocked=%s volley spawned=%d survived=%d"
			% [context, all_blocked, spawned.size(), survived])


## Spawns one volley through the attack state and returns the newly added
## Enemies-group members (the probe reuses the group as its spawn ledger).
func _fire_and_count() -> Array:
	var before := get_tree().get_nodes_in_group("Enemies")
	_attack_state._spawn_projectiles()
	var added: Array = []
	for node in get_tree().get_nodes_in_group("Enemies"):
		if not before.has(node):
			added.append(node)
	return added