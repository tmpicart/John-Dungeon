# AI Rework Log — Restart Spec

> **Purpose:** Spec for the AI rework after the 2026-09-13 attempt was rolled
> back pre-commit. Carries the user goals, observed bugs with root causes,
> proven keepers, and the intended behavior. Delete it once the rework lands
> and its conventions live in `systemPatterns.md`.

## Goals (user spec)
- Missiles: leave the necromancer knowing the player's location, navigate like
  an entity (round cover), with enough steer limitation to be outmaneuvered and
  caused to crash. The shooter never hunts for angles.
- Necromancer: no angle-hunting at all — missiles do the navigating.
- Archer: arrows fly straight, so LOS still applies; behavior must stay simple.
- Enemies must not snag on candles/chests; crowds must not jam.
- Keep code small: originals were 68 lines (missile) / 121 lines (chase).

## Observed bugs & root causes (rolled-back attempt)
| Bug | Root cause |
|---|---|
| Archer/necromancer shuffle back and forth behind cover | vantage-ring hunt re-picked ring points every repath (0.5s) — oscillation |
| Enemies freeze until the player moves | no-LOS stall at attack-range edge once a committed vantage had no valid cells |
| Necromancer gives up firing | stale `_los_blocked` flag: set on blocked attack entry, only cleared inside `_enter_attack` — out of range it orbited the ring forever |
| Reflected missiles never consumed on enemies | hit handler had no `reflected` branch |
| Reflected missiles spiraled | one-sided whisker bias + min turn radius vs close targets |
| Missile crash on stationary player behind tight corners | navmesh path points run along cell boundaries (zero clearance) + obstacle polys overhang past their tiles |
| Enemies snag on candles/chests | prop bodies overlap walkable navmesh cells |

Disproven: a suspected OnHit animation-loop wedge — OnHit/Summon/Attack do not loop (only Idle/Walk).

## Proven keepers (green before rollback)
- NavBaker: runtime navmesh baked to a hidden `GeneratedNav` layer (TileMapLayer
  + legacy TileMap sources, per-scope baking); prop-exclusion circle probe per
  painted cell, radius 12 — bodies poking out of blocked cells claim the
  walkable cell, fixing prop snags at plan time.
- Probes: `tests/nav_probe` (coverage/exclusion/route) and `tests/missile_probe`
  (cover-scenario closest approach) — probe-green gates the restart.
- Necromancer `require_line_of_sight = false` (correct per spec).
- Summon placement preferring the `GeneratedNav` layer (fixes dungeon depth-3
  lookup and error spam).
- RVO crowd avoidance on 5 enemy scenes scoped to chase/retreat worked in
  soaks — re-apply only after movement is stable (the NPC's static body killed
  missiles).
- Missile lessons: a `move_and_slide` root made crashes precisely nameable;
  the vantage ring itself was the shuffle/freeze source.

## Fresh-start plan (intended behavior)
1. Start from HEAD — the rollback restored the originals; nothing to un-do.
2. Resurrect NavBaker + both probes first; probe-green before anything else.
   Keep prop exclusion radius 12; revisit overhang rays (corner pockets remain).
3. Missile: original homing + pass-by leniency on a small centered hitbox; add
   slide/crash handling only if corner deaths reappear in playtest; if routes
   still hug edges, steer through walkable-verified cell centers from day one
   (engine facts: `techContext.md`).
4. Necromancer fires without LOS gating; archer keeps the LOS gate with a plain
   approach — no vantage ring, ever.
5. Redo from the earlier session: wall-gated AXIS_BOX melee attacks (RADIAL
   ranged un-gated), skeleton box tuning, facing debounce.
6. Re-apply RVO crowd wiring once movement is stable.
