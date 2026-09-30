# Memory Bank Protocol

The `memory-bank/` folder is the project's documentation system. The code shows what is; the memory bank records what is intended and decided.

## Reading (session start, before coding)
1. `memory-bank/activeContext.md` — current phase, in-flight work, working agreements
2. `memory-bank/progress.md` — status of systems
3. When making convention, architecture, engine, or design decisions, also read `systemPatterns.md`, `techContext.md`, and `productContext.md` / `projectbrief.md`.

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