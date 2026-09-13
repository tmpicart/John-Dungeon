# AI Rework Log — Attempts & Findings (pre-restart)

> **Purpose:** Working record of the 2026-09-13 AI rework attempt, abandoned
> before commit and rolled back. This file is the spec for the fresh
> implementation. Delete it once the rework lands and its conventions live in
> `systemPatterns.md`.

## Original goals (user spec)
- Missiles: leave the necromancer knowing the player's location, navigate like an
  entity (round cover), with enough steer limitation to be outmaneuvered and
  caused to crash. The shooter never hunts for angles.
- Necromancer: no angle-hunting at all — missiles do the navigating.
- Archer: arrows fly straight, so LOS still applies; behavior must stay simple.
- Enemies must not snag on candles/chests; crowds must not jam.
- Keep code small: originals were 68 lines (missile) / 121 lines (chase); the
  iterations grew them to 165 / 349 before rollback.

## Playtest bugs & root-cause findings
| Bug | Root cause | Verdict |
|---|---|---|
| Archer/necromancer shuffle back and forth behind cover | vantage-ring hunt re-picked ring points every repath (0.5s) — oscillation | confirmed |
| Enemies freeze until the player moves | no-LOS stall at attack-range edge once a committed vantage had no valid cells | confirmed |
| Necromancer gives up firing | stale `_los_blocked` flag: set on blocked attack entry, only cleared inside `_enter_attack` — out of range it orbited the ring forever | confirmed |
| Suspected animation-loop wedge (OnHit awaiting forever) | OnHit/Summon/Attack do not loop (only Idle/Walk) | disproven |
| Reflected missiles never consumed on enemies | hit handler had no `reflected` branch | confirmed |
| Reflected missiles spiraled | one-sided whisker bias + min turn radius vs close targets | confirmed |
| Missile crash on stationary player behind tight corner | navmesh path points run along cell boundaries (zero clearance) + obstacle polys overhang past their tiles | confirmed |
| Enemies snag on candles/chests | prop bodies overlap walkable navmesh cells | confirmed |

## Attempted changes (all rolled back)
| Area | Change | Outcome |
|---|---|---|
| NavBaker | runtime navmesh baked to a hidden GeneratedNav layer; TileMapLayer + legacy TileMap sources; per-scope baking | green — nav probe PASSED; keeper concept |
| NavBaker prop exclusion | Environment-mask circle probe per painted cell; radius 9→12 so bodies poking out of blocked cells claim the walkable cell | green (coverage 342); fixes prop snags at plan time |
| NavBaker overhang exclusion | ray toward blocked neighbors; exclude cells whose edge geometry sits closer than cell span − 1px | green; catches bottom-edge pockets, not corner pockets |
| Chase vantage hunt | ring sampling + commit guards + hunt timeout | reverted as design — it was the shuffle/freeze source |
| Chase simplification | vantage apparatus deleted (349→257 lines); blocked LOS = walk straight at player | lint/boot green |
| Necromancer | `require_line_of_sight = false` | correct per spec; keeper |
| Melee | wall-gated AXIS_BOX attacks (RADIAL ranged un-gated); skeleton box tuning; facing debounce | earlier-session work, rolled back — redo list |
| Crowds | RVO avoidance on 5 enemy scenes scoped to chase/retreat; NavigationObstacle2D on NPC | green in soaks — but the NPC static body later killed missiles (see below); re-apply after movement is stable |
| Summon | placement prefers the GeneratedNav layer (fixed dungeon depth-3 lookup and error spam) | small keeper |
| Probes | `tests/nav_probe` (coverage/exclusion/route) and `tests/missile_probe` (cover-scenario closest approach) | nav probe stable green; missile probe drove every named finding below |
| Missile v1 | nav-agent cursor following + whiskers + fly-by + clear-shot gating | 165 lines; corner deaths |
| Missile v2 | normal-aware wall-slide whiskers | best pre-rollback result (closest approach 147→54.7px) |
| Missile v3 | CharacterBody2D root + move_and_slide; slide vs steep-impact crash (velocity·normal); hitbox narrowed to player-only | crashes became precisely nameable |
| Missile v4 | private waypoint cursor steered through cell centers; projection-based advance; corner slowdown; walkable-side nudge | no crash, no orbit — but no convergence near corner cells; abandoned |

## Missile-gate failure chain (named mechanisms, in order)
1. Prop/NPC body poke-in: the Potion Seller's static (center inside a blocked
   cell) clipped the route cell — the occupancy probe must reach into blocked
   neighbors (radius 12 fixed it).
2. Portal-edge zero clearance: tile-navmesh waypoints sit ON cell boundaries; a
   body follower with any radius grazes blocked geometry.
3. Obstacle overhang polys poke into walkable cells (canopy shapes); bottom-edge
   rays catch them, corner pockets remain.
4. Pure-pursuit orbit: waypoint acceptance window (6px) smaller than the turn
   radius (speed/turn-rate ≈ 12px) — advance waypoints by projection instead.
5. Boundary floor bias: `local_to_map` floors exact-boundary points into the
   blocked cell; nudge each waypoint toward its predecessor before snapping.
6. After all five: no crash, no orbit, but no convergence — waypoint anchoring
   near corner cells still wrong. Abandoned per the circuit breaker.

## Engine facts (4.7.2) — beyond techContext
- Tile-navmesh paths hug cell boundaries: a follower needs half-cell margin
  (steer through walkable-verified cell centers) or slide-or-crash handling.
- `local_to_map` floors boundary points into the +x/+y cell — verify the snapped
  cell against the layer itself (`get_cell_tile_data(cell) != null`).
- A proximity waypoint window smaller than speed/turn-rate orbits; advance
  waypoints by projection past their plane.
- `move_and_slide` on a projectile gives slide-vs-crash for free (impact
  steepness = velocity·normal) and needs a collision shape on the scene root.
- A long/forward-offset Area2D hitbox detects walls early — keep damage hitboxes
  centered and small; let a body handle geometry.
- NavigationAgent2D's internal cursor only advances when the follower's position
  approaches the cursor point — custom anchors require owning the raw
  `get_current_navigation_path()` list.

## Fresh-start recommendations
1. Start from HEAD — the rollback restored the originals; nothing to un-do.
2. Resurrect NavBaker + both probes first (both were green; they de-risk
   everything else). Keep prop exclusion radius 12; revisit overhang rays.
3. Missile: original homing + pass-by leniency on a small centered hitbox; add
   slide/crash only if corner deaths reappear in playtest; if routes still hug
   edges, steer through walkable-verified cell centers from day one.
4. Necromancer fires without LOS gating; archer keeps the LOS gate with a plain
   approach — no vantage ring, ever.
5. Re-apply RVO crowd wiring once movement is stable.
