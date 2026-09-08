extends Node
class_name PlayerProgress

## Session-scoped progression state on the player: one-shot world flags plus
## per-speaker dialogue stage counters. Dialogue, the boss-key taunt, and
## future event gating read and write through this API only.

var _flags: Dictionary = {}
var _stages: Dictionary = {}


## Whether a one-shot world flag is set.
func has_flag(flag: StringName) -> bool:
	return _flags.has(flag)


## Sets a one-shot world flag.
func set_flag(flag: StringName) -> void:
	_flags[flag] = true


## Next unconsumed stage index for a speaker (0 when never met).
func get_stage(speaker: StringName) -> int:
	return _stages.get(speaker, 0)


## Marks stages below `next_index` consumed for a speaker.
func set_stage(speaker: StringName, next_index: int) -> void:
	_stages[speaker] = next_index