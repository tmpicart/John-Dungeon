# Research — Look It Up, Don't Guess

> **Purpose:** Design decisions are validated against outside sources before
> they reach the plan or the code. The agent's first idea is a hypothesis,
> not a decision.

## When to research
- Conventions & industry standards (planning): before designing any
  nontrivial system, structure, pattern, or game-feel behavior, search for
  how the broader industry and the Godot community solve the same problem
  (standard patterns, reference implementations, official demos). An
  explicit "look this up" from the user is always mandatory.
- Solution selection: when multiple approaches exist, research the
  candidates and present a comparison in the plan — what each optimizes,
  known failure modes — with a recommendation checked against project
  constraints (memory-bank conventions, engine version, scope).
- Engine behavior (implementation): any engine API that new code uses and
  this repo has not already exercised — exact names, return shapes,
  semantics — verified against the class reference, not memory.
- Unexplained bugs: reproduce or collect the stack trace first, then check
  docs/changelogs for API drift before theorizing.

## How to research
- Source order for conventions: project memory bank (owns intent) → Godot
  official docs and demos → other engines' documentation as prior art for
  behavior design (e.g., AI perception models) → community consensus.
- Engine API facts: raw class-reference XML pinned to the version in
  techContext.md —
  raw.githubusercontent.com/godotengine/godot/<tag>/doc/classes/<Class>.xml
  (nearest tag; master as fallback for newer builds). Prefer raw sources
  over rendered doc pages (SPA pages return chrome).
- Quote the decisive fact and name the source in the plan or summary so
  research-driven conclusions stay auditable.

## Fit filter — use only what we need
- A standard solution is adopted only after checking it against project
  conventions, codebase scope, and the user's stated direction. Trim the
  standard to the need and note what was deliberately left out.
- If research contradicts project intent, surface the conflict and let the
  user decide (memory-bank source-of-truth hierarchy).
