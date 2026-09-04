extends Camera2D

const TIME_SCALE_DEFAULT := 1.0

@export var shake_duration_default := 0.3
@export var shake_strength_default := 4
@export var shake_interval_default := 0.005
@export var freeze_scale_default := 0.5

var shaking := false
var shake_strength := 0.0
var original_offset := Vector2.ZERO
var next_shake_time := 0.0
var current_shake_offset := Vector2.ZERO

## Bumped per freeze so a newer freeze supersedes an older restore.
var _freeze_flow_id := 0

func _ready():
	original_offset = offset

func _exit_tree():
	# A scene change mid-freeze would otherwise leave the game in slow motion.
	Engine.time_scale = TIME_SCALE_DEFAULT

func _process(delta: float):
	if shaking:
		next_shake_time -= delta
		if next_shake_time <= 0.0:
			# Only change shake offset at intervals
			current_shake_offset = Vector2(
				randf_range(-shake_strength, shake_strength),
				randf_range(-shake_strength, shake_strength)
			)
			next_shake_time = shake_interval_default
		offset = original_offset + current_shake_offset
	else:
		offset = original_offset

func frame_freeze(multiplier: int = 1) -> void:
	shake_strength = shake_strength_default * multiplier
	var shake_duration = shake_duration_default * multiplier
	var target_scale = freeze_scale_default * multiplier

	Engine.time_scale = target_scale
	shaking = true
	next_shake_time = 0.0  # Start shake immediately

	_freeze_flow_id += 1
	_start_shake_coroutine(shake_duration, _freeze_flow_id)

func _start_shake_coroutine(duration: float, flow_id: int) -> void:
	# ignore_time_scale: the unfreeze runs in real seconds even while frozen
	await get_tree().create_timer(duration, true, false, true).timeout
	if flow_id != _freeze_flow_id:
		return
	shaking = false
	Engine.time_scale = TIME_SCALE_DEFAULT

