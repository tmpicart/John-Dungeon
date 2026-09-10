# Product Context — Design Intent

> **Purpose:** Why features exist and how the game should feel. Read before design-adjacent changes. The code shows *what is*; this file records *what is intended*.

## Core Fantasy
A tight, readable top-down action crawl: clear rooms of enemies, manage consumables, unlock progression gates, and overcome multi-phase bosses.

## Combat Feel (targets)
- **Mouse-facing action:** the player faces and acts toward the mouse; attack, block, and dash are committed actions with recovery windows.
- **Parry & reflect:** blocking toward an incoming hit parries it; ranged projectiles can be reflected back at attackers (`shield.parry()` + attacker `reflect()`); melee attackers are stunned when their hit is parried.
- **Dash:** quick repositioning with a cooldown, oriented on movement input.
- **Hit feedback:** frame-freeze scaled by damage, on-hit animations, distinct death sequences.
- Health is low-granularity (heart scale); potions are the primary sustain.

## Progression & Economy
- **Coins** from kills/chests → **blacksmith** (weapon upgrade, bombs, armor, wands, stamina upgrades) and **potion seller** (potions, max HP up).
- **Keys** gate doors/chests; a dedicated **boss key** gates each tier's arena (descent gates — see The Descent).
- **Weapon upgrades** visibly track level (sprite frame, damage, hitbox growth).
- **Gear intent (2026-09-09)**: **armor** (absorb = full negation incl. unblockables — effectively an i-frame with clank SFX + VFX + hitstop, no heart loss) · **wand** (secondary fire, one equipped; sword stays primary) · **loadout slots** (alt-weapon · potion · tool) · **potion types** (typed belt, equipped slot for quick-use) · **stamina** (chunk-costed rolls, no i-frames, upgradeable) with **mutual action cancels** (roll ⇄ attack ⇄ block; hitbox hygiene on cancel).

## The Descent — Structure (decided 2026-09-09)
- One continuous descent: **endless generated levels** organized into **6 tiers**; each tier is a stretch of levels (depths) ending in an **authored boss arena** at its bottom. Authored rooms = arenas, gate levels, the final prep room; everything else is generated.
- **Tier gate**: boss key drops on a pity schedule → gate level (key + stairs down) → arena → next tier. Tier 6's gate level is the **final prep room** (guaranteed double shop + Max-HP altar).
- **Finale**: Sorceress (existing 2-phase fight) → rift passage (checkpoint + heart container; cuttable) → **the Deity**, 3-phase, cosmic arena — immediate, no generated level between. Victory = the Deity. Per-arena death checkpoints (deity deaths retry the deity; the Sorceress stays dead).
- **Post-victory**: endless mode — dials frozen at cap, full pool. A gauntlet corridor before the arena is a designed-in later add, not built now.

### Tier table (decided; variants provisional)
| Tier | Gate boss | Cumulative pool unlocks |
|---|---|---|
| 1 · intro | — | green slime, lesser skelly, archer |
| 2 | Slime King | flail skelly, red slime, lesser skelly variant |
| 3 | Skeleton Lord | necromancer, blue slime, flail variant |
| 4 | Archer King | archer variant, yellow slime, lesser variant 2 |
| 5 | Nightborne | necromancer variant |
| 6 | Sorceress | — |
| Finale | The Deity (3-phase) | post-victory: Nightborne joins the pool |

## Depth Director (decided; numbers provisional until playtest)
- Run state = `(tier, depth)`; depth counts completed levels within the tier, resets at the boss. One **`TierProfile`** resource per tier drives everything from depth: budget curve, pool, loot, shop stock, room weights, key pity, mood.
- **Budget**: `base(tier) + step × depth`, capped; `base(tier+1) = cap(tier)` — monotonic ratchet; pool upgrades do the difficulty work, budget steps stay small.
- **Loot**: per-tier `LootTable` (quality) × depth scalar (quantity — coins/potion odds only). **Shop**: stock tier-gated; guaranteed ~once per tier.
- **Key pity** per depth: `0 / 15 / 35 / 60 / 100%` (expected ≈3.2 levels/tier, hard max 5).
- **Room mix per depth**: shop-early / full-mix mid / treasure-weighted late / gate at bottom — provisional shape, revisit after playtest.

## Death (decided)
- **Zelda-continue**: death regenerates the current depth's level; the build is kept (weapon, hearts, coins, keys). Boss deaths retry their own arena. Counters track completed levels only. Session game — no save system in MVP.

## Bosses & the Undying Knight (decided)
- **The style exception is the design**: bosses carry visual novelty; original sheets are reserved for bosses. Roster: Slime King (scaled slime art), Skeleton Lord + Archer King (AstroBob sheets), Nightborne (art to be sourced — intake pending), Sorceress (built; `boss_shadow.png` is her boss sprite, not an effect), Deity (art to be sourced — intake pending).
- **The Undying Knight** — her second-in-command (lesser nightborn; art to be sourced, matching the Nightborne family): roams from tier 2 (random encounters, evasion viable) + rare duel rooms (premium loot); escalates per tier; undying while she lives; final optional duel post-victory, then dead for good.
- Post-victory pool addition: **Nightborne only**. The Knight was always in the pool and dies for good.

## Asset Constraint (decided)
- **No original art creation.** Sourced downloads allowed only through the intake policy (source + license → CREDITS/ASSETS). Pending sources: the Deity, the Nightborne + Knight family, wand sprites (check `assets/items/weapons.png` first).
- Variety levers: hue-rotation shader (slime colors + elite tints — `self_modulate` cannot hue-shift), mood stack (per-tier CanvasModulate, torch-light palettes, banner/prop/decal sets — in-style Pixel_Poem props incl. spikes-as-hazards), composition (pairs/packs/hybrids), VFX deaths (particles/flash/tweens — never new frames).
- Chroma shifts are the Zelda-1 tradition (palette swaps; blue = tougher): enemies shift freely, at most one environment axis per tier.

## NPCs & Dialogue
- Proximity-based interaction with a unified "[E] to …" prompt (InteractionManager).
- NPCs deliver paginated dialogue loaded from text files, then route to their service (shop).
- Future direction: a more prominent dialogue system and richer NPC interactions.

## Future Systems (explicit intent)
- **Summonable ally creatures** that fight alongside the player — combat ownership, faction, and targeting must stay clean enough to support this.
- Smarter, more varied enemy AI; multi-phase boss design.
- Complete sound and music design.