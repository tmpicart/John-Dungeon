# Active Context - Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (<=60 lines) - history goes to `progress.md`, not here.

## Phase
Descent design audited and revised (2026-09-09): task lists split into S/E/W/B tracks - one system or enemy per task (`devPlan.md`). Record errors fixed: `boss_shadow.png` = Sorceress boss sprite (not an effect); vampire sheet NOT in use. Design source: `productContext.md` "The Descent" sections. First build task: **S-1 hue-shift shader**.

## In Flight (user, Godot editor)
- `custom_dungeon.tres` rework: 16px atoms; collision painted on wall tiles (physics layer 0 -> Environment 4); TileSet patterns next
- `test_room.tscn` working-tree edits - user's editor session, never revert

## Conventions (systemPatterns "Tileset authoring")
- Patterns stamp collision/nav/custom data; wall collision = tiles; scene StaticBody2D only for dynamic blockers (doors/chests); nav on floor tiles only (cleanup: strip nav from 2:3/3:3/4:3)
- Decals: paint-time randomize (multi-select probability + scattering % + random flips)

## Decisions added 2026-09-09 (audit pass)
- Rolls: NO i-frames, stamina chunks; mutual action cancels (roll/attack/block) with hitbox hygiene
- Armor = full negation incl. unblockables (clank SFX + VFX + hitstop); wand = secondary fire via loadout slots (alt-weapon / potion / tool); potion belt typed
- Status framework (S-2) parked until variant/wand effect scope; E-1 lesser skelly may double as player summon (D-5)
- Art to be sourced via intake: Deity, Nightborne, Knight, wand sprites (check assets/items/weapons.png)

## Verification Gates
- gdlint on touched files; baseline in `migrationMap.md`
- `tests/interaction_smoke.tscn` headless - 66 assertions (local-only now; needs assets on disk)
- `--headless --import` before headless runs; boots `--quit-after 5`
- After agent disk edits with editor open: user restarts editor before playtesting

## Next Up
1. S-1 hue-shift shader (first code task of the S-track)
2. R-40 room-block standard: patterns + descent room-type conventions (user's editor work continues)
3. E-1 lesser skelly (blocked on user's sheet pick)
4. S-4 armor, then S-3 stamina+cancels
5. GitHub Support cache-purge request for old commit SHAs (still pending)

## Open Decisions
- Wand input binding + potion carry model: settle at S-5/S-6 implementation
- Depth room-mix shape + director numbers: provisional until playtest
- `WilfingerS/CS415-2024` still hosts the 2024 build + history - owner (Seth) to delete/privatize
- Public release: replace unknown-origin assets (HUD art, ~20 SFX); BDragon1727 VFX requires creator contribution for commercial use