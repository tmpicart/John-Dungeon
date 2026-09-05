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
- `entities/enemies/base_enemy.gd` — `BaseEnemy` CharacterBody2D base: `hp`/`damage`/`attack_cooldown_duration` exports; typed interrupt routing (`state_control`/`hurt_state`/`stun_state` exports, validated in `_ready`); signal-driven action flows (`run_action_animation` → `attack`) guarded by interrupt flow tokens; `take_damage(dmg, from_position)` knockback-ready; `attack_sfx_from_animation` for animation-triggered swing sounds; audio hooks
- Reusable states: `entities/enemies/states/enemy_idle|chase|attack|retreat|hurt|stun|summon|pounce.gd` — every enemy scene configures the same state set through exports (typed state refs wired `../`-prefixed; ranges/speeds/cooldowns/flags per scene); bundles hold scene + scripts + states together
- Per-enemy behavior = exported configuration (R-23): `EnemyChase` (proximity/hit retreat, line-of-sight, radial/axis-box ranges, approach stop, summon rolls; unassigned `attack_state` = validated pacifist), `EnemyAttack` (projectile sets), `EnemySummon` (composition + cooldown owned by the state; same-room flood-fill over summonable tiles; R-43 room markers supersede tile scanning; the flourish effect is the telegraph — creatures materialize `spawn_delay` later, dead summoner cancels). State subclasses only for genuinely unique behavior (`EnemyPounce` lunge; red slime's death/explode semantics live on its enemy script)
- Velocities are px/s — never multiplied by delta (`move_and_slide` applies the tick delta)
- Target: all combatants — including bosses — run on this framework

### Interaction
Autoload `InteractionManager` (registry + world-space prompt) and `Interactable` (Area2D: `prompt`, `enabled`, `one_shot`, `auto_pickup`, `interacted` signal). Areas self-register on player contact and unregister on `_exit_tree`; the nearest area wins; nearest is re-resolved only on registry change or keypress (no per-frame scans); player resolves via `Global.player`; freed entries are pruned; prompt prefix derives from the `interact` input binding; `set_locked()` freezes interaction for future modals.
- Universal pickups: `Pickup` (extends `Interactable`; `pickup.tscn` bakes auto + one-shot) + `PickupItem` (item root: desynced bob, fake-height `scatter()`/`eject()` with bounces, collection gated until settle + `pickup_delay`, airborne z+1, front-hemisphere scatter default, `loot_tier`/`loot_value` exports)
- Loot: `LootTable` resource (`tier`, `entries: Array[PackedScene]`) — `roll(budget)` picks random affordable entries until spent; item scenes own pricing (single source of truth); a value-1 entry guarantees exact sums. Chests: `drop_scene` (deterministic progression) + `loot_table`/`loot_value` (rolled); keys/boss keys are progression (tier −1, never rolled)

### Combat Surfaces
- Physics layers 6–9: PlayerHitbox / PlayerHurtbox / EnemyHitbox / EnemyHurtbox (full map in `techContext.md`)
- Damage roles: hurtboxes resolve `hitbox.get("damage")` first, falling back to `hitbox.owner.damage` — scripted `EnemyHitbox` surfaces (entities/enemies/hitbox.gd) carry per-surface values (boss swing 2 / slide 1); plain areas resolve the owner's export. `unblockable` (same probe) makes PlayerHurtbox skip its parry branch — waves, intervention light, and stars are dodge-only; magic missiles reflect
- `Hurtbox` (enemies) → direct `take_damage` routing; `PlayerHurtbox` → mouse-angle check routes parry / reflect / stun / damage; block+facing a non-interruptible boss's body hitbox (melee/slide) routes her `stun()` → parry-stagger (freeze-frame + doubled damage); projectiles reflect (missiles) or are unblockable (waves/stars/light); beam recovery keeps the exposure-only window
- Player aim API (`PlayerCombat`): `aim_direction()` (player→cursor vector; feeds the parry cone and reflect launches) and `get_aim_target()` — EnemyHurtbox shape query centered on the cursor within `aim_snap_radius`, nearest surface wins (layer-first, no group scans; physics-step only). Facing direction is the input-agnostic aim primitive; the controller model is an open decision (reticle vs direction + soft lock)

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
| New interactable | Node + `Interactable` child (or instance `pickup.tscn` for walk-over items); connect `interacted`, configure `prompt`/`one_shot`/`auto_pickup` in the scene; toggle `enabled` instead of poking collision shapes |
| Folder structure | **Hybrid** — all folders snake_case (Godot docs): feature bundles under `entities/` (player, enemies, boss, npcs, projectiles, interactables — scene + scripts + states together); type-based `systems/` (state_core, interaction, dialogue, shop), `ui/`, `levels/` (incl. `room_blocks/`), `assets/` (vendored art packs — documented basic-assets exception to `addons/`); the `Global` autoload lives in `systems/global/` |
| State transitions | Typed references — states export direct `State` references wired in the Inspector and validated at startup (deferred ready pass); player and enemy states have no string-matched names. Godot 4.7 loader quirk: sibling references in `.tscn` must be `../`-prefixed — bare sibling NodePaths load as null |
| Enemy state customization | Shared states + exported configuration (landed R-23); state subclasses only for genuinely unique behavior (e.g. `EnemyPounce`) |
| Rendering tiers | z-index: ground decals + floor TileMapLayer −1, y-sorted world 0, airborne (projectiles, beam line) +1, UI on CanvasLayer |
| Flash palette | On-hit flash WHITE for enemies, RED for the player; stun/vulnerable YELLOW `Color(1, 1, 0, 1)` pulsed on a `FlashPlayer` animation channel (per-animation flash_color tracks own the color) |
| Non-interruptible bosses | `interruptible = false`: hits flash + damage only; a parried body hitbox staggers via the boss `stun()` override (`boss_stagger` state: freeze-frame + exposure, doubled damage); attack surfaces are animation-track- or code-driven, so interrupts and death must kill them (`disable_attack_surfaces()` + slide `exit()` cleanups); summon placement needs `is_summonable`-painted tiles and skips cleanly without |
| Reflectable projectiles | one Area2D (`Hitbox`): `collision_layer` swaps at reflect (8→6) for victim-side damage pairing; `collision_mask` carries lifetime — Player + Environment pre, Enemies + Environment post (no piercing); `body_entered` self-frees; missiles launch `reflect_arc_deg` wide and re-lock `get_aim_target()` whenever targetless |
| Animation coupling | Signal-driven flow (`await animation_finished` + interrupt flow tokens, Call Method Tracks for hit windows/sfx); polling waits removed (R-22) |

## Known Trade-offs (accepted for now)
- Player states receive the character via the injected `actor` reference; `Global.player` (property-backed; re-resolves freed/missing refs) remains the access path for non-state consumers.