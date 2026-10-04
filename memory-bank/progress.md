# Progress — Status & Log

> **Purpose:** Feature status and a compact work log. One line per task; caps and archiving rules in `.clinerules/log-hygiene.md`.

## Status
Migration complete: frameworks R-01..R-33 landed; development phase — task list in `devPlan.md` (R-40..R-42 lead).

## Log
- 2026-09-02 | setup | Audited codebase; established memory bank + clinerules; accepted Godot 4.7 importer metadata migration (240 `.import` files).
- 2026-09-02 | planning | Adopted hybrid structure and framework decisions; authored refactorPlan (R0–R4) and devPlan (D-1..D-7).
- 2026-09-02 | refactor | R-01 dead-file purge: 31 tracked files removed (orphans, junk audio, duplicate sheets, zip); zero refs verified by path + uid.
- 2026-09-02 | assets | Vendored Monsters_Creatures_Fantasy (21 sheets) + Enemy_Animations_Set (16 sheets + Aseprite) under Assets/.
- 2026-09-02 | refactor | R-02 debug-spam removal: 24 prints + 7 dead print lines + 3 empty _process stubs; error paths → push_error/push_warning.
- 2026-09-02 | fix | R-03 MainMenu startup: _ready() + random title via preload; node renamed TitleCard.
- 2026-09-02 | refactor | R-10 hybrid tree: 146 files → Entities/Systems/UI/Levels/room_blocks; tileset + door sound deduped; res:// refs + autoload anchors rewritten; 4 stale hitbox refs → R-24.
- 2026-09-02 | refactor | R-11 snake_case sweep: 744 paths renamed (asset folders, scripts/scenes + .uid sidecars, dialogue txt); 543 path refs rewritten; all gates green.
- 2026-09-02 | refactor | R-12 folder snake_case: 22 game folders incl. `Assets`→`assets` per Godot docs; ~850 paths + 355 reference files rewritten; gates green.
- 2026-09-03 | refactor | R-20 state core rebuild: typed+validated transitions, actor injection, `Global` hardening, single-tick fix, framerate-independent decay, idle-state deletion; 41 files.
- 2026-09-03 | fix | Player movement feel: rates rescaled for the single tick (accel 1000 / friction 800 / decay 800), dash normalized to fixed `dash_speed` 200; user-verified.
- 2026-09-03 | refactor | R-21 player subsystem API: spend/consume/add methods on PlayerInventory, upgrade_weapon() with damage resync, shop/NPC/doors/chest/pickup rewiring.
- 2026-09-03 | refactor | R-22 enemy anim/logic separation: signal-driven waits + interrupt flow tokens, EnemyHurt/EnemyStun states, knockback-ready take_damage, px/s velocity retune; several feel fixes folded in.
- 2026-09-04 | refactor | R-23 enemy state configuration: typed transitions + exported behavior config replace all per-enemy state scripts; shared EnemySummon + EnemyPounce added; 11 scripts deleted.
- 2026-09-04 | refactor | R-24 Sorceress onto BaseEnemy: typed states + non-interruptible intake, per-hitbox damage, parry-vulnerable/beam-recovery window, unblockable projectile tiers; playtest-hardened.
- 2026-09-04 | feat | LootTable resource + tier-1 table: exact-sum budget rolls, item-owned tier/value.
- 2026-09-04 | refactor | R-30 interaction framework: Interactable base, event-driven InteractionManager, `interact` on E, PickupItem scatter drops, chest loot wiring, headless smoke test.
- 2026-09-04 | feat | Sorceress parry-stagger: parried melee/slide freezes her on the yellow pulse with doubled damage (boss_stagger, stun() override); beam recovery unchanged.
- 2026-09-04 | feat | Aim-locked arcing homing reflects: PlayerCombat aim API (aim_direction + cursor-snap get_aim_target), ±75° launches with persistent re-lock, no-pierce reflect.
- 2026-09-04 | feat | Summon telegraph: creatures materialize spawn_delay (0.5s) after the flourish via shared EnemySummon; dead summoners cancel pending spawns.
- 2026-09-04 | fix | Boss phase-2: intervention warning 3.0→1.5s; stars spawn at chest height, wall-bounce via collision_mask 4, contact-kill on PlayerHurtbox.
- 2026-09-05 | fix | Parry-stagger flush violation: stagger pauses mid-action, exit stops; necromancer summon/cast swap poses and share the purple attack strobe.
- 2026-09-06 | refactor | R-31 unified doors: one LockType script, animation Call Method unlock timing (4 scenes); boolean boss key on PlayerInventory + HUD; stale door/chest scripts retired.
- 2026-09-06 | refactor | R-32 shop rework: ShopData-driven mouse shop (dynamic cards, click-buy, coin bar, walk-away close, modal input freeze); Max HP+ altar; legacy shop UI retired.
- 2026-09-06 | refactor | Test room promoted to default level: main menu loads test_room, floor_1 deleted; shared custom_dungeon.tres; layer stack with z/collision/nav flags + HUD parity.
- 2026-09-06 | feat | Door/chest variants + summon guard: door_red.tscn no-lock door, prompt-flash locked feedback, locked chest consumes a key; enemy_summon occupancy guard.
- 2026-09-06 | fix | Chest loot spawns at chest origin: `_spawn()` drops the 15px down-screen offset; `scatter()` alone displaces drops.
- 2026-09-07 | feat | R-33 resource-driven dialogue: DialogueData/Stage .tres per speaker, npc_dialog rewrite (typewriter, portraits, stage consumption), unified npc.gd, PlayerProgress flags + stage counters, boss-key taunt.
- 2026-09-07 | feat | Dynamic prompt anchoring: alpha-aware frame bounds hug the drawn art (rotation/scale/flip proof), manager-side margin + label height, screen-space prompt_offset nudge.
- 2026-09-07 | fix | Screen-space prompt layer: per-frame anchor projection on the manager CanvasLayer, frame-relative used-rects (sideways prompts fixed: NPCs, boss key, chest), UI-subtree exclusion; smoke 66 checks.
- 2026-09-08 | feat | R-40 props foundation: entities/props family (flicker, lights, foot blockers, wall z-tier), key rotation, legacy torch.tscn removed, ui gdlint cleared.
- 2026-09-08 | chore | Asset license purge: code-only repo policy; assets/ untracked (fonts + custom shader whitelisted); CREDITS.md/ASSETS.md added; history purged to zero residual; pack 53.7→0.65 MiB.
- 2026-09-08 | docs | Provenance recorded: enemy family mapped (chibi derivatives in scenes; originals kept for planned bosses); asset intake policy added (.clinerules/assets.md).
- 2026-09-08 | docs | CREDITS.md rewritten in industry credit format; ASSETS.md provenance classes aligned.
- 2026-09-09 | design | Descent architecture locked: 6-tier endless levels + depth director (TierProfile), Zelda-continue death + per-arena checkpoints, boss roster + roaming Undying Knight, deity cosmic-arena finale.
- 2026-09-09 | design | Task tracks split (one system or enemy per task): armor-negation rules, no-i-frame rolls + action cancels, wand secondary fire via loadout slots, potion belt; R-41 rescoped to tier-1 slice.
- 2026-09-12 | fix | Door collision accuracy: red door blocker widened to the closed-door silhouette, prompt area grown, sprite + interaction shape realigned (570ceaa).
- 2026-09-12 | feat | R-40-prep level toolset: test_room reference stack (Floor/Walls/Decals/Obstacles/Overhead flags), five unlit prop scenes, obstacle_outline.gd @tool (8411cf0).
- 2026-09-12 | feat | Validated-landing loot scatter: PickupItem rest-point query validation + hop speed scaling, chest 2-3 wave spew, static button-pickup keys y-sorted, seeded obstacle probe (1be19eb).
- 2026-09-13 | docs | Rules: research-before-design policy (research.md), standalone-voice commit messages (git.md), debug-loop containment (circuit-breaker.md).
- 2026-09-13 | docs | ai-rework-log.md added as the AI restart spec.
- 2026-09-13 | docs | Docs/rules audit: stale entries removed, duplicated facts single-homed (engine facts → techContext, gear design → productContext), length caps added to log-hygiene.
- 2026-09-13 | refactor | Refactor retirement: legacy demo floor deleted (dungeon + 8 room blocks), doors renamed to the door_<variant> family, last string-form connect migrated.
- 2026-09-13 | docs | Plans consolidated: refactorPlan/migrationMap retired (R-40..R-42 lead devPlan, R-43 → W-1); D-9 group-retirement task recorded; projectbrief moved to the development phase.
- 2026-09-30 | feat | Runtime navmesh baking: NavBaker carves Environment cells at agent_radius clearance; main_scene bakes on load; nav/level_nav/scene probes.
- 2026-09-30 | feat | Width-aware aim gate on the Environment layer (3-ray, 2px clearance); arrow flight identity via Global.player; NPC feet join env layer.
- 2026-09-30 | feat | Shared chase/attack states on the baked mesh: RVO avoidance on all five enemies, corner press-through, archer LOS volley; chase_probe.
- 2026-09-30 | feat | Escape-scored retreat with cornered fight latch and ranged standoff repositioning; retreat_probe.
- 2026-09-30 | docs | Verified layer/system map into techContext; design-review follow-ups R-43..R-46 + D-10 into devPlan.
- 2026-09-30 | docs | Playtest findings logged as BUG-1..3: doorway pathing stall, doorway sprite vanish, necromancer missile rework.
- 2026-10-04 | fix | Door standard: door_key matched to door_red colliders/link and seated in the west archway; deprecated door scenes removed.
- 2026-10-04 | fix | BUG-2 resolved: character roots z 3 (enemies + NPCs), airborne projectiles z 4, per systemPatterns tiers.
