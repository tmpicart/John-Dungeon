# Git Rules

## Commit workflow (mandatory)
1. On task completion, inspect `git status` and review the full diff.
2. Draft a conventional commit message:
   - `type(scope): imperative subject` — ≤50 characters, no trailing period
   - blank line, then a structured body: short context paragraph + bulleted changes
   - `BREAKING CHANGE:` footer when applicable
   - types: `feat`, `fix`, `refactor`, `docs`, `chore`, `style`, `perf`, `test`, `assets`
3. **Present the drafted message and stop. Do not commit until the user approves.**
4. After approval, in one uninterrupted sequence with no second approval: commit the code work, update the memory bank (see `memory-bank.md`), then commit those updates as a `docs(memory):` commit.
   - Exception: convention changes in `systemPatterns.md` / `techContext.md` that are inseparable from the code introducing them ride in that code commit.
5. **Never push to the remote unless explicitly instructed.**

## Staging discipline
- Review status before every staging; stage with explicit pathspecs.
- Never stage: `.godot/`, temp/backup files, or unrelated working-tree changes.
- Godot sidecar files (`.import`, `.uid`) belong with the change that caused them.
- Mass `.import` rewrites after a Godot upgrade are a normal migration: verify the diff is importer metadata only, then commit as an isolated `chore(assets):` commit immediately.
- Before committing scene files, confirm the user has saved their work in the Godot editor so no half-saved state is committed.

## Message style
Plain, factual, informative — the commit history doubles as project documentation.