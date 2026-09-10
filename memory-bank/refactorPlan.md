# Refactor Plan — Restructure & Migration

> **Purpose:** The ordered migration task list: restructure the project and move all systems onto the adopted architecture while preserving game feel. Feel improvements are allowed only where the code is already being touched; features go to `devPlan.md`.
> **Lifecycle:** Tasks are deleted on completion (noted in `progress.md`); keep this file under ~80 lines. Rules: `.clinerules/log-hygiene.md`.

## Adopted Decisions (summary — details in `systemPatterns.md`)
Hybrid folder structure · typed state transitions · shared states + config exports + hooks · signal-driven animation · mouse-driven `ShopData` shop · resource-authored dialogue + `PlayerProgress` on player · descent-structured (generated levels + authored arenas — productContext "The Descent") · boss 1:1 migration (redesign in `devPlan.md`) · opportunistic feel fixes only.

## Phase R4 — World & content
| ID | Task | Notes |
|---|---|---|
| R-40 | Room-block standard | Prop family landed (`entities/props/`); remaining: `TileMapLayer`-only stack, shared navigation, door anchors, spawn markers, HUD at level root (remove per-room HUD); `test_room.tscn` is the reference stack; author new templates on `custom_dungeon.tres` (16px atoms + patterns); conventions must cover descent room types (combat / treasure / shop / hallway / duel / gate) |
| R-41 | Tier-1 vertical slice | Supersedes "Floor1 parity" (descent design): hand-assemble the first descent tier from standardized blocks — combat rooms + gate level + arena — proving the standard before the generator exists |
| R-42 | Boss arena encounter flow | Trigger, lock/unlock, victory handling; per-arena death checkpoints; remove `Global.door` flag coupling |
| R-43 | Descent foundations | `TierProfile`/`EnemyData` metadata + spawn markers + `(tier, depth)` run state; generation itself is `devPlan.md` W-track |