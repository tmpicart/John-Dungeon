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
| QA-0 | Repo-wide pattern sweep (all 170 files; conventions baseline + triage; seeds Cross-cutting) | pending |
| QA-1 | Nav foundation: `nav_baker.gd` + nav/level_nav/scene probes | pending |
| QA-2 | Enemy movement/combat states + chase probe family | pending |
| QA-3 | Projectiles & reflect (magic_missile, volley_report, player_combat) + missile_probe | pending |
| QA-4 | Necromancer & summon loop (retreat/standoff, ledger) + retreat/room_spawn probes | pending |
| QA-5 | Doors, z-bands, level scenes | pending |
| QA-6 | Player subsystem (movement, inventory, states, shield, camera) | pending |
| QA-7 | Boss — Sorceress states | pending |
| QA-8 | Systems (dialogue, shop, interaction, loot, state_core, global) + UI | pending |
| QA-9 | Pickups, interactables, NPCs, props | pending |
| QA-T | Test-suite consolidation: all 16 test scripts (~4,700 lines) — keep/retire/dedupe | pending |
| QA-X | Cross-cutting consolidation + conventions codified | pending |

History's role — context only, never an audit object:
- The audit unit is the file cluster at current state; commit content may already be overwritten or redesigned, and commit messages may not describe current behavior.
- Three cheap supports: the churn map (already set the queue order — enemy states, projectiles, nav churn hardest); per-segment commit subjects skimmed for intent-vs-reality contrast; blame on demand via `git log -p <file>`.

Closing gate — the Lookback: (1) re-run the QA-0 sweep for drift introduced by our own fixes; (2) verify the appendix still accounts for 170/170; (3) confirm baselines (gdlint, techContext §Tests) reflect reality; (4) wider lens down the chain — do older commit series flag the same shortcomings, is continuing further worth it, and to what point? Standing default (scope settled): the current-state audit already covers every surviving file; extension means process-archaeology of superseded commits only — user decides.

## QA-1/QA-3 context — restart-intent baseline (`9c15168` ai-rework-log, pre-restart)
- Intent: missiles navigate (necromancer never angle-hunts); archer stays simple with LOS; enemies must not snag on props; crowds must not jam; **keep code small** — originals 68 (missile) / 121 (chase) lines; rolled-back iterations reached 165 / 349; today: **315 / 501** (prime drift metric for QA-3/QA-2).
- Named keeper concepts: runtime NavBaker (prop-exclusion radius 12), `require_line_of_sight = false` necromancer, RVO crowd wiring, nav/missile probes.
- Missile-gate failure chain (audit lenses for QA-3): zero-clearance cell-boundary paths · `local_to_map` boundary flooring · overhang polys poking into walkable cells · pure-pursuit orbit when acceptance window < turn radius (advance by projection) · waypoint anchoring near corner cells.

## Cross-cutting findings (parked → resolved in QA-X)
- (none yet)

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

