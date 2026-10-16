# Active Context — Session Snapshot

> **Purpose:** Where work stands and what's next — pointers only; facts live in their owning files (phase/mission → projectbrief, conventions → systemPatterns, engine facts → techContext, tasks & decisions → devPlan).

## Phase
Development phase — charter: `projectbrief.md` §Current Phase; task order: `devPlan.md`.

## Just Landed
- QA-2 enemy states closed (2026-10-15): audit + fixes — pounce tick countdown vs freed-instance resume, missing-anim guard + attack handover, red slime explosion sfx wired, chase enter guards, hurtbox damage contract; slime_contact probe hardened; contact-damage stall traced → QA-10

## Next Up
1. QA-2 close-out commits — message drafted, awaiting user approval; playtest first: red slime explosion sound + a pounce suicide (sound plays, no debugger spam); reload saved scenes before editor saves (slime_red.tscn changed)
2. QA-10 micro-fix (recommended next): contact_hitbox re-arm on empty overlap read + probe rerun
3. QA-3 projectiles & reflect — next audit segment

## Pointers
- Conventions & architecture: `systemPatterns.md`
- Engine facts, tests, gates: `techContext.md`
- Quality-audit program (closed registers, queue): `memory-bank/quality-audit.md`
- Open decisions register: `devPlan.md` §Open Decisions
- Work log & history: `progress.md` (pre-2026-09-30 lines in `archive/`)

## Notes
- QA-1 + QA-2 closed 2026-10-15; F-2 stays parked until a dedicated archer look
- F-overlap policy: QA segments stay no-behavior-change; feel work lives on the F- rows (F-4/F-5/F-6/F-7)
- Commit discipline: messages drafted only after task DONE confirmed; never push unless told


