extends Area2D
class_name Interactable

## Proximity interaction surface. Registers with the InteractionManager while
## the player overlaps it and `enabled` is true; the manager prompts for and
## triggers the nearest one. With `auto_pickup` the `interacted` signal fires
## on contact itself (no prompt, no keypress).

signal interacted

## Cache of measured opaque-frame bounds, keyed per texture and frame.
static var _used_rect_cache := {}

@export var prompt: String = ""
## Screen-space nudge applied after the prompt anchor (negative y = up).
## Anchoring itself is automatic — the prompt floats above the owner's
## visible sprites; without any, it anchors to the area origin. The
## InteractionManager adds its own gap above the anchor.
@export var prompt_offset: Vector2 = Vector2(0, 0)
@export var enabled: bool = true:
	set(value):
		enabled = value
		_refresh_registration()
@export var one_shot: bool = false
@export var auto_pickup: bool = false

var _in_range := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func try_interact() -> bool:
	if not enabled:
		return false
	if one_shot:
		enabled = false
	interacted.emit()
	return true


func _refresh_registration() -> void:
	if not enabled or not _in_range:
		InteractionManager.unregister_area(self)
	elif auto_pickup:
		# Re-check on enable: an item may settle on a standing player after
		# body_entered already fired while collection was gated.
		try_interact()
	else:
		InteractionManager.register_area(self)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	_in_range = true
	if auto_pickup:
		try_interact()
	else:
		_refresh_registration()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	_in_range = false
	_refresh_registration()


func _exit_tree() -> void:
	InteractionManager.unregister_area(self)


## Anchor for the world-space prompt: top-center of the owner's visible
## sprites (rotation/scale proof), or the area origin when there is no art
## to measure. The manager applies its own gap and the screen-space nudge.
func prompt_anchor_position() -> Vector2:
	var bounds := _owner_visual_bounds()
	if bounds.size == Vector2.ZERO:
		return global_position
	return Vector2(bounds.position.x + bounds.size.x / 2.0, bounds.position.y)


func _owner_visual_bounds() -> Rect2:
	var owner_root := get_parent() as Node2D
	if owner_root == null:
		return Rect2()
	var sprites: Array[Sprite2D] = []
	_collect_sprites(owner_root, sprites)
	var bounds := Rect2()
	for sprite in sprites:
		var rect := _global_sprite_rect(sprite)
		if rect.size == Vector2.ZERO:
			continue
		bounds = rect if bounds.size == Vector2.ZERO else bounds.merge(rect)
	return bounds


func _collect_sprites(root: Node, into: Array[Sprite2D]) -> void:
	for child in root.get_children():
		if child == self:
			continue
		if child is Sprite2D and child.visible:
			into.append(child)
		_collect_sprites(child, into)


## Opaque-pixel bounds of the sprite's current frame, in global space.
## Sheets carry transparent headroom (character frames especially), so the
## prompt hugs the drawn art instead of the frame rectangle.
func _global_sprite_rect(sprite: Sprite2D) -> Rect2:
	var used := _frame_used_rect(sprite)
	if used.size == Vector2i.ZERO:
		return Rect2()
	var frame_size := _frame_pixel_size(sprite)
	if sprite.flip_h:
		used.position.x = frame_size.x - used.end.x
	if sprite.flip_v:
		used.position.y = frame_size.y - used.end.y
	var base := sprite.get_rect()
	var ratio := base.size / Vector2(frame_size)
	var local := Rect2(
		base.position + Vector2(used.position) * ratio,
		Vector2(used.size) * ratio,
	)
	var lo := sprite.to_global(local.position)
	var hi := lo
	for extent in [Vector2(local.size.x, 0), Vector2(0, local.size.y), local.size]:
		var point := sprite.to_global(local.position + extent)
		lo = lo.min(point)
		hi = hi.max(point)
	return Rect2(lo, hi - lo)


func _frame_pixel_size(sprite: Sprite2D) -> Vector2i:
	if sprite.region_enabled:
		return Vector2i(sprite.region_rect.size)
	var tex_size := Vector2i(sprite.texture.get_size())
	return tex_size / Vector2i(maxi(sprite.hframes, 1), maxi(sprite.vframes, 1))


## Opaque bounds of the current frame in sheet pixels, cached per texture
## and frame pair. Zero-size when the frame has no opaque pixels.
func _frame_used_rect(sprite: Sprite2D) -> Rect2i:
	var texture := sprite.texture
	var cache_key := "%s|%d|%s" % [texture.resource_path,
			texture.get_instance_id(), sprite.frame_coords]
	if _used_rect_cache.has(cache_key):
		return _used_rect_cache[cache_key]
	var image := texture.get_image()
	var frame_size := _frame_pixel_size(sprite)
	var origin := frame_size * sprite.frame_coords
	var lo := Vector2i(frame_size)
	var hi := Vector2i(-1, -1)
	if image != null:
		for y in frame_size.y:
			for x in frame_size.x:
				if image.get_pixel(origin.x + x, origin.y + y).a > 0.01:
					lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
					hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
	var used := Rect2i()
	if hi.x >= 0:
		used = Rect2i(origin + lo, hi - lo + Vector2i.ONE)
	_used_rect_cache[cache_key] = used
	return used
