# Progress — Status & Log

> **Purpose:** Feature status and a compact work log. One line per task; caps and archiving rules in `.clinerules/log-hygiene.md`.

## Refactor Status

### Working on the new framework
- Player subsystems: movement/dash, combat + parry/reflect, inventory, animation ✔
- Enemy base class + pathfinding states (idle/chase/attack/retreat/summon) ✔
- Regular enemies: slimes, arcane archer, flail skeleton, necromancer behaviors ✔
- Interaction manager/areas, HUD wiring, main-menu → Floor1 flow ✔

### Pending migration (details in `migrationMap.md`)
- Shop item effects → route through `PlayerInventory` / `PlayerCombat` APIs
- Doors/chests → replace undefined `Global` helpers with inventory service calls
- The Sorceress (boss) → migrate onto the enemy framework + current states
- MainMenu polish (title card load), dialogue system expansion
- Legacy inventory UI (`Scenes/Items/inventory.gd`) → superseded by `PlayerInventory`; retire or redesign
- Level content → rebuild from the original level into modular room blocks

## Log
- 2026-09-02 | setup | Audited codebase; established memory bank + clinerules; accepted Godot 4.7 importer metadata migration (240 `.import` files).
- 2026-09-02 | planning | Adopted hybrid structure and framework decisions; authored `refactorPlan.md` (R0–R4) and `devPlan.md` (D-1..D-7).