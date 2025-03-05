extends CanvasLayer

var active = false

@onready var player = get_tree().get_first_node_in_group("Player")
var cost1 : int
var cost2 : int
var item1 : String
var item2 : String
var imgfile : String
var imgfile2 : String
var loaded = false
var upgrade = 1
var max1 : int
# Called when the node enters the scene tree for the first time.
func _ready():
	closeShop()
	#load_file()
	
func openShop():
	if !loaded:
		$GridContainer/Panel/RichTextLabel.text = item1
		$GridContainer/Panel/RichTextLabel2.text = $GridContainer/Panel/RichTextLabel2.text + str(cost1)
		$GridContainer/Panel2/RichTextLabel.text = item2
		$GridContainer/Panel2/RichTextLabel2.text = $GridContainer/Panel2/RichTextLabel2.text + str(cost2)
		$GridContainer/Panel/TextureRect.texture = load(imgfile)
		$GridContainer/Panel2/TextureRect.texture = load(imgfile2)
		loaded = true
	if $GridContainer.visible:
		closeShop()
		return
	$ColorRect.visible = true
	$GridContainer.visible = true
	$RichTextLabel.visible = true
	player.talking = true
	
func closeShop():
	$ColorRect.visible = false
	$GridContainer.visible = false
	$RichTextLabel.visible = false
	player.talking = false
	
func buyitem1():
	if player.coins >= cost1:
		player.spendCoin(cost1)
		get_parent().items1()
	
func buyitem2():
	if player.coins >= cost2:
		if upgrade < max1:
			upgrade += 1
			player.spendCoin(cost2)
			get_parent().items2()
		#player.maxHP += 1
		#player.HP += 1
		#player.coins -= cost2

func _input(event):
	if $GridContainer.visible:
		if event.is_action_pressed("buy1"):
			buyitem1()
		if event.is_action_pressed("buy2"):
			buyitem2()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
