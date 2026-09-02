extends Panel
class_name Slot


@export var itemName:String
@export var icon:Texture
@export var amount:int = 0

func updateSelf():
	if amount == 0:
		$Amount.visible = false
	if amount != null:
		$Amount.text = str(amount)
	if itemName != null:
		$ItemName.text = itemName
	if icon != null:
		$Texture.texture = icon
	
func _ready():
	updateSelf()

func _exit_tree():
	#Disconnect Signals to release memory
	pass
