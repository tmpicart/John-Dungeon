# Migration Map — Legacy → Target

> **Purpose:** The working map for the refactor: superseded patterns, their target replacements, and entities awaiting rewiring. Entries are **removed as they are fixed** — this file shrinks toward empty.

## API Migration Table
| Legacy (superseded) | Target | Seen in |
|---|---|---|
| `connect("signal", method)` string form | `signal.connect(callable)` | `entities/player/player_hurtbox.gd` (enemy-side `hurtbox.gd` fixed in R-22) |

## Framework Debt (targeted by `refactorPlan.md`)
| Issue | Task |
|---|---|
| Group-scan/exception discovery: `beam.gd` add_exception loop over `Enemies` (likely a no-op under its Player+Environment mask), `energy_star.gd` group loops, projectile `Enemies` membership | D-5 faction pass |
| Per-room duplicated HUD in room blocks | R-41 |
| Legacy `TileMap` wrapper around `TileMapLayer` children | R-41 |

## gdlint Baseline (repo-wide, measured 2026-09-06 after R-32)
| Area | Findings | Cleared by |
|---|---|---|
| entities/enemies | 0 | — |
| entities/boss | 0 | — (cleared R-24) |
| entities/player | 41 | opportunistic (scoped gate on rewrites) |
| entities/projectiles | 3 (`bomb.gd`) | opportunistic |
| entities/interactables | 0 | — (cleared R-31) |
| entities/npcs | 0 | — (cleared R-30) |
| systems | 0 | — (cleared R-33) |
| ui | 0 | — (cleared R-40) |
| levels | 0 | — |