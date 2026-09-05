extends Node2D
class_name PlayerCombat

# Signals
signal hp_changed(current_hp: int)
signal max_hp_changed(max_hp: int)

# Aiming: the reflect-target lock picks the enemy nearest the cursor
# (the reticle) within aim_snap_radius.
@export var aim_snap_radius := 120.0

# Combat-related nodes
@onready var weapon: Node = $Weapon
@onready var shield: Node = $Shield
@onready var ouch_sfx: AudioStreamPlayer = $"../ouch_sfx"
@onready var animation = $"../PlayerAnimation"
@onready var hurtbox = $"../Hurtbox"
@onready var player = get_parent()

# Combat state
var damage: int = 0
var blocking: bool = false
var is_hit: bool = false
var is_dead: bool = false
var disabled: bool = false

# Health state
@export var max_hp: int = 3:
	set(value):
		max_hp = value
		max_hp_changed.emit(value)

var hp: int = 3

# Grab Camera2D node from the scene tree
@onready var camera: Camera2D = $"../Camera2D"


func _ready():
	damage = weapon.damage
	hp = max_hp
	max_hp_changed.emit(max_hp)
	hp_changed.emit(hp)

# --- Aiming ---
## Unit vector from the player toward the mouse cursor; the single source of
## aim truth for the parry cone and reflected-projectile targeting.
func aim_direction() -> Vector2:
	return (get_global_mouse_position() - player.global_position).normalized()

## The enemy the player is aiming at: the EnemyHurtbox surface nearest the
## cursor (the reticle), inside aim_snap_radius. Null when none — callers
## fall back to straight fire. Only callable from the physics step.
func get_aim_target() -> Node2D:
	var cursor := get_global_mouse_position()
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = aim_snap_radius
	query.shape = circle
	query.transform = Transform2D(0.0, cursor)
	query.collision_mask = 1 << 8 # EnemyHurtbox
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var best: Node2D = null
	var best_distance := INF
	for hit in get_world_2d().direct_space_state.intersect_shape(query):
		var surface := hit.collider as Area2D
		var enemy := surface.owner as BaseEnemy
		if enemy == null or enemy.is_dead:
			continue
		var distance := surface.global_position.distance_to(cursor)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best

# --- Combat ---
func attack():
	if is_dead or disabled:
		return
	weapon.enable_hitbox()
	await animation.play_attack()
	weapon.disable_hitbox()
	
func block():
	if blocking or is_dead or disabled:
		return
	blocking = true
	hurtbox.scale = Vector2(1.5, 1.5)
	await animation.play_block()
	hurtbox.scale = Vector2(1, 1)
	blocking = false

# --- Health / Damage ---
func take_damage(dmg: int):
	if is_hit or is_dead or disabled:
		return

	is_hit = true
	ouch_sfx.play()

	player.set_collision_layer_value(1, false)
	player.set_collision_mask_value(2, false)

	hp -= dmg
	hp_changed.emit(hp)
	
	if hp > 0:
		camera.frame_freeze(dmg)  # Call frame freeze on Camera2D
		await animation.play_hit()
	else:
		camera.frame_freeze(dmg*2)  # Call frame freeze on Camera2D
		kill()
	
	player.set_collision_layer_value(1, true)
	player.set_collision_mask_value(2, true)
	
	is_hit = false	
	
func heal(amount: int):
	if is_dead or disabled:
		return
	hp = clamp(hp + amount, 0, max_hp)
	hp_changed.emit(hp)

# --- Weapon upgrade ---
## Raises the weapon one level and resyncs the cached damage.
func upgrade_weapon() -> void:
	weapon.upgrade()
	damage = weapon.damage

# --- Death ---
func kill():
	is_dead = true
	animation.play_death()
	get_parent().on_player_death()

# --- Other ---
func set_disabled(value: bool):
	disabled = value
