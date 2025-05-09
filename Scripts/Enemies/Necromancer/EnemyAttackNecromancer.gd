extends EnemyAttack
class_name EnemyAttackNecromancer

@export var projectile: PackedScene = null
@export var rayCast: RayCast2D

var can_attack = true

func Enter():
	# Common attack behavior from base class
	if can_attack:
		await enemy.attack()
		can_attack = false
		$attack_cooldown.start()
	
	ChangeState.emit(self, "EnemyChase")

func spawn_projectiles():
	if projectile and not enemy.is_dead:
		var offsets = [Vector2(-15, -25), Vector2(0, -30), Vector2(15, -25)]
		for offset in offsets:
			var proj = projectile.instantiate()
			get_tree().current_scene.add_child(proj)
			proj.add_to_group("Enemies")
			proj.global_position = enemy.global_position + offset
			proj.global_rotation = rayCast.global_rotation

func _on_attack_cooldown_timeout() -> void:
	can_attack = true

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Attack":
		spawn_projectiles()
