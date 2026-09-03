# Code Style

- Naming and structural conventions live in `memory-bank/systemPatterns.md` (single source of truth).

## Linting
- `gdlint` (gdtoolkit; config pinned in `gdlintrc` at the repo root) must pass on every file a task touches.
- Pre-existing findings in lines a task does not otherwise change: leave them to the owning refactor task or record them in `memory-bank/migrationMap.md` — no drive-by fixes.
- The Godot editor LSP (Workspace Problems) is advisory and can serve stale analysis after external edits; the engine (`--headless --check-only --script`, scene boots) is the authoritative parse check.

## Comments
- Minimal and professional: explain non-obvious intent only.
- No self-notes, TODOs, FIXMEs, or reminders in code — the memory bank is the documentation system.
- No commented-out dead code — delete it; git history preserves it.
- Remove debug `print()` output before commit.