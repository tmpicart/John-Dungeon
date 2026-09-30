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

## Layer consumers (verified 2026-09-30)
| Consumer | Mask | Role |
|---|---|---|
| Bodies (player/enemies) | Environment = layer 3, `1 << 2` | walls/props solid; NPC foot bodies sit on bit 3 too |
| Aim gate | `AIM_BLOCKING_MASK := 1 << 2` (`base_enemy.gd`) | the only blocking geometry for attack decisions |
| Arrow flight | mask 5 = bits 1+3 | a blocking player passes; Environment ends flight |
| Nav bake | `EXCLUSION_MASK := 1 << 2` (`nav_baker.gd`) | Environment cells carved from the baked navmesh |
| Reflected arrow | layer bit 6, mask bits 2+3 | retagged player-owned projectile |
| Summon occupancy | mask 23 = bits 1,2,3,5 | spawn placement guard |

Unwalkable ≠ solid: carve nav without collision (water/pits) by adding the layer name to `BLOCKER_LAYER_NAMES`; never reuse the Environment bit — water that must block the player gets its own bit.

## Input Map
`right/left/up/down` (WASD) · `attack` (LMB) · `block` (RMB) · `dash` (Space) · `interact` (E, physical) · `bomb` (Q) · `potion` (Shift) · `quit` (Esc — also closes modals)

> `interact` is the single interaction action (R-30 consolidated the old `pickup`/`Interact` pair); controller support later = adding an event to the action. Prompts derive their key label from this binding.

## Engine facts (4.7.2 — navigation & physics)
- `PhysicsDirectSpaceState2D.intersect_ray` returns a single Dictionary (empty when clear) — not an array.
- `NavigationAgent2D.get_next_path_position()` must be called every physics frame, finished path or not — the agent's internal path state stalls otherwise.
- `NavigationAgent2D.velocity_computed` emits continuously while avoidance is enabled; connect/disconnect it per owning state.
- A hidden TileMapLayer stops updating its nav internals — hide baked nav layers via `modulate.a = 0`, not `visible = false`.
- `simplify_path` corrupts tight-cover routes (corner cuts through blocked cells); leave simplification off for tile navmeshes.
- Tile-navmesh paths hug cell boundaries (zero clearance) and obstacle tilesets can carry polygons overhanging past their cell — followers need half-cell margin (steer through walkable-verified cell centers) or slide-or-crash handling.
- `local_to_map` floors boundary points into the +x/+y cell — verify the snapped cell against the layer (`get_cell_tile_data(cell) != null`).
- A proximity waypoint window smaller than speed/turn-rate orbits; advance waypoints by projection past their plane.
- `move_and_slide` on a projectile gives slide-vs-crash for free (impact steepness = velocity·normal) and needs a collision shape on the scene root.
- Long/forward-offset Area2D hitboxes detect walls early — keep damage hitboxes centered and small; let the body handle geometry.
- NavigationAgent2D's internal cursor only advances when the follower approaches the cursor point — custom anchors require owning the raw `get_current_navigation_path()` list.
- GDScript lambdas capture by value at creation.
- Headless probes must drive physics by frame count (tick-based assertions), not wall-clock waits.
- Headless engine runs on this machine: `Start-Process -FilePath <engine> -ArgumentList ... -Wait -PassThru` to capture exit codes and redirected output.
- `NavigationPolygon.agent_radius` erodes the baked surface: enemy discs run 5.88–7.14 px, inside `AGENT_RADIUS := 7.0` with 2 px slack in 16-px doorways; `NavigationAgent2D.radius` is avoidance-only and does not affect pathfinding.

## Tests
- `tests/interaction_smoke.tscn` — headless regression suite (66 assertions; exit 0 = pass): interaction framework, dialogue stage flow, shipped-resource canary, prompt anchoring + tracking. Run: `Godot --headless --path . res://tests/interaction_smoke.tscn`
- Headless probes (manual diagnostics; the result `txt` files are the record, gitignored): `nav_probe` (bake invariants), `level_nav_probe` (room walk matrix), `chase_probe` (staging/chase/attack), `retreat_probe` (corner + standoff), `scene_probe` (scene staging audit)
- gdlint baseline (repo-wide): all areas clean except `entities/player` (41 findings — opportunistic gate on rewrites) and `entities/projectiles` (3, `bomb.gd`)

## Repository
- Remote: `https://github.com/tmpicart/John-Dungeon.git`, branch `master`
- `.gitattributes`: `* text=auto eol=lf` · `.gitignore`: `.godot/`, `*.tmp`, `*~`, `.vscode/`, plus the asset policy block (`/assets/*` with whitelists — see `ASSETS.md`)
- Asset policy: code-only repo (manifest + whitelist: `ASSETS.md`); asset blobs purged from history 2026-09-08
- `.uid` sidecar files are tracked (Godot 4.4+); always move them together with their script/scene
- Godot upgrades rewrite `.import` sidecars with new importer metadata — a normal one-time migration (commit procedure: `.clinerules/git.md`)