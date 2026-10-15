# Godot Editor Collaboration

The user works directly in the Godot editor; the agent works through code and the terminal. Both touch the same plaintext files. Files stay valid text — the hazard is silently lost changes, not corruption.

## Conflict model
| Mode | Mechanism | Guard |
|---|---|---|
| Cache-stale overwrite | The editor caches scenes/resources in memory; external edits reload unreliably — especially non-active scenes (godot #75865) — so a later editor save writes the stale copy back over the file (godot #24646) | After agent-side scene/resource edits, reload (`Scene > Reload Saved Scene`) or restart the editor before further editor saves; the script-cache variant is owned by `techContext.md` |
| Two-writer lost update | Both writers edit one file between saves; the last save wins silently | Never edit a file holding unsaved editor changes; re-read before editing when the user reports recent editor work |

## Scene & resource files
- `.tscn` / `.tres` / `.import` are text: surgical edits are allowed (wire a node, adjust an exported value, fix a path). Keep edits minimal and consistent with Godot's generated format (uid references, node paths).
- After text-editing a scene, note it in the task summary so the user can verify it in the editor.

## Editor-made changes
- Manual scene changes by the user take precedence over agent-side assumptions.
- Benign rewrites are expected: uid additions, property reordering, `.import` metadata on engine upgrades — never revert or "clean up" them without asking.

## Renames & moves
- Terminal moves/renames are normal practice: `git mv` the file, move its `.uid`/`.import` sidecar with it, then rewrite every reference (scenes, scripts, autoloads, `project.godot`) and verify with a grep sweep. Stage the reference rewrites together with the moves.
- The Godot editor's FileSystem dock performs the same rewrites automatically — either route is fine.
- Flag renames of nodes that state machines reference by name (see `systemPatterns.md` trade-offs).

## Verification loop
- After script or scene changes, the user runs the project in the editor; their runtime feedback is the test result. The headless smoke suite (`tests/interaction_smoke.tscn`, 66 assertions — see `memory-bank/techContext.md`) covers the interaction framework only; there is no automated gameplay suite, so never claim runtime verification without a user playtest.