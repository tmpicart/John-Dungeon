extends CharacterBody2D
class_name Character

const FRICTION: float = 0.2

# Custom Values
@onready var healthbar = get_tree().get_first_node_in_group("health")
@onready var label = $Label
# walking
@export var acceleration: int = 50
@export var maxSpeed: int = 100
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
@onready var sprite:Sprite2D = get_node("CharSprite")
@onready var hurtBox:Hurtbox = get_node("Hurtbox")
#@onready var inventory = get_node("Inventory")
@onready var bombScene = preload("res://Scenes/Weapons/bomb.tscn")
@onready var weapon:Node2D = get_node("Weapon")
@onready var shield:Sprite2D = get_node("Shield")
@onready var damage = weapon.damage

#other used variables
var mov_Direction:Vector2 = Vector2.ZERO
var blocking = false
var isDead = false
var isHit = false
var talking = false

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
	var  invincibility_length = $OnHitPlayer.current_animation_length
	await get_tree().create_timer(invincibility_length).timeout
	set_hp(HP - dmg)
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
	weapon.visible = false
	shield.visible = false  
	$AnimationPlayer.stop()
	$OnHitPlayer.play("Death_Roll")
	label.show()
	await get_tree().create_timer($OnHitPlayer.current_animation_length).timeout
	$OnHitPlayer.play("Death")
	
	# NOTE: IF THE PLAYER DIES THE GAME WILL CLOSE LOL
	#queue_free() # apparently this will delete node after it can be
	
# Movement Stuff
func move():
	mov_Direction = Vector2.ZERO
	if not(isDead or talking):
		mov_Direction = Vector2(
			Input.get_action_strength("right") - Input.get_action_strength("left"),
			Input.get_action_strength("down") - Input.get_action_strength("up")
		).normalized()
	velocity += mov_Direction * acceleration
	velocity = velocity.limit_length(maxSpeed)
	velocity = lerp(velocity,Vector2.ZERO,FRICTION)
	
func _physics_process(_delta):
	# Character Move OverHere
	move_and_slide()
	move()
	
	#rotation based facing
	var mouse_position = get_global_mouse_position()		
	var direction = mouse_position - global_position
	var angle = direction.angle()	
	
	if not isDead:
		if velocity.length() < 1:
				
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
		else:
			if $walk_sfx.playing == false:
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
