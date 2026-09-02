# Active Context — Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (≤60 lines) — history goes to `progress.md`, not here.

## Phase
Planning complete: architecture decisions (D1–D9) adopted; refactor plan and development plan authored.

## In Flight
- None. Plans and rules are committed on `master` (local, unpushed).

## Next Up
1. Phase R0 (hygiene): dead-file purge, debug-spam removal, MainMenu fix — no design dependencies, editor-verifiable.
2. Phase R1: hybrid folder migration — user drives moves in the Godot editor; agent updates references and docs.

## Open Decisions
- None. Resolved decisions live in `systemPatterns.md` and `refactorPlan.md`.

## Working Agreements (quick recall)
- Commits: agent drafts → user approves → agent commits. Never push unless told.
- Scene text edits are allowed but surgical; editor-made scene changes are expected and never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.