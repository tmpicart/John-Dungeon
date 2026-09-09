# Asset Intake Policy

The repository is code-only: everything under `assets/` is gitignored except
whitelisted files. The two registries have separate jobs:

- `CREDITS.md` — human-facing credits, grouped by discipline
  (Remaster → Art: Original art → Third-party assets → Style adaptations →
  Music & Sound → Fonts → Original Game → Engine → Licence notes).
  List art and items, never file paths.
- `ASSETS.md` — technical manifest: file-path ↔ source mapping and
  provenance classes (team-original / style adaptation / third-party as-is /
  original-sheet-for-boss / unknown).

Sounds follow the same rules as visual assets.

## Adding any asset

1. Ask the user for the asset's source before wiring it in: creator, page
   URL, and license. No exceptions, including placeholders.
2. In the same task: add a human credit line to `CREDITS.md`
   (`item — creator`, or `item — Artist, after "Pack" by Creator` for
   adaptations), add a provenance row to `ASSETS.md`, and record licence
   terms under `CREDITS.md`'s Licence notes.
3. Decide tracking: only files with an explicit redistribution grant (CC0,
   OFL, team-original work) may be whitelisted in `.gitignore` and committed.
   Everything else stays local-only and is recorded only in `ASSETS.md`.
4. Never commit a binary asset without a recorded source decision.
5. Unknown-origin items are intentionally omitted from `CREDITS.md`; record
   them only as the "unknown provenance" class in `ASSETS.md`. Do not
   "helpfully" re-add them to the credits.

## Style adaptations

Credit both the artist and the source on one line:
`X — Artist, after "Pack" by Creator`. Place these in the Style adaptations
section, never mixed into Original art.

## Renaming or moving assets

- Move the file together with its `.import` sidecar (and `.uid` where
  present); rewrite every reference (scenes, scripts, resources).
- Update `.gitignore` whitelist paths, `ASSETS.md`, and `CREDITS.md` in the
  same task.
- Verify with a reference grep sweep and a headless boot
  (`--quit-after 5`).
