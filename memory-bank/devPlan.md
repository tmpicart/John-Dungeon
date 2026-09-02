# Development Plan — Continued Feature Work

> **Purpose:** New features beyond the migration. Sequenced against `refactorPlan.md` phases; entries move to `progress.md` when shipped.
> **Lifecycle:** Same rules as `refactorPlan.md` — delete completed items; keep under ~80 lines. Rules: `.clinerules/log-hygiene.md`.

## D-1 Combat feel pass (after R-22 / R-23)
- Knockback on hit for enemies (uses the knockback-ready damage signature from R-22); player knockback evaluation
- Hit-stop / frame-freeze tuning pass
- Coin behavior feel (pickup magnetism, drop arcs) and enemies dropping coins/loot
- Death/restart flow: restart prompt/option on player death

## D-2 Progression & economy (after R-21 / R-32)
- Expanded shop stock, weapon tiers, consumable variety

## D-3 Dialogue & world content (after R-33)
- Staged dialogue authored in the JSON format; new NPCs and story beats

## D-4 Bestiary (after R-23 / R-24)
- New enemies; new bosses; **The Sorceress fight redesign** (migration is 1:1 per refactorPlan R-24; redesign intent recorded here)

## D-5 Ally summons (after R-23)
- Summonable ally creatures that fight alongside the player (faction/targeting cleanliness comes from R-20/R-23)

## D-6 World expansion (after R-43)
- Multi-floor dungeon; procedural generation over the room metadata standard

## D-7 Audio pass
- Complete sound and music design pass