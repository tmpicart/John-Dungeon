# Active Context - Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (<=60 lines) - history goes to `progress.md`, not here.

## Phase
Development phase. Missile/volley + firing repositioning series landed 2026-10-13. Devplan leads: R-40..R-42.

## Just Landed
- Missile consume pairing: reflected shots die on the hurtbox that
  takes the damage; player contact consumes via a per-tick sweep after
  the physics flush (same-frame parries keep the shot); capsule widened
- Firing stance repositioning: EnemyChase FIRING scorer (navmesh fan
  probes + `_bounded_close_in`), EnemyRetreat grades stances via
  `band_clear_at(position)`; necromancer retreat is hit-driven only
- Ten unpushed combat commits reworded 2026-10-13 (trees verified
  identical); framing standard in `.clinerules/git.md`; backup tags until push
- missile_probe at 13 stages / 39 checks (reflect pairing set added)

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
1. Task 2R: straight-launch reflect (drop the arc fan), cone
   soft-seek for targetless shots (stub combat aim-direction seam)
2. Necromancer playtest: whiff exports + firing repositioning tuning
3. Archer flip: `reposition_after_whiff` + firing stance ON
4. R-40 room-block standard, then R-41 tier-1 slice

## Open Decisions
- Archer repositioning ships OFF until necromancer playtest
- Wand input binding + potion carry model: settle at S-5/S-6
- Public release: replace unknown-origin assets (HUD art, ~20 SFX)
