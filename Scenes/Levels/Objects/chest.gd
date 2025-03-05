extends Node2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var Inv = []

const lines: Array[String] = [
	"Hey Im a Cheast!"
]

func _ready():
	interaction_area.interact = Callable(self, "_on_interact")
	
	
func _on_interact():
	print("Testing F")
