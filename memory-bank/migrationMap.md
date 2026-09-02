# Migration Map — Legacy → Target

> **Purpose:** The working map for the refactor: superseded patterns, their target replacements, and entities awaiting rewiring. Entries are **removed as they are fixed** — this file shrinks toward empty.

## API Migration Table
| Legacy (superseded) | Target | Seen in |
|---|---|---|
| `player.coins` / `spendCoin(n)` | `player.inventory.coins` + a spend method on inventory | `Systems/Shop/shop_2.gd` |
| `player.keys` / `useKey()` | `player.inventory.keys` + inventory consumption method | `Entities/Interactables/doors/keyDoor.gd`, `Entities/Interactables/chests/chest.gd` |
| `player.bombs` / `addPotion()` | `player.inventory.bombs` / potions API | `Entities/NPCs/blacksmith.gd`, `Entities/NPCs/potion_seller.gd`, `Entities/Interactables/pickups/potion.gd` |
| `player.upgradeWeapon()` | `weapon.upgrade()` via `PlayerCombat` | `Entities/NPCs/blacksmith.gd` |
| `player.set_maxHP(n)` / `player.maxHP` | `player.combat.max_hp` setter (signal already wired) | `Entities/NPCs/potion_seller.gd` |
| `Global.time_in_seconds` | Not defined anywhere — replace with a typed constant or timer helper | Door, keyDoor, bosskeyDoor, chest, bossKey, `Beam.gd` (boss) |
| `connect("signal", method)` string form | `signal.connect(callable)` | `Entities/Enemies/Hurtbox.gd` |
| `player.acceleration` | `player.movement.acceleration` | `Entities/Projectiles/curse_glyph.gd` (boss) |
| `player.blocking` / `player.take_damage(n)` | `player.combat.blocking` / `player.combat.take_damage(n)` | `Entities/Projectiles/force_wave.gd` (boss) |

## Entities Awaiting Rewiring
| Entity | Note | Target |
|---|---|---|
| `Systems/Shop/shop_2.gd` | Listens for undefined input actions `buy1`/`buy2`; superseded player API | Defined input actions or an interaction-driven purchase flow |
| `Entities/NPCs/blacksmith.gd`, `Entities/NPCs/potion_seller.gd` | Superseded player API; asset paths point to relocated files (`Assets/bombPlaceholder.png` → `Assets/Items/…`, `Assets/plus.png` → `Assets/Hud/…`) | Inventory/combat API + corrected paths |
| The Sorceress | Standalone pre-framework boss; does not extend `BaseEnemy` | Migrate onto the enemy framework + reusable states; absorb misplaced `Idle.gd` (now beside her in `Entities/Boss/TheSorceress/`) |
| Legacy inventory UI (`UI/inventory.gd`, `UI/slot.gd`) | Superseded by `PlayerInventory`; contains indexing bugs | Retire or redesign on the new inventory service |

## Duplicates & Relocations (consolidate during reorganization)
- `Door.gd` duplicate: live script at `Entities/Interactables/doors/Door.gd` (used by `Door.tscn`, `Door2.tscn`); unreferenced legacy copy at `Entities/Interactables/Door.gd` → one canonical door script with key/boss-key variants parameterized (R-31)
- Shop scene consolidation: `Systems/Shop/panel.tscn` / `panel_2.tscn` are the live cards of active `Systems/Shop/shop_2.tscn` → retire in the R-32 rework
- `Entities/Enemies/EnemyStun.gd` is unwired — but the parry-stun mechanic is live via `BaseEnemy.stun()` called from `PlayerHurtbox` → keep the file; unify into the interrupt flow (R-22)
- Naming sweep: spaces in file names (`Systems/StateCore/State Control.gd`, `Entities/Projectiles/Summon Effect.gd`, `Entities/Boss/TheSorceress/Force Current.gd`, `Entities/Boss/TheSorceress/Magic Missile.gd`, vendored pack art like `Flying eye/`, `Take Hit.png`, `All Characters.png`), `Levels/Doungeon.tscn` spelling — `.uid` sidecars travel along; all references updated and verified (R-11)

## Framework Debt (targeted by `refactorPlan.md`)
| Issue | Task |
|---|---|
| String-based state transitions | R-20 |
| Mouse attack/block ignored from idle (input type filter) | R-20 |
| `Global` autoload caches null player/door at startup | R-20 |
| Polling `wait_for_animation` lock-in guards | R-22 |
| Double-delta enemy velocities (framerate-dependent) | R-22 |
| Copy-paste enemy state override classes | R-23 |
| InteractionManager per-frame sort + uncached player lookup | R-30 |
| Per-room duplicated HUD in room blocks | R-40 |
| Legacy `TileMap` wrapper around `TileMapLayer` children | R-40 |
| Framerate-dependent per-tick decay (PlayerAttack `*0.9`, PlayerBlock `*0.75`) | R-20 |
| Red-slime pounce never moves (velocity set while `attacking` blocks `move_and_slide`) | R-22 |
| `Engine.time_scale` not restored if the scene changes mid-freeze (camera) | R-22 |
| `arcane_arrow.gd` lacks screen-exit cleanup (missed shots leak) | R-22 |
| Parry-stun state file unwired (mechanic is method-based) | R-22 |
| Boss projectiles: per-frame `await` timers (magic_missile, energy_star) | R-24 |
| Boss projectiles: motion without delta (force_wave, energy_star) | R-24 |
| Manual `proj._ready()` re-initialization hack (Stars) | R-24 |
| `Beam.gd` loop variable shadows `enemy` export; degree/radian `lerp_angle` mix | R-24 |
| Boss `Summon.gd` scans legacy `TileMap` per summon + debug prints | R-24 |
| No player input freeze during dialogue/shop modals | R-32 / R-33 |
| File/class mismatch `EnemyAttackFlailSkeleton.gd` ↔ `EnemyChaseFlailSkeleton` | R-11 |
| Sorceress-unique projectile hitbox nodes (`energy_star`, `force_wave`, `intervention_light`, boss melee hitbox in `the_sorceress.tscn`) | Legacy `Hitbox.gd`/`projectile_hitbox.gd` deleted 2025-04; nodes load scriptless — physics layers carry hitbox duty now; repaired when the Sorceress migrates | R-24 |