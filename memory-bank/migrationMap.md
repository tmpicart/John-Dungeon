# Migration Map — Legacy → Target

> **Purpose:** The working map for the refactor: superseded patterns, their target replacements, and entities awaiting rewiring. Entries are **removed as they are fixed** — this file shrinks toward empty.

## API Migration Table
| Legacy (superseded) | Target | Seen in |
|---|---|---|
| `Global.time_in_seconds` | Replace with local timing constants | `entities/boss/the_sorceress/beam.gd` (R-24), unreferenced duplicate `entities/interactables/door.gd` (R-31) |
| `connect("signal", method)` string form | `signal.connect(callable)` | `entities/Enemies/hurtbox.gd` |
| `player.acceleration` | `player.movement.acceleration` | `entities/Projectiles/curse_glyph.gd` (boss) |
| `player.blocking` / `player.take_damage(n)` | `player.combat.blocking` / `player.combat.take_damage(n)` | `entities/Projectiles/force_wave.gd` (boss) |

## Entities Awaiting Rewiring
| Entity | Note | Target |
|---|---|---|
| `systems/shop/shop_2.gd` | Purchases rewired onto the inventory API (R-21); `buy1`/`buy2` keys are a temporary bridge | Mouse-card `ShopData` shop retires the script (R-32) |
| The Sorceress | Standalone pre-framework boss; does not extend `BaseEnemy` | Migrate onto the enemy framework + reusable states; absorb misplaced `idle.gd` (now beside her in `entities/Boss/TheSorceress/`) |
| Legacy inventory UI (`ui/inventory.gd`, `ui/slot.gd`) | Superseded by `PlayerInventory`; contains indexing bugs | Retire or redesign on the new inventory service |

## Duplicates & Relocations (consolidate during reorganization)
- `Door.gd` duplicate: live script at `entities/Interactables/doors/door.gd` (used by `door.tscn`, `door_2.tscn`); unreferenced legacy copy at `entities/Interactables/door.gd` → one canonical door script with key/boss-key variants parameterized (R-31)
- `entities/interactables/chests/chest.gd` is referenced by no scene — both chest scenes run `chest_no_key.gd`; rewired onto the inventory API in R-21 regardless; retire or make canonical in the chest consolidation (R-31)
- Shop scene consolidation: `systems/Shop/panel.tscn` / `panel_2.tscn` are the live cards of active `systems/Shop/shop_2.tscn` → retire in the R-32 rework
- `entities/Enemies/enemy_stun.gd` is unwired — but the parry-stun mechanic is live via `BaseEnemy.stun()` called from `PlayerHurtbox` → keep the file; unify into the interrupt flow (R-22)

## Framework Debt (targeted by `refactorPlan.md`)
| Issue | Task |
|---|---|
| String-based state transitions in enemy/boss states (player states are typed; strings bridge through `transition_to("Name")`) | R-23 |
| Polling `wait_for_animation` lock-in guards | R-22 |
| Double-delta enemy velocities (framerate-dependent) | R-22 |
| Copy-paste enemy state override classes | R-23 |
| camelCase/PascalCase identifiers (`rayCast`, `textFile`, `openShop`/`closeShop`, chest `Path`/`Inv`) plus class-definitions-order and blank-line-whitespace findings in surgically-touched scripts — normalize to snake_case per the GDScript style guide (state-core identifiers `Physics_Update`/`ChangeState` done in R-20; gdlint re-baselined at 48 findings after R-21) | R-22 / R-23 / R-32 / R-33 |
| InteractionManager per-frame sort + uncached player lookup | R-30 |
| Per-room duplicated HUD in room blocks | R-40 |
| Legacy `TileMap` wrapper around `TileMapLayer` children | R-40 |
| Red-slime pounce never moves (velocity set while `attacking` blocks `move_and_slide`) | R-22 |
| `Engine.time_scale` not restored if the scene changes mid-freeze (camera) | R-22 |
| `arcane_arrow.gd` lacks screen-exit cleanup (missed shots leak) | R-22 |
| Parry-stun state file unwired (mechanic is method-based) | R-22 |
| Boss projectiles: per-frame `await` timers (magic_missile, energy_star) | R-24 |
| Boss projectiles: motion without delta (force_wave, energy_star) | R-24 |
| Manual `proj._ready()` re-initialization hack (Stars) | R-24 |
| `beam.gd` loop variable shadows `enemy` export; degree/radian `lerp_angle` mix | R-24 |
| Boss `summon.gd` scans legacy `TileMap` per summon + debug prints | R-24 |
| No player input freeze during dialogue/shop modals | R-32 / R-33 |
| Sorceress-unique projectile hitbox nodes (`energy_star`, `force_wave`, `intervention_light`, boss melee hitbox in `the_sorceress.tscn`) | Legacy `Hitbox.gd`/`projectile_hitbox.gd` deleted 2025-04; nodes load scriptless — physics layers carry hitbox duty now; repaired when the Sorceress migrates | R-24 |