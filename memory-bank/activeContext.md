# Active Context - Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (<=60 lines) - history goes to `progress.md`, not here.

## Phase
R-32 shipped (81b2f5d): ShopData-driven mouse shop with modal input freeze; Max HP+ moved to a new NPC-less altar; shopkeeps + altar on floor_1; legacy shop/inventory UI retired. Next: R-33 dialogue.

## Conventions
- Shop: any `Interactable` owner attaches a `ShopData` (title + `ShopItem` entries); `ShopItem` subclasses own `grant(player)` (bomb/potion/sword_upgrade/max_hp under `systems/shop/items/`); shared `shop.tscn` builds one card per entry - hover highlight, atomic `spend_coins` -> `grant`, live coin bar, MAX/greyed states; caps are session-scoped
- Modal freeze: `Global.player.set_input_locked(true)` + `InteractionManager.set_locked(true)`; gates state input routing + combat (invulnerable while open); movement stays live so walk-away works - R-33 dialogue reuses this
- Walk-away close: shop and dialogue both close at 140 px; dialogue grants `spoke` only when pages are finished (talk-first still gates the shop)
- Shop UI: dark flat slab (StyleBoxFlat + black border + shadow), parchment text, 0.3 world dim; modal layers default hidden in scenes (level editor stays clean)
- Stock: nurse = potions; altar = Max HP+ (6x); blacksmith = bomb + Sword lvl+ (3x), single-frame AtlasTexture icons
- Doors/boss key/aim/reflect/parry/summon/interaction/loot conventions unchanged (see `systemPatterns.md`)
- gdlint scoped gate: rewritten files pass clean; `npc_dialog.gd` keeps 3 R-33-owned findings; baseline in `migrationMap.md`

## In Flight
- Playtest confirmation of R-32 in the editor: mouse buy flow, caps/MAX states, Esc + walk-away closes, freeze while open, coin bar spacing

## Verification Gates
- gdlint on touched files (clean); repo baseline in `migrationMap.md`
- `tests/interaction_smoke.tscn` headless - 32 assertions, exit 0; deletes `smoke_result.txt` after
- `--headless --import` before headless runs; scene boots `--quit-after 5`
- After agent disk edits with the editor open: user reloads scene tabs before playtesting

## Next Up
1. R-33 dialogue system (JSON pages, `PlayerProgress`, boss-key message box) - reuses the R-32 modal-freeze pattern
2. HUD restyle (user: current HUD "looks awful") - fold into R-40 or a dedicated pass
3. D-plan hooks: monster coin drops (D-1), expanded stock (D-2), allies faction registry (D-5)

## Open Decisions
- Controller aim model (when pad support lands): direction + soft lock favored; plugs into the PlayerCombat aim API

## Working Agreements (quick recall)
- Commits: agent drafts -> user approves -> commit; memory bank follows as `docs(memory)`. Push only when instructed.
- Pre-flight before any commit pause: repo-wide gdlint baseline + scoped gate on touched files, both green.
- Circuit breaker: 3 failed attempts on a step -> stop, report, defer.
- Scene text edits surgical; editor-made changes never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.