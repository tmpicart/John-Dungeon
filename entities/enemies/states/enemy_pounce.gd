extends State
class_name EnemyPounce

## Lunge attack: dashes toward the direction captured on entry for
## `pounce_duration`. Integrates movement itself (the base enemy skips
## move_and_slide while `attacking`) and emits `pounce_contact` on slide
## collisions so the owning enemy can react — the red slime explodes.

signal pounce_contact

@export var chase_state: State
## Pounce speed in px/s (physics-tick independent).
@export var pounce_speed := 133
@export var pounce_duration := 3.0

var direction := Vector2.ZERO
var enemy: BaseEnemy

func _ready() -> void:
	enemy = actor

func enter() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		direction = (player.global_position - enemy.global_position).normalized()

	enemy.attacking = true
	await get_tree().create_timer(pounce_duration).timeout

	enemy.attacking = false

	if enemy.is_dead:
		return

	transition_to(chase_state)

func physics_update(_delta: float) -> void:
	if enemy.is_dead:
		return

	enemy.velocity = direction * pounce_speed
	enemy.move_and_slide()
	if enemy.get_slide_collision_count() > 0:
		pounce_contact.emit()
