extends EnemySummon

## Boss summon: shared flood-fill placement with her phase-dependent creature
## compositions.

@export var summoned_creature_2: PackedScene
@export var phase2_creature: PackedScene
@export var phase2_creature_2: PackedScene
@export var primary_count := 3
@export var secondary_count := 2
@export var phase2_primary_count := 3
@export var phase2_secondary_count := 2
@export var phase2_fallback_count := 7

func validate_exports() -> void:
	super()
	if summoned_creature_2 == null:
		push_error("%s: summoned_creature_2 is not assigned" % get_path())
	if phase2_creature == null:
		push_error("%s: phase2_creature is not assigned" % get_path())
	if phase2_creature_2 == null:
		push_error("%s: phase2_creature_2 is not assigned" % get_path())

func _spawn_creatures() -> void:
	var tilemap_layer = _find_tilemap_layer()
	if tilemap_layer == null:
		push_error("%s: no TileMapLayer found for summon placement" % get_path())
		return

	var boss = enemy
	var requests: Array = []
	if boss.phase2:
		if randi_range(1, 2) == 1:
			requests = [[phase2_creature, phase2_primary_count], [phase2_creature_2, phase2_secondary_count]]
		else:
			requests = [[phase2_creature, phase2_fallback_count]]
	else:
		requests = [[summoned_creature, primary_count], [summoned_creature_2, secondary_count]]

	var total := 0
	for request in requests:
		total += request[1]

	var positions = _get_valid_summon_positions(total, tilemap_layer)
	if positions.size() < total:
		push_warning("Found only %d valid summon positions." % positions.size())

	var index := 0
	for request in requests:
		for i in request[1]:
			if index >= positions.size():
				return
			_spawn_summon(positions[index], request[0])
			index += 1