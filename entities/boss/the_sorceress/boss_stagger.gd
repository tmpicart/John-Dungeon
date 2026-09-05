extends State

## Parry-stagger: the current animation freezes on the yellow pulse and she
## cannot act for the duration. Doubled damage during the window comes from
## the exposure opened on entry (same contract as EnemyStun, minus the anim).

@export var return_state: State
## Seconds she stays staggered (and exposed).
@export var duration := 3.0

var boss  # TheSorceress (velocity, stun flag, flash)

func _ready() -> void:
	boss = actor

func enter() -> void:
	boss.velocity = Vector2.ZERO
	boss.stunned = true
	# pause() holds her current frame and applies no track values; stop() seeks
	# to 0 and would write the animation's first-frame hitbox keys while the
	# parry's area signal is still inside the physics flush.
	boss.animation_player.pause()
	boss.begin_exposure(duration)
	await get_tree().create_timer(duration).timeout
	if boss.is_dead:
		return
	transition_to(return_state)

func exit() -> void:
	boss.stunned = false
	# Clears the pause and position so a repeat of the same attack animation
	# restarts from the top instead of resuming mid-swing.
	boss.animation_player.stop()
