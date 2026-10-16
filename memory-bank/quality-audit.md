# Quality Audit — Whole-Codebase Program

> **Purpose:** Restore and enforce consistent professional code quality, logic, and convention conformance across the whole codebase — not only anti-drift of the auto-compaction era.
> **Execution model:** In parts. One segment at a time (vertical): Part 1 audit → Part 2 review/plan → Part 3 fix, then the segment leaves this log. Segments never run in parallel; no segment advances without the user's route decisions.
> **Expiry (one-off working log):** Delete this file at program completion — durable engine facts land in `techContext.md`, conventions in `systemPatterns.md`, history in `progress.md`.

## Prime directive
One standard, uniform depth, all 170 files. Era data decides queue order only — never depth or rigor. Untouched rework-era files are audited just as hard as auto-compaction-era files, and may need bringing forward to conventions that evolved after they were written.

## Scope — closed set
- Unit: current state of the 170 tracked code files (`.gd`/`.tscn`/`.tres`/`.gdshader`); per-file assignment appendix below must always sum to 170/170.
- 0 files survive from before the 2026-09-02 gated rework — "how far back" is settled: there is nothing older.
- 24 files born + 63 touched in the auto-compaction era (2026-09-30..HEAD, everything after `9c15168` recorded the failed AI rework for restart); ~107 untouched since the gated era.
- History is context only, never an audit object (see History's role below the segment queue).

## Part 1 — audit checklist (identical for every segment)
1. **Logic correctness** — edge cases; init/order assumptions; signal lifecycle (connect/disconnect, freed-object safety); physics-frame semantics; state-machine integrity (transition validity, interrupt tokens); numeric sanity (magic numbers vs exported tuning).
2. **Architecture & convention conformance** — `systemPatterns.md` conventions; hybrid-tree placement; state-core and interaction-framework usage; `Global.player` access (D-9); layer/mask discipline vs the `techContext.md` map.
3. **Engine-mechanic fit** — built-ins used instead of hand-rolled equivalents (`move_and_slide`, NavigationServer, tweens, timers, physics callbacks); every nontrivial API verified against the pinned 4.7.2 class reference.
4. **Professional quality & drift** — redundancy (duplication within and across files); iterative drift (vestiges of superseded approaches); overcomplicated logic; unprofessional workarounds; naming; dead/commented-out code; comment quality (the F-12 sweep generalized to every file); print remnants; gdlint findings; function cohesion.
5. **Design-intent alignment** — `productContext.md` decisions and `devPlan.md` open decisions respected; no superseded patterns extended.

Sources: systemPatterns · techContext (layers, engine facts) · productContext · devPlan decisions · raw 4.7.2 class-reference XML · Godot demos / Game Programming Patterns where a pattern applies (fit-filtered to project scope).

Findings format (one line each): `- [H|M|L] file:line — issue. Routes: (a)… (b)… Decision: —` (H = correctness/regression risk, M = convention/architecture, L = polish). Cross-segment findings park in §Cross-cutting instead of forcing a local fix.

## Part 2 — review/plan protocol
Per segment: findings elaborated; each offered with fix routes + benefit vs cost; user picks the route; concrete step-by-step fix plan recorded under the segment before any code moves.

## Part 3 — fix protocol
Implement the chosen plan on the user's go. Intent: functionality remains unchanged unless the plan explicitly changes it; no new bugs. Gates: gdlint on touched files · the segment's own probe where one exists · `tests/interaction_smoke.tscn` (66) · `tests/missile_probe.tscn` (39) when projectiles are touched · headless scene boots · user playtest for anything feel-affecting. Lands as a series of patch/quality commits per `commit-protocol.md`. Then: remove the segment from this log, one `progress.md` line.

## Segments — queue (risk-ordered; uniform depth)
| ID | Scope | Status |
|---|---|---|
| QA-1 | Nav foundation: `nav_baker.gd` + nav/level_nav/scene probes | closed 2026-10-15 |
| QA-2 | Enemy movement/combat states + chase probe family | closed 2026-10-15 |
| QA-3 | Projectiles & reflect (magic_missile, volley_report, player_combat) + missile_probe | pending |
| QA-4 | Necromancer & summon loop (retreat/standoff, ledger) + retreat/room_spawn probes | pending |
| QA-5 | Doors, z-bands, level scenes | pending |
| QA-6 | Player subsystem (movement, inventory, states, shield, camera) | pending |
| QA-7 | Boss — Sorceress states | pending |
| QA-8 | Systems (dialogue, shop, interaction, loot, state_core, global) + UI | pending |
| QA-9 | Pickups, interactables, NPCs, props | pending |
| QA-10 | Contact-damage re-drive stall: `contact_hitbox.gd` empty-read at expiry (traced 2026-10-15 via slime_contact) | pending — re-arm-on-empty fix + probe rerun |
| QA-T | Test-suite consolidation: all 16 test scripts (~4,700 lines) — keep/retire/dedupe | pending |
| QA-X | Cross-cutting consolidation + conventions codified | pending |

## QA-0 — closed 2026-10-15 (triage register; rows consumed by their owning segments)
Appendix 170/170 verified · 12 probe lenses (git grep — search_codebase excludes code files) · every candidate context-validated · spot-samples per cluster. No H findings at sweep depth.

### Conventions verified holding (repo-wide)
| Convention | Result |
|---|---|
| D-9 accessor | all 27 production reads via `Global.player` |
| Velocity px/s | 0 violations; all 12 delta uses legit (accel/angle/manual integration) |
| Inventory API | all mutations inside `player_inventory.gd` |
| NodePath wiring | root→child + state→`../` sibling everywhere (loader quirk clean) |
| .tres authoring | no StringName/PackedStringArray serialized |
| Layers/masks | all values match the techContext map; .gd masks via named constants |
| Connect style | method-reference everywhere but bomb.gd:16 |
| Production hygiene | no print/TODO/FIXME/dead markers; 32 uniform push_error/warning sites |
| stop() sites | boss_stagger (documented pause), base_enemy (post-frame, token-guarded), the_sorceress (timer ctx) sanctioned; shield.gd:57 → finding below |
| create_timer awaits | 25 sites; explicit guards in 7 files; full exit-safety → X-5 |

Baselines refreshed: appendix 170/170 · gdlint unchanged (44: player 41, bomb.gd 3).

### Findings — segment-triaged (decisions recorded 2026-10-15)
- [M] shield.gd:57 — parry() stop() may run mid-physics-flush (parry routes from hurtbox contact). Routes: (a) QA-6 verifies; re-route via pause/deferred if flush-timed (b) prove safe, document. Decision: (a)
- [L] player_animation.gd:12, shield.gd:10, weapon.gd:11 — `var Direction = Global.Direction` aliases drive most player gdlint findings. Routes: (a) inline during QA-6 (b) standalone cleanup now. Decision: (a)
- [L] character.tscn:700 — body mask 31 (layers 1–5) vs enemy standard 7. Routes: (a) tighten at QA-6 (b) document exception. Decision: (a)
- [L] character.tscn:813 — z_index 50 outlier. Routes: (a) QA-6 verify purpose (b) comment/normalize. Decision: (a)
- [L] bomb.gd:3,16,19 — dead `player` var; string connect + redundant disconnect; explode()/_ready double play. Routes: (a) QA-3 batch (b) now. Decision: (a)
- [L] bomb.tscn:102 — composite collision values 160/320 undocumented. Routes: (a) QA-3 verify + comment (b) split surfaces. Decision: (a)
- [L] enemy_idle.gd:19,30,35 — restating comments (F-12 lens). Routes: (a) QA-2 sweep (b) now. Decision: (a)
- [L] tests/interaction_smoke.gd:216,292 — object-capturing lambdas (freed-capture class). Routes: (a) QA-T audit (b) bind methods now. Decision: (a)
- [L] the_sorceress state names spaced ("Magic Missile") vs enemy PascalCase. Routes: (a) QA-7 normalize (b) codify both styles at QA-X. Decision: (b)
- [L] boss_door.tscn:106 — mask default while siblings set 3 — recorded pre-standard exception; act at boss-arena reseating only. Decision: baseline exception stands

History's role — context only, never an audit object:
- The audit unit is the file cluster at current state; commit content may already be overwritten or redesigned, and commit messages may not describe current behavior.
- Three cheap supports: the churn map (already set the queue order — enemy states, projectiles, nav churn hardest); per-segment commit subjects skimmed for intent-vs-reality contrast; blame on demand via `git log -p <file>`.

Closing gate — the Lookback: (1) re-run the QA-0 sweep for drift introduced by our own fixes; (2) verify the appendix still accounts for 170/170; (3) confirm baselines (gdlint, techContext §Tests) reflect reality; (4) wider lens down the chain — do older commit series flag the same shortcomings, is continuing further worth it, and to what point? Standing default (scope settled): the current-state audit already covers every surviving file; extension means process-archaeology of superseded commits only — user decides.

## QA-1/QA-3 context — restart-intent baseline (`9c15168` ai-rework-log, pre-restart)
- Intent: missiles navigate (necromancer never angle-hunts); archer stays simple with LOS; enemies must not snag on props; crowds must not jam; **keep code small** — originals 68 (missile) / 121 (chase) lines; rolled-back iterations reached 165 / 349; today: **315 / 501** (prime drift metric for QA-3/QA-2).
- Named keeper concepts: runtime NavBaker (prop-exclusion radius 12), `require_line_of_sight = false` necromancer, RVO crowd wiring, nav/missile probes.
- Missile-gate failure chain (audit lenses for QA-3): zero-clearance cell-boundary paths · `local_to_map` boundary flooring · overhang polys poking into walkable cells · pure-pursuit orbit when acceptance window < turn radius (advance by projection) · waypoint anchoring near corner cells.

## QA-1 — closed 2026-10-15
Audit + fixes landed: nav_probe mesh-readiness poll closes the region→map sync flake (fact → techContext); `_bake_region` doc drift and the F-12 comment site rewritten; duplicate-layer warning, assumption/contract comments, `BLOCKER_MASK` → `NavBaker.EXCLUSION_MASK`. No behavior change; gates green (gdlint · nav_probe ×3 · level_nav · scene · smoke 66). All 8 findings resolved en route (a).
- [M] tests/nav_probe.gd:113 — flaky fixed-frame settle: the route query can precede region-to-map registration (sync lands on a later frame than the region node's creation; level_nav_probe.gd:124-134 documents the same race and polls `map_get_closest_point` until the mesh answers — nav_probe waits a fixed 5+5 frames). Observed: baseline run 1 returned an empty route; identical geometry passed on rerun (diag: 29 polygons, endpoint mesh gaps 0.0 px). Routes: (a) port the readiness poll before the path stage (b) retry loop around the path assertion only. Decision: (a)
- Standing note for QA-5: level_nav_probe pins ~30 hardcoded `test_room.tscn` coordinates (spawn, mouths, lane sweeps) — room edits must re-run the probe.
- Structural probe dedupe → X-6; main_scene await guard → X-7 (§Cross-cutting).

## QA-2 — closed 2026-10-15
Audit (24 files) + fixes landed; all 11 findings route (a), no behavior change. Gates: gdlint (8 files) · chase family · smoke 66 · missile 39 · 4/4 scene boots green; slime_contact hardened (below). Two implementation-time notes: F1's planned post-await guard cannot run in the fatal case — the engine drops the resume into the freed instance (the X-7 error class itself) — so the pounce timer became a physics_update countdown (nothing outlives the node); F7 retracted on ground truth — kill()'s queue_free (:266) is already outside both has_animation guards, no corpse path exists. L-fix summary: explode() re-entry guard + docstring drift fixed (slime_red explodes on every death), chase enter null-player fallback to idle (velocity_computed connected before the bail-out — exit() disconnects unconditionally) + time_since_last_path reset, hurtbox damage contract mirrored from player_hurtbox (own `damage` → owner fallback), idle comment sweep + normalized wander vector, D-9c exemption for enemy_attack.gd:148 recorded on its devPlan row.
- [M] enemy_pounce.gd:28 — the 3.0 s timer await was orphaned on every contact explosion (state node freed mid-await; X-7-class error). Fixed structurally: physics-tick countdown in the state.
- [M] base_enemy.gd:370 + enemy_attack.gd:51 — a variant wired to EnemyAttack without an "Attack" animation hung its machine silently on the first swing (config-only E-1..E-8 exposure). Fixed: has_animation guard (push_error + false) in run_action_animation; the attack state hands back to chase on every non-routed false (from-state guard no-ops routed interrupts).
- [M] slime_red.tscn:262 — explode_sfx shipped streamless: pounce-explosion deaths were silent. Fixed: explosion randomizer assigned, 6.0 dB (F-4 tunes if it feels off).
- Standing note for QA-10: the hardened slime_contact check traced a real pre-existing stall — contact_hitbox.gd's expiry tick can read an empty overlap set (broadphase pair dropped during the player's i-frame body-layer toggles, player_combat.gd:103-117) and return without re-arming → silent until re-entry. Self-heals in live play (a moving player re-fires area_entered). Probe now polls the re-tick with a 2 s cap and traces the failing state (hp/is_hit/overlaps/rearm) instead of racing a fixed deadline one retry interval wide.

## Cross-cutting findings (parked → resolved in QA-X)
- X-1 [M] D-9a gap — enemy_idle.gd:31 reads the `"Player"` group (the plan names chase/pounce/retreat only); its cached ref also never re-resolves after a player free. Routes: (a) extend D-9a scope, migrate in batch (b) migrate now in QA-0. Decision: (a) — D-9a row updated in devPlan
- X-2 [M] D-9c scope — `"Enemies"` also tags 6 combatant roots (the_sorceress + 5 enemy .tscn roots); chase/missile/retreat/room_spawn probes consume the tag. Routes: (a) extend the D-9c strip + update probes (b) sanction combatant-root tags, strip only projectile/boss-script sites. Decision: (b) — D-9c row updated in devPlan
- X-3 [L] D-9c confirm — `"health"` tag (test_room.tscn:149 HeartBar) has no consumer; main_scene wires the node path directly. Routes: (a) strip with D-9c (b) keep. Decision: (a)
- X-4 [L] z-ladder (0 floor / 3 entities / 4 projectiles / 10 overhead) consistent repo-wide but uncoded. Routes: (a) codify in systemPatterns at QA-X (b) leave tribal. Decision: (a)
- X-5 [M] create_timer awaits in state scripts (25 sites; explicit guards in 7 files) — per-segment exit-safety verification is a standing checklist item. Routes: (a) fold into each segment's checklist (QA-2/3/6/7/9) (b) dedicated pass at QA-X. Decision: (a)
- X-6 [L] probe harness duplication — `_check`/`_tee` helpers in 8 probe scripts; the nav walker harness (`_walk_the_route`/`_walk_route`, stall gates, `WALKER_*` consts) duplicated across nav_probe/level_nav_probe. QA-1 decision (2026-10-15): park to QA-T — one consolidation design for the whole 16-script family beats a 2-of-8 local fix; a new shared file would also grow the closed set (appendix updates then). Routes: (a) shared probe base/util at QA-T (b) keep probes self-contained, codify the pattern. Decision: parked to QA-T (QA-1, 2026-10-15); consolidation shape decided at QA-T
- X-7 [L] ui/main_scene.gd:39-42 — `_bake_nav()` awaits 2 physics frames unguarded; scene teardown inside the window logs a freed-instance resume error (X-5 family, outside the 25 state-script sites). Found during QA-1; file is QA-8's. Routes: (a) `is_inside_tree` guard after the awaits (fix at QA-8) (b) accept — the main-scene chain is persistent. Decision: —

## Per-file assignment — must always sum to 170/170 (Lookback re-verifies)

### QA-1 — Nav foundation — 6
- `systems/nav/nav_baker.gd` (1)
- `tests/`: nav_probe.gd/.tscn, level_nav_probe.gd/.tscn, scene_probe.gd (5)

### QA-2 — Enemy movement/combat states — 24
- `entities/enemies/`: base_enemy.gd, contact_hitbox.gd, hitbox.gd, hurtbox.gd (4)
- `entities/enemies/states/`: enemy_attack.gd, enemy_chase.gd, enemy_hurt.gd, enemy_idle.gd, enemy_pounce.gd, enemy_stun.gd (6)
- `entities/enemies/` scenes: arcane_archer/arcane_archer.tscn, flail_skeleton/flail_skeleton.tscn, slime_green/slime_green.tscn, slime_red/slime_red.gd/.tscn (5)
- `assets/effects/on_hit_flash.gdshader` (1)
- `tests/`: chase_probe.gd/.tscn, chase_probe_corners.gd, chase_probe_doorway.gd, chase_probe_flicker.gd, chase_probe_press.gd, slime_contact_probe.gd/.tscn (8)

### QA-3 — Projectiles & reflect — 16
- `entities/projectiles/`: arcane_arrow, bomb, curse_glyph, energy_star, force_wave, magic_missile (each .gd/.tscn = 12), volley_report.gd (13)
- `entities/player/player_combat.gd` (1)
- `tests/`: missile_probe.gd/.tscn (2)

### QA-4 — Necromancer & summon loop — 9
- `entities/enemies/`: necromancer/necromancer.tscn, states/enemy_retreat.gd, states/enemy_summon.gd (3)
- `entities/projectiles/`: summon_effect.gd/.tscn (2)
- `tests/`: retreat_probe.gd/.tscn, room_spawn_probe.gd/.tscn (4)

### QA-5 — Doors, z-bands, level scenes — 6
- `levels/`: obstacle_outline.gd, test_room.tscn (2)
- `entities/interactables/doors/`: door.gd, boss_door.tscn, door_key.tscn, door_red.tscn (4)

### QA-6 — Player subsystem — 17
- `entities/player/`: camera_2d.gd, character.gd/.tscn, player_animation.gd, player_hurtbox.gd, player_inventory.gd, player_movement.gd, player_progress.gd, shield.gd/.tscn, weapon.gd/.tscn (12)
- `entities/player/states/`: player_attack.gd, player_block.gd, player_dash.gd, player_dead.gd, player_move.gd (5)

### QA-7 — Boss: Sorceress — 17
- `entities/boss/the_sorceress/`: beam.gd, boss_stagger.gd, boss_summon.gd, cast.gd, curse.gd, engage.gd, force_current.gd, intervention.gd, magic_missile.gd, melee.gd, slide_away.gd, slide_into.gd, stars.gd, the_sorceress.gd/.tscn (15)
- `entities/projectiles/`: intervention_light.gd/.tscn (2)

### QA-8 — Systems & UI — 40
- `systems/dialogue/`: blacksmith.tres, boss_taunt_sorceress.tres, dialogue_data.gd, dialogue_stage.gd, npc_dialog.gd/.tscn, potion_seller.tres, tutorial.tres (8)
- `systems/global/global.gd` (1)
- `systems/interaction/`: interactable.gd/.tscn, interaction_manager.gd/.tscn (4)
- `systems/loot/`: loot_table.gd, loot_table_tier_1.tres (2)
- `systems/state_core/`: state.gd, state_control.gd (2)
- `systems/shop/`: altar_shop.tres, blacksmith_shop.tres, potion_shop.tres, shop.gd/.tscn, shop_card.gd/.tscn, shop_data.gd, shop_item.gd, items/bomb_item.gd, items/max_hp_item.gd, items/potion_item.gd, items/sword_upgrade_item.gd (13)
- `ui/`: heart.gd/.tscn, heart_bar.gd/.tscn, item_box.tscn, item_hud.gd/.tscn, main_menu.gd/.tscn, main_scene.gd (10)

### QA-9 — Pickups, interactables, NPCs, props — 31
- `entities/interactables/altar/`: altar.gd/.tscn (2)
- `entities/interactables/chests/`: chest.gd, chest.tscn, chest_no_key.tscn (3)
- `entities/interactables/pickups/`: boss_key.gd/.tscn, coin.gd/.tscn, key.gd/.tscn, pickup.gd/.tscn, pickup_item.gd, potion.gd/.tscn (11)
- `entities/npcs/`: blacksmith.tscn, npc.gd, potion_seller.tscn, tutorial_npc.tscn (4)
- `entities/props/`: candlestick.tscn, candlestick_2.tscn, candlestick_2_unlit.tscn, candlestick_unlit.tscn, side_torch.tscn, wall_shackle.tscn, wall_shackle_2.tscn, wall_torch.tscn, wall_torch_unlit.tscn (9)
- `tests/`: obstacle_bounce_probe.gd/.tscn (2)

### QA-T — Test-suite core — 4
- `tests/`: interaction_smoke.gd/.tscn, stub_player.gd, stub_player_body.gd (4)

**Total: 6+24+16+9+6+17+17+40+31+4 = 170** · QA-0/QA-X own no exclusive files (cross-cutting sweeps).

