# Active Context — Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (≤60 lines) — history goes to `progress.md`, not here.

## Phase
Phase R3 shipped (R-30 interaction framework). Boss experiment shipped: the Sorceress staggers on parries (04168fb). Next: R-31 unified doors or R-32 shop rework.

## Conventions
- Boss parry-stagger: parried boss body hitboxes (melee/slide) route `stun()` → `boss_stagger` — freeze-frame + Vulnerable pulse + doubled damage (3 s, returns to Engage); `interruptible = false` keeps hits flinch-free; attack surfaces are killed on interrupt/death (`disable_attack_surfaces()` + slide `exit()` cleanups); beam recovery stays exposure-only (unparriable, direct-damage raycast).
- Interaction: `Interactable` (Area2D — prompt/enabled/one_shot/auto_pickup + `interacted` signal); InteractionManager is event-driven (nearest re-selection on registry change/keypress only, cached `Global.player`, freed-entry pruning, `set_locked()` freeze hook). Prompts derive from the `interact` binding ("[E] …").
- Pickups: `PickupItem` root (desynced bob, fake-height scatter/bounce, collection gated until settle + `pickup_delay`, airborne z+1, front-hemisphere scatter, loot exports) + `Pickup` area (`pickup.tscn` bakes auto + one-shot). Toggle `enabled`; never poke collision shapes.
- Loot: `LootTable.roll(budget)` exact-sum rolls; chests default to the tier-1 table; item scenes own tier/value; keys/boss keys are progression (tier −1).
- Input: single `interact` action (E physical); controller support later = adding an event to it.
- gdlint is a scoped gate: rewritten files pass clean; untouched findings ride migrationMap.

## In Flight
- None. `levels/floor_1.tscn` holds the user's uncommitted playtest layout (boss removed, doors/pickups placed, chest2 `drop_scene` restored) — pending a user level-content commit.
- User playtest feedback on the parry-stagger (duration, Engage hand-off, phase-2 balance) drives tuning.

## Verification Gates
- gdlint on touched files (clean); baseline in `migrationMap.md`.
- `tests/interaction_smoke.tscn` headless — 32 assertions, exit 0 = pass.
- `--headless --import` before headless runs (new `class_name` scripts); boot floor_1 `--quit-after 5` (ObjectDB warnings = engine noise). Boss scene boots clean headless.

## Next Up
1. R-31 unified doors (retire 3 door scripts + parse-stale `chest.gd`/`door.gd` duplicates) or R-32 shop rework.
2. D-plan hooks now live: monster coin drops (`PickupItem.scatter(TAU)`), pickup animation, bomb pickup scene (tier-2 loot).

## Open Decisions
- None recorded this session.

## Working Agreements (quick recall)
- Commits: agent drafts → user approves → commit; memory bank follows as `docs(memory)`. Push only when instructed.
- Pre-flight before any commit pause: repo-wide gdlint baseline + scoped gate on touched files, both green.
- Circuit breaker: 3 failed attempts on a step → stop, report, defer.
- Scene text edits surgical; editor-made changes never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.
