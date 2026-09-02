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
- 2026-09-02 | refactor | R-01 dead-file purge: 31 tracked files removed (orphans, junk audio copies, skeleton-dup sheets, zip); zero refs verified by path + uid.
- 2026-09-02 | assets | Vendored Monsters_Creatures_Fantasy (21 sheets) + Enemy_Animations_Set (16 sheets + Aseprite) under Assets/; v2.0 pack download confirmed byte-duplicate of the vendored copy.
- 2026-09-02 | refactor | R-02 debug-spam removal: 24 prints + 7 dead #print lines + 3 empty _process stubs dropped; error paths → push_error/push_warning (8aab1a4).
- 2026-09-02 | fix | R-03 MainMenu startup: _ready() + random title from Assets/Hud via preload; node renamed TitleCard (1fef410).
- 2026-09-02 | refactor | R-10 hybrid tree: 146 files → Entities/Systems/UI/Levels/room_blocks; dedupe tileset + door sound; every res:// ref + autoload/main-scene anchors rewritten; 4 stale Sorceress-projectile hitbox refs documented → R-24 (983dbfc).
- 2026-09-02 | refactor | R-11 snake_case sweep: 744 paths renamed (29 asset folders, ~140 assets, 78 scripts/scenes + .uid sidecars, dialogue txt), 2 file/class mismatches fixed, 543 path refs rewritten; all 5 verification gates green (67d4588).
- 2026-09-02 | refactor | R-12 folder snake_case: 22 game folders incl. `Assets`→`assets` lowercased per Godot docs; ~850 paths + 355 reference files rewritten; gates green + silent headless run (cc1df32).