extends RefCounted
class_name NavBaker

## Bakes a level scope's runtime navigation mesh as one merged polygon. The
## Floor layer's bounding rect is the traversable outline; obstruction
## geometry mirrors authored physics: every Walls/Obstacles tile collision
## polygon is emitted at its real footprint padded by AGENT_RADIUS (so thin
## door-arch strips stay thin), floor-less cells keep a padded full-cell
## rect, and free-standing bodies on the exclusion mask (props, chests, NPC
## foot bodies) contribute their real collision outlines, also padded.
## Door bodies join TRANSIENT_GROUP: their passability is runtime-gated, so
## they carve at their real footprint with no clearance — the seam a closed
## door seals — while the armed PassageLink bridges that seam without a
## rebake. A candle or chest can sit anywhere, even mid-cell, so only real
## outlines keep small blockers from claiming whole cells. Art layers keep
## navigation disabled; the painted "GeneratedNav" TileMapLayer remains as
## a walkability visualization only.

const WALKABLE_LAYER_NAME := "Floor"
const BLOCKER_LAYER_NAMES: Array[String] = ["Walls", "Obstacles"]
const GENERATED_LAYER_NAME := "GeneratedNav"
const GENERATED_REGION_NAME := "GeneratedNavRegion"
## Physics bits of free-standing bodies that carve the mesh at their real
## footprint: Environment blockers (props, doors, chests, NPC foot bodies —
## value 4). Interaction prompt areas (Interactables, value 16) are
## walk-through zones, not obstacles: carving them produced phantom
## obstacles in front of every interactable.
const EXCLUSION_MASK := 1 << 2
## Bodies whose passability is runtime-gated (openable doors): the bake
## carves their real footprint without clearance; the armed PassageLink
## bridges the seam.
const TRANSIENT_GROUP := "nav_transient"
## NavigationAgent2D path_desired_distance for followers: above the 11.3px
## cell half-diagonal so the agent's waypoint cursor still advances when a
## follower stops near a cell center, below the 16px cell so corner waypoints
## are not skipped before the follower rounds them (the 20.0 default does).
const WAYPOINT_REACH_DISTANCE := 12.0

## Waypoint advance distance for path following (chase/retreat agents).
## Switching 12px early cut 90-degree corner chords up to ~8.5px inside
## the AGENT_RADIUS margin, grinding 7px-class bodies into tile corner
## apices. 4px keeps the cut inside the margin.
const PATH_SWITCH_DISTANCE := 4.0

## Clearance the baker pads onto static obstruction outlines (cells and
## free-standing bodies): enemy feet discs run 5.9-7.7px world radius, so
## 7.0 margins the common discs when corners are taken tightly
## (PATH_SWITCH_DISTANCE); bulkier discs may brush walls. Twice the radius
## still fits a 16px doorway. Door bodies stay unpadded.
const AGENT_RADIUS := 7.0


## Bakes the scope's walkable space into the GeneratedNav region. Must run
## outside the physics flush, after the scene tree is ready so body transforms
## read final; callers await physics frames first (see ui/main_scene.gd).
## Returns the visualization layer; the merged region carries the mesh.
static func bake(scope: Node) -> TileMapLayer:
	var layers := _collect_tile_layers(scope)
	var floor_layer: TileMapLayer = layers.get(WALKABLE_LAYER_NAME)
	if floor_layer == null or floor_layer.tile_set == null:
		push_warning("NavBaker: no %s TileMapLayer in scope; nav not baked" % WALKABLE_LAYER_NAME)
		return null

	# The art floor paints wall-to-wall; its nav regions would route paths
	# straight through walls. The GeneratedNav layer replaces them.
	floor_layer.navigation_enabled = false

	var blockers: Array[TileMapLayer] = []
	for blocker_name in BLOCKER_LAYER_NAMES:
		var blocker: TileMapLayer = layers.get(blocker_name)
		if blocker != null:
			blockers.append(blocker)

	var nav_layer := _find_or_create_nav_layer(scope, floor_layer.tile_set.tile_size.x)
	var transient_outlines: Array[PackedVector2Array] = []
	var body_bounds: Array[Rect2] = []
	var body_outlines := _collect_body_outlines(scope, transient_outlines, body_bounds)
	body_bounds.append_array(_outline_bounds(transient_outlines))
	var half := Vector2(floor_layer.tile_set.tile_size) / 2.0

	var used := floor_layer.get_used_rect()
	var obstruction_outlines := _collect_obstruction_outlines(floor_layer, used, blockers)
	for x in range(used.position.x, used.end.x):
		for y in range(used.position.y, used.end.y):
			var cell := Vector2i(x, y)
			if floor_layer.get_cell_source_id(cell) == -1:
				continue
			if _is_blocked(cell, blockers):
				continue
			# A body outline reaching into the cell keeps it unpainted; the
			# mesh itself is carved from the real outline below.
			if _cell_reaches_body(cell, floor_layer, half, body_bounds):
				continue
			nav_layer.set_cell(cell, 0, Vector2i.ZERO)
	nav_layer.update_internals()

	_bake_region(scope, floor_layer, used, obstruction_outlines, body_outlines,
			transient_outlines)
	return nav_layer


## Builds and bakes the merged region: the used-rect bound as the traversable
## outline, the padded obstruction outlines (tile polygons, cell fallbacks and
## static bodies, with padding suppressed inside door gaps) plus the door
## bodies' real-footprint outlines. Clearance
## is already authored into the outlines, so the bake itself runs with
## agent_radius 0. Outline points are emitted in global space and the region
## keeps an identity transform, so polygon space equals world space regardless
## of the tile layers' own transforms.
static func _bake_region(
		scope: Node,
		floor_layer: TileMapLayer,
		used: Rect2i,
		obstruction_outlines: Array[PackedVector2Array],
		body_outlines: Array[PackedVector2Array],
		transient_outlines: Array[PackedVector2Array]) -> void:
	var cell_size := Vector2(floor_layer.tile_set.tile_size)
	var half := cell_size / 2.0
	var bound_start := floor_layer.to_global(floor_layer.map_to_local(used.position) - half)
	var bound_end := floor_layer.to_global(floor_layer.map_to_local(used.end - Vector2i.ONE) + half)
	var nav_poly := NavigationPolygon.new()
	nav_poly.agent_radius = 0.0
	var source := NavigationMeshSourceGeometryData2D.new()
	# Outline winding follows the class-reference bake example (top-left,
	# bottom-left, bottom-right, top-right).
	source.add_traversable_outline(PackedVector2Array([
		bound_start,
		Vector2(bound_start.x, bound_end.y),
		bound_end,
		Vector2(bound_end.x, bound_start.y),
	]))
	for outline in obstruction_outlines:
		source.add_obstruction_outline(_normalize_winding(outline))
	for outline in body_outlines:
		source.add_obstruction_outline(_normalize_winding(outline))
	for outline in transient_outlines:
		source.add_obstruction_outline(_normalize_winding(outline))
	NavigationServer2D.bake_from_source_geometry_data(nav_poly, source)
	var region := _find_or_create_nav_region(scope)
	region.navigation_polygon = nav_poly


static func _find_or_create_nav_region(scope: Node) -> NavigationRegion2D:
	var region: NavigationRegion2D = scope.get_node_or_null(NodePath(GENERATED_REGION_NAME))
	if region == null:
		region = NavigationRegion2D.new()
		region.name = GENERATED_REGION_NAME
		scope.add_child(region)
	return region


## True when any Walls/Obstacles layer paints the cell with tile collision.
## Painted-but-physics-free atoms — the doorway thresholds in
## custom_dungeon.tres — must stay walkable; carving every painted cell
## permanently sealed all four doorways off the mesh. A TileSet without any
## physics layer blocks nothing by definition (synthetic probe stacks).
static func _is_blocked(cell: Vector2i, blockers: Array[TileMapLayer]) -> bool:
	for layer in blockers:
		if layer.tile_set == null or layer.tile_set.get_physics_layers_count() == 0:
			continue
		var tile_data: TileData = layer.get_cell_tile_data(cell)
		if tile_data != null and tile_data.get_collision_polygons_count(0) > 0:
			return true
	return false


## Gathers the world-space collision outlines of every body on the exclusion
## mask (props, doors, chests, NPCs), wherever they sit in the scope tree.
## Static bodies keep their real footprint padded by AGENT_RADIUS; bodies in
## TRANSIENT_GROUP (doors: passability is runtime-gated) carve at their real
## footprint with no clearance. real_bounds receives the static bodies'
## unpadded footprint bounds for the walkability visualization's cell
## exclusion.
static func _collect_body_outlines(
		scope: Node,
		transient_outlines: Array[PackedVector2Array],
		real_bounds: Array[Rect2]) -> Array[PackedVector2Array]:
	var outlines: Array[PackedVector2Array] = []
	var stack: Array[Node] = [scope]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
			if child is CollisionObject2D and (child.collision_layer & EXCLUSION_MASK) != 0:
				var collected: Array[PackedVector2Array] = []
				_append_body_outlines(child, collected)
				real_bounds.append_array(_outline_bounds(collected))
				if child.is_in_group(TRANSIENT_GROUP):
					for outline in collected:
						transient_outlines.append(outline)
				else:
					for outline in collected:
						_emit_static_outline(
								_offset_outline(outline, AGENT_RADIUS), outlines)
	return outlines


static func _append_body_outlines(
		body: CollisionObject2D,
		outlines: Array[PackedVector2Array]) -> void:
	for child in body.get_children():
		var shape_node := child as CollisionShape2D
		if shape_node != null:
			if shape_node.disabled:
				continue
			_append_points(_shape_outline(shape_node.shape), shape_node.global_transform, outlines)
			continue
		var polygon_node := child as CollisionPolygon2D
		if polygon_node != null and not polygon_node.disabled:
			_append_points(polygon_node.polygon, polygon_node.global_transform, outlines)


## Transforms local outline points into world space and stores them.
static func _append_points(
		local_points: PackedVector2Array,
		transform: Transform2D,
		outlines: Array[PackedVector2Array]) -> void:
	if local_points.size() < 3:
		return
	var world_points := PackedVector2Array()
	for point in local_points:
		world_points.append(transform * point)
	outlines.append(world_points)


## Obstruction outlines for the used rect, mirroring authored physics: each
## blocker-layer tile collision polygon is emitted at its real footprint
## padded by AGENT_RADIUS, so thin door-arch strips stay thin instead of
## inflating into full-cell blocks that seal doorway mouths. Padded
## full-cell rects remain the fallback for floor-less cells and concave
## authored polygons; physics-free painted atoms (doorway thresholds) and
## plain floor stay walkable.
static func _collect_obstruction_outlines(
		floor_layer: TileMapLayer,
		used: Rect2i,
		blockers: Array[TileMapLayer]) -> Array[PackedVector2Array]:
	var outlines: Array[PackedVector2Array] = []
	var half := Vector2(floor_layer.tile_set.tile_size) / 2.0
	for x in range(used.position.x, used.end.x):
		for y in range(used.position.y, used.end.y):
			var cell := Vector2i(x, y)
			var tile_polygons := _cell_tile_polygons(cell, blockers)
			if tile_polygons.is_empty():
				if floor_layer.get_cell_source_id(cell) != -1:
					continue
				_emit_cell_rect(floor_layer, cell, half, outlines)
				continue
			for polygon in tile_polygons:
				if _is_convex_outline(polygon):
					_emit_static_outline(
							_offset_outline(polygon, AGENT_RADIUS), outlines)
				else:
					# Concave authored collision: the miter offsetter is
					# convex-only, so keep the padded cell approximation.
					_emit_cell_rect(floor_layer, cell, half, outlines)
	return outlines


## World-space authored collision polygons of every blocker layer painting
## the cell; TileData polygons are layer-local points relative to the tile
## center. Walkability-only paint (no physics polygons) yields nothing, as
## before.
static func _cell_tile_polygons(
		cell: Vector2i,
		blockers: Array[TileMapLayer]) -> Array[PackedVector2Array]:
	var polygons: Array[PackedVector2Array] = []
	for layer in blockers:
		if layer.tile_set == null or layer.tile_set.get_physics_layers_count() == 0:
			continue
		var tile := layer.get_cell_tile_data(cell)
		if tile == null:
			continue
		var center_local: Vector2 = layer.map_to_local(cell)
		for p in tile.get_collision_polygons_count(0):
			var points := tile.get_collision_polygon_points(0, p)
			if points.size() < 3:
				continue
			var world := PackedVector2Array()
			for point in points:
				world.append(layer.to_global(center_local + point))
			polygons.append(world)
	return polygons


## Cross-product convexity test (collinear runs allowed). Authored tile
## collision here is rect strips and cells; anything concave falls back to
## the padded cell approximation rather than feeding the miter offsetter a
## shape it would invert.
static func _is_convex_outline(outline: PackedVector2Array) -> bool:
	var positive := false
	var negative := false
	var count := outline.size()
	for i in count:
		var a := outline[i]
		var b := outline[(i + 1) % count]
		var c := outline[(i + 2) % count]
		var cross := (b - a).cross(c - b)
		if cross > 0.01:
			positive = true
		elif cross < -0.01:
			negative = true
	return not (positive and negative)


static func _rect_outline(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		Vector2(rect.position.x, rect.end.y),
		rect.end,
		Vector2(rect.end.x, rect.position.y),
	])


## Obstruction outlines must share the traversable outline's winding (top-
## left, bottom-left, bottom-right, top-right — negative shoelace area). The
## server's own offset step rewound inputs when agent_radius did the
## clearance; the raw subtraction at agent_radius 0 does not, and mixed
## windings self-intersect the result and kill the convex partition.
static func _normalize_winding(outline: PackedVector2Array) -> PackedVector2Array:
	var area := 0.0
	for i in outline.size():
		var j := (i + 1) % outline.size()
		area += outline[i].x * outline[j].y - outline[j].x * outline[i].y
	if area > 0.0:
		outline.reverse()
	return outline


static func _emit_cell_rect(
		floor_layer: TileMapLayer,
		cell: Vector2i,
		half: Vector2,
		outlines: Array[PackedVector2Array]) -> void:
	var center: Vector2 = floor_layer.to_global(floor_layer.map_to_local(cell))
	var cell_rect := Rect2(center - half, half * 2.0)
	_emit_static_outline(_rect_outline(cell_rect.grow(AGENT_RADIUS)), outlines)


## Emits one static obstruction outline at its padded footprint.
static func _emit_static_outline(
		padded: PackedVector2Array,
		outlines: Array[PackedVector2Array]) -> void:
	if padded.size() < 3:
		return
	outlines.append(padded)


## Outward miter offset of a convex outline by amount (circle/capsule/rect/
## convex-polygon footprints). Winding-agnostic: each edge normal is flipped
## to point away from the outline centroid, tested at the edge midpoint (a
## vertex test misclassifies corners of small shapes and inverts the offset).
static func _offset_outline(outline: PackedVector2Array, amount: float) -> PackedVector2Array:
	if amount <= 0.0 or outline.size() < 3:
		return outline
	var centroid := Vector2.ZERO
	for point in outline:
		centroid += point
	centroid /= outline.size()
	var count := outline.size()
	var starts: Array[Vector2] = []
	var dirs: Array[Vector2] = []
	var normals: Array[Vector2] = []
	for i in count:
		var start := outline[i]
		var end := outline[(i + 1) % count]
		var dir := (end - start).normalized()
		var normal := Vector2(dir.y, -dir.x)
		var mid := (start + end) / 2.0
		if (mid + normal).distance_squared_to(centroid) < mid.distance_squared_to(centroid):
			normal = -normal
		starts.append(start)
		dirs.append(dir)
		normals.append(normal)
	var result := PackedVector2Array()
	for i in count:
		var j := (i + 1) % count
		result.append(_ray_intersect(
				starts[i] + normals[i] * amount, dirs[i],
				starts[j] + normals[j] * amount, dirs[j],
				starts[j] + (normals[i] + normals[j]).normalized() * amount))
	return result


## Intersection of two offset edge lines (point + direction); falls back to
## the averaged offset point for near-parallel edges (miter blowup guard).
static func _ray_intersect(
		point_a: Vector2,
		dir_a: Vector2,
		point_b: Vector2,
		dir_b: Vector2,
		fallback: Vector2) -> Vector2:
	var denominator := dir_a.cross(dir_b)
	if absf(denominator) < 0.0001:
		return fallback
	var t := (point_b - point_a).cross(dir_b) / denominator
	return point_a + dir_a * t


## Local-space convex outline for the blocker shape types: circles and
## capsules become 16-gon approximations (the capsule's bounding ellipse),
## area-less shapes (segments, world boundaries) are skipped.
static func _shape_outline(shape: Shape2D) -> PackedVector2Array:
	var circle := shape as CircleShape2D
	if circle != null:
		return _ellipse_outline(circle.radius, circle.radius)
	var capsule := shape as CapsuleShape2D
	if capsule != null:
		return _ellipse_outline(capsule.radius, capsule.height / 2.0)
	var rectangle := shape as RectangleShape2D
	if rectangle != null:
		var half: Vector2 = rectangle.size / 2.0
		return PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(-half.x, half.y),
			Vector2(half.x, half.y),
			Vector2(half.x, -half.y),
		])
	var convex := shape as ConvexPolygonShape2D
	if convex != null:
		return convex.points
	return PackedVector2Array()


static func _ellipse_outline(radius_x: float, radius_y: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points


## Bounding rects of the collected outlines, in world space.
static func _outline_bounds(outlines: Array[PackedVector2Array]) -> Array[Rect2]:
	var bounds: Array[Rect2] = []
	for outline in outlines:
		var rect := Rect2(outline[0], Vector2.ZERO)
		for point in outline:
			rect = rect.expand(point)
		bounds.append(rect)
	return bounds


## True when any body outline's bounds reach into the cell's world-space rect.
static func _cell_reaches_body(
		cell: Vector2i,
		floor_layer: TileMapLayer,
		half: Vector2,
		body_bounds: Array[Rect2]) -> bool:
	if body_bounds.is_empty():
		return false
	var center: Vector2 = floor_layer.to_global(floor_layer.map_to_local(cell))
	var cell_rect := Rect2(center - half, half * 2.0)
	for rect in body_bounds:
		if rect.intersects(cell_rect):
			return true
	return false


static func _find_or_create_nav_layer(scope: Node, cell_size: int) -> TileMapLayer:
	var nav_layer: TileMapLayer = scope.get_node_or_null(NodePath(GENERATED_LAYER_NAME))
	if nav_layer == null:
		nav_layer = TileMapLayer.new()
		nav_layer.name = GENERATED_LAYER_NAME
		scope.add_child(nav_layer)
	nav_layer.tile_set = _build_nav_tile_set(cell_size)
	nav_layer.clear()
	# Painted cells only visualize walkability; the merged region is the
	# navigation map's sole region source. A hidden TileMapLayer tears down
	# its nav internals; fade out instead.
	nav_layer.navigation_enabled = false
	nav_layer.modulate.a = 0.0
	return nav_layer


## One transparent tile; painted cells visualize walkable space for debugging.
static func _build_nav_tile_set(cell_size: int) -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(cell_size, cell_size)
	var source := TileSetAtlasSource.new()
	var image := Image.create_empty(cell_size, cell_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = Vector2i(cell_size, cell_size)
	source.create_tile(Vector2i.ZERO)
	tile_set.add_source(source, 0)
	return tile_set


## All TileMapLayer descendants by name, descending through legacy TileMap
## wrappers (R-40 debt) that hold the layers one level deeper.
static func _collect_tile_layers(scope: Node) -> Dictionary:
	var layers := {}
	var stack: Array[Node] = [scope]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			if child is TileMapLayer:
				layers[child.name] = child
			else:
				stack.append(child)
	return layers
