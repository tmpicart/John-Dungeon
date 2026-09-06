extends CanvasLayer

const WALK_AWAY_DISTANCE := 140.0

var page = 0
var active = false
var spoke = false
var _anchor := Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("Player")
var textFile = ""
var dialogue = []
# Called when the node enters the scene tree for the first time.
func _ready():
	$NinePatchRect.visible = false

func load_file():
	var file = FileAccess.open(textFile, FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "":
			dialogue.append(line)
	file.close()

func talk():
	if active:
		page += 1
		if page >= len(dialogue):
			spoke = true
			_close()
			return
		$NinePatchRect/text.text = dialogue[page]
	else:
		load_file()
		active = true
		_anchor = get_parent().global_position
		$NinePatchRect.visible = true
		$NinePatchRect/text.text = dialogue[page]

func _process(_delta: float) -> void:
	if not active:
		return
	var walker: Node2D = Global.player
	if walker == null or walker.global_position.distance_to(_anchor) > WALK_AWAY_DISTANCE:
		_close()

func _close() -> void:
	active = false
	page = 0
	$NinePatchRect.visible = false

