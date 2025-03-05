extends State
class_name EnemySummon

@export var enemy: CharacterBody2D
@export var summoned_creature: PackedScene = null
@export var summon_effect: PackedScene = null
@export var aim: RayCast2D
@export var monster1_pos: RayCast2D
@export var monster2_pos: RayCast2D
@export var monster3_pos: RayCast2D

var on_cooldown = false
var positions = []
const DEG_TO_RAD = PI / 180

func Enter():
	_set_initial_ray_positions()
	if not on_cooldown:
		enemy.velocity = Vector2.ZERO
		await enemy.summon()
		ChangeState.emit(self, "EnemyRetreat")
	else: 
		print("ON COOLDOWN")
		ChangeState.emit(self, "EnemyAttack")
		
func _on_animation_player_animation_finished(animation):
	if animation == "Summon":
		positions = [
			_get_valid_position(monster1_pos),
			_get_valid_position(monster2_pos),
			_get_valid_position(monster3_pos)
		]
		
		print(positions)

		# Summon skeletons at valid positions
		for position in positions:
			if position != Vector2.INF:
				var effect = summon_effect.instantiate()
				get_tree().current_scene.add_child(effect)
				effect.global_position = position

				var skeleton = summoned_creature.instantiate()
				get_tree().current_scene.add_child(skeleton)
				skeleton.global_position = position

func _set_initial_ray_positions():
	monster1_pos.global_rotation = aim.global_rotation
	monster2_pos.global_rotation = aim.global_rotation + 45 * DEG_TO_RAD
	monster3_pos.global_rotation = aim.global_rotation - 45 * DEG_TO_RAD
	
	monster1_pos.force_raycast_update()
	monster2_pos.force_raycast_update()
	monster3_pos.force_raycast_update()

func _get_valid_position(ray: RayCast2D) -> Vector2:
	var original_rotation = ray.rotation
	for angle in range(0, 360, 10):
		ray.rotation = original_rotation + angle * DEG_TO_RAD
		ray.force_raycast_update()
		if not ray.is_colliding():
			return ray.global_position + ray.target_position.rotated(ray.rotation)
	return Vector2.INF
