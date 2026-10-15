# System Patterns — Architecture & Conventions

> **Purpose:** Agreed architecture and conventions — new code follows this file.

## Architecture Map

### Player (`entities/player/character.tscn`)
Hub-and-subsystems: `Character.gd` delegates to child subsystem nodes and a state machine.
- `PlayerMovement` — acceleration/friction movement; dash with cooldown timer
- `PlayerCombat` — HP, attack/block execution, damage intake
- `upgrade_weapon()` resyncs cached damage
- `PlayerCombat` signals: `hp_changed`, `max_hp_changed`
- `PlayerInventory` — coins/bombs/potions/keys + boolean `has_boss_key` (floor progression, at most one)
- API: `add_coin`/`spend_coins`/`add_key`/`consume_key`/`add_potion`/`add_bomb`/`use_potion`/`use_bomb`/`give_boss_key`/`use_boss_key`
- atomic spend/consume return `bool`
- every mutation emits its `*_changed` signal
- callers never write the count fields directly
- `PlayerAnimation` — 4-direction mouse-facing animation routing; equipment layering (weapon/shield foreground vs background)
- `State Control` — generic state machine (`systems/state_core/state.gd`, `state_control.gd`); states call `transition_to(target)` via typed `State` refs
- control injects `actor` (the owning entity) into every state; validates exported refs at startup (deferred ready pass)

### Enemies
- `entities/enemies/base_enemy.gd` — `BaseEnemy` CharacterBody2D base: `hp`/`damage`/`attack_cooldown_duration` exports
- typed interrupt routing: `state_control`/`hurt_state`/`stun_state` exports, validated in `_ready`
- signal-driven action flows (`await animation_finished`; `run_action_animation` → `attack`) guarded by interrupt flow tokens; Call Method Tracks carry hit windows/sfx
- `take_damage(dmg, from_position)` knockback-ready
- `attack_sfx_from_animation` for animation-triggered swing sounds; audio hooks
- reusable states: `entities/enemies/states/enemy_idle|chase|attack|retreat|hurt|stun|summon|pounce.gd` — every enemy scene configures the same state set through exports (typed state refs wired `../`-prefixed; ranges/speeds/cooldowns/flags per scene)
- bundles hold scene + scripts + states together
- per-enemy behavior = exported configuration
- `EnemyChase` — proximity/hit retreat, line-of-sight, radial/axis-box ranges, approach stop, summon rolls; unassigned `attack_state` = validated pacifist
- `EnemyChase` reads the outcome gate through a 0.1 s cached clock on the in-range tick path; the reposition scorer and the probes query raw
- `EnemyAttack` — projectile sets
- `EnemySummon` — composition + cooldown owned by the state; same-room flood-fill over summonable tiles
- `EnemySummon` occupancy guard (bodies/areas): spawns never land inside props, entities, or the player
- Summon live-cap ledger: slots tracked per summoner on `BaseEnemy` (pending telegraphs hold budget); rolls clamp to the remaining budget — partial casts fire; at-cap reads not-ready so chase and flight handovers stand down
- summon tile scanning pending migration to room markers
- summon telegraph: the flourish effect — creatures materialize `spawn_delay` later; dead summoner cancels
- state subclasses only for genuinely unique behavior (`EnemyPounce` lunge; red slime's death/explode semantics live on its enemy script)
- velocities are px/s — never multiplied by delta (`move_and_slide` applies the tick delta)
- target: all combatants — including bosses — run on this framework

### Interaction
- autoload `InteractionManager` — interaction registry + screen-space prompt
- `Interactable` (Area2D): `prompt`, `enabled`, `one_shot`, `auto_pickup`; `interacted` signal
- areas self-register on player contact; unregister on `_exit_tree`
- nearest area wins; re-resolved only on registry change or keypress — no per-frame scans
- player resolves via `Global.player`
- freed entries pruned
- prompt prefix derives from the `interact` input binding
- `set_locked()` freezes interaction for future modals
- prompt label: screen-space, on the manager's `CanvasLayer` (layer 10, VT323)
- manager re-projects the active area's world anchor through the canvas transform every frame while shown; registry events position synchronously
- bobbing/moving/rotating owners are followed; world rendering can never occlude the prompt
- anchor = top-center of the union of the owner's visible sprite art: alpha-aware used-rect of the displayed frame, frame-relative, cached per texture+frame; rotation/scale/flip/region proof
- `CanvasLayer`/`Control` subtrees excluded from bounds; tree visibility required
- manager owns the `PROMPT_MARGIN` gap (12 screen px); label sized to its text
- `prompt_offset` — screen-space nudge (default zero)
- sprite-less areas anchor at the area origin
- universal pickups: `Pickup` (extends `Interactable`; `pickup.tscn` bakes auto + one-shot) + `PickupItem` item root
- `PickupItem`: desynced bob; fake-height `scatter()`/`eject()` with bounces
- collection gated until settle + `pickup_delay`; airborne z+1; front-hemisphere scatter default
- `loot_tier`/`loot_value` exports
- `scatter()` validates the landing point with a one-shot Environment point query (shrinking re-rolls; fallback = source)
- flight is cosmetic integration under the fake-height arc — no physics bodies on drops
- `LootTable` resource (`tier`, `entries: Array[PackedScene]`): `roll(budget)` picks random affordable entries until spent
- item scenes own pricing (single source of truth); a value-1 entry guarantees exact sums
- chests: `drop_scene` (deterministic progression) + `loot_table`/`loot_value` (rolled)
- keys/boss keys are progression (tier −1, never rolled)

### Combat Surfaces
- physics layers 6–9: PlayerHitbox / PlayerHurtbox / EnemyHitbox / EnemyHurtbox (full map in `techContext.md`)
- hurtboxes resolve `hitbox.get("damage")` first, falling back to `hitbox.owner.damage`; plain areas resolve the owner's export
- scripted `EnemyHitbox` surfaces (`entities/enemies/hitbox.gd`) carry per-surface values (boss swing 2 / slide 1)
- `unblockable` (same probe) makes PlayerHurtbox skip its parry branch — waves, intervention light, and stars are dodge-only; magic missiles reflect
- `Hurtbox` (enemies) → direct `take_damage` routing
- `PlayerHurtbox` — mouse-angle check routes parry / reflect / stun / damage
- block+facing a non-interruptible boss's body hitbox (melee/slide) routes her `stun()` → parry-stagger (freeze-frame + doubled damage)
- beam recovery keeps the exposure-only window
- aim API (`PlayerCombat`): `aim_direction()` — player→cursor vector; feeds the parry cone and reflect launches
- `get_aim_target()` — EnemyHurtbox shape query centered on the cursor within `aim_snap_radius`; nearest surface wins (layer-first, no group scans; physics-step only)
- facing direction = input-agnostic aim primitive
- controller model decided: direction + soft lock — the `get_aim_target()` cursor-snap is the lock; no reticle

### HUD
- signal-driven: `main_scene.gd` wires player subsystem signals to `heart_bar` and `item_hud`; no polling

### Shop
- `ShopData` resource (`title`, `entries: Array[ShopItem]`) — attached by any `Interactable` owner, NPC or inanimate (altar)
- `ShopItem` subclasses (`systems/shop/items/`) own `grant(player)`; data fields `display_name`/`cost`/`icon`/`max_purchases`
- stock lives in `.tres` files authored in the Inspector
- shared `shop.tscn` (per-owner instance) builds one card per entry at open
- hover highlight; click buys via atomic `spend_coins` → `grant`; live coin bar; MAX/greyed states
- purchase caps session-scoped
- modal freeze: open calls `Global.player.set_input_locked(true)` + `InteractionManager.set_locked(true)`
- player gate stops state input routing and disables combat (invulnerable while open); movement stays live so walk-away closing works
- both restore on close; dialogue modals reuse the same freeze
- closes on Esc (`quit` action) or walking 140 px from the owner
- theme: dark flat-slab (StyleBoxFlat, parchment text, 0.3 world dim)
- modal layers default hidden in scenes so the level editor stays clean

## Adopted Conventions
| Area | Convention |
|---|---|
| Naming | Folders/files `snake_case` (Godot project-organization docs; exported PCKs are case-sensitive), no spaces; classes `PascalCase` via `class_name`; variables/functions `snake_case`; signals as events (`hp_changed`, `*_changed`) |
| Naming | Node names PascalCase; node names referenced by state-machine string transitions stay stable across renames |
| Player reference | `Global.player` at point of use; group lookups live only inside `global.gd` (the `"Player"` group is the locator's private mechanism); contact identity = collision-layer bit 1; groups are broadcast/tagging only |
| Player reference | States receive the character via the injected `actor`; `Global.player` serves non-state consumers. Pass references at creation boundaries (`actor`, exported refs, spawn context), never call chains |
| Scene edits | `.tscn`/`.tres` surgical edits: `.clinerules/godot-collaboration.md` |
| New enemy | Extend `BaseEnemy.gd`; wire nav agent + audio in the scene (reuse base states, override only unique — Architecture Map) |
| New interactable | Node + `Interactable` child (or instance `pickup.tscn` for walk-over items); connect `interacted`; toggle `enabled` to gate — never poke collision shapes |
| Folder structure | **Hybrid**, all folders snake_case: feature bundles under `entities/` — player, enemies, boss, npcs, projectiles, interactables (scene + scripts + states together) |
| Folder structure | Type-based `systems/` (state_core, interaction, dialogue, shop) + `ui/`, `levels/`, `assets/` (vendored art packs — documented basic-assets exception to `addons/`); `Global` autoload in `systems/global/` |
| State transitions | Typed refs only — no string-matched state names; sibling refs in `.tscn` need the `../` prefix (4.7 loader quirk: techContext) |
| Rendering tiers | z-index: floor TileMapLayer -1; Walls/Decals/Obstacles 0, tree order Floor, Walls, Decals, Obstacles (equal-z ties break by tree order; decals over walls, under every y-sorted entity); y-sorted world 0; airborne (projectiles, beam line) +1; wall-face overlay 10 (Overhead layer + wall-mounted props); UI on CanvasLayer |
| Rendering tiers | The `Environment` container is not y-sorted — chests/props sort against the player as one block; deliberate fix planned with the room-block standard |
| Tileset authoring | `custom_dungeon.tres`: 16px atoms; TileSet **patterns** stamp composed chunks carrying their collision/nav/custom data. Wall collision painted on tiles (TileSet physics layer 0 → Environment 4); scene `StaticBody2D` only for dynamic blockers (doors/chests). Nav polygons on floor tiles only — strip any from collision tiles |
| Reference room stack | `test_room.tscn`: Floor(z −1, nav on, collision off), Walls(0, collision on), Decals(0, both off), Obstacles(0, collision on, nav off, cool modulate tint + outline script), Overhead(10, collision ON on purpose — doorway/archway atoms gate bodies; they also stop projectiles at the west archway, accepted; nav off); non-default flags explicit per layer |
| Decal authoring | Paint-time randomize: multi-select probability + scattering % + random flips |
| Mid-room obstacles | Obstacles-layer atoms with NO Floor tile beneath (nav exclusion; collision from atom physics) |
| Obstacle outline | `levels/obstacle_outline.gd` on the Obstacles layer draws 8 offset silhouette mirrors behind (outer rim) plus 1px seam lines on shared edges between adjacent bricks (@tool, rebuilds on `changed`) |
| Light split | Alignment-sensitive wall decor (torches lit/unlit, shackles) = scriptless entities, rotate/flip per wall side; unlit floor candles = scriptless variants (`candlestick_unlit`, `candlestick_2_unlit`: AtlasTexture crop + foot blocker, no light) |
| Banners | Static wall atoms; animated frames parked; per-tier tint via layer material parked with the slime-variant scope |
| Flash palette | On-hit flash WHITE (enemies), RED (player); stun/vulnerable YELLOW `Color(1, 1, 0, 1)` pulsed on a `FlashPlayer` animation channel — per-animation `flash_color` tracks own the color |
| Flash palette | Action telegraphs reuse the enemy's own attack strobe channel (necromancer summon/cast share the purple strobe on swapped poses) |
| Non-interruptible bosses | `interruptible = false`: hits flash + damage only; a parried body hitbox staggers via the boss `stun()` override (`boss_stagger`: freeze-frame + exposure, doubled damage) |
| Non-interruptible bosses | Attack surfaces are animation-track- or code-driven — interrupts and death must kill them (`disable_attack_surfaces()` + slide `exit()` cleanups); summon placement needs `is_summonable`-painted tiles, skips cleanly without |
| Animation interrupts | Interrupt states freeze mid-action with `animation_player.pause()`; `stop()` is illegal inside area-signal flushes — `boss_stagger` pairs an `exit()` stop to reset position for repeat attacks |
| Reflectable projectiles | One Area2D (`Hitbox`): `collision_layer` swaps at reflect (8→6) for victim-side damage pairing; `collision_mask` carries lifetime — Player + Environment pre, Enemies + Environment post |
| Reflectable projectiles | Post-reflect the consume surface equals the damage surface: `area_entered` dies on enemy hurtboxes; player body contact consumes via a per-tick sweep after the physics flush — a same-frame parry keeps the shot |
| Reflectable projectiles | Missiles launch `reflect_arc_deg` wide; re-lock `get_aim_target()` whenever targetless |
| Hybrid missile routing | Blind per-muzzle launch at the player — no sight gate on the flight line, dodges crash on purpose; a blocked center line hands steering to the baked mesh (`move_and_slide` root names crashes) |
| Hybrid missile routing | Routing releases only through a width-aware 3-lane exit gate (3 px clearance + full hysteresis); a tangent-clear center ray with a clipping lane holds the route |
| Muzzle spawn clearance | A volley muzzle must be point-clear (`spawn_point_clear` skips buried ones) and reachable from the shooter (`aim_line_clear` — the offsets outrun thin cover, so a point-clear muzzle can hang on the player's side of a wall); a fully sealed volley registers zero and the whiff gate repositions the body |
| Volley whiff gating | `EnemyAttack` owns outcome knowledge: one `VolleyReport` per volley (arrived inside `whiff_arrival_radius`; register/retire live count; zero-registered = whiffed at once). `EnemyChase` owns the decision: the handover consults `fire_gate_open()` beside the blind gate — the body keeps pathing, no enter() bounce |
| Whiff gate policy | A settled whiff (no arrival, no live shots) closes the handover until the body travels `whiff_reposition_distance` from the fire position or `whiff_retry_seconds` lapse; in-flight volleys and arrivals never close; arrival marks pre-reflection only (a reflected shot is player-owned) |
| Whiff gate policy | A settled whiff (no arrival, no live shots) closes the handover behind a 0.1 s continuous confirmation; arrival satisfaction (`whiff_satisfied()`) clears the memory outright when the body lands on a stance the volley can fire from; the retry window lapses it without movement |
| Firing stance scoring | EnemyChase's FIRING scorer probes navmesh-clamped fan points at three reaches and holds attack range via `_bounded_close_in` instead of parking on the player; EnemyRetreat's FIRING desire grades candidate stances through `band_clear_at(position)` — repositioning targets clear muzzle bands, not just open space; necromancer retreat is hit- and stance-driven only |
| Firing stance scoring | EnemyChase's FIRING scorer probes navmesh-clamped fan points at three reaches and holds attack range via `_bounded_close_in` instead of parking on the player; EnemyRetreat's FIRING desire grades candidate stances through `band_clear_at(position)` — repositioning targets clear muzzle bands, not just open space |
| Melee press | A finished path beside the player presses at a level point (`melee_press_range`): box attackers aim at a point beside the player's swing band, radial attackers press straight; sub-threshold progress per `press_stall_window` flips the lateral side once, then a guard hold faces the player until the range gate opens |
| Standoff hold | Ranged chasers on cooldown hold ground instead of re-ticking the attack handover (the per-frame bounce re-rolled summon chances); `standoff_shuffle` drifts inside `shuffle_radius` at reduced speed under the facing pin, retarget steps never tighter than `SHUFFLE_MIN_STEP` |
| EnemyReposition | The whiff-gate handover state (FIRING-desire EnemyRetreat): fan candidates grade connectability (`max_detour_ratio` detour cap) and rank in-band > clear > fallback; mesh-clamped candidates and a mid-flight empty fan keep the current route; an empty opening fan cornered-disengages under `suppress_retreat` |
| Retreat triggers | Run-on-hit is the universal backstop; ranged enemies add a proximity flight (player inside `retreat_range` behind a continuous-presence confirm, suppressed while sight-blocked or a shot is ready) and panic-summon reflexes on the chase and both retreat desires, each with its own trigger and cooldown |
| Gate confirmations | Per-tick boundary predicates route handovers only after holding continuously (REPOSITION_GATE_CONFIRM, PROXIMITY_RETREAT_CONFIRM) — a body straddling the boundary cannot flap the states; arrival satisfaction outranks travel thresholds |
| Confirmed walk facing | The sprite flips only after a contrary velocity sign holds FLIP_CONFIRM_SECONDS; `face_toward` and pin-holding states commit facing through `_apply_facing`, and the chase re-decides `facing_pinned` every tick — per-tick steering jitter never lands as a flip |
| Door scenes | `door_red.tscn` = reference scene (no lock, eli art; rotate instances for wall sides); `door_key.tscn` = its exact sibling (`key_door_sheet.png`, `lock_type` key); `boss_door.tscn` (boss arena) keeps pre-standard geometry until the boss-arena reseating; door/chest blockers sit on Environment |
| Door key geometry | Interaction 20×26 @ (0, −2), slab 16×6 @ (0, −3) on Environment 4/mask 3; `PassageLink` on the origin, endpoints (−25, 0)/(17, 0), sprites art-centered |
| Boss key | Prompted interact pickup; first pickup plays its boss's `boss_taunt` DialogueData through the shared dialogue box |
| Chests | One script (`entities/interactables/chests/chest.gd`): opens on interact (sprite frame 2) and scatters its `loot_table` roll; `requires_key` consumes a key first with the same prompt-flash feedback as doors. `chest.tscn` = key chest (locked look, red sheet frame 1), `chest_no_key.tscn` = free chest |
| Props | Scriptless decor in `entities/props/`: lit `wall_torch`, `side_torch`, `candlestick`, `candlestick_2`; unlit variants per the light split; `wall_torch_unlit` (lit geometry minus animation/light); `wall_shackle`/`wall_shackle_2` |
| Prop anatomy | `AnimatedSprite2D` autoplaying `default` at 5.7 fps, radial `PointLight2D`, foot blocker `StaticBody2D` on Environment (layer 4, mask 0) |
| Prop placement | Wall-mounted props render at z 10 (Overhead tier) to overlay wall faces; floor props stay z 0 for y-sort; side torch is a left-facing profile — flip H / rotate per wall side (door_red convention) |
| Prop art sets | Pack per-frame art (`torch_1..4`, `candlestick_1/2_*`) is distinct from the `objects/` strips (`wall_torch_h`, `torch_animation`) — not interchangeable |
| Dialogue | Per-speaker `DialogueData` .tres (`systems/dialogue/`): portrait = AtlasTexture crop; one-shot stages (`pages` + `requires_flag` gate, `set_flag` on completion); greeting fallback once stages are consumed |
| Dialogue | Consumption lives on the player's `PlayerProgress` (flags + per-speaker stage counters, session-scoped); author pages as `Array[String]`, flags as `String` (4.7.2 resource hazard: techContext) |
| Dialogue | `npc.gd` opens its dialogue on interact, hands off to `shop_data` when the dialogue finishes normally; boss keys play their taunt via the shared box (`boss_key.gd`) |

## Asset Policy
- Code-only repo; whitelist, source classes, and per-path mapping: `ASSETS.md`. Intake/renaming procedure: `.clinerules/assets.md`. Attribution and licences: `CREDITS.md`.
- Enemy sheets split (usage convention): scenes use the chibi derivatives (`enemy_*.png`); original pack sheets are reserved for planned boss appearances — both ship in-game; never redistribute the raw files.
