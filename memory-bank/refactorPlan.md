# Refactor Plan — Restructure & Migration

> **Purpose:** The ordered migration task list: restructure the project and move all systems onto the adopted architecture while preserving game feel. Feel improvements are allowed only where the code is already being touched; features go to `devPlan.md`.
> **Lifecycle:** Tasks are deleted on completion (noted in `progress.md`); keep this file under ~80 lines. Rules: `.clinerules/log-hygiene.md`.

## Adopted Decisions (summary — details in `systemPatterns.md`)
Hybrid folder structure · typed state transitions · shared states + config exports + hooks · signal-driven animation · mouse-driven `ShopData` shop · JSON dialogue + `PlayerProgress` on player · handcrafted-first, procgen-ready · boss 1:1 migration (redesign in `devPlan.md`) · opportunistic feel fixes only.

## Phase R2 — Combat & AI framework
| ID | Task | Notes |
|---|---|---|
| R-24 | Boss migration (1:1) | Sorceress onto `BaseEnemy` + shared state core; absorb misplaced `Idle.gd`; phase-2 as reusable layer; fight design preserved (redesign → `devPlan.md`); boss projectile fixes (per-frame timers, delta units, `Stars` `_ready()` hack, `Beam` cleanup, `Summon` scan); repair her 4 scriptless hitbox nodes (stale legacy `Hitbox.gd`/`projectile_hitbox.gd` — physics layers carry hitboxes now); damage stays per-surface (`BaseEnemy.damage` = body only; projectiles keep their own exports) |

## Phase R3 — Interaction & UI systems (after R2)
| ID | Task | Notes |
|---|---|---|
| R-32 | Shop rework | Mouse cards (hover + click), N items via `ShopData` resource, purchases through `PlayerInventory`; close on Esc/walk-away; retire legacy shop scenes; freeze player input while open |
| R-33 | Dialogue system | JSON dialogue (pages, stage transitions); `PlayerProgress` on player (flags + per-NPC stages); correct stale Tutorial text (Tab → Shift); freeze player input during dialogue; one-time "what to do with the boss key" message box |

## Phase R4 — World & content (after R2–R3)
| ID | Task | Notes |
|---|---|---|
| R-40 | Room-block standard | `TileMapLayer`-only, shared navigation, door anchors, spawn markers, HUD at level root (remove per-room HUD) |
| R-41 | Floor1 parity rebuild | Reassemble original content from standardized blocks: enemies, NPCs, shop, key/boss-key progression |
| R-42 | Boss room encounter flow | Trigger, lock/unlock, victory handling; remove `Global.door` flag coupling |
| R-43 | Procgen-ready foundations | Room metadata (exits, difficulty) + spawn markers only; generation itself is `devPlan.md` D-6 |