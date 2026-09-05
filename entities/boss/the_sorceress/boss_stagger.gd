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
	# Freezing the main player holds her current frame; the yellow pulse rides
	# the FlashPlayer channel on top of it.
	boss.animation_player.stop()
	boss.begin_exposure(duration)
	await get_tree().create_timer(duration).timeout
	if boss.is_dead:
		return
	transition_to(return_state)

func exit() -> void:
	boss.stunned = false
