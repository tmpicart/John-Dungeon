# Migration Map — Legacy → Target

> **Purpose:** The working map for the refactor: superseded patterns, their target replacements, and entities awaiting rewiring. Entries are **removed as they are fixed** — this file shrinks toward empty.

## API Migration Table
| Legacy (superseded) | Target | Seen in |
|---|---|---|
| `player.coins` / `spendCoin(n)` | `player.inventory.coins` + a spend method on inventory | `shop_2.gd` |
| `player.keys` / `useKey()` | `player.inventory.keys` + inventory consumption method | `keyDoor.gd`, `chest.gd` |
| `player.bombs` / `addPotion()` | `player.inventory.bombs` / potions API | `blacksmith.gd`, `potion_seller.gd`, `potion.gd` |
| `player.upgradeWeapon()` | `weapon.upgrade()` via `PlayerCombat` | `blacksmith.gd` |
| `player.set_maxHP(n)` / `player.maxHP` | `player.combat.max_hp` setter (signal already wired) | `potion_seller.gd` |
| `Global.time_in_seconds` | Not defined anywhere — replace with a typed constant or timer helper | Door, keyDoor, bosskeyDoor, chest, bossKey, `Beam.gd` (boss) |
| `connect("signal", method)` string form | `signal.connect(callable)` | `Hurtbox.gd` |
| `player.acceleration` | `player.movement.acceleration` | `curse_glyph.gd` (boss) |
| `player.blocking` / `player.take_damage(n)` | `player.combat.blocking` / `player.combat.take_damage(n)` | `force_wave.gd` (boss) |

## Entities Awaiting Rewiring
| Entity | Note | Target |
|---|---|---|
| `shop_2.gd` | Listens for undefined input actions `buy1`/`buy2`; superseded player API | Defined input actions or an interaction-driven purchase flow |
| `blacksmith.gd`, `potion_seller.gd` | Superseded player API; asset paths point to relocated files (`Assets/bombPlaceholder.png` → `Assets/Items/…`, `Assets/plus.png` → `Assets/Hud/…`) | Inventory/combat API + corrected paths |
| The Sorceress | Standalone pre-framework boss; does not extend `BaseEnemy` | Migrate onto the enemy framework + reusable states; absorb `Scenes/Characters/Idle.gd` (its activate state, currently misplaced) |
| Legacy inventory UI (`Scenes/Items/inventory.gd`, `slot.gd`) | Superseded by `PlayerInventory`; contains indexing bugs | Retire or redesign on the new inventory service |

## Duplicates & Relocations (consolidate during reorganization)
- `Door.gd` exists in `Scripts/Objects/` and `Scenes/Levels/Objects/` → one canonical door script with key/boss-key variants parameterized
- Shop scene consolidation: `panel.tscn` / `panel_2.tscn` are the live cards of active `shop_2.tscn`; legacy `shop.tscn` already removed → retire in the R-32 rework
- Stray media in code folders: `Scenes/Items/KEY.png`, `Scenes/Levels/Objects/BOSS_DOOR.png` + `image.png`, mp3 files under `Scenes/` → `Assets/` (keyDoor already points at the Assets copy of `image.png`; the Scenes copy is unreferenced)
- `Scripts/Dialogue/NPC_Dialog.tscn` (a scene under Scripts/) → relocate with the dialogue system
- The real summon state `Scripts/Projectiles and Effects/EnemySummon.gd` (a state misplaced among projectiles) → relocate into the necromancer bundle (R-10)
- Tileset double-vendored: `Assets/Tilesets/Dungeon_Tileset.png` ≡ `Assets/2D Pixel Dungeon Asset Pack/character and tileset/Dungeon_Tileset.png` — byte-identical, distinct uids; rooms split across both copies (ChestRoomLeft/Right, HallWay, HallWayVert → Tilesets; MultiRoom, Starting Room, torch.tscn → pack copy) → repoint to one copy, delete the other (R-10)
- Door sound double-vendored: `Assets/Sounds/dorm-door-opening-6038.mp3` ≡ `Scenes/Levels/Objects/dorm-door-opening-6038.mp3` (keyDoor.tscn → Assets copy; BossDoor.tscn → Scenes copy) → repoint BossDoor, delete the stray (R-10)
- `Scenes/Characters/EnemyStun.gd` is unwired — but the parry-stun mechanic is live via `BaseEnemy.stun()` called from `PlayerHurtbox` → keep the file; unify into the interrupt flow (R-22)
- Naming sweep: spaces in file names (`State Control.gd`, `Summon Effect.gd`, `Force Current.gd`, `Magic Missile.gd`, vendored pack art like `Flying eye/`, `Take Hit.png`, `All Characters.png`), `Doungeon.tscn` spelling — rename via the Godot editor once the folder structure is decided

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