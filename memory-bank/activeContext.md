# Active Context — Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (≤60 lines) — history goes to `progress.md`, not here.

## Phase
R1 structure: R-10 done (hybrid tree adopted, `983dbfc`). Next: R-11 snake_case sweep.

## In Flight
- Post-restructure editor smoke run if not yet done: menu → Floor1 → combat/shop/doors/chests → boss (also covers pending R-01…R-03 verification). The 4 Hitbox load errors are known, documented debt — see `migrationMap.md` (R-24), not a regression.

## Recently Completed
- `983dbfc` refactor(structure): adopt hybrid tree (R-10) — 146 files moved, asset dedup, all references rewritten.

## Next Up
1. R-11 snake_case sweep (file renames incl. spaces, PascalCase scripts, `Levels/Doungeon.tscn`; `.uid` sidecars travel with files; references updated + verified)

## Open Decisions
- None.

## Working Agreements (quick recall)
- Commits: agent drafts → user approves once → agent commits code, updates the memory bank, and commits it (`docs(memory):`) automatically. Never push unless told.
- Terminal file moves are normal practice: stage reference rewrites together with the moves (see `.clinerules/godot-collaboration.md`).
- Scene text edits surgical; editor-made changes never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.