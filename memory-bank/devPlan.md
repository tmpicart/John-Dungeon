# Development Plan — Continued Feature Work

> **Purpose:** New features beyond the migration. Sequenced against `refactorPlan.md` phases; entries move to `progress.md` when shipped.
> **Lifecycle:** Same rules as `refactorPlan.md` — delete completed items; keep under ~80 lines. Rules: `.clinerules/log-hygiene.md`.

## D-1 Combat feel pass (after R-22 / R-23)
- Knockback on hit for enemies (uses the knockback-ready damage signature from R-22); player knockback evaluation
- Hit-stop / frame-freeze tuning pass
- Coin behavior feel (pickup magnetism, drop arcs) and enemies dropping coins/loot
- Death/restart flow: restart prompt/option on player death
- Boss pacing (deferred from R-24): inter-attack cooldowns, magic missile lifetime
- Projectile PointLight2D optimization (burst render cost during volleys; deferred from R-24)

## Player systems track — S- (one system per task; absorbs former D-2/D-4/D-6 scope, split 2026-09-09)
| ID | Task | Notes |
|---|---|---|
| S-1 | Hue-shift shader | Shared material, per-scene hue param — blue/yellow slimes + elite tints (`self_modulate` can't hue-rotate) |
| S-2 | Status-effect framework | PARKED until variant/wand effect scope decides; application API, ticking, feedback, cleanse synergy |
| S-3 | Stamina + action cancels | Chunk-costed rolls (NO i-frames — movement only); mutual cancels roll ⇄ attack ⇄ block with hitbox hygiene (`disable_hitbox()` on cancel, deflect stops attack surfaces); upgradeable; stamina HUD |
| S-4 | Armor | Blacksmith purchase, HUD icon; absorb = full negation incl. unblockables ("effectively an i-frame") with clank SFX + VFX + hitstop; no heart loss |
| S-5 | Loadout slots + potion belt | Unified slots — alt-weapon (wand) · potion (one equipped type) · tool (bomb); typed potion inventory + HUD; input binding TBD |
| S-6 | Wand secondary fire | One wand equipped; player-owned projectile (PlayerHitbox conventions); tiers + shop item; HUD icon; art: check `assets/items/weapons.png` first |
| S-7 | Death VFX variety | Per-family particle colors/flash/tweens — no new frames |

Build order: S-1 → E-1 → S-4 → S-3 → S-5 → S-6 → S-7 (S-2 parked)

## D-3 Dialogue & world content (after R-33)
- More `DialogueData` stages and NPCs on the shipped resource format; new story beats
- Boss intro cutscene/dialogue for The Sorceress (dormancy + door flow removed in R-24)
- Knight taunt stages (escalating per tier via PlayerProgress flags) + deity summoning beat

## Enemy track — E- (one enemy per task; tier order per productContext tier table)
| ID | Task |
|---|---|
| E-1 | Lesser skelly — sheet pick pending; likely doubles as the player summon creature (D-5 convergence) |
| E-2 | Blue slime (S-1; new attack/effect) |
| E-3 | Lesser skelly variant |
| E-4 | Flail skelly variant |
| E-5 | Archer variant |
| E-6 | Yellow slime (S-1) |
| E-7 | Lesser skelly variant 2 |
| E-8 | Necromancer variant |

Variants = new/modified attack + additional effects (S-2 when unparked) + shading — not config-only tints

## D-5 Ally summons (after R-23)
- Summonable ally creatures that fight alongside the player (faction/targeting cleanliness comes from R-20/R-23)
- Likely reuses E-1's lesser-skelly sheet — pick art that serves both roles

## World track — W- (descent generator; one slice per task)
| ID | Task |
|---|---|
| W-1 | `TierProfile` resource + `(tier, depth)` run state |
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

## D-7 Audio pass
- Complete sound and music design pass

## D-8 Lighting & VFX pass
- Ambient lighting/effects pass: item glows, projectile light budget, room mood lighting (a boss-key glow was explored and shelved 2026-09-06)