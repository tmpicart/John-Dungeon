# Asset Intake Policy

The repository is code-only: everything under `assets/` is gitignored except
whitelisted files. `ASSETS.md` is the rebuild manifest; `CREDITS.md` is the
attribution and license registry. Sounds follow the same rules as visual
assets.

## Adding any asset

1. Ask the user for the asset's source before wiring it in: creator, page
   URL, and license. No exceptions, including placeholders.
2. Record it in `CREDITS.md` (attribution + license terms) in the same task.
3. Decide tracking: only files with an explicit redistribution grant (CC0,
   OFL, team-original work) may be whitelisted in `.gitignore` and committed.
   Everything else stays local-only and gets a row in `ASSETS.md`.
4. Never commit a binary asset without a recorded source decision.

## Renaming or moving assets

- Move the file together with its `.import` sidecar (and `.uid` where
  present); rewrite every reference (scenes, scripts, resources).
- Update `.gitignore` whitelist paths, `ASSETS.md`, and `CREDITS.md` in the
  same task.
- Verify with a reference grep sweep and a headless boot
  (`--quit-after 5`).
