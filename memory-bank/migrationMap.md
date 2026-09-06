# Migration Map — Legacy → Target

> **Purpose:** The working map for the refactor: superseded patterns, their target replacements, and entities awaiting rewiring. Entries are **removed as they are fixed** — this file shrinks toward empty.

## API Migration Table
| Legacy (superseded) | Target | Seen in |
|---|---|---|
| `connect("signal", method)` string form | `signal.connect(callable)` | `entities/player/player_hurtbox.gd` (enemy-side `hurtbox.gd` fixed in R-22) |

## Framework Debt (targeted by `refactorPlan.md`)
| Issue | Task |
|---|---|
| `textFile` camelCase + class-definitions-order in `npc_dialog.gd` — normalize per the GDScript style guide (state-core done R-20; enemy-side done R-22; interaction-side done R-30; item_hud done R-31; shop-side done R-32) | R-33 |
| Group-scan/exception discovery: `beam.gd` add_exception loop over `Enemies` (likely a no-op under its Player+Environment mask), `energy_star.gd` group loops, projectile `Enemies` membership | D-5 faction pass |
| Per-room duplicated HUD in room blocks | R-40 |
| Legacy `TileMap` wrapper around `TileMapLayer` children | R-40 |
| No player input freeze during dialogue (shop freeze done R-32) | R-33 |

## gdlint Baseline (repo-wide, measured 2026-09-06 after R-32)
| Area | Findings | Cleared by |
|---|---|---|
| entities/enemies | 0 | — |
| entities/boss | 0 | — (cleared R-24) |
| entities/player | 41 | opportunistic (scoped gate on rewrites) |
| entities/projectiles | 3 (`bomb.gd`) | opportunistic |
| entities/interactables | 0 | — (cleared R-31) |
| entities/npcs | 0 | — (cleared R-30) |
| systems | 3 (`npc_dialog.gd`) | R-33 |
| ui | 4 (`main_scene.gd`) | opportunistic (R-40 HUD pass) |
| levels | 0 | — |