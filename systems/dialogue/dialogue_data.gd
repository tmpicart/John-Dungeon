extends Resource
class_name DialogueData

## One speaker's conversation, authored as a .tres per speaker (mirrors the
## ShopData convention). One-shot stages play in order — flag-gated stages
## are skipped until their flag appears — and the greeting repeats once
## every stage is consumed. `portrait` is the speaker's face crop (top half
## of a sprite frame) shown beside the text in the dialogue box.

@export var npc_id: StringName = &""
@export var portrait: Texture2D
@export var stages: Array[DialogueStage] = []
@export var greeting: DialogueStage