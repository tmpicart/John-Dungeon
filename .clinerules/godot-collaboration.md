# Godot Editor Collaboration

The user works directly in the Godot editor; the agent works through code and the terminal. Both touch the same plaintext files — coordinate accordingly.

## Scene & resource files
- `.tscn` / `.tres` / `.import` are text: surgical edits are allowed (wire a node, adjust an exported value, fix a path). Keep edits minimal and consistent with Godot's generated format (uid references, node paths).
- After text-editing a scene, note it in the task summary so the user can verify it in the editor.

## Editor-made changes
- The editor rewrites files on open/save (uid additions, property reordering, `.import` metadata on engine upgrades). Unexplained diffs in scene/asset files are expected and belong to the user's editor session — never revert or "clean up" them without asking.
- Manual scene changes by the user take precedence over agent-side assumptions; re-read scenes before editing if the user reports recent editor work.

## Renames & moves
- Prefer file renames/moves inside the Godot editor (auto-updates references and uid remaps).
- If done via terminal/filesystem: update every reference (scenes, scripts, autoloads, `project.godot`) and move each `.uid` sidecar together with its file. Flag renames of nodes that state machines reference by name (see `systemPatterns.md` trade-offs).

## Verification loop
- After script or scene changes, the user runs the project in the editor; treat their runtime feedback as the test result. There is no headless test suite — never claim runtime verification without it.