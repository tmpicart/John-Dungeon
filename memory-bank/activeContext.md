# Active Context — Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (≤60 lines) — history goes to `progress.md`, not here.

## Phase
Phase R2: R-23 enemy state configuration shipped (fc90c84). Next: R-24 Sorceress boss migration.

## Conventions
Enemy states (R-23): eight shared states configured entirely by scene exports — typed `State` refs (`../`-prefixed siblings), ranges/speeds/cooldowns/flags per scene; zero per-enemy state scripts (`EnemyPounce` is the one unique-behavior state). `BaseEnemy` routes interrupts via `state_control`/`hurt_state`/`stun_state` exports. Damage roles: `BaseEnemy.damage` = body/contact only; projectiles/hazards own their `damage` (`hitbox.owner.damage` contract).
State core (R-20): typed+validated transitions, actor injection; the string bridge remains for the boss only (removal → R-24). Godot 4.7: sibling `.tscn` NodePaths must be `../`-prefixed.
Enemy flow (R-22): signal-driven animation waits guarded by interrupt flow tokens; `take_damage(dmg, from_position)` knockback-ready; velocities are px/s (never `* delta`).
gdlint is a scoped gate: rewritten files pass clean; untouched findings ride migrationMap. Repo-wide baseline table lives in `migrationMap.md`.

## In Flight
- R-23 runtime verification pending (user editor run): archer keeps distance/LOS/retreats at close range but NOT when hit; flail engages only in the 15×5 axis box; necromancer retreats after hits and summons 2–5 skeletons same-room on a 10 s cooldown; green slime contact-damages without attacking; red-slime pounce + explode-on-contact unchanged.
- `levels/floor_1.tscn` is the user's test scratch space — enemies placed ad hoc; the agent never stages or depends on it.

## Verification Gates
- gdlint on touched files (must be clean); repo-wide baseline table in `migrationMap.md`.
- Godot headless boots from the terminal: `Godot_v4.7.2-stable_win64.exe --headless --path . <scene> --quit-after 5` — parse/wiring checks per scene + level boot; startup validation (typed exports) must be silent. ObjectDB "leaked at exit" warnings under `--quit-after` are stochastic engine noise, not a gate failure.

## Next Up
1. R-24 boss migration (1:1) — Sorceress onto `BaseEnemy` + shared state core; absorb misplaced `Idle.gd`; projectile fixes; repair 4 scriptless hitbox nodes; string-bridge removal lands with her.

## Open Decisions
- None. (Damage roles decided: body vs per-surface — recorded in `systemPatterns.md`.)

## Working Agreements (quick recall)
- Commits: agent drafts → user approves → commit; memory bank follows as `docs(memory)`. Push only when instructed.
- Pre-flight before any commit pause: repo-wide gdlint baseline + scoped gate on touched files, both green.
- Circuit breaker: 3 failed attempts on a step → stop, report, defer.
- Scene text edits surgical; editor-made changes never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.
