extends BaseEnemy

## Boss body on the enemy framework: non-interruptible (hits flash + damage
## only), with the phase-2 gate here. Fight choreography lives in the state
## bundle (Engage/Cast pickers plus the attack states); she engages from spawn.

@export var phase_transition_hp := 75
## Seconds of yellow flash + double damage after a parry.
@export var expose_duration := 3.0

var phase2 = false
var is_glide = false
var exposed = false
var _expose_id := 0

@onready var flash_player: AnimationPlayer = $FlashPlayer
@onready var slide_hitbox: EnemyHitbox = $"Slide Hitbox"

## Phase-2 gate shared by the Engage/Cast pickers.
func should_transition_phase() -> bool:
	return hp <= phase_transition_hp and not phase2

## A live slide hitbox must not survive into the death animation.
func kill():
	_expose_id += 1
	exposed = false
	_reset_flash()
	slide_hitbox.set_active(false)
	super()

## Parry response: a vulnerable window instead of a stun — she flashes yellow
## and takes double damage while attacks keep flowing.
func stun() -> void:
	if is_dead:
		return
	begin_exposure(expose_duration)

## Vulnerable window: yellow pulse + doubled damage. Used by the parry and the
## beam's recovery timeout. Nothing interrupts her attacks.
func begin_exposure(duration: float) -> void:
	_expose_id += 1
	var id = _expose_id
	exposed = true
	flash_player.play("Vulnerable")
	await get_tree().create_timer(duration).timeout
	if id != _expose_id:
		return
	exposed = false
	_reset_flash()

## Restores the flash material after a looping vulnerable animation.
func _reset_flash() -> void:
	flash_player.stop()
	var material := ($Sprite2D as Sprite2D).material as ShaderMaterial
	material.set_shader_parameter("flash_color", Color.WHITE)
	material.set_shader_parameter("flash_value", 0.0)

func take_damage(dmg: int, from_position: Vector2 = Vector2.INF) -> void:
	if exposed:
		dmg *= 2
	super(dmg, from_position)

## Parallel flash channel: action animations keep playing through hits. A hit
## during a vulnerable window interrupts the pulse and then resumes it.
func _play_hit_flash() -> void:
	flash_player.play("OnHit")
	await flash_player.animation_finished
	if exposed and not is_dead:
		flash_player.play("Vulnerable")

func handle_animations() -> void:
	# Her only locomotion animation is the glide loop; walking plays Idle.
	if is_glide:
		animation_player.play("Move")
	elif velocity.length() > 0:
		animation_player.play("Idle")

	if abs(velocity.x) > FLIP_THRESHOLD:
		if velocity.x < 0:
			$Sprite2D.scale.x = -1
		else:
			$Sprite2D.scale.x = 1

		last_velocity_x = velocity.x