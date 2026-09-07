# Active Context - Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (<=60 lines) - history goes to `progress.md`, not here.

## Phase
Test room is the default level (main menu -> test_room; floor_1 deleted) on the shared `assets/tilesets/custom_dungeon.tres` with the Ground/Decals/Walls/Overhead stack - the R-40 room standard starts here. Next: R-33 dialogue.

## Conventions
- Tile room stack: Ground (z -1, nav + is_summonable), Decals (z -1, collision+nav off), Walls (z 0, physics), Overhead (z 10, collision optional - only tiles with painted polygons go solid, nav off); room root y-sorted; entities z 0, player root z 3
- Door family: key_door.tscn (locked, `key_door_sheet.png`) / door_red.tscn (no-lock, eli art, rotate the instance for wall sides) / no_open.tscn (decorative sealed) / door.tscn + door_2.tscn (kept, unused). Labels retired - locked feedback flashes the world-space prompt "You Need a Key To Open!" for 1s via `InteractionManager.refresh_prompt`
- Chest family: chest.tscn = key chest (red sheet frame 1 locked -> frame 2 open; `requires_key` consumes a key, prompt flash on failure) / chest_no_key.tscn = free chest; key-drop behavior retired
- Summon placement: the `is_summonable` flood-fill now occupancy-guards every candidate (8px circle vs Player/Enemies/Environment/Interactables, excludes the summoner) and re-checks at materialize after the telegraph
- Doors/boss key/aim/reflect/parry/summon/interaction/loot/shop conventions unchanged (see `systemPatterns.md`)
- gdlint scoped gate: rewritten files pass clean; baseline in `migrationMap.md`

## In Flight
- Playtest confirmation in the editor: red door animation + rotation on wall sides, locked chest consume/fail flow, prompt flashes, summon placement avoiding chests/player, Overhead depth

## Verification Gates
- gdlint on touched files (clean); repo baseline in `migrationMap.md`
- `tests/interaction_smoke.tscn` headless - 32 assertions, exit 0
- `--headless --import` before headless runs; scenes boot `--quit-after 5`
- After agent disk edits with the editor open: user reloads scene tabs before playtesting

## Next Up
1. R-33 dialogue system (JSON pages, `PlayerProgress`, boss-key message box) - reuses the R-32 modal-freeze pattern
2. R-41 floor rebuild: boss progression (boss door/key, altar, NPCs) re-instances onto test-room blocks
3. HUD restyle (fold into R-40 or a dedicated pass)

## Open Decisions
- Controller aim model (when pad support lands): direction + soft lock favored; plugs into the PlayerCombat aim API

## Working Agreements (quick recall)
- Commits: agent drafts -> user approves -> commit; memory bank follows as `docs(memory)`. Push only when instructed.
- Pre-flight before any commit pause: repo-wide gdlint baseline + scoped gate on touched files, both green.
- Circuit breaker: 3 failed attempts on a step -> stop, report, defer.
- Scene text edits surgical; editor-made changes never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.