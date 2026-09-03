# Tech Context — Engine & Environment

> **Purpose:** Engine facts and environment configuration. Update in place when tooling or config changes.

## Engine
- Godot **4.7.2 stable** (win64), Forward Plus renderer, GDScript
- Editor path (VS Code setting): `c:\Users\Silent\Documents\Code\Godot_v4.7.2-stable_win64.exe`
- Display: 1920×1080, `canvas_items` stretch mode, nearest texture filter (pixel art)
- Main scene chain: `ui/main_menu.tscn` → `levels/floor_1.tscn` (remaster test level)

## Autoloads
| Name | Path | Role |
|---|---|---|
| `Global` | `systems/global/global.gd` | player/door references (property-backed; re-resolves freed/missing refs), `Direction` enum, `has_boss_key` flag |
| `InteractionManager` | `systems/interaction/interaction_manager.tscn` | interaction registry + "[F] to …" prompt label |

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
`right/left/up/down` (WASD) · `attack` (LMB) · `block` (RMB) · `dash` (Space) · `pickup` (E) · `Interact` (F) · `bomb` (Q) · `potion` (Shift) · `quit` (Esc)

> Note: `pickup` (E) is currently unwired — reserved for future use, do not remove. Binding consolidation (with `Interact`) happens during the interaction refactor (R-30).

## Repository
- Remote: `https://github.com/tmpicart/John-Dungeon.git`, branch `master`
- `.gitattributes`: `* text=auto eol=lf` · `.gitignore`: `.godot/`, `*.tmp`, `*~`, `.vscode/`
- `.uid` sidecar files are tracked (Godot 4.4+); always move them together with their script/scene
- Godot upgrades rewrite `.import` sidecars with new importer metadata — a normal one-time migration; commit as an isolated `chore:` commit when it appears (see `.clinerules/git.md`)