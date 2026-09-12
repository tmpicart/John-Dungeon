# Active Context - Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (<=60 lines) - history goes to `progress.md`, not here.

## Phase
R-40 prep complete and committed (2026-09-12): test_room reference stack, level-construction toolset, validated-landing pickups, door collision fix. Next build task: **R-40 room-block standard**, with S-1 hue-shift shader as the first S-track task.

## Just Landed (commits 570ceaa..34c51ff)
- `fix(doors)` red door blocker/prompt shapes match the art (player stuck fix)
- `feat(levels)` layer stack (Floor/Walls/Decals/Obstacles/Overhead), 5 unlit props, `obstacle_outline.gd` @tool (3px rim + seams, hue-shifted tint)
- `feat(pickups)` validated-landing scatter (rest-point query + hop-series speed), chest 2-3 wave spew with hidden queue, static button-pickup keys (y-sorted), seeded obstacle probe
- `docs(patterns)` stack/wall-decor/outline/pickup conventions synced

## Working Agreements
- Pickups: `scatter()` = genre-standard validated landing; no physics bodies; flight is cosmetic. Chest waves: hidden queue, item-owned tween delays (never `await` timers - freed-instance crash class)
- Wall-decor rule: alignment-sensitive decor = entity (rotate/flip); filler decor = tile
- Obstacle look: `outline_color`/`outline_thickness` (3) exports on the layer + `modulate` hue tint - no shader (S-1 shader would enable true hue rotation)

## Known Limits (accepted)
- `Environment` container not y-sorted: chests/props sort vs player as one block; fix deliberately in R-40/R-41 (chest origins + wall decor interact)
- Stale editor script cache strips unknown exports on save (outline_thickness incident) - restart editor after agent disk edits

## Verification Gates
- gdlint on touched files; baseline in `migrationMap.md`
- `tests/interaction_smoke.tscn` headless - 66 assertions (local-only now; needs assets on disk)
- `--headless --import` before headless runs; boots `--quit-after 5`
- `tests/obstacle_bounce_probe.tscn` - seeded six-roll sweep, exit 0 = pass
- After agent disk edits with editor open: user restarts editor before playtesting

## Next Up
1. R-40 room-block standard: patterns + descent room-type conventions (user editor work continues)
2. S-1 hue-shift shader (first code task of the S-track)
3. R-41 tier-1 vertical slice (unblocked by this prep)
4. E-1 lesser skelly (blocked on user sheet pick)
5. GitHub Support cache-purge request for old commit SHAs (still pending)

## Open Decisions
- Obstacle tint/outline values: user-tuned to 3px + cooler tint; revisit only if playtest objects
- Wand input binding + potion carry model: settle at S-5/S-6 implementation
- Depth room-mix shape + director numbers: provisional until playtest
- `WilfingerS/CS415-2024` still hosts the 2024 build + history - owner (Seth) to delete/privatize
- Public release: replace unknown-origin assets (HUD art, ~20 SFX); BDragon1727 VFX requires creator contribution for commercial use
