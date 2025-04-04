extends CharacterBody2D
class_name Character

const FRICTION: float = 200

# Custom Values
# walking
@export var acceleration: int = 350
@export var maxSpeed: int = 85
@export var dash_speed: float = 175 # Speed during dash
@export var deceleration := 400

# hp stuff/items yea
@export var maxHP: int = 6
@export var HP: int = 6

@export var coins: int = 5
@export var bombs: int = 5
@export var keys: int = 0
@export var potions: int = 1

#Signals (Hopefully self explanatory)
signal hp_changed # gonna be used for later with uh gui or something
signal maxHp_changed
signal bomb_changed
signal key_changed
signal coin_changed
signal potion_changed


#Onready's
@onready var healthbar = get_tree().get_first_node_in_group("health")
@onready var label = $Label
@onready var sprite:Sprite2D = get_node("CharSprite")
@onready var hurtBox:Hurtbox = get_node("Hurtbox")
#@onready var inventory = get_node("Inventory")
@onready var bombScene = preload("res://Scenes/Weapons/bomb.tscn")
@onready var weapon:Node2D = get_node("Weapon")
@onready var shield:Sprite2D = get_node("Shield")
@onready var damage = weapon.damage
@onready var dash_cooldown_timer = $"Dash Cooldown"


#other used variables
var mov_Direction:Vector2 = Vector2.ZERO
var blocking = false
var isDead = false
var isHit = false
var talking = false
var is_dashing: bool = false
var can_dash: bool = true

func _ready():
	label.hide()
# Update Items?
func upgradeWeapon():
	weapon.upgrade()
	damage = weapon.damage 
	
func spendCoin(amount: int):
	if coins >= amount:
		coins -= amount
		coin_changed.emit(coins)
		
func addCoin(add: int):
	coins+=add
	print(str(coins) + " coins")
	coin_changed.emit(coins)

func addKey():
	keys += 1
	key_changed.emit(keys)
	
func addPotion():
	potions += 1
	potion_changed.emit(potions)
	
func usePotion():
	if potions > 0:
		set_hp(HP + Global.potionHealing)
		potions -= 1
		potion_changed.emit(potions)
func useKey():
	if keys > 0:
		keys -= 1
		key_changed.emit(keys)
# Actions
func use_Bomb():
	if bombs > 0:
		var bomb = bombScene.instantiate()
		owner.add_child(bomb)
		bomb.player = self
		bomb.explode()
		bombs -= 1
		bomb_changed.emit(bombs)
		
func block():
	if blocking: # since events handled on _input use just_pressed
		return
	blocking = true
	await shield.Block()
	blocking = false

func parry():
	$reflect_sfx.play()
	
func take_damage(dmg:int):
	if isHit or blocking or isDead:
		return
	
	isHit = true
	if HP - dmg > 0:
		$OnHitPlayer.play("OnHit")
	else:
		kill()
	$ouch_sfx.play()
	set_hp(HP - dmg)
	var  invincibility_length = $OnHitPlayer.current_animation_length
	await get_tree().create_timer(invincibility_length).timeout
	isHit = false

func set_maxHP(amount:int):
	maxHP = amount
	maxHp_changed.emit(maxHP)
	set_hp(maxHP)

func set_hp(newHP):
	if newHP < maxHP:
		if newHP <= 0:
			HP = 0
		else:
			HP = newHP
	else:
		HP = maxHP
	hp_changed.emit(HP)
	
func kill():
	#print("Player Dead?")
	isDead = true
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
	mov_Direction = Vector2.ZERO
	
	# Get movement input only if not dead or talking
	if not (isDead or talking):
		mov_Direction = Vector2(
			Input.get_action_strength("right") - Input.get_action_strength("left"),
			Input.get_action_strength("down") - Input.get_action_strength("up")
		).normalized()
	
	# If dashing, temporarily override movement speed
	if is_dashing:
		# Dash movement (exceeding maxSpeed)
		velocity += mov_Direction * dash_speed * delta
	else:
		# Normal acceleration towards movement direction
		velocity += mov_Direction * acceleration * delta
		
		# Gradually slow down if exceeding maxSpeed
		if velocity.length() > maxSpeed:
			velocity = velocity.move_toward(mov_Direction * maxSpeed, deceleration * delta)
		elif velocity.length() > maxSpeed and !is_dashing:
			velocity = velocity.move_toward(mov_Direction * maxSpeed, deceleration * delta)

	# Apply friction so movement stops smoothly when no input is given
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)



func _physics_process(delta):
	move_and_slide()
	move(delta)
	#print(velocity)
	
	#rotation based facing
	var mouse_position = get_global_mouse_position()		
	var direction = mouse_position - global_position
	var angle = direction.angle()	
	
	if not isDead and not is_dashing:
		
		if velocity.length() < 1:  # If the player is not moving (idle)
			if abs(angle) < PI / 4:
				shield.Right()
				$AnimationPlayer.play("Right")
			elif abs(angle) > 3 * PI / 4:
				shield.Left()
				$AnimationPlayer.play("Left")
			elif angle > 0:
				shield.Down()
				$AnimationPlayer.play("Down")
			else:
				shield.Up()
				$AnimationPlayer.play("Up")
		else:  # If the player is moving
			if not $walk_sfx.playing:
				$walk_sfx.play()
				
			if abs(angle) < PI / 4:
				shield.Right()
				$AnimationPlayer.play("Right_Move")
			elif abs(angle) > 3 * PI / 4:
				shield.Left()
				$AnimationPlayer.play("Left_Move")
			elif angle > 0:
				shield.Down()
				$AnimationPlayer.play("Down_Move")
			else:
				shield.Up()
				$AnimationPlayer.play("Up_Move")
		
func dash():
	if can_dash and not isDead and not talking and mov_Direction != Vector2.ZERO:
		can_dash = false
		is_dashing = true
		velocity = mov_Direction.normalized() * dash_speed  # Apply dash speed\
		
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
		
		if not isDead:
			shield.show()
			weapon.show()
		dash_cooldown_timer.start()

func _on_dash_cooldown_timeout():
	can_dash = true  # Reset dash availability when cooldown ends
		
func _input(event):
	if (isDead or talking): #Can't Perform Actions if dead
		if event.is_action_pressed("quit"):
			get_tree().change_scene_to_file("res://Scenes/Hud/MainMenu.tscn")
		return
	if event.is_action_pressed("potion"):
		usePotion()
		print(HP)
	if event.is_action_pressed("attack"):
		weapon.ATTACK()
		#upgradeWeapon() #This was here for testing
	if event.is_action_pressed("quit"):
		get_tree().quit()
	if event.is_action_pressed("block"):
		block()
	if event.is_action_pressed("bomb"):
		use_Bomb()
	if event.is_action_pressed("dash"):
		dash()
