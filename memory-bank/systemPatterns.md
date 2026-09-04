# System Patterns — Architecture & Conventions

> **Purpose:** The agreed architecture and conventions. New code follows this file; patterns marked superseded in `migrationMap.md` are not to be extended.

## Architecture Map

### Player (`entities/player/character.tscn`)
Hub-and-subsystems: `Character.gd` delegates to child subsystem nodes and a state machine.
- `PlayerMovement` — acceleration/friction movement, dash with cooldown timer
- `PlayerCombat` — HP, attack/block execution, damage intake, `upgrade_weapon()` (resyncs cached damage); signals `hp_changed`, `max_hp_changed`
- `PlayerInventory` — coins/bombs/potions/keys; public API `add_coin`/`spend_coins`/`add_key`/`consume_key`/`add_potion`/`add_bomb`/`use_potion`/`use_bomb` — atomic spend/consume return `bool`; every mutation emits its `*_changed` signal; callers never write the count fields directly
- `PlayerAnimation` — 4-direction mouse-facing animation routing, equipment layering (weapon/shield foreground vs background)
- `State Control` — generic state machine (`systems/state_core/state.gd`, `state_control.gd`): states call `transition_to(target)` — typed `State` refs on the player, node-name strings bridged until R-23; the control injects `actor` (the owning entity) into every state and validates exported refs at startup

### Enemies
- `entities/enemies/base_enemy.gd` — CharacterBody2D base: `hp`/`damage`/`attack_cooldown_duration` exports; signal-driven action flows (`run_action_animation` → `attack`/`summon`) guarded by interrupt flow tokens; `take_damage(dmg, from_position)` knockback-ready; `stun()`/`kill()` route interrupts through State Control; audio hooks
- Reusable states: `entities/enemies/states/enemy_idle|chase|attack|retreat|hurt|stun.gd` (pathfinding + interrupt states; every enemy scene wires `EnemyHurt`/`EnemyStun`); bundles hold scene + scripts + states together
- Per-enemy behavior via override states (e.g. `EnemyChaseNecromancer`, `EnemyAttackFlailSkeleton`) wired in each enemy scene
- Velocities are px/s — never multiplied by delta (`move_and_slide` applies the tick delta)
- Summoning: shared combatant capability (necromancer now; Sorceress R-24; future bosses by design) — R-23 promotes a shared `EnemySummon` state: radius + summonable-tile gating with a same-room flood-fill failsafe; only composition is per-summoner; R-43 room markers supersede tile scanning
- Target: all combatants — including bosses — run on this framework

### Interaction
Autoload `InteractionManager` (registry + prompt label) and `InteractionArea` (`action_name`, `interact` Callable). Areas register/unregister on player contact; the nearest area wins; prompt format "[F] to …".

### Combat Surfaces
- Physics layers 6–9: PlayerHitbox / PlayerHurtbox / EnemyHitbox / EnemyHurtbox (full map in `techContext.md`)
- `Hurtbox` (enemies) → direct `take_damage` routing; `PlayerHurtbox` → mouse-angle check routes parry / reflect / stun / damage

### HUD
Signal-driven: `main_scene.gd` wires player subsystem signals to `heart_bar` and `item_hud`; no polling.

### Dialogue & Shop
- `npc_dialog` paginates lines from text files; NPC scenes embed dialog + shop child nodes and configure costs/items in `_ready`
- Shop UI is CanvasLayer-based; item effects currently route through NPC scripts (pending rewiring onto the inventory API — see `migrationMap.md`)

## Adopted Conventions
| Area | Convention |
|---|---|
| File & folder names | `snake_case` everywhere per the Godot project-organization docs (exported PCKs are case-sensitive); no spaces; node names stay PascalCase |
| Class names | `PascalCase` via `class_name` |
| Identifiers | `snake_case` variables/functions; signals as events (`hp_changed`, `*_changed`) |
| Node names | PascalCase; node names referenced by state-machine string transitions must stay stable across renames |
| Globals | `Global` autoload = service locator (player reference, shared enums, cross-scene flags); InteractionManager remains an autoload by design; no ad-hoc globals elsewhere |
| Scene edits | `.tscn`/`.tres` are text and may be edited surgically (see `.clinerules/godot-collaboration.md`) |
| New enemy | Extend `BaseEnemy.gd`; reuse base states; add override states only for unique behavior; wire nav agent + audio in the scene |
| New interactable | `Node2D` + `InteractionArea`; assign the `interact` Callable in `_ready`; keep effects data-driven where possible |
| Folder structure | **Hybrid** — all folders snake_case (Godot docs): feature bundles under `entities/` (player, enemies, boss, npcs, projectiles, interactables — scene + scripts + states together); type-based `systems/` (state_core, interaction, dialogue, shop), `ui/`, `levels/` (incl. `room_blocks/`), `assets/` (vendored art packs — documented basic-assets exception to `addons/`); the `Global` autoload lives in `systems/global/` |
| State transitions | Typed references — states export direct `State` references wired in the Inspector and validated at startup (deferred ready pass); player states have no string-matched names (enemy/boss bridge strings until R-23). Godot 4.7 loader quirk: sibling references in `.tscn` must be `../`-prefixed — bare sibling NodePaths load as null |
| Enemy state customization | Shared states + exported configuration + hook methods; subclass copy-paste overrides are not used for new enemies (target: R-23) |
| Animation coupling | Signal-driven flow (`await animation_finished` + interrupt flow tokens, Call Method Tracks for hit windows/sfx); polling waits removed (R-22) |

## Known Trade-offs (accepted for now)
- Player states receive the character via the injected `actor` reference; `Global.player` (property-backed; re-resolves freed/missing refs) remains the access path for non-state consumers.