# Log Hygiene — Anti-Bloat Rules

Documentation must stay small enough to be read in full, every session.

## Caps & rotation
| File | Rule |
|---|---|
| `activeContext.md` | Hard cap 60 lines. Rewritten each session — never appended. |
| `progress.md` | One line per task (`YYYY-MM-DD \| type \| summary`), ≤ ~160 chars, commit-message voice (`memory-bank/commit-protocol.md`). When the log exceeds ~100 lines, move the oldest entries to `memory-bank/archive/progress-<year>-q<n>.md` (create the folder on first archive). |
| `devPlan.md` | Tasks are deleted on completion (noted in `progress.md`). Keep under ~80 lines; no status columns or dates — task IDs plus `progress.md` carry state. |
| `systemPatterns.md` / `techContext.md` / `productContext.md` | Soft caps ~180 / ~100 / ~60 lines; exceeding triggers an AI-memory compression pass at the next docs touch (below). Edit in place, no changelogs; `productContext.md` also changes only by explicit user decision. |
| `projectbrief.md` | Change only by explicit user decision. Edit in place. |
| One-off working logs | Carry an expiry in the header; delete at that event, landing durable engine facts in `techContext.md` and conventions in `systemPatterns.md` first. |
| `archive/` | Cold storage only. Never treat archived content as current truth. |

## AI-memory compression (soft-cap pass)
- Keep identifiers (file/scene/script/signal names), intent (why a rule exists), and qualifiers (conditions, ranges, version limits).
- Cut duplication, history/provenance, and prose narrative; entries too dubious to trust are deleted — uncertain memory is worse than absent memory.
- Enforce by dedupe, rehoming facts to their owning file, or splitting concerns into their own section/file — never fact-trim to fit a cap.

## Content discipline
- Tables over prose; bullets over paragraphs.
- No duplication across files — one fact, one home, cross-referenced elsewhere.
- Table cells ≤ ~400 chars — split longer content into short rows or bulleted subsections.
- Update at task completion and after commit approval — not mid-task, not speculatively.
- If an update does not change future decisions, it does not belong in the memory bank.