# Active Context — Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (≤60 lines) — history goes to `progress.md`, not here.

## Phase
R1 structure complete (R-10 `983dbfc`, R-11 `67d4588`, R-12 `cc1df32`). Next: R-20 state core rebuild (opens Phase R2).

## Conventions
Godot official docs adopted as naming authority (R-12): folders + files snake_case, node names + `class_name` PascalCase, identifiers snake_case with past-tense signals. Vendored art lives in `assets/` (documented basic-assets exception to `addons/`). Script identifier normalization rides R-20/R-22/R-23/R-32/R-33 (`migrationMap.md`).

## In Flight
- Smoke run passed in the user's editor session post-R-12 (no regressions reported) — R-11 + R-12 editor-verified; R1 fully closed. The 4 Sorceress hitbox load errors remain known debt (R-24).

## Recently Completed
- `cc1df32` refactor(structure): snake_case all game folders (R-12) — 22 folders, ~850 paths, 355 reference files, gates green, headless run silent.

## Next Up
1. R-20 state core rebuild — typed transitions (`@export var next_state: State` validated in `_ready()`), attack/block-from-idle input filter, states receive owner refs instead of `Global.player`, `Global` null-cache hardening, velocity-decay normalization (Attack/Block).

## Open Decisions
- None.

## Working Agreements (quick recall)
- Commits: agent drafts → user approves once → agent commits code, updates the memory bank, and commits it (`docs(memory):`) automatically. Never push unless told.
- Terminal file moves are normal practice: stage reference rewrites together with the moves (see `.clinerules/godot-collaboration.md`).
- Circuit breaker: 3 failed attempts on a step → stop, error report, defer to user (`.clinerules/circuit-breaker.md`).
- Scene text edits surgical; editor-made changes never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.
