# Active Context — Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (≤60 lines) — history goes to `progress.md`, not here.

## Phase
Phase R2: R-22 enemy anim/logic separation shipped (757331a). Next: R-23 enemy state configuration.

## Conventions
State core (R-20): typed `next_state: State` exports validated at startup; states receive `actor` by injection; enemy states keep string transitions (bridge → R-23). Godot 4.7: sibling `.tscn` NodePaths must be `../`-prefixed.
Enemy flow (R-22): signal-driven animation waits guarded by interrupt flow tokens; hits/parry-stuns/deaths route through State Control (`EnemyHurt`/`EnemyStun` wired in every enemy scene); `take_damage(dmg, from_position)` is knockback-ready (D-1 consumes); attack cooldowns are a `BaseEnemy` export; enemy velocities are plain px/s (never `* delta`).
Summoning (decided): shared combatant capability (necromancer, Sorceress R-24, future bosses). R-23: shared `EnemySummon` state — radius + summonable-tile gating, same-room flood-fill failsafe; only composition is per-summoner; R-43 room markers supersede tile scanning.
gdlint is a scoped gate: rewritten files pass clean; untouched findings ride migrationMap. Repo-wide baseline lives as a per-directory table in `migrationMap.md` (the old "48" was a mis-scoped measure).

## In Flight
- R-22 runtime verification pending (user editor run): parry-stun the flail skeleton (stun + doubled damage), red-slime pounce lunge, archer/necromancer cooldowns, die-mid-freeze restart (time scale restored), arrow despawn, necromancer summons 2–5 skeletons.
- `levels/floor_1.tscn` holds the user's uncommitted editor changes (all five enemies placed for the verification run) — never staged by the agent.

## Verification Gates
- gdlint on touched files (must be clean).
- Godot headless boots work from the terminal (the R-21 "binary not locatable" note was stale): `Godot_v4.7.2-stable_win64.exe --headless --path . <scene> --quit-after 5` — parse/wiring checks per scene + full level integration boot.

## Next Up
1. R-23 enemy state configuration — exports for ranges/speeds/cooldowns; typed transitions; behavior hooks; promote necromancer summon to shared `EnemySummon`.

## Open Decisions
- None.

## Working Agreements (quick recall)
- Commits: agent drafts → user approves → commit; memory bank follows as `docs(memory)`. Push only when instructed.
- Pre-flight before any commit pause: repo-wide gdlint baseline + scoped gate on touched files, both green.
- Circuit breaker: 3 failed attempts on a step → stop, report, defer.
- Scene text edits surgical; editor-made changes never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.
