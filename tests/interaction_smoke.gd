extends Node

## Headless smoke test for the interaction framework. Run:
## Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/interaction_smoke.tscn
## Exits 0 on pass, 1 on failure.

const TierOneTable: LootTable = preload("res://systems/loot/loot_table_tier_1.tres")
const AreaScene: PackedScene = preload("res://systems/interaction/interactable.tscn")

var _failures := 0
var _signal_fired := false
var _log: FileAccess


func _ready() -> void:
	_log = FileAccess.open("res://smoke_result.txt", FileAccess.WRITE)
	await _run()
	if _failures > 0:
		_tee("SMOKE TEST FAILED: %d failure(s)" % _failures)
		_log.close()
		get_tree().quit(1)
	else:
		_tee("SMOKE TEST PASSED")
		_log.close()
		get_tree().quit(0)


func _tee(message: String) -> void:
	print(message)
	_log.store_line(message)


func _check(condition: bool, test_name: String) -> void:
	if condition:
		_tee("  PASS: " + test_name)
	else:
		_failures += 1
		_tee("  FAIL: " + test_name)


func _make_area(prompt_text: String, offset: Vector2) -> Interactable:
	var area: Interactable = AreaScene.instantiate()
	area.prompt = prompt_text
	area.position = offset
	add_child(area)
	return area


func _run() -> void:
	var manager: Node2D = get_node("/root/InteractionManager")
	var player := Node2D.new()
	player.add_to_group("Player")
	add_child(player)

	var near := _make_area("Near", Vector2(10, 0))
	var far := _make_area("Far", Vector2(50, 0))

	# Registry + nearest selection, prompt from the bound `interact` key.
	manager.register_area(far)
	manager.register_area(near)
	manager._select_best()
	_check(manager._best_area == near, "nearest area wins")
	var prompt_text: String = manager.label.text
	_check(prompt_text == "[E] Near", "prompt derived from input map: " + prompt_text)
	_check(manager.label.visible, "prompt visible while in range")

	# Registry churn re-selects.
	manager.unregister_area(near)
	_check(manager._best_area == far, "best re-selected after unregister")

	# One-shot interact disables and unregisters the area.
	manager.register_area(near)
	far.one_shot = true
	far.interacted.connect(_on_signal)
	_check(far.try_interact(), "try_interact fires when enabled")
	_check(_signal_fired, "interacted signal emitted")
	_check(not far.enabled, "one_shot disabled the area")
	_check(not manager._active_areas.has(far), "one_shot unregistered the area")
	_check(not far.try_interact(), "disabled area refuses interaction")

	# Freed areas are pruned instead of crashing the selection.
	var ghost := Interactable.new()
	manager.register_area(ghost)
	_check(manager._active_areas.size() == 2, "sanity: ghost registered before prune")
	ghost.free()
	manager._select_best()
	_check(manager._active_areas.size() == 1, "freed area pruned from registry")
	_check(manager._best_area == near, "selection survives freed entries")

	# Auto pickup fires on contact without a prompt.
	var coin_area := _make_area("Coin", Vector2(90, 0))
	coin_area.auto_pickup = true
	coin_area.one_shot = true
	_signal_fired = false
	coin_area.interacted.connect(_on_signal)
	coin_area._on_body_entered(player)
	_check(_signal_fired, "auto_pickup fires interacted on contact")
	_check(not coin_area.enabled, "auto_pickup one_shot consumed")
	_check(not manager._active_areas.has(coin_area), "auto_pickup never registers a prompt")

	# Universal Pickup defaults and prompt centering math.
	var drop: Pickup = preload("res://entities/interactables/pickups/pickup.tscn").instantiate()
	_check(drop.auto_pickup and drop.one_shot, "pickup defaults to auto + one-shot")
	drop.free()
	var near_screen: Vector2 = _to_screen(manager, near.global_position)
	_check(absf(manager.label.position.x - (near_screen.x - manager.label.size.x / 2.0)) < 0.01,
			"prompt centered over the target area")

	# Prompt anchoring: sprite-less areas fall back to the offset rotated
	# with the area; parent-chain scale (chests at 0.06) never applies.
	var scaled := Node2D.new()
	scaled.scale = Vector2(0.06, 0.06)
	scaled.rotation = 0.5
	scaled.position = Vector2(2, 0)
	add_child(scaled)
	var shrunk: Interactable = AreaScene.instantiate()
	shrunk.prompt = "Scaled"
	shrunk.prompt_offset = Vector2(0, -15)
	scaled.add_child(shrunk)
	manager.register_area(shrunk)
	_check(manager._best_area == shrunk, "sanity: scaled area is nearest")
	var shrunk_screen: Vector2 = _to_screen(manager, shrunk.global_position)
	_check(absf(manager.label.position.y
			- (shrunk_screen.y + shrunk.prompt_offset.y
			- manager.PROMPT_MARGIN
			- manager.label.size.y)) < 0.01,
			"sprite-less prompt uses the area origin plus offset")

	# With visible art the anchor floats above the OPAQUE pixels (sheets
	# carry transparent headroom), regardless of parent scale/rotation.
	var art := Sprite2D.new()
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	image.fill_rect(Rect2i(1, 2, 2, 2), Color.WHITE)
	art.texture = ImageTexture.create_from_image(image)
	art.position = Vector2(0, -6)
	scaled.add_child(art)
	shrunk.prompt_offset = Vector2.ZERO
	manager._update_prompt()
	# Opaque block at rows 2-3, cols 1-2 of the centered 4x4 frame: in
	# sprite-local space that rect is (-1, 0, 2, 2) (to_global adds the
	# node position and parent transform).
	var local_used := Rect2(-1.0, 0.0, 2.0, 2.0)
	var art_screen: Vector2 = _to_screen(manager, art.to_global(local_used.get_center()))
	var top := INF
	for corner in [local_used.position, local_used.position + Vector2(2, 0),
			local_used.position + Vector2(0, 2), local_used.end]:
		top = minf(top, _to_screen(manager, art.to_global(corner)).y)
	var expected := Vector2(
		art_screen.x - manager.label.size.x / 2.0,
		top - manager.PROMPT_MARGIN - manager.label.size.y,
	)
	_check(manager.label.position.distance_to(expected) < 0.01,
			"prompt anchors above visible art automatically")

	# The prompt tracks its anchor every frame while shown: translating the
	# owner re-positions via _process, with no registry event involved.
	scaled.position.y += 10.0
	manager._process(0.016)
	_check(manager.label.position.distance_to(expected + Vector2(0, 10)) < 0.01,
			"prompt follows a moving anchor every frame")

	# UI subtrees under the owner never contribute to the anchor.
	var ui_layer := CanvasLayer.new()
	scaled.add_child(ui_layer)
	var ui_sprite := Sprite2D.new()
	ui_sprite.texture = art.texture
	ui_sprite.position = Vector2(5000, 5000)
	ui_layer.add_child(ui_sprite)
	manager._update_prompt()
	_check(manager.label.position.distance_to(expected + Vector2(0, 10)) < 0.01,
			"ui subtrees never contribute to the anchor")
	ui_layer.free()

	# Multi-frame sheets measure the DISPLAYED frame, not the sheet: the
	# opaque rect is frame-relative, so a frame-1 sprite anchors above its
	# own art rather than being pushed right by earlier frames' columns.
	art.free()
	var sheet := Image.create(8, 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	sheet.fill_rect(Rect2i(0, 2, 2, 2), Color.WHITE)
	sheet.fill_rect(Rect2i(5, 2, 2, 2), Color.WHITE)
	var framed := Sprite2D.new()
	framed.texture = ImageTexture.create_from_image(sheet)
	framed.hframes = 2
	framed.frame = 1
	scaled.add_child(framed)
	manager._update_prompt()
	var framed_top := INF
	for corner in [local_used.position, local_used.position + Vector2(2, 0),
			local_used.position + Vector2(0, 2), local_used.end]:
		framed_top = minf(framed_top, _to_screen(manager, framed.to_global(corner)).y)
	var framed_expected := Vector2(
		_to_screen(manager, framed.to_global(local_used.get_center())).x
				- manager.label.size.x / 2.0,
		framed_top - manager.PROMPT_MARGIN - manager.label.size.y,
	)
	_check(manager.label.position.distance_to(framed_expected) < 0.01,
			"multi-frame sheets anchor to the displayed frame")
	framed.free()
	manager.unregister_area(shrunk)
	scaled.free()
	_check(manager._best_area == near, "selection restored after scaled area")

	# Ejection gates collection until the item settles.
	var CoinScene: PackedScene = preload("res://entities/interactables/pickups/coin.tscn")
	var flier: PickupItem = CoinScene.instantiate()
	flier.position = Vector2(200, 0)
	add_child(flier)
	flier.eject(Vector2(40, 0), 120.0)
	_check(not flier.interaction_area.enabled, "ejection gates collection")
	_check(flier.z_index == 1, "airborne items render on the airborne tier")
	_check(flier._sprite.position.y == flier._sprite_base_y,
			"ejection starts at the spawn point")
	var settle_flag := {"ok": false}
	flier.settled.connect(func(): settle_flag.ok = true)
	var waited := 0.0
	var rose := false
	while not settle_flag.ok and waited < 5.0:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
		if flier._sprite.position.y < flier._sprite_base_y:
			rose = true
	_check(settle_flag.ok, "ejected item settles")
	_check(rose, "ejected item rises before falling")
	_check(not flier.interaction_area.enabled, "collection stays gated during the pickup delay")
	var enable_wait := 0.0
	while not flier.interaction_area.enabled and enable_wait < 2.0:
		await get_tree().create_timer(0.1).timeout
		enable_wait += 0.1
	_check(flier.interaction_area.enabled, "collection re-enables after the pickup delay")
	_check(flier.z_index == 0, "settled items return to the world tier")
	var hemispherical := true
	for _i in 20:
		flier.scatter(50.0)
		if flier._velocity.y < -0.01:
			hemispherical = false
	_check(hemispherical, "scatter defaults spill toward the viewer")
	flier.queue_free()

	# Loot rolls sum exactly to the budget.
	var table: LootTable = LootTable.new()
	table.entries = [
		CoinScene,
		preload("res://entities/interactables/pickups/potion.tscn"),
	]
	var rolled := table.roll(7)
	var total := 0
	for scene in rolled:
		var item: Node = scene.instantiate()
		total += item.loot_value
		item.free()
	_check(total == 7, "loot roll sums exactly to budget")
	_check(table.roll(0).is_empty(), "zero budget rolls nothing")
	_check(TierOneTable.tier == 1 and not TierOneTable.entries.is_empty(),
			"tier 1 table resource loads with entries")
	_check(TierOneTable.roll(5).size() >= 1, "tier 1 table rolls")

	# Locked state hides the prompt.
	manager.set_locked(true)
	_check(not manager.label.visible, "locked hides the prompt")
	manager.set_locked(false)
	_check(manager.label.visible, "unlock restores the prompt")

	# Dialogue: stage selection prefers unlocked one-shots, consumes them
	# once, falls back to the greeting, and pairs the modal freeze.
	var stub: Node2D = preload("res://tests/stub_player.gd").new()
	var prog := PlayerProgress.new()
	stub.progress = prog
	stub.add_child(prog)
	stub.add_to_group("Player")
	add_child(stub)
	var saved_player: Node = Global.player
	Global.player = stub

	var intro := DialogueStage.new()
	intro.pages = ["intro line"]
	var unlockable := DialogueStage.new()
	unlockable.pages = ["unique line"]
	unlockable.requires_flag = "met_smoke_boss"
	unlockable.set_flag = "smoke_flag"
	var greet := DialogueStage.new()
	greet.pages = ["hello again"]
	var convo := DialogueData.new()
	convo.npc_id = &"smoke_npc"
	convo.stages = [intro, unlockable]
	convo.greeting = greet

	var box: CanvasLayer = preload("res://systems/dialogue/npc_dialog.tscn").instantiate()
	add_child(box)
	var finished_count := [0]
	box.finished.connect(func() -> void: finished_count[0] += 1)

	_check(box.open(convo, Vector2.ZERO), "intro stage opens the box")
	_check(stub.locked and manager._locked, "opening dialogue freezes player + interaction")
	_check(box._pages[0] == "intro line", "unlocked one-shot stage is selected first")
	_check(box._text.visible_characters == 0, "typing starts hidden")
	await get_tree().create_timer(0.15).timeout
	var partial: int = box._text.visible_characters
	_check(partial > 0 and partial < box._text.get_total_character_count(),
			"characters reveal progressively while typing")
	box._advance()
	_check(box._text.visible_characters == -1, "pressing mid-type reveals the page")
	box._advance()
	_check(finished_count[0] == 1, "final page emits finished")
	_check(prog.get_stage(&"smoke_npc") == 1, "completed stage is consumed")
	_check(not stub.locked and not manager._locked, "closing restores player + interaction")

	_check(box.open(convo, Vector2.ZERO), "greeting opens before the gate unlocks")
	_check(box._pages[0] == "hello again", "greeting is the fallback while gated")
	box._close(false)
	_check(finished_count[0] == 1, "aborting close does not emit finished")

	prog.set_flag(&"met_smoke_boss")
	_check(box.open(convo, Vector2.ZERO), "gated stage opens once its flag appears")
	_check(box._pages[0] == "unique line", "unlocked unique stage takes precedence")
	box._advance()
	box._advance()
	_check(finished_count[0] == 2, "unlocked stage completion emits finished")
	_check(prog.has_flag(&"smoke_flag"), "set_flag applies on stage completion")

	_check(box.open(convo, Vector2.ZERO), "greeting returns after all stages")
	_check(box._pages[0] == "hello again", "greeting repeats once stages are done")
	box._close(false)

	# Gate-failing stages are skipped even as the only stage.
	var locked_only := DialogueStage.new()
	locked_only.pages = ["secret"]
	locked_only.requires_flag = "smoke_missing"
	var gated := DialogueData.new()
	gated.npc_id = &"smoke_gated"
	gated.stages = [locked_only]
	gated.greeting = greet
	_check(box.open(gated, Vector2.ZERO), "locked-only data still has a greeting")
	_check(box._pages[0] == "hello again", "gate-failing stages are skipped")
	box._close(false)

	var empty := DialogueData.new()
	empty.npc_id = &"smoke_empty"
	_check(not box.open(empty, Vector2.ZERO), "data without stages or greeting refuses to open")

	prog.set_stage(&"smoke_npc", 99)
	_check(prog.get_stage(&"smoke_npc") == 99, "set_stage records consumption")
	_check(prog.get_stage(&"nobody") == 0, "fresh speakers start at stage 0")

	# Shipped dialogue resources stay playable (guards against editor
	# re-saves stripping .tres properties).
	for res_path in ["res://systems/dialogue/blacksmith.tres",
			"res://systems/dialogue/potion_seller.tres",
			"res://systems/dialogue/tutorial.tres",
			"res://systems/dialogue/boss_taunt_sorceress.tres"]:
		var shipped: DialogueData = load(res_path)
		_check(shipped != null and box.open(shipped, Vector2.ZERO),
				"shipped dialogue playable: " + res_path.get_file())
		box._close(false)

	Global.player = saved_player
	box.free()
	stub.free()


func _to_screen(manager: Node2D, world_pos: Vector2) -> Vector2:
	return manager.get_viewport().get_canvas_transform() * world_pos


func _on_signal() -> void:
	_signal_fired = true