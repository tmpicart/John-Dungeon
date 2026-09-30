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
- Asset-policy decision and purge record: see "Purge & recovery record" below; authoring conventions: `memory-bank/systemPatterns.md`.

## Purge & recovery record (2026-09-08)
- Asset blobs purged from history via 4 filter-repo passes (residual 0); pack 53.7 → 0.65 MiB; force-pushed as c75abfa
- Backups: `%TEMP%\john-dungeon-pre-wipe.bundle` (full original history — the only map to pre-purge commit hashes) + `D:\Godot_Games\John-Dungeon-assets-backup-20260908\` (610 files, 26.4 MB)
- Open external action: GitHub Support request to purge cached pre-purge commits
