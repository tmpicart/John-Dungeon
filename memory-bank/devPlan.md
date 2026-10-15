# Development Plan — Task Backlog
> **Purpose:** The ordered feature task list and open-decisions register; shipped entries move to `progress.md`. Sizes (F-/R-/D-9 tables): S = one sitting, no playtest · M = one session incl. playtest/probe · L = multi-session or blocked.
## Open Decisions
| Topic | Status | Next look |
|---|---|---|
| Aim controller model | Decided: direction + soft lock (no reticle) | Revisit at F-3 (straight-launch reflect) |
| Archer whiff repositioning | Ships OFF by default | F-2 dedicated look — F-1 closed with no archer read |
| Necromancer fires from bad spots | Resolved: arrival-satisfied whiff gate + EnemyReposition + panic reflexes shipped (cd7473a..2260066) | Tuning continues via scene exports |

Resolved 2026-10-13 decisions landed in owning docs: aim → systemPatterns; wand/potion → productContext + S-5/S-6 rows; S-2 → its row; unknown assets → ASSETS.md (closed as-is).

Quality audit — whole codebase, one segment at a time (audit → plan → fix per segment): `quality-audit.md`.

## Combat feel & verdicts — F-
| ID | Sz | Task | Notes |
|---|---|---|---|
| F-2 | S | Archer whiff-flip decision | Enable or keep OFF the archer whiff-repositioning default; awaits a dedicated archer look — F-1 closed with no archer read |
| F-3 | L | Straight-launch reflect | Alternative to the aim-locked arcing reflect; revisit the aim-controller decision here |
| F-4 | S | Hit feedback pass | On-hit flash duration/timeout up across the board; hit-stop/frame-freeze tuning; damage-scaled shake down, time-freeze up |
| F-5 | M | Stun collision-off | Stunned enemies drop attack hitbox + body collision — they stop eating projectiles and the player phases through (anti-crowding) |
| F-6 | S | Flail skeleton scale | Scale back down (early-development enlargement) |
| F-7 | M | Knockback | Enemy knockback via the knockback-ready damage signature; player knockback evaluation |
| F-8 | M | Coin feel + enemy drops | Pickup magnetism, drop arcs; enemies drop coins/loot |
| F-9 | M | Death/restart flow | Restart prompt/option on player death |
| F-10 | S | Boss pacing | Inter-attack cooldowns, magic missile lifetime |
| F-11 | M | Volley light cost | Projectile PointLight2D burst render cost during volleys |
| F-12 | S | Code-comment sweep | 7 pre-rework comment sites → current-behavior voice: enemy_summon.gd:161,199; player_attack.gd:5; player_block.gd:5; max_hp_item.gd:5; player_movement.gd:4; nav_baker.gd:489; dedupe the doubled R-40-debt note — absorbed into the quality audit (QA-1/QA-4/QA-6) |
## Frameworks — R- room blocks & descent · D-9 group retirement
D-9 convention (Godot docs + Game Programming Patterns "Service Locator"): `Global.player` at point of use — the `"Player"` group stays private to `global.gd`; physics-contact identity uses collision-layer bits; groups are broadcast/tagging only.
| ID | Sz | Task | Notes |
|---|---|---|---|
| R-40a | M | Layer-stack standard | `TileMapLayer`-only stack + shared navigation; `test_room.tscn` is the reference stack |
| R-40b | M | Room-block anatomy | Door anchors, spawn markers, HUD at level root |
| R-40c | L | Descent room-type templates | Combat / treasure / shop / hallway / duel / gate authored on `custom_dungeon.tres` (16px atoms + patterns) |
| R-41 | L | Tier-1 vertical slice | Hand-assemble the first descent tier from standardized blocks — combat rooms + gate level + arena — proving the standard before the generator exists |
| R-42 | M | Boss arena encounter flow | Trigger, lock/unlock, victory handling; per-arena death checkpoints; remove `Global.door` flag coupling |
| R-43 | S | Per-size-class nav maps | When B-1 lands or the first body >8 px wide ships; today's discs (5.88–7.14 px) fit one map (`AGENT_RADIUS := 7.0`) |
| R-44 | S | Width-cast aim query | `cast_motion` ignores already-overlapping shapes — pair with an origin `intersect_shape` / center-ray guard |
| R-45 | M | Const-derivation pass | Runtime-derive cell-size/roster/projectile constants; per-entity values become exports |
| R-46 | S | Tileset nav-polygon cleanup | Delete the dead painted nav polygons from `custom_dungeon.tres` (runtime bakes instead); optional bake debug draw |
| D-10 | — | Enemy brain split threshold | Single shared state tree until an enemy-count/perf threshold justifies splitting chase/attack off |
| D-9a | M | `Global.player` migration | Boss states (cast/curse/melee/slide_into/slide_away/stars/beam), enemy states (chase/pounce/retreat), projectiles (magic_missile/curse_glyph) |
| D-9b | S | `interactable.gd` layer check | `is_in_group("Player")` → collision-layer check |
| D-9c | M | Vestigial tag strip | `"Enemies"` (Sorceress + 4 projectile scenes, `add_to_group` on 5 boss-spawn scripts, `beam.gd` exception loop), `"health"` (HeartBars — verify main_scene wiring first); keep smoke stubs' `"Player"` |
## Content tracks — S- systems · E- enemies · W- descent slices · B- bosses
Variants = new/modified attack + additional effects (S-2 when unparked) + shading — not config-only tints. Build order: S-1 → E-1 → S-4 → S-3 → S-5 → S-6 → S-7 (S-2 parked).
| ID | Task | Notes |
|---|---|---|
| S-1 | Hue-shift shader | Shared material, per-scene hue param — blue/yellow slimes + elite tints (see techContext) |
| S-2 | Status-effect framework | PARKED; unparks just-in-time at its first consumer (first variant or wand-effect task); application API, ticking, feedback, cleanse synergy |
| S-3 | Stamina + action cancels | Chunk-costed rolls; mutual cancels roll ⇄ attack ⇄ block with hitbox hygiene; upgradeable; stamina HUD (design: productContext "Gear intent") |
| S-4 | Armor | Blacksmith purchase, HUD icon; absorb semantics per productContext "Gear intent" |
| S-5 | Loadout slots + potion belt | Unified slots per productContext "Gear intent"; owned potion collection (typed belt) + cycle input, binding decided here; HUD |
| S-6 | Wand secondary fire | Player-owned projectile (PlayerHitbox conventions); tiers + shop item; HUD icon; owned wand collection + cycle input, binding decided here; art: check `assets/items/weapons.png` first |
| S-7 | Death VFX variety | Per-family particle colors/flash/tweens — no new frames |
| E-1 | Lesser skelly | Sheet pick pending; doubles as the player summon (see D-5) |
| E-2 | Blue slime | S-1; new attack/effect |
| E-3 | Lesser skelly variant | |
| E-4 | Flail skelly variant | |
| E-5 | Archer variant | |
| E-6 | Yellow slime | S-1 |
| E-7 | Lesser skelly variant 2 | |
| E-8 | Necromancer variant | |
| W-1 | `TierProfile` resource + `(tier, depth)` run state | Absorbed R-43: `EnemyData` metadata + spawn markers (room markers supersede EnemySummon tile scanning) |
| W-2 | Room-type library from R-40 blocks | Combat / treasure / shop / hallway / duel / gate |
| W-3 | Level graph generator | Seeded; key-conservation + reachability validation |
| W-4 | Budget spawner | EnemyData costs, tier-gated pools, marker placement |
| W-5 | Gate flow | Key pity, gate levels, arena entry, per-arena checkpoints |
| W-6 | Per-tier loot tables + shop stock tiering | |
| W-7 | Post-victory endless | Frozen dials, full pool |
| W-8 | Knight roaming + duel-room spawn rules | Art pending |
| B-1 | Slime King | Scaled slime art, split mechanic |
| B-2 | Skeleton Lord | AstroBob sheet |
| B-3 | Archer King | AstroBob sheet |
| B-4 | Nightborne | Art to be sourced — intake |
| B-5 | Sorceress finale polish + rift passage | |
| B-6 | Deity | 3-phase, cosmic arena; art to be sourced — intake |
| D-3 | Dialogue & world content | More DialogueData stages/NPCs on the shipped resource format; Sorceress boss intro (dormancy + door flow removed in R-24); Knight taunt stages (escalating per tier via PlayerProgress flags) + deity summoning beat |
| D-5 | Ally summons | Summonable allies fighting alongside the player (faction/targeting groundwork from the state-core/enemy frameworks); likely reuses E-1's lesser-skelly sheet — pick art serving both roles |
| D-7 | Audio | Complete sound and music design pass |
| D-8 | Lighting & VFX | Item glows, projectile light budget, room mood lighting (boss-key glow explored and shelved 2026-09-06) |