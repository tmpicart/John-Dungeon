extends Node2D
class_name PickupItem

## Universal dropped-item root: desynced bob, fake-height ejection with
## bounces, and collection gating while in flight. scatter() is the shared
## entry point for chest loot and future monster drops.

signal settled

const MIN_BOUNCE_POP := 30.0

@export var sprite_path: NodePath = ^"../Sprite2D"
@export var bob_height := 1.5
@export var bob_time := 0.8
@export var loot_tier := 0
@export var loot_value := 1
@export var bounce_gravity := 320.0
@export var bounce_damping := 0.55
@export var ground_friction := 0.8
@export var pickup_delay := 0.4

var _sprite: Node2D
var _sprite_base_y := 0.0
var _velocity := Vector2.ZERO
var _height := 0.0
var _height_velocity := 0.0
var _flying := false
var _bob_tween: Tween

@onready var interaction_area: Interactable = get_node_or_null("InteractionArea")


func _ready() -> void:
	_sprite = get_node_or_null(sprite_path)
	if _sprite != null:
		_sprite_base_y = _sprite.position.y
	_start_bob()


## Chest / monster-drop entry point: random direction, speed and pop.
## Defaults spill toward the viewer (front hemisphere) so drops never hide
## behind the source; pass angle_spread = TAU for omnidirectional bursts.
func scatter(strength: float, angle_center: float = PI * 0.5, angle_spread: float = PI) -> void:
	var angle := angle_center + randf_range(-angle_spread * 0.5, angle_spread * 0.5)
	var speed := randf_range(strength * 0.6, strength)
	eject(Vector2.from_angle(angle) * speed, randf_range(90.0, 140.0))


## Explicit ejection: ground-plane velocity plus an upward pop speed.
## Height starts at zero so items rise out of the spawn point.
func eject(velocity: Vector2, pop: float) -> void:
	_velocity = velocity
	_height = 0.0
	_height_velocity = pop
	_flying = true
	_stop_bob()
	z_index = 1
	if _sprite != null:
		_sprite.position.y = _sprite_base_y
	_set_collection(false)


func _process(delta: float) -> void:
	if not _flying:
		return
	position += _velocity * delta
	_height_velocity -= bounce_gravity * delta
	_height += _height_velocity * delta
	if _height > 0.0:
		if _sprite != null:
			_sprite.position.y = _sprite_base_y - _height
		return
	# Ground contact: bounce on the fall speed or settle.
	_height = 0.0
	if -_height_velocity > MIN_BOUNCE_POP:
		_height_velocity = -_height_velocity * bounce_damping
		_velocity *= ground_friction
		if _sprite != null:
			_sprite.position.y = _sprite_base_y
	else:
		_settle()


func _settle() -> void:
	_flying = false
	_height = 0.0
	_height_velocity = 0.0
	_velocity = Vector2.ZERO
	z_index = 0
	if _sprite != null:
		_sprite.position.y = _sprite_base_y
	_start_bob()
	settled.emit()
	# Grace beat: let the drop read before it becomes collectable.
	var gate := create_tween()
	gate.tween_interval(pickup_delay)
	gate.tween_callback(_enable_collection)


func _enable_collection() -> void:
	_set_collection(true)


func _set_collection(value: bool) -> void:
	if interaction_area != null:
		interaction_area.enabled = value


func _start_bob() -> void:
	if _sprite == null or _bob_tween != null:
		return
	_bob_tween = _sprite.create_tween()
	_bob_tween.tween_interval(randf_range(0.0, bob_time))
	_bob_tween.tween_callback(_run_bob_loop)


func _run_bob_loop() -> void:
	if _sprite == null:
		return
	_bob_tween = _sprite.create_tween().set_loops()
	_bob_tween.tween_property(_sprite, "position:y", _sprite_base_y - bob_height, bob_time * 0.5) \
			.set_trans(Tween.TRANS_SINE)
	_bob_tween.tween_property(_sprite, "position:y", _sprite_base_y, bob_time * 0.5) \
			.set_trans(Tween.TRANS_SINE)


func _stop_bob() -> void:
	if _bob_tween != null:
		_bob_tween.kill()
		_bob_tween = null