# Active Context — Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (≤60 lines) — history goes to `progress.md`, not here.

## Phase
R-31 shipped (74f9b2a): one `lock_type` door script with animation-owned unlock timing, boolean boss key on `PlayerInventory` with a HUD icon, stale door/chest scripts retired, floor_1 carries test doors. Next: R-32 shop rework or R-33 dialogue.

## Conventions
- Doors: one script (`entities/interactables/doors/door.gd`) with `lock_type` (none/key/boss_key); each scene's "open" animation Call Method track calls `_set_passable()` — no timer constants; `Label`/SFX optional per scene (plain doors now play the shared open SFX).
- Boss key: boolean on `PlayerInventory` (`give/use_boss_key` + `boss_key_changed`); prompted interact pickup ("Pick Up", `auto_pickup` off) — the `interacted` signal is the future R-33 message-box trigger; HUD icon box shows possession. Item lighting deferred to D-8.
- Regular keys stay counted (`add_key`/`consume_key`); keys/boss keys are progression (tier −1).
- Player aim API (`PlayerCombat`): `aim_direction()` + `get_aim_target()` (EnemyHurtbox shape query, `aim_snap_radius`); facing is the input-agnostic aim primitive; controller model open (reticle vs direction + soft lock).
- Reflectable projectiles: one `Hitbox` Area2D — `collision_layer` swaps 8→6 at reflect, `collision_mask` carries lifetime; missiles re-lock the aim when targetless.
- Boss parry-stagger: parried body hitboxes route `stun()` → `boss_stagger` (freeze-frame, Vulnerable pulse, doubled damage); attack surfaces killed on interrupt/death; beam recovery stays exposure-only.
- Summoning (shared `EnemySummon`): flood-fill on `is_summonable` tiles; flourish effect is the telegraph; dead summoner cancels pending spawns.
- Interaction: `Interactable` (Area2D — prompt/enabled/one_shot/auto_pickup + `interacted`); event-driven InteractionManager; prompts derive from the `interact` binding.
- Loot: `LootTable.roll(budget)` exact-sum rolls; item scenes own tier/value.
- Input: single `interact` action (E physical); `buy1`/`buy2` are temporary until R-32.
- gdlint is a scoped gate: rewritten files pass clean; untouched findings ride migrationMap.

## In Flight
- Playtest verification of R-31 in the editor: door locks/warnings, boss-key HUD icon appear/consume, chest2 key drop, SFX on plain doors. Reposition the floor_1 TestDoor/TestKeyDoor/TestBossDoor/TestBossKey instances freely.

## Verification Gates
- gdlint on touched files (clean); baseline in `migrationMap.md`.
- `tests/interaction_smoke.tscn` headless — 32 assertions, exit 0 = pass; it writes `smoke_result.txt` to the repo root — delete it, never commit it.
- `--headless --import` before headless runs; scene boots `--quit-after 5`.

## Next Up
1. R-32 shop rework (mouse cards, `ShopData`, input freeze) or R-33 dialogue system (JSON pages, `PlayerProgress`, boss-key message box).
2. HUD restyle requested (user: current HUD "looks awful") — fold into the HUD consolidation (R-40) or a dedicated pass.
3. D-plan hooks: monster coin drops, pickup animation, bomb pickup scene; D-5 allies force the faction/targeting registry decision.

## Open Decisions
- Controller aim model (when pad support lands): direction + soft lock favored; both plug into the PlayerCombat aim API.

## Working Agreements (quick recall)
- Commits: agent drafts → user approves → commit; memory bank follows as `docs(memory)`. Push only when instructed.
- Pre-flight before any commit pause: repo-wide gdlint baseline + scoped gate on touched files, both green.
- Circuit breaker: 3 failed attempts on a step → stop, report, defer.
- Scene text edits surgical; editor-made changes never reverted silently.
- New code follows `systemPatterns.md`; superseded patterns live in `migrationMap.md` only.
