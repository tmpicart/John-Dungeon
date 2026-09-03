# Active Context — Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (≤60 lines) — history goes to `progress.md`, not here.

## Phase
Phase R2 opened: R-21 player subsystem API shipped (e70a04d). Next: R-22 enemy anim/logic separation.

## Conventions
State core (R-20): typed `next_state: State` exports validated at startup (deferred ready pass); states receive `actor` by injection; `Global.player` only for non-state consumers; enemy/boss states keep string transitions (bridge → R-23). Godot 4.7: sibling `.tscn` NodePaths must be `../`-prefixed.
Inventory/combat access (R-21): all callers mutate player stats only via `PlayerInventory`/`PlayerCombat` methods — atomic spend/consume return `bool`; count fields are never written directly; the HUD stays signal-fed. `HeartBar.set_max_health` resizes both directions.
gdlint is a scoped gate: rewritten files pass clean; findings on untouched lines ride migrationMap (re-baselined at 48 after R-21).

## In Flight
- R-21 runtime verification pending (user editor run): shop purchases via keys 1/2, sword upgrade applying real damage, key door/chest key flow, heart-bar growth. Godot binary not locatable from the terminal — editor run is the only runtime gate.
- `levels/floor_1.tscn` holds the user's uncommitted editor changes (Flail_Skeleton placement) — never staged by the agent.

## Recently Completed
- R-21 player subsystem API: inventory spend/consume/add methods, combat upgrade path with stale-damage fix, consumer rewiring (shop, NPCs, key/boss-key doors, chest, potion pickup), local door-timing constants, shrink-safe heart bar, temporary `buy1`/`buy2` input actions.
- R-20 state core rebuild + post-playtest movement feel fix (see `progress.md`).

## Next Up
1. R-22 enemy anim/logic separation — signal-driven interruption-safe flow, double-delta velocities, attack cooldowns in base, knockback-ready damage signature, red-slime pounce fix, `time_scale` restore guard, `arcane_arrow` screen-exit cleanup, parry-stun unification.

## Open Decisions
- None.

## Working Agreements (quick recall)
- Commits: agent drafts → user approves → commit; memory bank follows as `docs(memory)`. Push only when instructed.
- Linting: gdlint on changed files (adopted R-20).
- Circuit breaker: 3 failed attempts on a step → stop, report, defer.
- Scene text edits surgical; editor-made changes never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.
