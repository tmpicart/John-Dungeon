extends Node

## Headless smoke test for the interaction framework. Run:
## Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/interaction_smoke.tscn
## Exits 0 on pass, 1 on failure.

const TierOneTable: LootTable = preload("res://systems/loot/loot_table_tier_1.tres")

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
	var area: Interactable = preload("res://systems/interaction/interactable.tscn").instantiate()
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
	var expected_x: float = near.global_position.x \
			- manager.label.size.x * manager.label.scale.x / 2.0
	_check(absf(manager.label.global_position.x - expected_x) < 0.01,
			"prompt centered over the target area")

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


func _on_signal() -> void:
	_signal_fired = true