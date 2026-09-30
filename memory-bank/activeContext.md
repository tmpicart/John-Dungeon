# Active Context - Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (<=60 lines) - history goes to `progress.md`, not here.

## Phase
Development phase. The AI navigation rework landed on `origin/master` as a
reviewed 8-commit series (2026-09-30): runtime navmesh baking, width-aware
aim, shared chase/attack states, escape-scored retreat, docs.

## Just Landed
- NavBaker: Environment cells carved from the navmesh at agent clearance;
  main_scene bakes once at load
- BaseEnemy aim gate: 3-ray check vs the Environment layer (2px clearance,
  hit-from-inside guard); arrow flight identity via Global.player
- Shared chase/attack states on the baked mesh; RVO avoidance live on all
  five enemies; navmesh-scored retreat with a cornered-fight latch
- Verified layer/system map in techContext; follow-ups R-43..R-46, D-10
  recorded in devPlan

## Working Agreements
- Enemy states are shared (`states/enemy_chase|attack|retreat.gd`);
  per-enemy behavior = exported config on the scene, not script overrides
- Player references: `Global.player` at point of use; layer bits for
  physics identity; groups for broadcast only
- Aim, flight, and nav all key off the Environment bit — check the
  layer-consumer table in `techContext.md` before adding layers
- Unwalkable ≠ solid: carve nav via `BLOCKER_LAYER_NAMES`, never by
  reusing the Environment bit
- Wall-decor rule: alignment-sensitive decor = entity; filler decor = tile

## Known Limits (accepted)
- Bodies >8 px wide need per-size-class nav maps (R-43); today's discs
  (5.88–7.14 px) fit the single map
- 3-ray aim is ray-thin, not projectile-width (R-44 width cast pending)
- `Environment` container not y-sorted: chests/props sort vs player as
  one block; fix deliberately in R-40/R-41
- Stale editor script cache strips unknown exports on save - restart
  editor after agent disk edits

## Verification Gates
- gdlint on touched files; baseline in `techContext.md`
- `tests/interaction_smoke.tscn` headless - 66 assertions (local-only now; needs assets on disk)
- Headless probes: nav_probe, level_nav_probe, chase_probe, retreat_probe
  (the result txt files are the record)
- `--headless --import` before headless runs; PowerShell `Start-Process -Wait -PassThru`
- After agent disk edits with editor open: user restarts editor before playtesting

## Next Up
1. Playtest the nav series: doorway corners, enemy pairs, fire-through-allies
2. R-40 room-block standard, then R-41 tier-1 slice (devPlan lead tasks)

## Open Decisions
- Wand input binding + potion carry model: settle at S-5/S-6 implementation
- Depth room-mix shape + director numbers: provisional until playtest
- Public release: replace unknown-origin assets (HUD art, ~20 SFX); BDragon1727 VFX requires creator contribution for commercial use
