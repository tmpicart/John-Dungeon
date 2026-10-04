extends Node

## Press-and-guard battery for the chase probe. One skeleton works the main
## probe's sealed-alcove pocket (an 8px sub-agency mouth channel the bake
## seals) through the guard lifecycle: the level-point press stalls and
## flips once, the guard engages and holds across the half-second repath
## cadence, sub-threshold player drift must not churn the hold, and
## dissolving the pocket body must release it - the fresh path ends at the
## player, the route-improvement latch stands down, and the chaser swings
## the moment the route lands. Lives on its own node so the main probe
## stays under the line-count gate; assertions report through the parent.

const SKELETON_SPAWN := Vector2(168, 120)
const PLAYER_SPOT := Vector2(198, 120)
const DRIFT_OFFSET := Vector2(5, -5)

var probe: Node

var _pocket_body: StaticBody2D


func run() -> void:
	_place_pocket()
	if not await _rebake("rebake with the sealed pocket"):
		_cleanup()
		await probe._teardown()
		return
	var skeleton: BaseEnemy = await probe._spawn_enemy(
			probe.SKELETON_SCENE, SKELETON_SPAWN)
	var chase: EnemyChase = probe._chase_state(skeleton)
	probe._force_chase(skeleton)
	probe._player.global_position = PLAYER_SPOT
	await _stage_engage_and_hold(chase)
	await _stage_drift_rejected(chase)
	_open_pocket()
	if not await _rebake("rebake with the pocket dissolved"):
		_cleanup()
		await probe._teardown()
		return
	await _stage_route_release(chase, skeleton)
	_cleanup()
	await probe._teardown()
	# Let the queue_freed fixtures land before the probe quits, or the
	# exit report counts them as leaked instances.
	await get_tree().physics_frame


## The main probe's sealed-alcove fixture: 8px sub-cells forming a pocket
## whose west mouth channel is 8px wide - narrower than twice the bake's
## agent radius, so the mesh seals the player inside.
func _place_pocket() -> void:
	_pocket_body = StaticBody2D.new()
	_pocket_body.collision_layer = probe.BLOCKER_MASK
	_pocket_body.collision_mask = 0
	var cells: Array[Vector2] = []
	for x in range(184, 240, 8):
		cells.append(Vector2(x, 104))
		cells.append(Vector2(x, 128))
	for y in range(112, 128, 8):
		cells.append(Vector2(184, y))
		cells.append(Vector2(232, y))
	cells.erase(Vector2(184, 120))  # the mouth channel
	for cell_origin in cells:
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(8, 8)
		shape_node.shape = shape
		shape_node.position = cell_origin + Vector2(4, 4)
		_pocket_body.add_child(shape_node)
	add_child(_pocket_body)


## Engagement: both level points sealed means flip once, then guard. The
## hold must survive the repath cadence with the player standing still.
func _stage_engage_and_hold(chase: EnemyChase) -> void:
	probe._tee("  stage: sealed press flips once, then guards without churn")
	var engaged := await _wait_until(
			func() -> bool: return chase._guarding, 8.0)
	probe._check(engaged, "sealed press engages the guard hold")
	if not engaged:
		return
	probe._check(chase._press_flipped, "guard engaged after the side flip")
	var releases := 0
	var clock := 0.0
	while clock < 2.5:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		if not chase._guarding:
			releases += 1
	probe._check(releases == 0, "guard holds across the repath cadence")


## Sub-threshold drift: each nudge stays under the retarget distance, but
## the repath cadence still re-queries, so a noise-sensitive latch would
## drop the hold here.
func _stage_drift_rejected(chase: EnemyChase) -> void:
	probe._tee("  stage: sub-threshold player drift cannot churn the guard")
	var base := PLAYER_SPOT
	var offset := Vector2.ZERO
	var releases := 0
	var clock := 0.0
	var step_clock := 0.0
	while clock < 2.0:
		await get_tree().physics_frame
		var step := get_physics_process_delta_time()
		clock += step
		step_clock += step
		if step_clock >= 0.35:
			step_clock = 0.0
			if offset == Vector2.ZERO:
				offset = DRIFT_OFFSET
			else:
				offset = Vector2.ZERO
			probe._player.global_position = base + offset
		if not chase._guarding:
			releases += 1
	probe._check(releases == 0, "hold survives sub-threshold drift")


## The pocket dissolves: the rebaked path ends at the player, the fresh
## final lands well inside the engaged distance, the latch stands down,
## and the in-range gate swings the moment the route lands.
func _stage_route_release(chase: EnemyChase, skeleton: BaseEnemy) -> void:
	probe._tee("  stage: dissolved pocket releases the guard and commits")
	var released := await _wait_until(
			func() -> bool: return not chase._guarding, 3.0)
	probe._check(released, "route improvement releases the guard")
	if not released:
		return
	var swung := await _wait_until(
			func() -> bool:
				return probe._current_state(skeleton) is EnemyAttack,
			6.0)
	probe._check(swung, "released chaser swings on the landed route")


## Free-before-frame-gap rebake (the main probe's ordering discipline),
## then wait until the mesh answers at the skeleton spawn.
func _rebake(label: String) -> bool:
	probe._remove_bake_artifacts()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var nav_layer: TileMapLayer = NavBaker.bake(probe)
	probe._check(nav_layer != null, label)
	if nav_layer == null:
		return false
	for i in 60:
		var closest := NavigationServer2D.map_get_closest_point(
				get_viewport().get_world_2d().navigation_map, SKELETON_SPAWN)
		if closest.distance_to(SKELETON_SPAWN) <= 2.0:
			for j in probe.FRAMES_TO_SETTLE:
				await get_tree().physics_frame
			return true
		await get_tree().physics_frame
	probe._check(false, "pocket mesh live at the skeleton spawn")
	return false


func _open_pocket() -> void:
	if is_instance_valid(_pocket_body):
		_pocket_body.queue_free()


func _cleanup() -> void:
	if is_instance_valid(_pocket_body):
		_pocket_body.queue_free()


func _wait_until(predicate: Callable, budget: float) -> bool:
	var clock := 0.0
	while clock < budget:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()
		if predicate.call():
			return true
	return false