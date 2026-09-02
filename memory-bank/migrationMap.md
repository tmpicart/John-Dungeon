# Migration Map — Legacy → Target

> **Purpose:** The working map for the refactor: superseded patterns, their target replacements, and entities awaiting rewiring. Entries are **removed as they are fixed** — this file shrinks toward empty.

## API Migration Table
| Legacy (superseded) | Target | Seen in |
|---|---|---|
| `player.coins` / `spendCoin(n)` | `player.inventory.coins` + a spend method on inventory | `shop_2.gd` |
| `player.keys` / `useKey()` | `player.inventory.keys` + inventory consumption method | `keyDoor.gd`, `chest.gd` |
| `player.bombs` / `addPotion()` | `player.inventory.bombs` / potions API | `blacksmith.gd`, `potion_seller.gd` |
| `player.upgradeWeapon()` | `weapon.upgrade()` via `PlayerCombat` | `blacksmith.gd` |
| `player.set_maxHP(n)` / `player.maxHP` | `player.combat.max_hp` setter (signal already wired) | `potion_seller.gd` |
| `Global.time_in_seconds` | Not defined anywhere — replace with a typed constant or timer helper | Door, keyDoor, bosskeyDoor, chest, bossKey |
| `Global.Keys` | `player.inventory.keys` | `chest.gd` debug prints |
| `connect("signal", method)` string form | `signal.connect(callable)` | `Hurtbox.gd` |

## Entities Awaiting Rewiring
| Entity | Note | Target |
|---|---|---|
| `shop_2.gd` | Listens for undefined input actions `buy1`/`buy2`; superseded player API | Defined input actions or an interaction-driven purchase flow |
| `blacksmith.gd`, `potion_seller.gd` | Superseded player API; asset paths point to relocated files (`Assets/bombPlaceholder.png` → `Assets/Items/…`, `Assets/plus.png` → `Assets/Hud/…`) | Inventory/combat API + corrected paths |
| `MainMenu.gd` | `_onready()` is not a Godot callback; title textures point to `Assets/Title*.png` (actual: `Assets/Hud/`) | `_ready()` + corrected paths |
| The Sorceress | Standalone pre-framework boss; does not extend `BaseEnemy` | Migrate onto the enemy framework + reusable states; absorb `Scenes/Characters/Idle.gd` (its activate state, currently misplaced) |
| Legacy inventory UI (`Scenes/Items/inventory.gd`, `slot.gd`) | Superseded by `PlayerInventory`; contains indexing bugs | Retire or redesign on the new inventory service |

## Duplicates & Relocations (consolidate during reorganization)
- `Door.gd` exists in `Scripts/Objects/` and `Scenes/Levels/Objects/` → one canonical door script with key/boss-key variants parameterized
- Shop scenes `shop.tscn`, `panel.tscn`, `panel_2.tscn` vs active `shop_2.tscn` → single shop scene
- `blacksmith.tscn` vs `blacksmith_remastered.tscn` → one NPC scene
- Stray media in code folders: `Scenes/Items/KEY.png`, `Scenes/Levels/Objects/BOSS_DOOR.png` + `image.png`, mp3 files under `Scenes/` → `Assets/`
- `Scenes/Weapons/Monsters_Creatures_Fantasy.zip` → extract to `Assets/` or remove from the repository
- Extension-less `walk1`–`walk4` files under `Assets/Sounds/Player*/` → remove
- Empty `Scripts/Dialogue/tutorial` file → remove or fill
- `Scripts/Dialogue/NPC_Dialog.tscn` (a scene under Scripts/) → relocate with the dialogue system
- Naming sweep: spaces in file names (`State Control.gd`, `Summon Effect.gd`, `Force Current.gd`, `Magic Missile.gd`), `Doungeon.tscn` spelling — rename via the Godot editor once the folder structure is decided