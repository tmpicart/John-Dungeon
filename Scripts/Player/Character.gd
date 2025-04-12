extends CharacterBody2D
class_name Character

const FRICTION: float = 200

# Custom Values
# Walking
@export var acceleration: int = 500
@export var max_speed: int = 85
@export var dash_speed: float = 175 # Speed during dash
@export var deceleration := 400

# HP stuff/items
@export var max_hp: int = 3
@export var hp: int = 3

@export var coins: int = 5
@export var bombs: int = 5
@export var keys: int = 0
@export var potions: int = 1

# Signals (Hopefully self explanatory)
signal hp_changed
signal max_hp_changed
signal bombs_changed
signal keys_changed
signal coins_changed
signal potions_changed

# Onready's
@onready var healthbar = get_tree().get_first_node_in_group("health")
@onready var label = $Label
@onready var sprite: Sprite2D = get_node("CharSprite")
@onready var hurtbox: PlayerHurtbox = get_node("Hurtbox")
# @onready var inventory = get_node("Inventory")
@onready var bomb_scene = preload("res://Scenes/Weapons/bomb.tscn")
@onready var weapon: Node2D = get_node("Weapon")
@onready var shield: Sprite2D = get_node("Shield")
@onready var damage = weapon.damage
@onready var dash_cooldown_timer = $"Dash Cooldown"

# Other used variables
var mov_direction: Vector2 = Vector2.ZERO
var blocking = false
var is_dead = false
var is_hit = false
var talking = false
var is_dashing: bool = false
var can_dash: bool = true

func _ready():
	label.hide()

# Update Items?
func upgrade_weapon():
	weapon.upgrade()
	damage = weapon.damage 

func spend_coin(amount: int):
	if coins >= amount:
		coins -= amount
		coins_changed.emit(coins)

func add_coin(add: int):
	coins += add
	print(str(coins) + " coins")
	coins_changed.emit(coins)

func add_key():
	keys += 1
	keys_changed.emit(keys)

func add_potion():
	potions += 1
	potions_changed.emit(potions)

func use_potion():
	if potions > 0:
		set_hp(hp + Global.potion_healing)
		potions -= 1
		potions_changed.emit(potions)

func use_key():
	if keys > 0:
		keys -= 1
		keys_changed.emit(keys)

# Actions
func use_bomb():
	if bombs > 0:
		var bomb = bomb_scene.instantiate()
		owner.add_child(bomb)
		bomb.player = self
		bomb.explode()
		bombs -= 1
		bombs_changed.emit(bombs)

func block():
	if blocking:
		return
	blocking = true
	await shield.block()
	blocking = false

func parry():
	$reflect_sfx.play()

func take_damage(dmg: int):
	if is_hit or is_dead:
		return
	
	is_hit = true
	frame_freeze()
	
	if hp - dmg > 0:
		$OnHitPlayer.play("OnHit")
	else:
		kill()
		
	$ouch_sfx.play()
	set_hp(hp - dmg)
	var invincibility_length = $OnHitPlayer.current_animation_length
	await get_tree().create_timer(invincibility_length).timeout
	is_hit = false

func set_max_hp(amount: int):
	max_hp = amount
	max_hp_changed.emit(max_hp)
	set_hp(max_hp)

func set_hp(new_hp):
	if new_hp < max_hp:
		if new_hp <= 0:
			hp = 0
		else:
			hp = new_hp
	else:
		hp = max_hp
	hp_changed.emit(hp)

func kill():
	is_dead = true
	acceleration = 0
	weapon.hide()
	shield.hide()
	$AnimationPlayer.stop()
	$OnHitPlayer.play("Death_Roll")
	label.show()
	await get_tree().create_timer($OnHitPlayer.current_animation_length).timeout
	$OnHitPlayer.play("Death")

# Movement Stuff
func move(delta):
	mov_direction = Vector2.ZERO
	
	# Get movement input only if not dead or talking
	if not (is_dead or talking):
		mov_direction = Vector2(
			Input.get_action_strength("right") - Input.get_action_strength("left"),
			Input.get_action_strength("down") - Input.get_action_strength("up")
		).normalized()
	
	# If dashing, temporarily override movement speed
	if is_dashing:
		# Dash movement (exceeding max_speed)
		velocity += mov_direction * dash_speed * delta
	else:
		# Normal acceleration towards movement direction
		velocity += mov_direction * acceleration * delta
		
		# Gradually slow down if exceeding max_speed
		if velocity.length() > max_speed:
			velocity = velocity.move_toward(mov_direction * max_speed, deceleration * delta)
		elif velocity.length() > max_speed and !is_dashing:
			velocity = velocity.move_toward(mov_direction * max_speed, deceleration * delta)

	# Apply friction so movement stops smoothly when no input is given
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

func _physics_process(delta):
	move_and_slide()
	move(delta)
	
	# Rotation based on facing
	var mouse_position = get_global_mouse_position()		
	var direction = mouse_position - global_position
	var angle = direction.angle()	
	
	if not is_dead and not is_dashing:
		if velocity.length() < 1:  # If the player is not moving (idle)
			if abs(angle) < PI / 4:
				shield.right()
				$AnimationPlayer.play("Right")
			elif abs(angle) > 3 * PI / 4:
				shield.left()
				$AnimationPlayer.play("Left")
			elif angle > 0:
				shield.down()
				$AnimationPlayer.play("Down")
			else:
				shield.up()
				$AnimationPlayer.play("Up")
		else:  # If the player is moving
			if not $walk_sfx.playing:
				$walk_sfx.play()
				
			if abs(angle) < PI / 4:
				shield.right()
				$AnimationPlayer.play("Right_Move")
			elif abs(angle) > 3 * PI / 4:
				shield.left()
				$AnimationPlayer.play("Left_Move")
			elif angle > 0:
				shield.down()
				$AnimationPlayer.play("Down_Move")
			else:
				shield.up()
				$AnimationPlayer.play("Up_Move")

func dash():
	if can_dash and not is_dead and not talking and mov_direction != Vector2.ZERO:
		can_dash = false
		is_dashing = true
		velocity = mov_direction.normalized() * dash_speed  # Apply dash speed
		
		$dash_sfx.play()
		
		shield.hide()
		weapon.hide()
		
		if velocity.x > 0:
			$AnimationPlayer.play("Right_Dash")  # Play the right dash animation
		elif velocity.x < 0:
			$AnimationPlayer.play("Left_Dash")  # Play the left dash animation
		elif velocity.y > 0:
			$AnimationPlayer.play("Down_Dash")  # Play the down dash animation
		else:
			$AnimationPlayer.play("Up_Dash")  # Play the up dash animation
		
		# Wait for the dash duration
		await get_tree().create_timer($AnimationPlayer.current_animation_length).timeout
	
		is_dashing = false
	
		if not is_dead:
			shield.show()
			weapon.show()
			
			dash_cooldown_timer.start()

func _on_dash_cooldown_timeout():
	can_dash = true  # Reset dash availability when cooldown ends

func _input(event):
	if is_dead or talking:  # Can't perform actions if dead
		if event.is_action_pressed("quit"):
			get_tree().change_scene_to_file("res://Scenes/Hud/MainMenu.tscn")
		return
		
	if event.is_action_pressed("potion"):
		use_potion()
		print(hp)
	if event.is_action_pressed("attack"):
		weapon.attack()
	if event.is_action_pressed("quit"):
		get_tree().quit()
	if event.is_action_pressed("block"):
		block()
	if event.is_action_pressed("bomb"):
		use_bomb()
	if event.is_action_pressed("dash"):
		dash()

func get_facing_direction() -> Vector2:
	var mouse_pos = get_global_mouse_position()
	return (mouse_pos - global_position).normalized()

# Time-slow function
func timeslow(multiplier: int = 1):
	print("Starting timeslow")

	# Set duration and target scale based on multiplier
	var target_scale := 0.25 * multiplier  # Decrease time more for higher multiplier
	var duration := 0.35 * multiplier     # Shorten duration for higher multiplier

	# Apply time scale directly (no need for tweening)
	Engine.time_scale = target_scale

	# Create a Timer node to wait for the specified duration
	var timer := Timer.new()
	add_child(timer)  # Add the Timer node to the scene tree
	timer.wait_time = duration  # Set the duration for the timer
	timer.one_shot = true  # Ensure the timer only runs once

	# Start the timer
	timer.start()

	# Wait until the timer is done
	await timer.timeout

	print("Returning to normal speed")

	# Restore time scale to normal
	Engine.time_scale = 1.0

func frame_freeze(multiplier: int = 1):
	print("Starting frame freeze")

	# ==== Settings ====
	var target_scale := 0.5 * multiplier
	var duration := 0.15 * multiplier
	var shake_strength := 2 * multiplier
	var shake_interval := 0.01  # Time interval for shake

	var camera := get_viewport().get_camera_2d()
	var original_position := camera.position if camera else Vector2.ZERO

	# Apply time scale (slowing the game down)
	Engine.time_scale = target_scale

	# Create timer that controls both freeze duration and shake interval
	var timer := Timer.new()
	timer.wait_time = shake_interval
	timer.one_shot = false  # Repeating every shake_interval
	add_child(timer)
	timer.start()

	var time_passed := 0.0
	while time_passed < duration:
		# Shake the camera if it exists
		if camera:
			var offset := Vector2(
				randf_range(-shake_strength, shake_strength),
				randf_range(-shake_strength, shake_strength)
			)
			camera.position = original_position + offset

		# Wait until the next shake interval
		await timer.timeout
		time_passed += shake_interval

	# Reset camera position back to original after shaking
	if camera:
		camera.position = original_position

	print("Returning to normal speed")

	# Restore normal time scale
	Engine.time_scale = 1.0
