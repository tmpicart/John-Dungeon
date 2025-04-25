extends EnemyChase
class_name EnemyChaseNecromancer

@export var rayCast: RayCast2D
@export var summon_chance := 0.25

func Physics_Update(delta: float):
    if not navigation_agent or not player:
        return

    var to_player = player.global_position - enemy.global_position
    var distance = to_player.length()

    # Stop chasing and switch to idle if the player is too far
    if distance > chase_drop_distance:
        ChangeState.emit(self, "EnemyIdle")
        return
    
    # Switch to retreat state if the enemy is retreating
    if enemy.retreat and not enemy.is_hit:
        enemy.retreat = false
        ChangeState.emit(self, "EnemyRetreat")
        return

    # Attack or summon logic if the player is within attack range
    if distance <= attempt_attack_range:
        enemy.velocity = Vector2.ZERO  # Stop moving when in attack range

        var angle_to_player = to_player.angle()
        rayCast.global_rotation = angle_to_player

        if rayCast.is_colliding() and rayCast.get_collider() == player:
            if randf() < summon_chance:
                ChangeState.emit(self, "EnemySummon")
            else:
                ChangeState.emit(self, "EnemyAttack")
        return

    # If outside attack range, move towards the player
    time_since_last_path += delta
    if time_since_last_path >= path_update_interval:
        time_since_last_path = 0.0
        if distance > attempt_attack_range:  # Only set the target if outside attack range
            navigation_agent.target_position = player.global_position

    if navigation_agent.is_navigation_finished():
        return

    var next_position = navigation_agent.get_next_path_position()
    if next_position.is_zero_approx():
        return

    var path_direction = (next_position - enemy.global_position).normalized()
    enemy.velocity = path_direction * speed * delta
