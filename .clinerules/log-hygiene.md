# Log Hygiene — Anti-Bloat Rules

Documentation must stay small enough to be read in full, every session.

## Caps & rotation
| File | Rule |
|---|---|
| `activeContext.md` | Hard cap 60 lines. Rewritten each session — never appended. |
| `progress.md` | One line per task (`YYYY-MM-DD \| type \| summary`), ≤ ~160 chars, commit-message voice (`.clinerules/git.md`). When the log exceeds ~100 lines, move the oldest entries to `memory-bank/archive/progress-<year>-q<n>.md` (create the folder on first archive). |
| `devPlan.md` | Tasks are deleted on completion (noted in `progress.md`). Keep under ~80 lines; no status columns or dates — task IDs plus `progress.md` carry state. |
| `systemPatterns.md`, `techContext.md` | Edit in place. No changelogs inside these files. |
| `projectbrief.md`, `productContext.md` | Change only by explicit user decision. Edit in place. |
| One-off working logs (e.g. `ai-rework-log.md`) | Carry an expiry in the header; delete at that event, landing durable engine facts in `techContext.md` and conventions in `systemPatterns.md` first. |
| `archive/` | Cold storage only. Never treat archived content as current truth. |

## Content discipline
- Tables over prose; bullets over paragraphs.
- No duplication across files — one fact, one home, cross-referenced elsewhere.
- Table cells ≤ ~400 chars — split longer content into short rows or bulleted subsections.
- Update at task completion and after commit approval — not mid-task, not speculatively.
- If an update does not change future decisions, it does not belong in the memory bank.