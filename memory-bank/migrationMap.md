# Migration Map — Legacy → Target

> **Purpose:** The working map for the refactor: superseded patterns, their target replacements, and entities awaiting rewiring. Entries are **removed as they are fixed** — this file shrinks toward empty.

## API Migration Table
| Legacy (superseded) | Target | Seen in |
|---|---|---|
| `connect("signal", method)` string form | `signal.connect(callable)` | `entities/player/player_hurtbox.gd` (enemy-side `hurtbox.gd` fixed in R-22) |
## Entities Awaiting Rewiring
| Entity | Note | Target |
|---|---|---|
| `systems/shop/shop_2.gd` | Purchases rewired onto the inventory API (R-21); `buy1`/`buy2` keys are a temporary bridge | Mouse-card `ShopData` shop retires the script (R-32) |
| Legacy inventory UI (`ui/inventory.gd`, `ui/slot.gd`) | Superseded by `PlayerInventory`; contains indexing bugs | Retire or redesign on the new inventory service |

## Duplicates & Relocations (consolidate during reorganization)
- Shop scene consolidation: `systems/Shop/panel.tscn` / `panel_2.tscn` are the live cards of active `systems/Shop/shop_2.tscn` → retire in the R-32 rework

## Framework Debt (targeted by `refactorPlan.md`)
| Issue | Task |
|---|---|
| camelCase/PascalCase identifiers (`textFile`, `openShop`/`closeShop`, `weaponName`) plus class-definitions-order and blank-line-whitespace findings in surgically-touched scripts — normalize to snake_case per the GDScript style guide (state-core done R-20; enemy-side done R-22; interaction-side done R-30; item_hud done R-31) | R-32 / R-33 |
| Group-scan/exception discovery: `beam.gd` add_exception loop over `Enemies` (likely a no-op under its Player+Environment mask), `energy_star.gd` group loops, projectile `Enemies` membership | D-5 faction pass |
| Per-room duplicated HUD in room blocks | R-40 |
| Legacy `TileMap` wrapper around `TileMapLayer` children | R-40 |
| No player input freeze during dialogue/shop modals | R-32 / R-33 |

## gdlint Baseline (repo-wide, measured 2026-09-06 after R-31)
| Area | Findings | Cleared by |
|---|---|---|
| entities/enemies | 0 | — |
| entities/boss | 0 | — (cleared R-24) |
| entities/player | 41 | opportunistic (scoped gate on rewrites) |
| entities/projectiles | 3 (`bomb.gd`) | opportunistic |
| entities/interactables | 0 | — (cleared R-31) |
| entities/npcs | 0 | — (cleared R-30) |
| systems | 19 | R-32 / R-33 |
| ui | 15 (`inventory.gd`/`slot.gd`/`main_scene.gd`) | R-32 (legacy UI retirement) |
| levels | 0 | — |