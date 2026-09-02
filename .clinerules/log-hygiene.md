# Log Hygiene — Anti-Bloat Rules

Documentation must stay small enough to be read in full, every session.

## Caps & rotation
| File | Rule |
|---|---|
| `activeContext.md` | Hard cap 60 lines. Rewritten each session — never appended. |
| `progress.md` | One line per task (`YYYY-MM-DD \| type \| summary`). When the log exceeds ~100 lines, move the oldest entries to `memory-bank/archive/progress-<year>-q<n>.md` (create the folder on first archive). |
| `migrationMap.md` | Entries are deleted when fixed; it must shrink toward empty. Growth is allowed only for newly discovered legacy references. |
| `systemPatterns.md`, `techContext.md` | Edit in place. No changelogs inside these files. |
| `archive/` | Cold storage only. Never treat archived content as current truth. |

## Content discipline
- Tables over prose; bullets over paragraphs.
- No duplication across files — one fact, one home, cross-referenced elsewhere.
- Update at task completion and after commit approval — not mid-task, not speculatively.
- If an update does not change future decisions, it does not belong in the memory bank.