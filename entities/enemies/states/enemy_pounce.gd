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
## Ticked in physics_update instead of a scene-tree timer await: the state
## node can be freed mid-pounce (the red slime's contact explosion), and a
## pending tree timer would resume into the freed instance.
var _pounce_clock := 0.0

func _ready() -> void:
	enemy = actor

func enter() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		direction = (player.global_position - enemy.global_position).normalized()

	_pounce_clock = 0.0
	enemy.attacking = true

func physics_update(delta: float) -> void:
	if enemy.is_dead:
		return

	_pounce_clock += delta
	if _pounce_clock >= pounce_duration:
		enemy.attacking = false
		transition_to(chase_state)
		return

	enemy.velocity = direction * pounce_speed
	enemy.move_and_slide()
	if enemy.get_slide_collision_count() > 0:
		pounce_contact.emit()
