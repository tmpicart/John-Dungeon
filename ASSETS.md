# Assets Manifest

This repository tracks code only. Art, audio, and data under `assets/`
(except `assets/fonts/`) are intentionally untracked: most third-party pack
licenses permit using the files inside a game but prohibit redistributing
the raw files, and a public git repository is a raw-file distribution
channel. The local checkout keeps its gitignored `assets/` contents, so the
game runs normally here.

## Rebuilding `assets/` on a new machine

Fetch the packs below, place them at the listed paths, then run
`Godot --headless --import` once to regenerate import metadata.

| Source | Destination |
|---|---|
| Team-original art — Elijah Geronimo (player, NPCs, weapons, keys, doors, chests, slime + variants, Sorceress) | `assets/player/`, `assets/npc/`, `assets/items/`, `assets/objects/` (doors, chests), `assets/enemies/enemy_slime.png`, `assets/enemies/boss_shadow.png`, `assets/tilesets/background.png` |
| Style adaptations — Elijah Geronimo, after credited sources (see CREDITS.md) | `assets/tilesets/` (dungeon tilesets), `assets/enemies/` (`enemy_skeleton.png`, `enemy_archer.png`, `enemy_necromancer.png`), `assets/items/arcane_arrow.png` |
| Third-party as-is — Pixel_Poem pack art (torches & candles, pickups, shop/HUD icons) | `assets/2d_pixel_dungeon_asset_pack/` (consumed by prop/pickup/shop scenes) |
| Original enemy sheets — AstroBob ×2, CreativeKind (planned boss use) | `assets/enemies/skeleton_enemy.png`, `assets/enemies/archer_enemy.png`, `assets/enemies/necromancer_creativekind_sheet.png` |
| BDragon1727 — "Retro Impact Effect Pack 3 / 5" (itch.io) | `assets/effects/` (retro_impact_*.png) |
| LuizMelo — "Monsters Creatures Fantasy" (itch.io, CC0) | `assets/monsters_creatures_fantasy/` |
| Pixel_Poem — enemy animations companion pack (itch.io) | `assets/enemy_animations_set/` |
| Freesound / Pixabay / bundled SFX (see CREDITS.md) | `assets/sounds/` |
| Unknown provenance — intentionally uncredited (see CREDITS.md policy in .clinerules) | `assets/hud/`, `assets/effects/slash.png` |

## Notes

- `assets/fonts/` (VT323, SIL OFL 1.1) **is tracked**; do not delete it.
- `assets/effects/on_hit_flash.gdshader` (+.uid) is project code (tutorial-derived) and tracked.
- `assets/effects/slash.png` is untracked (provenance unverifiable) and lives
  in gitignored `assets/effects/` locally. If ever confirmed team-original,
  whitelist it in `.gitignore` and commit it.
- On a fresh clone, Godot logs `ext_resource` UID warnings for missing
  textures until `assets/` is populated and re-imported; it falls back to
  text paths and the game runs.
- Asset-policy decision and purge record: see "Purge & recovery record" above; authoring conventions: `memory-bank/systemPatterns.md`.

## Purge & recovery record (2026-09-08)
- History purged of asset blobs via 4 filter-repo passes (1762 + 2238 + 179 + 24 paths; final residual 0), incl. the legacy tracked `.godot/` caches and 2024-era duplicates under `Scenes/`; 2 empty commits pruned; pack 53.7 MiB → 0.65 MiB
- Backups: `%TEMP%\john-dungeon-pre-wipe.bundle` (full original history) + `D:\Godot_Games\John-Dungeon-assets-backup-20260908\` (610 files, 26.4 MB)
- Every commit hash in older docs/logs is stale (full rewrite); the bundle is the only map to old hashes
- Force-push DONE (c75abfa on origin/master, 2026-09-08); still recommended: GitHub Support request to purge cached old commits (0 forks)
- `WilfingerS/CS415-2024` still hosts the 2024 build zip + full history — needs owner (Seth) to delete/privatize
- Provenance (final): original art + style adaptations by Elijah Geronimo — adaptations after Pixel_Poem dungeon pack (tileset), AstroBob (flail skeleton; arcane archer + arrow), CreativeKind (necromancer); originals of those enemies kept as boss sheets; Thayer Picart owns the remaster. Licences: Pixel_Poem/AstroBob/CreativeKind — use/modify/commercial OK, no raw-file redistribution; LuizMelo CC0; BDragon1727 — non-commercial free, commercial = contribute; 7 Freesound CC0. Unknown-origin items (hud art, ~20 SFX) intentionally uncredited in CREDITS.md — replace before any public release
- Cloners need packs to run the game (see rebuild table above); CREDITS.md intentionally omits unknown-origin items
