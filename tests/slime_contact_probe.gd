extends Node

## Headless regression probe for the green slime's contact damage. Run:
## Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/slime_contact_probe.tscn
## Exits 0 on pass, 1 on failure. Real player and slime scenes are instanced
## cold: the contact hitbox must reach the player hurtbox at body contact,
## land through the PlayerHurtbox pipeline with i-frames holding inside the
## rearm cooldown, and re-tick once the cooldown elapses while the grind
## persists. The slime's state machine is frozen so the contact geometry,
## not pathing, owns the body pose.

const PLAYER_SCENE := "res://entities/player/character.tscn"
const SLIME_SCENE := "res://entities/enemies/slime_green/slime_green.tscn"
const FRAMES_TO_SETTLE := 5
## Lateral body-contact distance: player body capsule radius 4.0 plus the
## slime's 5.0 body circle. The probe parks the slime just outside contact
## so the overlap is pure hitbox/hurtbox reach at grinding range.
const CONTACT_OFFSET_X := 9.5

var _failures := 0
var _log: FileAccess
var _player: CharacterBody2D
var _slime: BaseEnemy


func _ready() -> void:
	var result_path := ProjectSettings.globalize_path("res://slime_contact_probe_result.txt")
	_log = FileAccess.open(result_path, FileAccess.WRITE)
	_tee("slime_contact_probe: start")
	await _run()
	_tee("slime_contact_probe: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	_log.close()
	get_tree().quit(0 if _failures == 0 else 1)


func _run() -> void:
	_player = (load(PLAYER_SCENE) as PackedScene).instantiate()
	add_child(_player)
	_player.global_position = Vector2(200, 150)
	_slime = (load(SLIME_SCENE) as PackedScene).instantiate()
	add_child(_slime)
	_slime.global_position = Vector2(320, 150)
	for i in FRAMES_TO_SETTLE:
		await get_tree().physics_frame
	_check(_player.combat.hp == 3, "player spawns at full health")
	# Freeze the chase so the contact geometry, not pathing, owns the pose.
	(_slime.get_node("State Control") as Node).set_physics_process(false)
	_slime.global_position = _player.global_position \
			+ Vector2(CONTACT_OFFSET_X, 0)
	await _wait_seconds(0.3)
	_check(_player.combat.hp == 2, "body contact lands one damage tick")
	await _wait_seconds(0.5)
	_check(_player.combat.hp == 2, "grind holds inside the rearm cooldown")
	await _wait_seconds(0.5)
	_check(_player.combat.hp == 1, "persistent grind re-ticks after the cooldown")
	_slime.queue_free()
	_player.queue_free()
	await get_tree().physics_frame


func _wait_seconds(duration: float) -> void:
	var clock := 0.0
	while clock < duration:
		await get_tree().physics_frame
		clock += get_physics_process_delta_time()


func _check(condition: bool, label: String) -> void:
	if condition:
		_tee("  ok   %s" % label)
	else:
		_failures += 1
		_tee("  FAIL %s" % label)


func _tee(line: String) -> void:
	print(line)
	_log.store_line(line)