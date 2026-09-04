# Active Context — Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (≤60 lines) — history goes to `progress.md`, not here.

## Phase
Phase R2: R-24 Sorceress migration shipped (ced8c35, playtest-hardened). Next: cleanup tasks (R-30+) or D-plan features.

## Conventions
- Enemy framework (R-22..R-24): `BaseEnemy` + shared states configured by scene exports; typed state core only (string bridge retired). `interruptible = false` (bosses): hits deal damage + `_play_hit_flash()` only — nothing cancels flows or routes interrupts.
- Per-hitbox damage: scripted `EnemyHitbox` (entities/enemies/hitbox.gd) carries `damage`; hurtboxes resolve `hitbox.get("damage")` → fallback `hitbox.owner.damage`. `unblockable` flag (same probe) makes PlayerHurtbox skip its parry branch — waves/intervention light/stars dodge-only; magic missiles reflect; boss melee/slide → vulnerable window.
- Boss vulnerable window: parry or beam recovery → `begin_exposure(duration)` — yellow pulse via the FlashPlayer "Vulnerable" loop + doubled damage; never interrupts. Palette: enemy + boss on-hit flash WHITE (player RED); stun/vulnerable YELLOW `Color(1,1,0,1)`.
- Rendering tiers (z): ground decals/effects −1 (floor TileMapLayer −1 too), entities/world 0 y-sorted, airborne +1 (projectiles, beam line), UI on CanvasLayer. `FlashPlayer` is the boss's parallel flash channel (renamed from OnHitPlayer).
- gdlint is a scoped gate: rewritten files pass clean; untouched findings ride migrationMap.

## In Flight
- None. User playtest feedback on the shipped fight drives the next round.

## Verification Gates
- gdlint on touched files (must be clean); baseline table in `migrationMap.md`.
- Headless: `Godot_v4.7.2-stable_win64.exe --headless --path . <scene> --quit-after 5` boots; scripted SceneTree tests for combat flows (stub-player pattern, enemies instantiated without entering the tree for static checks). ObjectDB leak warnings under `--quit-after` are engine noise.
- New `class_name` scripts need `--headless --import` before headless script runs can resolve them.

## Next Up
1. R-30/R-31/R-32 cleanup tasks or D-plan features. Deferred from R-24 (user call): projectile lighting optimization, boss attack cooldowns, missile lifetime.
2. Boss room remake (R-42/R-43): paint `is_summonable` ground tiles; reset the room's z tiers (boss_room root currently sits at z −1).

## Open Decisions
- None recorded this session.

## Working Agreements (quick recall)
- Commits: agent drafts → user approves → commit; memory bank follows as `docs(memory)`. Push only when instructed.
- Pre-flight before any commit pause: repo-wide gdlint baseline + scoped gate on touched files, both green.
- Circuit breaker: 3 failed attempts on a step → stop, report, defer.
- Scene text edits surgical; editor-made changes never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.
