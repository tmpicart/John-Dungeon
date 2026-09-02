# Active Context — Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (≤60 lines) — history goes to `progress.md`, not here.

## Phase
R0 hygiene in progress: R-01 (dead-file purge) + asset vendoring committed; R-02 / R-03 remain in the phase.

## In Flight
- Runtime verification of the R-01 changeset in the editor still outstanding (shop NPCs, necromancer summon, walk sounds).

## Recently Completed (this session)
- `c81d780` chore(cleanup): remove dead files (R-01) — 31 files, 408 deletions
- `41c572f` chore(assets): add monster/enemy sprite packs — 75 files
- Downloaded "2D Pixel Dungeon Asset Pack v2.0" confirmed byte-identical to the vendored pack — do not re-attempt.

## Next Up
1. R-02 debug-spam removal (Hurtbox, chest, boss states, summon; empty `_process` stubs)
2. R-03 MainMenu fix (`_onready()` → `_ready()`, title textures, node rename)
3. Phase R1 structure work (R-10/R-11) — now carries two new dedup entries in `migrationMap.md` (double-vendored tileset + door sound)

## Open Decisions
- None.

## Working Agreements (quick recall)
- Commits: agent drafts → user approves → agent commits. Never push unless told.
- Scene text edits are allowed but surgical; editor-made scene changes are expected and never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.