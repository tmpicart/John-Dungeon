extends State

@export var enemy : CharacterBody2D
@export var collision_layer = 1
@export var beamCast : RayCast2D
@export var beam : Line2D
@export var rotation_speed : float = 6.0  # Adjust this value to control the tracking speed
@export var beam_damage = 2
@export var beam_recovery = 5
@onready var charge = $AudioStreamPlayer

var player : CharacterBody2D
var target_rotation : float = 0.0
var current_rotation : float = 0.0
var particles : GPUParticles2D

func Enter():
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if enemy is CharacterBody2D:
			beamCast.add_exception(enemy)
	
	print("Beam")
	enemy.velocity = Vector2.ZERO
	charge.play()
	await Global.time_in_seconds
	enemy.beam()
	player = get_tree().get_first_node_in_group("Player")
	particles = $"../../../BeamRaycast/GPUParticles2D"
	beamCast.enabled = true
	beam.visible = true
	appear()
	$beam_duration.start()

func _physics_process(_delta):
	
	if player:
		var raycast_start = enemy.global_position + Vector2(15, -80)
		var direction = (player.global_position - raycast_start).normalized()
		target_rotation = direction.angle()
		current_rotation = lerp_angle(current_rotation, target_rotation, rotation_speed * get_process_delta_time())
		beamCast.global_rotation = current_rotation
		update_laser()
		
func update_laser():
	
	particles.emitting = beamCast.is_colliding()
	
	if beamCast.is_colliding():
		var collision_point = beamCast.get_collision_point()
		beam.points = [Vector2.ZERO, beamCast.to_local(collision_point)]
		particles.global_rotation = beamCast.get_collision_normal().angle()
		particles.position = collision_point
		if beamCast.get_collider() == player:
			player.take_damage(beam_damage)

func lerp_angle(from, to, weight):
	var difference = (to - from + 180) % 360 - 180
	return (from + difference * weight) % 360

func _on_beam_duration_timeout():
	beamCast.enabled = false
	disappear()
	await get_tree().create_timer(beam_recovery).timeout
	beam.visible = false
	ChangeState.emit(self, "Cast")

	
func appear() -> void:
	var tween = create_tween()
	tween.tween_property($"../../../BeamRaycast/BeamLine", "width", 10.0, 2)

func disappear() -> void:
	var tween = create_tween()
	tween.tween_property($"../../../BeamRaycast/BeamLine", "width", 0, 1)
	
