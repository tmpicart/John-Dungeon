extends Node

## Walk-flip battery for the chase probe. The confirm window is a
## BaseEnemy mechanism, so the oscillation stages suspend the skeleton's
## own physics and drive handle_animations directly with crafted lateral
## velocities - real flows cannot reproduce a per-tick sign alternation
## on demand. Lives on its own node so the main probe stays under the
## line-count gate; assertions report through the parent.

const JITTER_SPEED := 8.0
const JITTER_TICKS := 30
## A held turn must land within this many ticks of opposite velocity;
## six ticks at 60 Hz clears the 0.08s confirm window with one to spare.
const CONFIRM_TICKS := 6

var probe: Node

var _skeleton: BaseEnemy


func run() -> void:
	probe._player.global_position = Vector2(232, 24)
	_skeleton = await probe._spawn_enemy(
			probe.SKELETON_SCENE, Vector2(24, 140))
	# The sprite mechanism under test: suspend the body's own tick so
	# the crafted velocities reach handle_animations verbatim.
	_skeleton.set_physics_process(false)
	await _stage_alternation_never_confirms()
	await _stage_held_turn_confirms_once()
	await _stage_face_toward_commits()
	await probe._teardown()
	await get_tree().physics_frame


func _stage_alternation_never_confirms() -> void:
	probe._tee("  stage: alternating lateral jitter never flips the sprite")
	var sprite: Sprite2D = _skeleton.get_node("Sprite2D")
	var start_sign := signf(sprite.scale.x)
	var step := get_physics_process_delta_time()
	for i in JITTER_TICKS:
		var side := 1.0 if i % 2 == 0 else -1.0
		_skeleton.velocity = Vector2(side * start_sign * JITTER_SPEED, 0)
		_skeleton.handle_animations(step)
	probe._check(signf(sprite.scale.x) == start_sign,
			"alternating lateral velocity never flips the sprite")


func _stage_held_turn_confirms_once() -> void:
	probe._tee("  stage: a held turn flips exactly once, inside the window")
	var sprite: Sprite2D = _skeleton.get_node("Sprite2D")
	var start_sign := signf(sprite.scale.x)
	var push := -start_sign * JITTER_SPEED
	var step := get_physics_process_delta_time()
	var flips := 0
	var last_sign := start_sign
	for i in CONFIRM_TICKS + 4:
		_skeleton.velocity = Vector2(push, 0)
		_skeleton.handle_animations(step)
		var live := signf(sprite.scale.x)
		if live != last_sign:
			flips += 1
			last_sign = live
	probe._check(flips == 1, "held opposite velocity flips exactly once")


func _stage_face_toward_commits() -> void:
	probe._tee("  stage: face_toward commits, the walk flip resumes from it")
	var sprite: Sprite2D = _skeleton.get_node("Sprite2D")
	var step := get_physics_process_delta_time()
	var held := signf(sprite.scale.x)
	var other := -held
	_skeleton.face_toward(
			_skeleton.global_position + Vector2(other * 40.0, 0))
	probe._check(signf(sprite.scale.x) == other,
			"face_toward lands the sprite on the point's side")
	for i in 4:
		_skeleton.velocity = Vector2(held * JITTER_SPEED, 0)
		_skeleton.handle_animations(step)
	probe._check(signf(sprite.scale.x) == other,
			"sub-confirm ticks on the old side never snap the sprite back")
	var flips := 0
	var last_sign := other
	for i in CONFIRM_TICKS + 4:
		_skeleton.velocity = Vector2(held * JITTER_SPEED, 0)
		_skeleton.handle_animations(step)
		var live := signf(sprite.scale.x)
		if live != last_sign:
			flips += 1
			last_sign = live
	probe._check(flips == 1, "held turn after face_toward flips exactly once")