@tool
extends TileMapLayer
## Fake outline for obstacle bricks. Offset silhouette copies drawn behind
## the layer produce the outer rim; 1px seam lines drawn on top mark shared
## edges between adjacent bricks. Rebuilds on every change (editor paint
## included), so no manual sync is needed.

const _OFFSETS: Array[Vector2i] = [
	Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1),
	Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
]

@export var outline_color := Color(0.07, 0.08, 0.12, 1.0)
@export_range(0, 2) var outline_thickness := .85

var _mirrors: Array[TileMapLayer] = []
var _seams: Array[Rect2] = []
var _seam_layer: Node2D


func _ready() -> void:
	for offset in _OFFSETS:
		var mirror := TileMapLayer.new()
		mirror.tile_set = tile_set
		mirror.show_behind_parent = true
		mirror.modulate = outline_color
		mirror.position = Vector2(offset) * float(outline_thickness)
		mirror.collision_enabled = false
		mirror.navigation_enabled = false
		add_child(mirror)
		_mirrors.append(mirror)
	_seam_layer = Node2D.new()
	add_child(_seam_layer)
	_seam_layer.draw.connect(_draw_seams)
	changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for mirror in _mirrors:
		mirror.clear()
		for cell in get_used_cells():
			var source := get_cell_source_id(cell)
			var atlas := get_cell_atlas_coords(cell)
			var alternative := get_cell_alternative_tile(cell)
			mirror.set_cell(cell, source, atlas, alternative)
	_rebuild_seams()
	_seam_layer.queue_redraw()


func _rebuild_seams() -> void:
	_seams.clear()
	var size := Vector2(tile_set.tile_size)
	var t := float(outline_thickness)
	for cell in get_used_cells():
		var base := Vector2(cell) * size
		if get_cell_source_id(cell + Vector2i.RIGHT) != -1:
			_seams.append(Rect2(base + Vector2(size.x - t, 0.0), Vector2(t, size.y)))
		if get_cell_source_id(cell + Vector2i.DOWN) != -1:
			_seams.append(Rect2(base + Vector2(0.0, size.y - t), Vector2(size.x, t)))


func _draw_seams() -> void:
	for rect in _seams:
		_seam_layer.draw_rect(rect, outline_color)
