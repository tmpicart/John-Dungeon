# Tech Context — Engine & Environment

> **Purpose:** Engine facts and environment configuration. Update in place when tooling or config changes.

## Engine
- Godot **4.7.2 stable** (win64), Forward Plus renderer, GDScript
- **Engine hazard (4.7.2):** editor saves omit `PackedStringArray`/`StringName` property values on scripted sub-resources in `.tres` — they silently revert to script defaults. The headless engine `ResourceSaver` is unaffected; the smoke suite's "shipped dialogue playable" canary guards this. Author shipped resource data with `String`/`Array[String]`/`int`/`Texture` fields (the ShopData pattern)
- Editor path (VS Code setting): `c:\Users\Silent\Documents\Code\Godot_v4.7.2-stable_win64.exe`
- Linting/formatting: `gdlint` / `gdformat` (gdtoolkit 4.5 via pip; config `gdlintrc`) — verification gate per `.clinerules/code-style.md`
- Display: 1920×1080, `canvas_items` stretch mode, nearest texture filter (pixel art)
- Main scene chain: `ui/main_menu.tscn` → `levels/test_room.tscn` (official test room)

## Autoloads
| Name | Path | Role |
|---|---|---|
| `Global` | `systems/global/global.gd` | player reference (property-backed; re-resolves freed/missing refs), `Direction` enum |
| `InteractionManager` | `systems/interaction/interaction_manager.tscn` | interaction registry + binding-derived "…" prompt (screen-space layer; world anchor projected per frame) |

## Physics Layers
| # | Name | # | Name |
|---|---|---|---|
| 1 | Player | 6 | PlayerHitbox |
| 2 | Enemies | 7 | PlayerHurtbox |
| 3 | Environment | 8 | EnemyHitbox |
| 4 | Pickups | 9 | EnemyHurtbox |
| 5 | Interactables | 10 | NPC |

Render layers 1–2: Player, Enemies.

## Input Map
`right/left/up/down` (WASD) · `attack` (LMB) · `block` (RMB) · `dash` (Space) · `interact` (E, physical) · `bomb` (Q) · `potion` (Shift) · `quit` (Esc — also closes modals)

> `interact` is the single interaction action (R-30 consolidated the old `pickup`/`Interact` pair); controller support later = adding an event to the action. Prompts derive their key label from this binding.

## Tests
- `tests/interaction_smoke.tscn` — headless regression suite (66 assertions; exit 0 = pass): interaction framework, dialogue stage flow, shipped-resource canary, prompt anchoring + tracking. Run: `Godot --headless --path . res://tests/interaction_smoke.tscn`

## Repository
- Remote: `https://github.com/tmpicart/John-Dungeon.git`, branch `master`
- `.gitattributes`: `* text=auto eol=lf` · `.gitignore`: `.godot/`, `*.tmp`, `*~`, `.vscode/`
- `.uid` sidecar files are tracked (Godot 4.4+); always move them together with their script/scene
- Godot upgrades rewrite `.import` sidecars with new importer metadata — a normal one-time migration; commit as an isolated `chore:` commit when it appears (see `.clinerules/git.md`)