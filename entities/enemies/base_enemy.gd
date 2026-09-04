extends CharacterBody2D
class_name BaseEnemy

## Base for all enemies: stats, signal-driven action flows, and interrupt routing.
## Interrupts (hit / parry-stun / death) cancel in-flight action flows via a flow
## token and hand control to the interrupt states (EnemyHurt / EnemyStun)
## through State Control via the typed state exports below.

const FLIP_THRESHOLD := 0.1

@export var hp: int = 1
@export var damage: int = 1
## Minimum seconds between attacks; 0 disables the cooldown.
@export var attack_cooldown_duration := 0.0
## Set when the attack sound is triggered by animation tracks, not by code.
@export var attack_sfx_from_animation := false
## Interrupt routing into the state machine (validated in _ready).
@export var state_control: StateControl
@export var hurt_state: State
@export var stun_state: State
## When false (bosses), hits deal damage + feedback only: no interrupt
## routing, no flow cancellation, and attacks continue through hits.
@export var interruptible := true

var attacking = false
var stunned = false
var is_dead = false
var is_hit = false
## Set on hit; consumed by EnemyChase when configured to retreat after damage.
var retreat_requested = false
## Position the last hit came from; consumed by the knockback pass (D-1).
var last_hit_from := Vector2.INF
var last_velocity_x := 0.0

## Bumped by every interrupt; async flows compare their token to detect staleness.
var _flow_id := 0
var _attack_cooldown: Timer

@onready var walk_sfx = $walk_sfx if has_node("walk_sfx") else null
@onready var attack_sfx = $attack_sfx if has_node("attack_sfx") else null
@onready var ouch_sfx = $ouch_sfx if has_node("ouch_sfx") else null
@onready var death_sfx = $death_sfx if has_node("death_sfx") else null
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
	_attack_cooldown = Timer.new()
	_attack_cooldown.one_shot = true
	add_child(_attack_cooldown)

	if state_control and interruptible and (hurt_state == null or stun_state == null):
		push_error("%s: state_control assigned but hurt_state/stun_state missing" % get_path())


func _physics_process(_delta):
	if is_dead or is_hit or attacking or stunned:
		return
	move_and_slide()
	handle_animations()

func handle_animations():
	if velocity.length() > 0:
		if animation_player.has_animation("Walk"):
			animation_player.play("Walk")
		if walk_sfx and not walk_sfx.playing:
			walk_sfx.play()
	else:
		if animation_player.has_animation("Idle"):
			animation_player.play("Idle")

	if abs(velocity.x) > FLIP_THRESHOLD:
		if velocity.x < 0:
			$Sprite2D.scale.x = -1
		else:
			$Sprite2D.scale.x = 1

		last_velocity_x = velocity.x

## Damage entry point (Hurtbox routes here). `from_position` is where the hit
## originated — stored for the knockback pass, not applied yet.
func take_damage(dmg: int, from_position: Vector2 = Vector2.INF) -> void:
	if is_dead:
		return

	if not interruptible:
		# Boss-style intake: feedback + damage only; nothing is cancelled or
		# routed, so movement and attacks continue through hits.
		if ouch_sfx:
			ouch_sfx.play()
		last_hit_from = from_position
		hp = max(hp - dmg, 0)
		_play_hit_flash()
		if hp == 0:
			kill()
		return

	if is_hit:
		return

	is_hit = true
	_cancel_flows()

	if stunned:
		dmg *= 2

	if ouch_sfx:
		ouch_sfx.play()

	last_hit_from = from_position
	hp = max(hp - dmg, 0)

	if hp == 0:
		kill()
		return

	retreat_requested = true

	if state_control:
		state_control.transition_to(hurt_state)
		return

	# No state machine attached: recover in place.
	await play_interrupt_animation("OnHit")
	is_hit = false


## Parry-stun entry point (called from PlayerHurtbox). Damage taken while
## stunned is doubled.
func stun() -> void:
	if is_dead or not interruptible:
		return

	_cancel_flows()

	if state_control:
		state_control.transition_to(stun_state)
		return

	# No state machine attached: recover in place.
	stunned = true
	await play_interrupt_animation("stun")
	stunned = false

func kill():
	if is_dead:
		return

	is_dead = true
	_cancel_flows()

	if animation_player.has_animation("Death"):
		animation_player.play("Death")
	if death_sfx:
		death_sfx.play()
	if animation_player.has_animation("Death"):
		await animation_player.animation_finished
	queue_free()


## Returns true when the attack completed; false when blocked or interrupted.
func attack() -> bool:
	if not can_attack():
		return false
	var sfx = null if attack_sfx_from_animation else attack_sfx
	var completed := await run_action_animation("Attack", sfx)
	if completed:
		start_attack_cooldown()
	return completed

func can_attack() -> bool:
	if attack_cooldown_duration <= 0.0:
		return true
	return _attack_cooldown.is_stopped()

func start_attack_cooldown() -> void:
	if attack_cooldown_duration > 0.0:
		_attack_cooldown.start(attack_cooldown_duration)

## Shared action flow: locks movement, plays the animation + sfx, and waits it
## out signal-driven. Returns false if an interrupt cancelled the flow.
func run_action_animation(anim_name: String, sfx: AudioStreamPlayer2D = null) -> bool:
	if attacking or is_dead or is_hit or stunned:
		return false

	attacking = true
	var flow = _flow_id

	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	if sfx:
		sfx.play()

	var completed := await _wait_for_animation(anim_name, flow)
	attacking = false
	return completed

## Plays an interrupt animation and waits it out signal-driven.
## Returns false if another interrupt took over while waiting.
func play_interrupt_animation(anim_name: String) -> bool:
	if not animation_player.has_animation(anim_name):
		return true

	await get_tree().process_frame
	animation_player.stop()
	animation_player.play(anim_name)
	return await _wait_for_animation(anim_name, _flow_id)

## Hit feedback for non-interruptible combatants. Silent by default; override
## to flash on a channel that does not cut action animations.
func _play_hit_flash() -> void:
	pass

func _cancel_flows() -> void:
	_flow_id += 1
	attacking = false

## Signal-driven wait for `anim_name` to finish. Returns false when the flow
## was superseded by an interrupt (token mismatch) instead of ending normally.
func _wait_for_animation(anim_name: String, flow: int) -> bool:
	while animation_player.current_animation != anim_name:
		if flow != _flow_id:
			return false
		await get_tree().process_frame

	var finished_name: StringName = await animation_player.animation_finished
	return flow == _flow_id and finished_name == anim_name

