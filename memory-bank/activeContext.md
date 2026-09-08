# Active Context - Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (<=60 lines) - history goes to `progress.md`, not here.

## Phase
R-33 dialogue shipped (resource-driven; committed through `e01bc68`). Test room default level with all three NPCs + a boss key. Next: R-40 room-block standard, then R-41 floor parity.

## Conventions
- Dialogue: `DialogueData`/`DialogueStage` `.tres` per speaker (systemPatterns); `PlayerProgress` on the player holds flags + per-speaker stage counters; unified `npc.gd` opens dialogue, hands off to `shop_data` on finish; boss keys taunt via a `boss_taunt` export
- .tres data hazard: 4.7.2 editor saves strip PackedStringArray/StringName from scripted sub-resources - author pages/flags as Array[String]/String (see techContext)
- Prompts auto-anchor above the owner's opaque art (alpha-aware, rotation/scale/flip proof); manager owns the 4px margin + label height; `prompt_offset` is a screen-space nudge only
- Tile room stack / door family / chest family / summon placement: unchanged (see systemPatterns.md)

## In Flight
- Editor playtest of the new prompt anchoring (doors both orientations, chests, boss key, NPCs) - headless gates green

## Verification Gates
- gdlint on touched files (clean); repo baseline in `migrationMap.md`
- `tests/interaction_smoke.tscn` headless - 64 assertions, exit 0 (dialogue + anchoring covered)
- `--headless --import` before headless runs; scenes boot `--quit-after 5`
- After agent disk edits with the editor open: user reloads/restarts the editor before playtesting

## Next Up
1. R-40 room-block standard (TileMapLayer-only stack, room markers, root HUD)
2. R-41 floor parity rebuild on the test-room blocks
3. D-3 dialogue content (new stages now that authoring is safe)

## Open Decisions
- Controller aim model (when pad support lands): direction + soft lock favored; plugs into the PlayerCombat aim API
- Optional: upstream bug report for the 4.7.2 .tres strip (repro steps captured this session)

## Working Agreements (quick recall)
- Commits: agent drafts -> user approves -> commit; memory bank follows as `docs(memory)`. Push only when instructed.
- Pre-flight before any commit pause: repo-wide gdlint baseline + scoped gate on touched files, both green.
- Circuit breaker: 3 failed attempts on a step -> stop, report, defer.
- Scene text edits surgical; editor-made changes never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.