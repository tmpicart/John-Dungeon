# Project Brief — John Dungeon: Remastered

> **Purpose:** Source of truth for project scope and goals. All other memory files cascade from this one. Changes require an explicit decision.

## Identity
- **Engine:** Godot 4.7.2 (GDScript, Forward Plus)
- **Genre:** 2D top-down pixel-art dungeon crawler
- **Origin:** Built in three weeks by a five-person team; continued as a solo project under the "Remastered" banner.

## Mission
Build on the original's foundation:
- Fix bugs from the original game
- Refactor the codebase for easier content expansion
- Quality-of-life improvements
- New enemies and bosses
- Deeper progression systems
- An expanded, multi-level dungeon
- More refined, strategic combat
- Smarter enemy AI
- A more prominent dialogue and NPC system
- Improved shop and item systems
- Complete sound and music design

## Current Phase
Development phase: the remastered player, enemy, interaction, dialogue, and shop frameworks are complete; content is built on the descent design (room-block standard, generated tiers). The game is not shippable until the tier-1 descent slice is playable.

## Scope Decisions (adopted)
| Decision | Choice |
|---|---|
| File naming | `snake_case` for all files |
| Level architecture | Rebuild the dungeon from modular room blocks; keep door/room layout generation-friendly (procedural generation is a possible future direction) |
| Boss (The Sorceress) | Migrate onto the current enemy framework |
| Global access | Formalize the `Global` autoload into a standard service-locator role |
| Future systems | Summonable ally creatures — informs combat ownership, faction, and targeting design |

## Non-Goals (current phase)
- No shipping milestone until the tier-1 descent slice is playable.
- No engine upgrade or platform targets.