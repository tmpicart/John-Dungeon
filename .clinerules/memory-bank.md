# Memory Bank Protocol

The `memory-bank/` folder is the project's documentation system. The code shows what is; the memory bank records what is intended and decided.

## Reading (session start, before coding)
1. `memory-bank/activeContext.md` — current phase, in-flight work, working agreements
2. `memory-bank/progress.md` — status of systems
3. `memory-bank/migrationMap.md` — what is superseded and what replaces it
4. When making convention, architecture, engine, or design decisions, also read `systemPatterns.md`, `techContext.md`, and `productContext.md` / `projectbrief.md`.

## Source-of-truth hierarchy
- **Memory bank** owns intent, decisions, and conventions.
- **The code** owns current behavior.
- On conflict: do not guess. State the conflict, propose which side to fix, and proceed only after the user decides. Never extend a superseded pattern just because it exists in code; never let documentation drift — update it in the same task.

## Updating (at task completion, after commit approval)
- `activeContext.md` — rewrite the snapshot (≤60 lines); never append
- `progress.md` — append one line per completed task
- `migrationMap.md` — delete entries for anything fixed; add newly discovered legacy references
- `systemPatterns.md` / `techContext.md` — edit in place when a convention or configuration changes
- `projectbrief.md` / `productContext.md` — change only by explicit user decision

## Documentation standard
- This repository is a portfolio project: all committed documentation uses professional, neutral, forward-looking language. Describe legacy code as "superseded" / "pending migration" — no editorializing.
- Each fact lives in exactly one file; cross-reference instead of duplicating. Prefer tables over prose.