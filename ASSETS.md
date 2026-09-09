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
| Pixel_Poem — "2D Pixel Dungeon Asset Pack" (itch.io) | `assets/2d_pixel_dungeon_asset_pack/` |
| BDragon1727 — "Retro Impact Effect Pack 3 / 5" (itch.io) | `assets/effects/` (retro_impact_*.png) |
| CreativeKind — "Necromancer (Free)" (itch.io) — original kept for planned boss use | `assets/enemies/necromancer_creativekind_sheet.png` |
| AstroBob — "Animated pixel art skeleton" + "Arcane archer animated pixel character" (itch.io) — originals kept for planned boss use | `assets/enemies/skeleton_enemy.png`, `assets/enemies/archer_enemy.png` |
| LuizMelo — "Monsters Creatures Fantasy" (itch.io, CC0) | `assets/monsters_creatures_fantasy/` |
| Pixel_Poem — enemy animations companion pack (itch.io) | `assets/enemy_animations_set/` |
| Freesound / Pixabay / bundled SFX (see CREDITS.md) | `assets/sounds/` |
| Team-original art (player, NPCs, most items, background/potion) | `assets/player/`, `assets/npc/`, `assets/items/` (except `key.png`), `assets/tilesets/background.png`, `assets/items/potion.png` |
| Chibi derivatives — Pixel_Poem / AstroBob sources (see CREDITS.md) | `assets/objects/`, `assets/tilesets/` (dungeon tilesets), `assets/enemies/` (`enemy_*.png`), `assets/items/arcane_arrow.png` |
| Unknown provenance (see CREDITS.md) | `assets/hud/`, `assets/items/key.png`, `assets/effects/slash.png` |

## Notes

- `assets/fonts/` (VT323, SIL OFL 1.1) **is tracked**; do not delete it.
- `assets/effects/on_hit_flash.gdshader` (+.uid) is team-original and tracked.
- `assets/effects/slash.png` is untracked (provenance unverifiable) and lives
  in gitignored `assets/effects/` locally. If ever confirmed team-original,
  whitelist it in `.gitignore` and commit it.
- On a fresh clone, Godot logs `ext_resource` UID warnings for missing
  textures until `assets/` is populated and re-imported; it falls back to
  text paths and the game runs.
- Asset-policy decision and purge record: see `memory-bank/activeContext.md`.
