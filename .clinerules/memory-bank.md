# Memory Bank Protocol

The `memory-bank/` folder is the project's documentation system. The code shows what is; the memory bank records what is intended and decided.

## Reading (when-to-read-what)
Session start reads `activeContext.md` only — its pointers route every other read.

| When | Read |
|---|---|
| Session start | `memory-bank/activeContext.md` (only) |
| Task order, open decisions | `memory-bank/devPlan.md` |
| What shipped when | `memory-bank/progress.md` |
| Convention / architecture choices | `memory-bank/systemPatterns.md` |
| Engine behavior, tests, gates | `memory-bank/techContext.md` |
| Product / design intent | `memory-bank/productContext.md`, `memory-bank/projectbrief.md` |
| Any commit | `memory-bank/commit-protocol.md` |
| Asset work (`assets/`, `CREDITS.md`, `ASSETS.md`, `.gitignore`) | `memory-bank/asset-intake.md` |
| Updating memory-bank files | `.clinerules/log-hygiene.md` |

## Source-of-truth hierarchy
- **Memory bank** owns intent, decisions, and conventions.
- **The code** owns current behavior.
- On conflict: do not guess. State the conflict, propose which side to fix, and proceed only after the user decides. Never extend a superseded pattern just because it exists in code; never let documentation drift — update it in the same task.

## Updating (at task completion, after commit approval)
- Per-file caps, rotation, and decision rules: `.clinerules/log-hygiene.md`.
- Timing: `activeContext.md` is rewritten at session end; `progress.md` gains one line per completed task; plan tasks are deleted as they ship. Never update mid-task or speculatively.

## Documentation standard
- This repository is a portfolio project: all committed documentation uses professional, neutral, forward-looking language. Describe legacy code as "superseded" / "pending migration" — no editorializing.
- Content discipline (duplication, density, tables over prose): `.clinerules/log-hygiene.md`.