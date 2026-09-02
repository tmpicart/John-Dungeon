# System Patterns — Architecture & Conventions

> **Purpose:** The agreed architecture and conventions. New code follows this file; patterns marked superseded in `migrationMap.md` are not to be extended.

## Architecture Map

### Player (`Scenes/Characters/Character.tscn`)
Hub-and-subsystems: `Character.gd` delegates to child subsystem nodes and a state machine.
- `PlayerMovement` — acceleration/friction movement, dash with cooldown timer
- `PlayerCombat` — HP, attack/block execution, damage intake; signals `hp_changed`, `max_hp_changed`
- `PlayerInventory` — coins/bombs/potions/keys with `*_changed` signals
- `PlayerAnimation` — 4-direction mouse-facing animation routing, equipment layering (weapon/shield foreground vs background)
- `State Control` — generic state machine (`Scripts/States/State.gd`, `State Control.gd`): states emit `ChangeState(state, "TargetName")`; transitions resolve by node name

### Enemies
- `Scripts/Enemies/BaseEnemy.gd` — CharacterBody2D base: HP/damage, `take_damage`/`stun`/`kill`/`attack` with animation-await helpers, audio hooks
- Reusable states: `Scripts/States/EnemyIdle|Chase|Attack|Retreat|Summon.gd` (NavigationAgent2D pathfinding)
- Per-enemy behavior via override states (e.g. `EnemyChaseNecromancer`, `EnemyAttackFlailSkeleton`) wired in each enemy scene
- Target: all combatants — including bosses — run on this framework

### Interaction
Autoload `InteractionManager` (registry + prompt label) and `InteractionArea` (`action_name`, `interact` Callable). Areas register/unregister on player contact; the nearest area wins; prompt format "[F] to …".

### Combat Surfaces
- Physics layers 6–9: PlayerHitbox / PlayerHurtbox / EnemyHitbox / EnemyHurtbox (full map in `techContext.md`)
- `Hurtbox` (enemies) → direct `take_damage` routing; `PlayerHurtbox` → mouse-angle check routes parry / reflect / stun / damage

### HUD
Signal-driven: `MainScene.gd` wires player subsystem signals to `heart_bar` and `ItemHud`; no polling.

### Dialogue & Shop
- `NPC_Dialog` paginates lines from text files; NPC scenes embed dialog + shop child nodes and configure costs/items in `_ready`
- Shop UI is CanvasLayer-based; item effects currently route through NPC scripts (pending rewiring onto the inventory API — see `migrationMap.md`)

## Adopted Conventions
| Area | Convention |
|---|---|
| File names | `snake_case` everywhere (`.gd`, `.tscn`, assets); no spaces in file names going forward |
| Class names | `PascalCase` via `class_name` |
| Identifiers | `snake_case` variables/functions; signals as events (`hp_changed`, `*_changed`) |
| Node names | PascalCase; node names referenced by state-machine string transitions must stay stable across renames |
| Globals | `Global` autoload = service locator (player reference, shared enums, cross-scene flags); InteractionManager remains an autoload by design; no ad-hoc globals elsewhere |
| Scene edits | `.tscn`/`.tres` are text and may be edited surgically (see `.clinerules/godot-collaboration.md`) |
| New enemy | Extend `BaseEnemy.gd`; reuse base states; add override states only for unique behavior; wire nav agent + audio in the scene |
| New interactable | `Node2D` + `InteractionArea`; assign the `interact` Callable in `_ready`; keep effects data-driven where possible |
| Folder structure | **Hybrid** — feature bundles under `Entities/` (Player, Enemies, Boss, NPCs, Projectiles, Interactables: scene + scripts + states together); type-based `Systems/` (StateCore, Interaction, Dialogue, Shop), `UI/`, `Levels/` (incl. `room_blocks/`), `Assets/`; the `Global` autoload lives in `Systems/Global/` |
| State transitions | Typed references — states export direct `State` references assigned in the Inspector and validated in `_ready()`; no string-matched node names (target: R-20; string transitions remain until migrated) |
| Enemy state customization | Shared states + exported configuration + hook methods; subclass copy-paste overrides are not used for new enemies (target: R-23) |
| Animation coupling | Signal-driven flow (`animation_finished`, Call Method Tracks for hit windows/sfx); polling waits are superseded (target: R-22) |

## Known Trade-offs (accepted for now)
- "Player" group lookups coexist with `Global.player`; the target access path is `Global.player` (R-20).