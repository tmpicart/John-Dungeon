# Active Context - Current Work Snapshot

> **Purpose:** Where work stands right now. Rewritten each session (<=60 lines) - history goes to `progress.md`, not here.

## Phase
R-40 props shipped. This session executed the asset-license purge (see Asset Policy). Next: R-40 room-block standard, then R-41 floor parity.

## Asset Policy (decided 2026-09-08 - governs all asset work)
- Repo is code-only: `/assets/*` gitignored except whitelists - `assets/fonts/` (VT323, SIL OFL 1.1) and `assets/effects/on_hit_flash.gdshader`(+.uid) project code; `slash.png` blacklisted (provenance unverifiable)
- History purged of asset blobs via 4 filter-repo passes (1762 + 2238 + 179 + 24 paths; final residual 0), incl. the legacy tracked `.godot/` caches and 2024-era duplicates under `Scenes/`; 2 empty commits pruned; pack 53.7 MiB -> 0.65 MiB
- Backups: `%TEMP%\john-dungeon-pre-wipe.bundle` (full original history) + `D:\Godot_Games\John-Dungeon-assets-backup-20260908\` (610 files, 26.4 MB)
- Every commit hash in older docs/logs is stale (full rewrite); bundle is the only map to old hashes
- Force-push DONE (c75abfa on origin/master, 2026-09-08); still recommended: GitHub Support request to purge cached old commits (0 forks)
- `WilfingerS/CS415-2024` still hosts the 2024 build zip + full history - needs owner (Seth) to delete/privatize
- Attribution: `CREDITS.md` - rebuild instructions: `ASSETS.md`
- Never re-commit pack art; re-adding verified team-original art = fresh commits only
- Provenance (final): original art + style adaptations by Elijah Geronimo - adaptations after Pixel_Poem dungeon pack (tileset), AstroBob (flail skeleton; arcane archer + arrow), CreativeKind (necromancer); originals of those enemies kept as boss sheets; Thayer Picart owns the remaster. Licences: Pixel_Poem/AstroBob/CreativeKind - use/modify/commercial OK, no raw-file redistribution; LuizMelo CC0; BDragon1727 - non-commercial free, commercial = contribute; 7 Freesound CC0. Unknown-origin items (hud art, ~20 SFX) intentionally uncredited in CREDITS.md - replace before any public release
- Cloners need packs to run the game (documented in ASSETS.md); CREDITS.md intentionally omits unknown-origin items

## Conventions
- Props: scriptless scenes in `entities/props/` - AnimatedSprite2D autoplay `default` 5.7 fps, radial PointLight2D, foot blockers on Environment (layer 4); wall props z 10, floor props z 0 y-sorted
- Pickup animation: universal coded bob in pickup_item.gd; frames ride on top
- .tres data hazard: 4.7.2 editor saves strip PackedStringArray/StringName from scripted sub-resources - author as Array[String]/String (see techContext)
- Tile room stack / door family / chest family / dialogue: unchanged (see systemPatterns.md)

## In Flight
- nothing - purge, provenance, and intake policy landed; force-push pending

## Verification Gates
- gdlint on touched files; baseline in `migrationMap.md`
- `tests/interaction_smoke.tscn` headless - 66 assertions (local-only now; needs assets on disk)
- `--headless --import` before headless runs; boots `--quit-after 5`
- After agent disk edits with editor open: user restarts editor before playtesting

## Next Up
1. GitHub Support cache-purge request for old commit SHAs
2. R-40 room-block standard on custom_dungeon.tres (slots + variant model)
3. R-41 floor parity rebuild
4. D-3 dialogue content

## Open Decisions
- Re-add verified team-original art (player/NPC/HUD/.kra outputs) in fresh commits - user decision
- Public release: replace unknown-origin assets (wallpaper, titles, buttons, hearts, plus, key, slash, ~20 SFX); BDragon1727 VFX requires creator contribution for commercial use