# Active Context - Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (<=60 lines) - history goes to `progress.md`, not here.

## Phase
R-40 in progress: prop foundation shipped (`ed4d33e`) - entities/props family (wall_torch, side_torch, candlestick, candlestick_2), key rotation, potion anim cleanup, torch_wall moved out of room_blocks. Next: the room-block standard itself, then R-41 floor parity.

## Conventions
- Props: scriptless scenes in `entities/props/` - AnimatedSprite2D autoplay `default` 5.7 fps, radial PointLight2D, foot blocker StaticBody2D on Environment (layer 4); wall-mounted props at z 10 (Overhead tier), floor props z 0 y-sorted; side torch is left-facing (flip H per side)
- Pack per-frame art (torch_1..4, candlestick_1/2_*) is distinct art from the objects/ strips (wall_torch_h, torch_animation) - verified pixel-level, not interchangeable
- Pickup animation: universal coded bob in pickup_item.gd; frame animations ride on top (coin/key rotate at 4 fps); no baked-bob sheets (potion.png frames are identical - its no-op AnimationPlayer was removed)
- .tres data hazard: 4.7.2 editor saves strip PackedStringArray/StringName from scripted sub-resources - author pages/flags as Array[String]/String (see techContext)
- Tile room stack / door family / chest family / dialogue: unchanged (see systemPatterns.md)

## In Flight
- nothing - props landed clean; user to visually confirm candle flicker + blockers in a fresh editor session

## Verification Gates
- gdlint on touched files (clean); repo baseline in `migrationMap.md` (ui area now 0)
- `tests/interaction_smoke.tscn` headless - 66 assertions, exit 0
- `--headless --import` before headless runs; scenes boot `--quit-after 5`; boots launched immediately after an import can exit 1 silently - rerun after a short settle delay
- After agent disk edits with the editor open: user restarts the editor before playtesting (stale in-memory scenes caused false bug reports this session)

## Next Up
1. R-40 room-block standard - author new templates on custom_dungeon.tres (slots + variant model; typed Door/Spawn/ChestSlot/DecorSlot markers)
2. R-41 floor parity rebuild on the template set (old room_blocks + dungeon.tscn retire here)
3. D-3 dialogue content

## Open Decisions
- side_torch facing variants (single scene + flip vs left/right scenes) if flipping proves awkward in practice
- standing torch removed by decision; revisit only if a floor torch is wanted (pack torch_1..4 art exists)
- Optional: upstream bug report for the 4.7.2 .tres strip (repro steps captured)

## Working Agreements (quick recall)
- Commits: agent drafts -> user approves -> commit; memory bank follows as `docs(memory)`. Push only when instructed.
- Pre-flight before any commit pause: repo-wide gdlint baseline + scoped gate on touched files, both green.
- Circuit breaker: 3 failed attempts on a step -> stop, report, defer.
- Scene text edits surgical; editor-made changes never reverted silently (editor-assigned scene uids get adopted into file headers).