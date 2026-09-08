extends Resource
class_name DialogueStage

## One playable chunk of a conversation: pages shown in order, optionally
## gated behind a progress flag, optionally setting one on completion.
## Fields are String/Array[String] on purpose: the 4.7.2 editor save omits
## PackedStringArray/StringName values from scripted sub-resources, while
## the ShopData pattern (plain strings on sub-resources) round-trips clean.

@export var pages: Array[String] = []
## Stage is only offered while this progress flag is set (empty = always).
@export var requires_flag: String = ""
## Progress flag applied when the stage finishes (empty = none).
@export var set_flag: String = ""