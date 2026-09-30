# Development Plan — Task Backlog

> **Purpose:** The ordered feature task list; entries move to `progress.md` when shipped.
> **Lifecycle:** Tasks are deleted on completion (noted in `progress.md`); keep this file under ~80 lines. Rules: `.clinerules/log-hygiene.md`.

## Room-block & descent foundations — R- (lead tasks)
| ID | Task | Notes |
|---|---|---|
| R-40 | Room-block standard | `TileMapLayer`-only stack, shared navigation, door anchors, spawn markers, HUD at level root; `test_room.tscn` is the reference stack; author new templates on `custom_dungeon.tres` (16px atoms + patterns); conventions must cover descent room types (combat / treasure / shop / hallway / duel / gate) |
| R-41 | Tier-1 vertical slice | Hand-assemble the first descent tier from standardized blocks — combat rooms + gate level + arena — proving the standard before the generator exists |
| R-42 | Boss arena encounter flow | Trigger, lock/unlock, victory handling; per-arena death checkpoints; remove `Global.door` flag coupling |

## Design-review follow-ups (2026-09-30)
| ID | Task | Trigger / note |
|---|---|---|
| R-43 | Per-size-class nav maps | When B-1 lands or the first body >8 px wide ships; today's discs (5.88–7.14 px) fit one map (`AGENT_RADIUS := 7.0`) |
| R-44 | Width-cast aim query | `cast_motion` ignores already-overlapping shapes — pair with an origin `intersect_shape` / center-ray guard |
| R-45 | Const-derivation pass | Runtime-derive cell-size/roster/projectile constants; per-entity values become exports |
| R-46 | Tileset nav-polygon cleanup | Delete the dead painted nav polygons from `custom_dungeon.tres` (runtime bakes instead); optional bake debug draw |
| D-10 | Enemy brain split threshold | Single shared state tree until an enemy-count/perf threshold justifies splitting chase/attack off |

## Bugs — playtest findings (2026-09-30)
| ID | Symptom | Direction |
|---|---|---|
| BUG-1 | Enemies stall/oscillate at doorways — pathing does not commit | Doorway surface is 2 px slack after agent_radius erosion; check waypoint handoff + repath churn at narrow cells (probe scenario) |
| BUG-2 | Sprites vanish inside doorways | Display, not physics: suspected z/y-sort tier overlap with the wall stack at door cells |
| BUG-3 | Necromancer missiles still need the rework | Original homing + pass-by leniency on a small centered hitbox; necromancer fires without LOS gate; spec: `ai-rework-log.md` fresh-start steps 3–4 |

## D-1 Combat feel pass
- Knockback on hit for enemies (uses the knockback-ready damage signature); player knockback evaluation
- Hit-stop / frame-freeze tuning pass
- Coin behavior feel (pickup magnetism, drop arcs) and enemies dropping coins/loot
- Death/restart flow: restart prompt/option on player death
- Boss pacing: inter-attack cooldowns, magic missile lifetime
- Projectile PointLight2D optimization (burst render cost during volleys)

## Player systems track — S- (one system per task)
| ID | Task | Notes |
|---|---|---|
| S-1 | Hue-shift shader | Shared material, per-scene hue param — blue/yellow slimes + elite tints (`self_modulate` can't hue-rotate) |
| S-2 | Status-effect framework | PARKED until variant/wand effect scope decides; application API, ticking, feedback, cleanse synergy |
| S-3 | Stamina + action cancels | Chunk-costed rolls; mutual cancels roll ⇄ attack ⇄ block with hitbox hygiene; upgradeable; stamina HUD (design: productContext "Gear intent") |
| S-4 | Armor | Blacksmith purchase, HUD icon; absorb semantics per productContext "Gear intent" |
| S-5 | Loadout slots + potion belt | Unified slots per productContext "Gear intent"; typed potion inventory + HUD; input binding TBD |
| S-6 | Wand secondary fire | Player-owned projectile (PlayerHitbox conventions); tiers + shop item; HUD icon; art: check `assets/items/weapons.png` first |
| S-7 | Death VFX variety | Per-family particle colors/flash/tweens — no new frames |

Build order: S-1 → E-1 → S-4 → S-3 → S-5 → S-6 → S-7 (S-2 parked)

## D-3 Dialogue & world content
- More `DialogueData` stages and NPCs on the shipped resource format; new story beats
- Boss intro cutscene/dialogue for The Sorceress (dormancy + door flow removed in R-24)
- Knight taunt stages (escalating per tier via PlayerProgress flags) + deity summoning beat

## Enemy track — E- (one enemy per task; tier order per productContext tier table)
| ID | Task |
|---|---|
| E-1 | Lesser skelly — sheet pick pending; doubles as the player summon (see D-5) |
| E-2 | Blue slime (S-1; new attack/effect) |
| E-3 | Lesser skelly variant |
| E-4 | Flail skelly variant |
| E-5 | Archer variant |
| E-6 | Yellow slime (S-1) |
| E-7 | Lesser skelly variant 2 |
| E-8 | Necromancer variant |

Variants = new/modified attack + additional effects (S-2 when unparked) + shading — not config-only tints

## D-5 Ally summons
- Summonable ally creatures that fight alongside the player (faction/targeting groundwork from the state-core/enemy frameworks)
- Likely reuses E-1's lesser-skelly sheet — pick art that serves both roles

## World track — W- (descent generator; one slice per task)
| ID | Task |
|---|---|
| W-1 | `TierProfile` resource + `(tier, depth)` run state | Absorbed R-43: `EnemyData` metadata + spawn markers (room markers supersede EnemySummon tile scanning) |
| W-2 | Room-type library from R-40 blocks (combat / treasure / shop / hallway / duel / gate) |
| W-3 | Level graph generator (seeded; key-conservation + reachability validation) |
| W-4 | Budget spawner (EnemyData costs, tier-gated pools, marker placement) |
| W-5 | Gate flow: key pity, gate levels, arena entry, per-arena checkpoints |
| W-6 | Per-tier loot tables + shop stock tiering |
| W-7 | Post-victory endless (frozen dials, full pool) |
| W-8 | Knight roaming + duel-room spawn rules (art pending) |

## Boss track — B- (one boss each; R-42 encounter flow = shared foundation)
| ID | Task |
|---|---|
| B-1 | Slime King — scaled slime art, split mechanic |
| B-2 | Skeleton Lord (AstroBob sheet) |
| B-3 | Archer King (AstroBob sheet) |
| B-4 | Nightborne (art to be sourced — intake) |
| B-5 | Sorceress finale polish + rift passage |
| B-6 | Deity — 3-phase, cosmic arena (art to be sourced — intake) |

## D-7 / D-8 — late passes
- Audio: complete sound and music design pass
- Lighting & VFX: item glows, projectile light budget, room mood lighting (a boss-key glow was explored and shelved 2026-09-06)

## D-9 Retire group-based lookups
Convention (Godot docs + Game Programming Patterns "Service Locator"): `Global.player` at point of use — the `"Player"` group stays private to `global.gd`; physics-contact identity uses collision-layer bits; groups are broadcast/tagging only.
- Replace direct `get_first_node_in_group("Player")` with `Global.player`: boss states (cast/curse/melee/slide_into/slide_away/stars/beam), enemy states (chase/pounce/retreat), projectiles (magic_missile/curse_glyph)
- `interactable.gd`: `is_in_group("Player")` → collision-layer check
- Strip vestigial tags: `"Enemies"` (Sorceress + 4 projectile scenes, `add_to_group` on 5 boss-spawn scripts, `beam.gd` exception loop), `"door"` (door_sealed), `"health"` (HeartBars — verify main_scene wiring first); keep smoke stubs' `"Player"`