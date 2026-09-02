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
- **Coins** from kills/chests → **blacksmith** (weapon upgrade, bombs) and **potion seller** (potions, max HP up).
- **Keys** gate doors/chests; a dedicated **boss key** gates the boss room.
- **Weapon upgrades** visibly track level (sprite frame, damage, hitbox growth).

## Level Structure (target architecture)
- The dungeon is assembled from **modular room blocks** (Starting Room, Hallways, Chest Rooms, Multi Room, Boss Room) connected by door objects with key requirements.
- Room-block composition intentionally supports future **procedural generation** and multi-floor layouts.
- The original handcrafted level remains as the reference for content parity.

## NPCs & Dialogue
- Proximity-based interaction with a unified "[F] to …" prompt (InteractionManager).
- NPCs deliver paginated dialogue loaded from text files, then route to their service (shop).
- Future direction: a more prominent dialogue system and richer NPC interactions.

## Future Systems (explicit intent)
- **Summonable ally creatures** that fight alongside the player — combat ownership, faction, and targeting must stay clean enough to support this.
- Smarter, more varied enemy AI; multi-phase boss design.
- Complete sound and music design.