# Active Context — Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (≤60 lines) — history goes to `progress.md`, not here.

## Phase
R3 shipped. Combat pass shipped: boss parry-stagger (04168fb), aim-locked arcing homing reflects (1ee97d4), summon telegraph (6897d87). Next: R-31 unified doors or R-32 shop rework.

## Conventions
- Player aim API (`PlayerCombat`): `aim_direction()` (player→cursor; feeds the parry cone + reflect launches) and `get_aim_target()` (EnemyHurtbox shape query centered on the cursor within `aim_snap_radius`, nearest surface wins; physics-step only, no group scans). The facing direction is the input-agnostic aim primitive; the controller model is an open decision (reticle vs direction + soft lock).
- Reflectable projectiles: one Area2D (`Hitbox`) — `collision_layer` swaps at reflect (8→6) for victim-side damage pairing, `collision_mask` carries lifetime (Player + Environment pre; Enemies + Environment post, no piercing); `body_entered` self-frees. Missiles launch `reflect_arc_deg` wide, re-lock the aim whenever targetless, and settle onto the aim line between locks; arrows unchanged behaviorally.
- Boss parry-stagger: parried boss body hitboxes (melee/slide) route `stun()` → `boss_stagger` — freeze-frame + Vulnerable pulse + doubled damage (3 s, returns to Engage); `interruptible = false` keeps hits flinch-free; attack surfaces are killed on interrupt/death (`disable_attack_surfaces()` + slide `exit()` cleanups); beam recovery stays exposure-only (unparriable, direct-damage raycast).
- Summoning (shared `EnemySummon`): flood-fill placement on `is_summonable` tiles; the flourish effect is the telegraph — creatures materialize `spawn_delay` (0.5 s) after it; a dead summoner cancels pending spawns.
- Interaction: `Interactable` (Area2D — prompt/enabled/one_shot/auto_pickup + `interacted` signal); InteractionManager is event-driven. Prompts derive from the `interact` binding ("[E] …").
- Pickups: `PickupItem` root (scatter/bounce, settle-gated collection, loot exports) + `Pickup` area (`pickup.tscn` bakes auto + one-shot). Toggle `enabled`; never poke collision shapes.
- Loot: `LootTable.roll(budget)` exact-sum rolls; item scenes own tier/value; keys/boss keys are progression (tier −1).
- Input: single `interact` action (E physical); controller support later = adding an event to it.
- gdlint is a scoped gate: rewritten files pass clean; untouched findings ride migrationMap.

## In Flight
- None. `levels/floor_1.tscn` holds the user's uncommitted playtest layout — pending a user level-content commit.
- User playtest feedback on reflect arc/lock feel and summon pacing drives tuning.

## Verification Gates
- gdlint on touched files (clean); baseline in `migrationMap.md`.
- `tests/interaction_smoke.tscn` headless — 32 assertions, exit 0 = pass.
- `--headless --import` before headless runs (new `class_name` scripts); scene boots `--quit-after 5` (ObjectDB warnings = engine noise). Boss/arrow scenes boot clean headless.

## Next Up
1. R-31 unified doors (retire door script duplicates) or R-32 shop rework.
2. D-plan hooks: monster coin drops, pickup animation, bomb pickup scene; D-5 allies will force the faction/targeting registry decision (see migrationMap).

## Open Decisions
- Controller aim model (when pad support lands): virtual reticle vs direction + soft lock — direction favored; both plug into the PlayerCombat aim API.

## Working Agreements (quick recall)
- Commits: agent drafts → user approves → commit; memory bank follows as `docs(memory)`. Push only when instructed.
- Pre-flight before any commit pause: repo-wide gdlint baseline + scoped gate on touched files, both green.
- Circuit breaker: 3 failed attempts on a step → stop, report, defer.
- Scene text edits surgical; editor-made changes never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.
