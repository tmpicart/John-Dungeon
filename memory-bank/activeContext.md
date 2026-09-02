# Active Context — Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (≤60 lines) — history goes to `progress.md`, not here.

## Phase
R0 hygiene complete (R-01/R-02/R-03 committed). Next: Phase R1 structure work.

## In Flight
- One combined runtime verification in the editor, covering R-01 + R-02 + R-03: shop NPCs, necromancer summon, walk sounds, chest open + bomb throw (console must be clean), boss fight incl. summons, menu title randomize over two launches, Play/Quit.
- `Scenes/Hud/MainMenu.tscn` was text-edited (node renamed `TitleCard`) — confirm it renders in the editor.

## Recently Completed
- `1fef410` fix(menu): repair MainMenu startup (R-03) — `_ready()` + random title from `Assets/Hud/`, node → `TitleCard`
- `8aab1a4` chore(cleanup): drop debug spam and stubs (R-02) — 25 files, +13/−60

## Next Up
1. R-10 adopt hybrid tree (editor-driven moves; carries the two dedup entries in `migrationMap.md`: double-vendored tileset + door sound)
2. R-11 snake_case sweep (incl. `Doungeon.tscn` rename)

## Open Decisions
- None.

## Working Agreements (quick recall)
- Commits: agent drafts → user approves once → agent commits code, updates the memory bank, and commits it (`docs(memory):`) automatically. Never push unless told.
- Scene text edits are allowed but surgical; editor-made scene changes are expected and never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.