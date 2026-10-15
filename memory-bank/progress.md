# Progress — Status & Log

> **Purpose:** Feature status and a compact work log. One line per task; caps and archiving rules in `.clinerules/log-hygiene.md`.

## Status
Migration complete: frameworks R-01..R-33 landed; current lead and task order: `devPlan.md`.

## Log
- 2026-09-30 | feat | Runtime navmesh baking: NavBaker carves Environment cells at agent_radius clearance; main_scene bakes on load; nav/level_nav/scene probes.
- 2026-09-30 | feat | Width-aware aim gate on the Environment layer (3-ray, 2px clearance); arrow flight identity via Global.player; NPC feet join env layer.
- 2026-09-30 | feat | Shared chase/attack states on the baked mesh: RVO avoidance on all five enemies, corner press-through, archer LOS volley; chase_probe.
- 2026-09-30 | feat | Escape-scored retreat with cornered fight latch and ranged standoff repositioning; retreat_probe.
- 2026-09-30 | docs | Verified layer/system map into techContext; design-review follow-ups R-43..R-46 + D-10 into devPlan.
- 2026-09-30 | docs | Playtest findings logged as BUG-1..3: doorway pathing stall, doorway sprite vanish, necromancer missile rework.
- 2026-10-04 | fix | Door standard: door_key matched to door_red colliders/link and seated in the west archway; deprecated door scenes removed.
- 2026-10-04 | fix | Doorway sprite vanish resolved: character roots z 3 (enemies + NPCs), airborne projectiles z 4, per systemPatterns tiers.
- 2026-10-12 | fix | Archway flank clipping: collision on the overhead arch atoms keeps bodies off the wall-layer arch segments; resolves BUG-1.
- 2026-10-12 | feat | Hybrid missile routing: blind launch, baked-mesh steering around cover, outmaneuver crashes; missile_probe cover suite.
- 2026-10-12 | fix | Buried volley muzzles skipped via spawn_point_clear (no clamp); width-aware 3-lane routing exit gate; missile_probe 6 stages.
- 2026-10-12 | feat | Whiff-triggered repositioning: VolleyReport telemetry, attack-state fire gate consulted by the chase handover, necromancer enabled; BUG-3 closed.
- 2026-10-12 | fix | Per-muzzle volley aim: each shot converges from its own muzzle; shared-rotation lanes inherited muzzle offsets and skimmed standing players.
- 2026-10-12 | fix | Volley muzzles must be reachable from the shooter: through-wall spawns skipped beside buried ones; missile_probe through-wall stage.
- 2026-10-12 | feat | Missile tuning from playtest: turn cap 5.5 (~15 px radius) and 12 px pass-by freeze; missed shots recover inside two-tile corridors.
- 2026-10-13 | feat | Firing stance repositioning: chase FIRING scorer, retreat stance grading via band_clear_at, hit-only retreat; chase/retreat probe stages.
- 2026-10-13 | fix | Missile consume pairs with damage: reflected shots die on the hurtbox that takes the hit; per-tick player sweep keeps same-frame parries alive.
- 2026-10-13 | docs | Commit framing rules added to git.md; the ten unpushed combat commits reworded to match (trees unchanged; msg-backup held until push).
- 2026-10-13 | docs | Docs-refinement program decided (aim, wand/potion, S-2, unknown assets); DOC-1..DOC-9 track landed as devPlan lead.
- 2026-10-13 | docs | DOC-1: decisions register atop devPlan; aim/wand-potion/S-2/unknown-asset decisions landed; provenance→source sweep; projectbrief drift fix.
- 2026-10-13 | docs | DOC-2: one-line charters; single-homed phase/mission/conventions/engine-facts; activeContext → pointer-snapshot.
- 2026-10-13 | docs | DOC-3: systemPatterns Architecture Map rewritten one-fact-per-bullet, telegraphic; task IDs stripped, facts kept plain-language.
- 2026-10-13 | docs | DOC-4: conventions table to one-fact rows, Architecture dupes merged, trade-offs folded, engine facts rehomed, IDs stripped.
- 2026-10-13 | docs | DOC-5: techContext IDs stripped, engine facts one per line; productContext verified clean, design tables untouched.

- 2026-10-14 | fix | Necromancer standoff wander and panic reflexes: facing pin ends drift-flip flicker, wider shuffle, dedicated close summon, hybrid proximity flight.
- 2026-10-14 | fix | Confirmed walk flip ends melee sprite flicker: 80ms sign persistence, press and guard face the player, flip battery, wall-pocket stage realigned.
- 2026-10-14 | fix | Necromancer panic and summon pacing: panic trigger 50px, main summon rolls 3-5, close-summon cooldown 8s.
- 2026-10-14 | feat | Summon ledger caps live skeletons at 8 (partial casts fire, at-cap stands down); cast cooldowns 12->4s/8->3s; probe covers clamp and bounce.
- 2026-10-14 | perf | Outcome-gate 0.1s cache, firing-fan stance dedup, cone sweep 0.1s + 10s missile lifetime; Track plays once.
- 2026-10-14 | planning | R-47 visual range toggles: exported ranges draw as shapes for tuning.
- 2026-10-14 | docs | DOC-6 devPlan restructure: D-1 re-IDed as sized F- track (playtest/archer-flip/reflect = F-1..F-3), R-40/D-9 subtasks, R-47 dropped, comment-sweep row; Sept 2-13 log archived.
- 2026-10-14 | docs | Necromancer playtest verdict: pass — hard-8 summon cap and 4s/3s cast cadence ship as-is; archer whiff-flip parked pending a dedicated look (F-2).
- 2026-10-14 | docs | Rules restructure: commit protocol and asset intake rehomed to memory-bank, gate stubs kept in .clinerules; session start reads activeContext only (DOC-7).
- 2026-10-15 | docs | Rules: editor conflict model (cache-stale overwrite, two-writer lost update); soft caps 180/100/60 + compression rules (DOC-8).
- 2026-10-15 | docs | DOC-9: README status reframed against the original-game baseline; goals condensed to four fronts; pck baseline noted in techContext.
- 2026-10-15 | docs | README recast as a feature comparison of original vs remaster; reflect claim scoped to magic missiles.
- 2026-10-15 | docs | Quality-audit program chartered: 170-file pass in segments QA-0..QA-X (quality-audit.md); history context-only; F-12 absorbed.
- 2026-10-15 | qa | QA-0 repo-wide conventions sweep closed: 170/170 appendix-verified, baseline strong (no H findings), 15 findings triaged to segment checklists; gdlint unchanged (44).
