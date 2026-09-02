# Active Context — Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (≤60 lines) — history goes to `progress.md`, not here.

## Phase
R1 structure complete (R-10 `983dbfc`, R-11 `67d4588`). Next: R-20 state core rebuild (opens Phase R2).

## In Flight
- First editor open after R-11 rescans the FileSystem dock (one-time); transient "invalid UID" warnings self-heal as the uid cache rebuilds. Then run the smoke pass: menu → Floor1 → combat/shop/doors/chests → boss (also covers pending R-01…R-03 verification). The 4 Sorceress hitbox load errors are known, documented debt — `migrationMap.md` (R-24), not a regression.

## Recently Completed
- `67d4588` refactor(naming): snake_case sweep (R-11) — 744 paths renamed, 543 references rewritten, all verification gates green.

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
