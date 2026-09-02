# Active Context — Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (≤60 lines) — history goes to `progress.md`, not here.

## Phase
Setup complete. Awaiting refactor planning (step three).

## In Flight
- None. Setup commits have landed on `master` (local, unpushed).

## Next Up
1. Refactor task list (step three): define and order migration tasks from `migrationMap.md`.
2. Resolve pending decision: target folder structure (type vs feature vs hybrid) — blocks the reorganization phase.
3. First refactor pass: player-facing API consolidation (shop/NPC rewiring onto `PlayerInventory` / `PlayerCombat`).

## Open Decisions
- Folder structure convention (see `systemPatterns.md` → Pending Decisions).

## Working Agreements (quick recall)
- Commits: agent drafts → user approves → agent commits. Never push unless told.
- Scene text edits are allowed but surgical; editor-made scene changes are expected and never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.