# John Dungeon: Remastered
**John Dungeon** is a top-down dungeon crawler originally built in just three weeks by a passionate team of five. The game blends pixelated action with a simple progression system, delivering a short but thrilling experience filled with danger, upgrades, and an epic boss fight.

## Features (Original Version)
- Varied enemies with unique behaviors  
- A challenging multi-phase boss battle  
- Custom-made assets  
- Engaging real-time combat  
- One handcrafted dungeon level  
- Player upgrades and consumables

## The Remaster
**John Dungeon: Remastered** continues the original as a solo project, building on its foundation in four areas:
- **Code quality**: fix the original's bugs, refactor for easier content expansion, quality-of-life improvements
- **Combat and AI**: more refined and strategic combat, smarter enemy AI, new enemies and bosses
- **Progression and content**: deeper progression systems, an expanded multi-level dungeon, better shops and items
- **Presentation and world**: a bigger dialogue and NPC system, complete sound and music

## What's different from the original

**Combat**
- A new dash ability
- Blocking into an attack parries it. Melee enemies get stunned and projectiles bounce back at whoever fired them. The necromancer's magic missiles even home in on the way back
- Parrying the Sorceress's melee attacks staggers her
- Some boss attacks can't be blocked and have to be dodged
- Reworked player animations and more reliable hit detection

**Enemies**
- Enemies path around walls and each other instead of running straight at you
- Ranged enemies hold fire when they can't see you and move to get a clear shot
- The necromancer telegraphs his summons and can only keep so many skeletons alive at once
- He panics when cornered, moves when his missiles miss, and his missiles curve around cover and come back around
- Wounded enemies fall back. Cornered enemies stand and fight

**World and systems**
- NPC dialogue with portraits, one-time story moments, and shops that open when the conversation ends
- A click-to-buy shop with a coin bar
- Locked doors and chests consume a key with a clear prompt flash
- The boss key plays its boss's taunt when you grab it
- Chests roll their loot from loot tables, and pickups bounce out and land on open floor
- More sound effects for coins, enemy deaths, weapon swings, footsteps, and shields

**Under the hood**
- All enemies run on one shared framework. Each enemy is just a list of settings instead of its own scripts, so new enemies are quick to add
- The player is split into small modules driven by a state machine
- Hits and hurtboxes are told apart with collision layers instead of name tags
- The HUD updates from signals instead of checking every frame
- Art and audio stay out of the repo, with credits and licenses recorded
- Headless test suites cover the interaction system and missile behavior

**Bug fixes**
- Fixed summoning bugs, jittery movement, on-hit animation glitches, doorway sprites vanishing, and enemies clipping through archways

> **Note:** The remaster is mid-rebuild. Levels will be built from hand-made room blocks shuffled together, so there is no shippable build yet. The test room is fully playable.
