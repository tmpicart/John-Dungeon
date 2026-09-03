# Active Context — Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (≤60 lines) — history goes to `progress.md`, not here.

## Phase
Phase R2 opened: R-20 state core rebuild shipped (ba5246a). Next: R-21 player subsystem API.

## Conventions
State core (R-20): typed `next_state: State` exports wired in the Inspector and validated at startup (deferred ready pass); states receive `actor` by injection — `Global.player` (property-backed) only for non-state consumers; enemy/boss states keep string transitions (bridge → R-23). Godot 4.7: sibling `.tscn` NodePaths must be `../`-prefixed — bare sibling paths load as null. gdlint (gdtoolkit) adopted as a scoped verification gate — changed files pass; legacy findings ride migrationMap, not drive-by fixes.

## In Flight
- User smoke run pending: movement feel with the 2×-compensated constants, attack/block decay parity, dash feel, death → Esc.

## Recently Completed
- R-20 state core rebuild: typed transitions, actor injection, `Global` hardening, single-tick fix, framerate-independent decay, `player_idle.gd` deletion, Sorceress `Idle.enemy` wiring.

## Next Up
1. R-21 player subsystem API — `spend_coins` / `consume_key` / `add_potion` on `PlayerInventory`; weapon upgrade via combat; public API documented; shrink-safe heart bar.

## Open Decisions
- None.

## Working Agreements (quick recall)
- Commits: agent drafts → user approves → commit; memory bank follows as `docs(memory)`. Push only when instructed.
- Linting: gdlint on changed files (adopted R-20).
- Circuit breaker: 3 failed attempts on a step → stop, report, defer.
- Scene text edits surgical; editor-made changes never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.
