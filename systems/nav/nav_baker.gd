extends RefCounted
class_name NavBaker

## Bakes a level scope's runtime navigation mesh as one merged polygon with
## baked agent clearance: the Floor layer's bounding rect is the traversable
## outline, every non-walkable cell (Walls, Obstacles) becomes a full-cell
## obstruction outline, and free-standing bodies on the exclusion mask (props,
## doors, chests, NPCs) contribute their real collision outlines — the
## NavigationServer2D bake insets each by AGENT_RADIUS. Tile collision fills
## its cell, but a candle or chest can sit anywhere, even mid-cell, so only
## real outlines keep small blockers from claiming whole cells. A navigation
## mesh only describes traversable area for an agent's center, so baking the
## clearance in is what keeps pathfinding clear of walls and props. Art layers
## keep navigation disabled; the painted "GeneratedNav" TileMapLayer remains
## as a walkability visualization only.

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

## Clearance baked into the navmesh: enemy feet discs run 5.9-7.7px world
## radius, so 7.0 margins the common discs when corners are taken tightly
## (PATH_SWITCH_DISTANCE); bulkier discs may brush walls. Twice the radius
## still fits a 16px doorway.
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
	var body_outlines := _collect_body_outlines(scope)
	var body_bounds := _outline_bounds(body_outlines)
	var half := Vector2(floor_layer.tile_set.tile_size) / 2.0

	var obstruction_cells: Array[Vector2i] = []
	var used := floor_layer.get_used_rect()
	for x in range(used.position.x, used.end.x):
		for y in range(used.position.y, used.end.y):
			var cell := Vector2i(x, y)
			if floor_layer.get_cell_source_id(cell) == -1:
				obstruction_cells.append(cell)
				continue
			if _is_blocked(cell, blockers):
				obstruction_cells.append(cell)
				continue
			# A body outline reaching into the cell keeps it unpainted; the
			# mesh itself is carved from the real outline below.
			if _cell_reaches_body(cell, floor_layer, half, body_bounds):
				continue
			nav_layer.set_cell(cell, 0, Vector2i.ZERO)
	nav_layer.update_internals()

	_bake_region(scope, floor_layer, used, obstruction_cells, body_outlines)
	return nav_layer


## Builds and bakes the merged region: the used-rect bound as the traversable
## outline, one rect per non-walkable cell plus the real collision outline of
## every exclusion body as obstruction outlines, baked with the AGENT_RADIUS
## inset. Outline points are emitted in global space and the region keeps an
## identity transform, so polygon space equals world space regardless of the
## tile layers' own transforms.
static func _bake_region(
		scope: Node,
		floor_layer: TileMapLayer,
		used: Rect2i,
		obstruction_cells: Array[Vector2i],
		body_outlines: Array[PackedVector2Array]) -> void:
	var cell_size := Vector2(floor_layer.tile_set.tile_size)
	var half := cell_size / 2.0
	var bound_start := floor_layer.to_global(floor_layer.map_to_local(used.position) - half)
	var bound_end := floor_layer.to_global(floor_layer.map_to_local(used.end - Vector2i.ONE) + half)
	var nav_poly := NavigationPolygon.new()
	nav_poly.agent_radius = AGENT_RADIUS
	var source := NavigationMeshSourceGeometryData2D.new()
	# Outline winding follows the class-reference bake example (top-left,
	# bottom-left, bottom-right, top-right).
	source.add_traversable_outline(PackedVector2Array([
		bound_start,
		Vector2(bound_start.x, bound_end.y),
		bound_end,
		Vector2(bound_end.x, bound_start.y),
	]))
	for cell in obstruction_cells:
		var center := floor_layer.to_global(floor_layer.map_to_local(cell))
		source.add_obstruction_outline(PackedVector2Array([
			center - half,
			center + Vector2(-half.x, half.y),
			center + half,
			center + Vector2(half.x, -half.y),
		]))
	for outline in body_outlines:
		source.add_obstruction_outline(outline)
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


## True when any Walls/Obstacles layer paints the cell.
static func _is_blocked(cell: Vector2i, blockers: Array[TileMapLayer]) -> bool:
	for layer in blockers:
		if layer.get_cell_source_id(cell) != -1:
			return true
	return false


## Gathers the world-space collision outlines of every body on the exclusion
## mask (props, doors, chests, NPCs), wherever they sit in the scope tree.
static func _collect_body_outlines(scope: Node) -> Array[PackedVector2Array]:
	var outlines: Array[PackedVector2Array] = []
	var stack: Array[Node] = [scope]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
			if child is CollisionObject2D and (child.collision_layer & EXCLUSION_MASK) != 0:
				_append_body_outlines(child, outlines)
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
