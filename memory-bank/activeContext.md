# Active Context - Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (<=60 lines) - history goes to `progress.md`, not here.

## Phase
Development phase. Docs-refinement program (DOC-2..DOC-9) is the devPlan lead; game tasks (2R, R-40..) queue behind it.

## Just Landed
- DOC-1: Open Decisions register at the top of devPlan; resolved
  decisions landed in owning docs (aim → systemPatterns,
  wand/potion → productContext + S-5/S-6 rows, S-2 unpark policy,
  unknown assets → ASSETS.md); provenance→source sweep;
  projectbrief generator drift fixed

## Working Agreements
- Enemy states are shared (`states/enemy_chase|attack|retreat.gd`);
  per-enemy behavior = exported config on the scene, not script overrides
- Volley knowledge in EnemyAttack (VolleyReport + `band_clear_at`),
  decision in EnemyChase (`fire_gate_open()` beside the blind gate)
- Consume surface == damage surface: projectiles die where they deal
- Player references: `Global.player` at point of use; layer bits for
  physics identity; groups for broadcast only
- Aim, flight, and nav all key off the Environment bit - check the
  layer-consumer table in `techContext.md` before adding layers
- Unwalkable ≠ solid: carve nav via `BLOCKER_LAYER_NAMES`, never by
  reusing the Environment bit

## Known Limits (accepted)
- Bodies >8 px wide need per-size-class nav maps (R-43); 3-ray aim is
  ray-thin (R-44 pending)
- `Environment` container not y-sorted: chests/props sort vs player as
  one block; fix deliberately in R-40/R-41
- Stale editor script cache strips unknown exports on save - restart
  the editor after agent disk edits
- retreat_probe obstacle-hop stage FAIL (comfort/cornered verdict) =
  known baseline, inherited through the series
- Archway blockers stop projectiles at the west archway (Environment-
  blocker side effect)

## Verification Gates
- gdlint on touched files; baseline in `techContext.md`
- Headless probes: nav, level_nav, chase, missile, retreat, scene -
  result txt files are the record; scene-file commits need an
  editor-clean confirmation first

## Next Up
1. DOC-2: purpose charter & single-homing
2. Task 2R: straight-launch reflect (drop the arc fan), cone
   soft-seek for targetless shots (stub combat aim-direction seam)
3. Necromancer playtest: whiff exports + firing repositioning tuning
4. Archer flip: `reposition_after_whiff` + firing stance ON
5. R-40 room-block standard, then R-41 tier-1 slice

## Open Decisions
- Register lives at the top of `devPlan.md`: aim revisit at 2R;
  archer repositioning OFF until the necromancer playtest
