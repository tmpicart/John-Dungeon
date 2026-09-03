extends HBoxContainer

var _last_hp := 0

@onready var heart_scene = preload("res://ui/heart.tscn")

## Resizes the bar to max_hp in either direction and repaints it.
func set_max_health(max_hp: int):
	while get_child_count() < max_hp:
		add_child(heart_scene.instantiate())
	for heart in get_children().slice(max_hp):
		heart.queue_free()
	update(_last_hp)

## Repaints the hearts for the given HP: filled up to it, empty after.
func update(current_hp: int):
	_last_hp = current_hp
	var hearts = get_children()
	for i in hearts.size():
		hearts[i].update(i < current_hp)
