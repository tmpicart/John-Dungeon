extends EnemyAttack
class_name EnemyAttackArcaneArcher

@export var projectile: PackedScene = null
@export var rayCast: RayCast2D

var can_attack = true

func Enter():
	# Common attack behavior from base class
	if can_attack and not enemy.is_hit:
		await enemy.attack()
		spawn_projectile()
		can_attack = false
		$attack_cooldown.start()
	ChangeState.emit(self, "EnemyChase")

func spawn_projectile():
	if projectile and not enemy.is_hit:
		var arrow = projectile.instantiate()
		get_tree().current_scene.add_child(arrow)
		arrow.add_to_group("Enemies")
		
		arrow.global_position = rayCast.global_position
		arrow.global_rotation = rayCast.global_rotation

func _on_attack_cooldown_timeout() -> void:
	can_attack = true
