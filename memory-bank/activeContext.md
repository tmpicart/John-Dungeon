# Active Context - Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (<=60 lines) - history goes to `progress.md`, not here.

## Phase
Development phase. Post-nav-rework (2026-09-30, 8 commits on origin/master);
door family standardization landed 2026-10-04 as a 7-commit series.

## Just Landed
- Door family standard: `door_red` = reference scene; `door_key` matched
  exactly (colliders, interaction, PassageLink) and seated in the test_room
  west archway (rotated -PI/2 per convention)
- Deprecated doors deleted: `door_sealed`, `door_standard_1/2`; boss door
  root renamed BossDoor (pre-standard geometry until R-42)
- BUG-2 resolved: character roots z 3, airborne projectiles z 4 (14 scenes)
- `tests/level_nav_probe` archway sweeps: link connects, sever + annex verified

## Working Agreements
- Enemy states are shared (`states/enemy_chase|attack|retreat.gd`);
  per-enemy behavior = exported config on the scene, not script overrides
- Player references: `Global.player` at point of use; layer bits for
  physics identity; groups for broadcast only
- Door scenes: author new doors as door_red/door_key siblings — shared
  geometry per the systemPatterns "Door scenes" row; never fork a variant
- Aim, flight, and nav all key off the Environment bit — check the
  layer-consumer table in `techContext.md` before adding layers
- Unwalkable ≠ solid: carve nav via `BLOCKER_LAYER_NAMES`, never by
  reusing the Environment bit
- Wall-decor rule: alignment-sensitive decor = entity; filler decor = tile

## Known Limits (accepted)
- Bodies >8 px wide need per-size-class nav maps (R-43); today's discs
  (5.88–7.14 px) fit the single map; 3-ray aim is ray-thin (R-44 pending)
- `Environment` container not y-sorted: chests/props sort vs player as
  one block; fix deliberately in R-40/R-41
- Stale editor script cache strips unknown exports on save - restart
  editor after agent disk edits
- Seated key-door slab now fully blocks projectiles at the west archway
  (side effect of the Environment-blocker convention)

## Verification Gates
- gdlint on touched files; baseline in `techContext.md`
- `tests/interaction_smoke.tscn` headless - 66 assertions (local-only now; needs assets on disk)
- Headless probes: nav_probe, level_nav_probe, chase_probe, retreat_probe
  (the result txt files are the record)
- `--headless --import` before headless runs; PowerShell `Start-Process -Wait -PassThru`
- After agent disk edits with editor open: user restarts editor before playtesting

## Next Up
1. User playtest: key door lock/open at the west archway; sprite layering
   in doorways; reload test_room.tscn in the editor before editing it
2. BUG-1 (doorway pathing stall) + BUG-3 (necromancer missile rework)
3. R-40 room-block standard, then R-41 tier-1 slice

## Open Decisions
- Wand input binding + potion carry model: settle at S-5/S-6 implementation
- Depth room-mix shape + director numbers: provisional until playtest
- Public release: replace unknown-origin assets (HUD art, ~20 SFX); BDragon1727 VFX requires creator contribution for commercial use
