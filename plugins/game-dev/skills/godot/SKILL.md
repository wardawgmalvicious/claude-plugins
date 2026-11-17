---
name: godot
description: "Godot 4.7 game projects worked from files and the command line on Windows. Pins one editor version, since a newer editor rewrites project.godot and scenes and an older one downgrades them, keeps .godot/ out of git and the .uid files in it, and enforces static typing through the debug/gdscript/warnings/untyped_declaration setting. Edits .tscn and .tres by hand: section order, ext_resource and sub_resource ids, uid:// references, parent paths and [connection] lines. Connects and emits signals and registers autoloads. Sets up crisp pixel art in project.godot (viewport stretch mode, integer scaling, nearest texture filter, 2D transform snap) and TileMapLayer in place of the deprecated TileMap. Runs Godot headless with the _console.exe build: --headless --import, a SceneTree smoke-test script and its exit code, --export-release with per-version export templates. Adds Steam through GodotSteam: app ID 480 in development, callbacks in an always-processing autoload, and the DLLs to ship."
when_to_use: "Use when asked to set up, edit, run, test or export a Godot 4 project: write a .gd script or type an untyped one, edit a .tscn, .tres or project.godot, make pixel art render crisp, paint or migrate a TileMap, run Godot headless or in CI, fix 'No export template found' or a project 'from a more recent and incompatible version of the engine', or add Steam with GodotSteam. Not for Godot 3, C# scripts or building the engine."
# model: inherit  # any model: value blocks Copilot slash invocation
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Godot 4 games on Windows: typed, hand-edited, headless

A Godot project is text a session can read and write: `project.godot`,
scenes (`.tscn`), resources (`.tres`) and GDScript (`.gd`). This skill
covers what goes wrong when it is worked from files and a terminal
instead of the editor: a second editor version rewriting files, an
untyped script nothing flags, a hand edit the next save discards, blurry
pixel art, a headless run before import, and an export with no
template.

**Dated, and drilled on 2026-11-16** from the Godot docs
(`godotengine/godot-docs` branch `4.7` at `9adca4c`), the engine's source
and class reference at `4.7.2-stable`, the 4.7.2 release's Windows
editor zip, and GodotSteam's docs (`godotsteam/godotsteam-docs` `master`
at `35d8f32`, on Codeberg). Past `references/`, the docs' source,
`curl -s https://raw.githubusercontent.com/godotengine/godot-docs/4.7/<path>.rst`
(the branch named for the project's minor version), the class reference
and engine source at `godotengine/godot/4.7.2-stable/` on the same host,
as `doc/classes/<Class>.xml`, and GodotSteam's at
`curl -s https://codeberg.org/godotsteam/godotsteam-docs/raw/branch/master/docs/<path>.md`.
A live page that contradicts a line here wins: say so, act on the page,
and route the fix by `capture-learning` where it is installed, else tell
the user, bar a dated measured line that
names the page it overrules and the call that measured it, which a page
changed since its date sends back to re-measure. An observed claim is
cited or marked pending a doc check, and stands, marked observed, only
where no page covers it.

**Not here.** Godot 3 and its GDScript; C# and the .NET build; building
the engine or GodotSteam from source; 3D, physics, animation, audio,
input, UI themes and shaders; export to anything but Windows; test
frameworks; GDScript's naming, code order and typing style beyond the
typing setting in § 3, which follow Godot's own GDScript style guide.

Detail lives in `references/`: `scene-format.md` (the `.tscn` and
`.tres` grammar, section by section, with examples from the docs) and
`steam.md` (GodotSteam's builds, initializing, callbacks, export and
the files to ship). Each cites its source.

## 1. Pin one editor version

**Pin the exact editor, `4.7.2` and not `4.7`, for the whole project,
and write it in the repo's `CLAUDE.md` or README.** Every session and
every collaborator then opens the files with the same binary. A
different one changes them:

- **A newer editor rewrites what it saves.** On save it rewrites
  `application/config/features` in `project.godot` to its own version
  branch, such as `4.7`, and its rendering method, and drops features it
  does not support (`core/config/project_settings.cpp` at
  `4.7.2-stable`, read 2026-11-16). A scene saved by 4.6 or later gains
  a `unique_id=` on every node, and `load_steps` is gone from its
  header (tscn.rst, read 2026-11-16). One open-and-save in another
  version is a diff in every file it touched.
- **An older 4.x editor downgrades the project.** `config_version` has
  been 5 since 4.0, so no 4.x editor refuses a 4.x project. The project
  manager warns "This project was last edited in Godot 4.7. Opening will
  change it to Godot 4.6." and asks "Open anyway? Project will be
  modified." (`core/config/project_settings.h` and
  `editor/project_manager/project_manager.cpp` at `4.7.2-stable`, read
  2026-11-16). **Opened directly, `-e --path .`, it asks nothing** and
  saves `project.godot` as it opens, unless headless, trimming
  `config/features` to its own version: every 4.x editor from
  `4.0-stable` to `4.7.2-stable` does (`editor/editor_node.cpp` and
  `core/config/project_settings.cpp`, read 2026-11-16). Only an engine
  with a lower `config_version` refuses: "is from a more recent and
  incompatible version of the engine" (`project_settings.cpp`, read
  2026-11-16).
- **Export templates are per exact version** (§ 9).

**Use the console build from a terminal.** The Windows editor zip holds
two binaries, `Godot_v4.7.2-stable_win64.exe` and
`Godot_v4.7.2-stable_win64_console.exe`, a 198 KB wrapper (observed
2026-11-16, the 4.7.2 release's `win64.exe.zip`). Output sent to the
terminal is seen on Windows only through the `console.exe`
(@GlobalScope reference, `printraw`, read 2026-11-16). Point a variable
at it once, `$godot = '<dir>\Godot_v4.7.2-stable_win64_console.exe'`,
and the commands below use it.

## 2. What git keeps

- **Ignore `.godot/`**, "various project cache data", and
  `*.translation`, binary imports generated from CSV
  (version_control_systems.rst, read 2026-11-16).
- **Let the editor write `.gitignore` and `.gitattributes`**: the
  project manager's Git option, or Project > Version Control > Generate
  Version Control Metadata. Its `.gitattributes` holds every file to LF,
  as the style guide asks of scripts; without it, set `core.autocrlf
  input` on Windows (version_control_systems.rst, read 2026-11-16).
- **Commit the `.uid` files.** Since 4.4 Godot writes `<file>.uid`
  beside each script and shader, holding its `uid://` id. **A script or
  shader moved outside Godot takes its `.uid` with it**, or every
  reference by `uid://` breaks (Godot blog, "UID changes coming to Godot
  4.4", read 2026-11-16). A `git mv` of `player.gd` is two moves.
- **Commit `export_presets.cfg`**; `.godot/export_credentials.cfg`
  holds secrets and stays out (exporting_projects.rst, read 2026-11-16).

## 3. Static typing, enforced

**Typed GDScript's warnings are off by default** (static_typing.rst,
read 2026-11-16), so an untyped declaration parses, runs and is never
flagged. Turn the check on in `project.godot`:

```ini
[debug]

gdscript/warnings/untyped_declaration=1
```

- **The level is 0, 1 or 2**: ignore, warn, error
  (`modules/gdscript/gdscript_warning.h`, read 2026-11-16). At 1 the
  editor and a run report "a variable or parameter has no static type,
  or … a function has no static return type"; at 2 it is an error
  (ProjectSettings reference, read 2026-11-16). Take 2 where a headless
  run must fail on it.
- **Leave `inferred_declaration` at 0.** It flags `:=`, which the style
  guide prefers where the type is written on the same line
  (gdscript_styleguide.rst, read 2026-11-16).
- **The `unsafe_*` warnings** (`unsafe_property_access`,
  `unsafe_method_access`, `unsafe_cast`, `unsafe_call_argument`, each 0
  by default) "do not cover all cases that unsafe lines cover"
  (static_typing.rst, read 2026-11-16): turn them on for more, never
  as proof.
- **`addons/` is exempt by default**, through
  `debug/gdscript/warnings/directory_rules`, `{ "res://addons": 0 }`,
  which the reference says not to remove (ProjectSettings reference,
  read 2026-11-16): a plugin's untyped code does not fail the project.
- **Silence one line, not the setting**: `@warning_ignore("untyped_declaration")`
  above it, the names matching the settings' (warning_system.rst, read
  2026-11-16).
- `project.godot` is INI: the first part of a setting's path is the
  `[section]`, the rest the key, and a setting at its default is not
  written (`project_settings.cpp`, read 2026-11-16). The docs recommend
  the Project Settings window over a hand edit (project_settings.rst,
  read 2026-11-16).

## 4. Scenes and resources by hand

**A hand edit is fine if it keeps the format's rules**; the grammar is
in `references/scene-format.md`. The ones a hand edit breaks:

- **Five sections, in order**: the `[gd_scene]` or `[gd_resource]`
  header, `[ext_resource]`s, `[sub_resource]`s, `[node]`s,
  `[connection]`s. A sub-resource must come after any it refers to:
  the loader fails on a `SubResource` id it has not read yet
  (`resource_format_text.cpp`, read 2026-11-16).
- **Exactly one root node**, with no `parent`; its children take
  `parent="."`, deeper ones the path below the root, `parent="Arm/Hand"`,
  never the root's name.
- **`id` is local to the file** and referenced as `ExtResource("<id>")`
  or `SubResource("<id>")`; a new one needs only to be unique among its
  kind. **`uid` is global**: copy it from the target's header or its
  `.uid` file, never invent one, or leave it out, as the docs' own
  `.tres` example does.
- **A property at its default is not stored, and `;` comments are
  dropped**: write either and the next save from the editor removes it.
- `unique_id` on a node is the editor's to write; a hand-added node
  without one is valid, as every pre-4.6 scene is.

All from tscn.rst, read 2026-11-16. **Open the scene in the pinned
editor, or run it headless (§ 8), after a hand edit**: a typo shows up
there, not in git.

## 5. Signals and autoloads

- **Connect in code with `Signal.connect`**,
  `timer.timeout.connect(_on_timer_timeout)`, and emit with
  `health_changed.emit(old, new)`; the reference recommends
  `Signal.connect` over `Object.connect` in GDScript (Object reference,
  read 2026-11-16). The callback's name is `_on_<node_name>_<signal>`
  by convention (signals.rst, read 2026-11-16).
- **Connecting the same callable twice is an error**,
  `ERR_INVALID_PARAMETER`, unless it was connected
  `CONNECT_REFERENCE_COUNTED`: check `is_connected` first where a
  connect can run twice (Object reference, read 2026-11-16).
- **The editor's Signals dock writes a `[connection]` line** into the
  `.tscn` and generates the callback only in its own script editor;
  with an external editor, connect in code (signals.rst, read
  2026-11-16). A hand-written `[connection signal="pressed"
  from="Button" to="." method="_on_button_pressed"]` loads with the
  editor's default flag (`resource_format_text.cpp`, read 2026-11-16).
- **Design a scene to need nothing outside itself**; where it must, its
  parent wires it, and a signal is for responding to behavior, not
  starting it (scene_organization.rst, read 2026-11-16).
- **An autoload is for a system that tracks its own data, is needed
  globally and stands alone**; systems that change others' data are
  their own scenes (scene_organization.rst, read 2026-11-16). It is
  registered in `project.godot` as `[autoload]` `Name="*res://path.gd"`,
  the `*` making it a global singleton (`project_settings.cpp`, read
  2026-11-16).

## 6. Pixel art

The docs' recipe for pixel art (multiple_resolutions.rst, read
2026-11-16) sets the `[display]` lines; the `[rendering]` two, and each
setting's meaning, are from the ProjectSettings reference (read 2026-11-16):

```ini
[display]

window/size/viewport_width=640
window/size/viewport_height=360
window/stretch/mode="viewport"
window/stretch/aspect="keep"
window/stretch/scale_mode="integer"

[rendering]

textures/canvas_textures/default_texture_filter=0
2d/snap/snap_2d_transforms_to_pixel=true
```

- **The viewport size is the art's resolution.** 640×360 "scales to
  1280×720, 1920×1080, 2560×1440, and 3840×2160 without any black bars
  when using integer scaling". Set `window_width_override` and
  `window_height_override` for a bigger window while developing.
- **`mode="viewport"`** renders at that size and scales the result,
  "recommended for games that use a pixel art aesthetic"; the default
  is `disabled`. **A project created in 4.7 starts at `canvas_items`
  and `expand`** (upgrading_to_godot_4.7.rst, read 2026-11-16), so its
  `project.godot` already names a mode: change it. `canvas_items` suits
  art that may move by sub-pixels.
- **`aspect="keep"`** holds one aspect ratio, with black bars; the
  recipe allows `expand` only with Controls anchored to fit.
- **`scale_mode="integer"`** scales by whole multiples only. A window
  smaller than the viewport then clips it: set `Window.min_size`. Use
  Exclusive Fullscreen, since plain Fullscreen's one-pixel line "can
  cause integer scaling to use a smaller scale factor than expected".
- **`default_texture_filter=0`** is Nearest, against the default 1,
  Linear.
- **`snap_2d_transforms_to_pixel`** rounds each `CanvasItem`'s
  position, "useful for low-resolution pixel art games", at the cost of
  smoothness, worst with `Camera2D` smoothing; it is read only at start,
  and not to be paired with `snap_2d_vertices_to_pixel`.

## 7. `TileMapLayer`, not `TileMap`

- **`TileMap` is deprecated since 4.3**: each layer is its own
  `TileMapLayer` node (upgrading_to_godot_4.3.rst; TileMap reference;
  read 2026-11-16). Migrate an old one in the editor: with the node
  selected, open the TileMap bottom panel, click the toolbox icon in its
  top-right corner and choose "Extract TileMap layers as individual
  TileMapLayer nodes".
- **Save the `TileSet` as its own `.tres`** to share it between layers
  and scenes (using_tilemaps.rst, read 2026-11-16).
- **Coordinates are 16-bit signed**, −32768 to 32767, and changes are
  batched to the end of the frame: call `update_internals()` where code
  needs them sooner (TileMapLayer reference, read 2026-11-16). Set a
  cell in code with `set_cell(coords, source_id, atlas_coords)`.
- **Since 4.5 physics is chunked by default**, which changes what
  `get_coords_for_body_rid()` returns; `physics_quadrant_size = 1`
  restores one body per cell (upgrading_to_godot_4.5.rst, read
  2026-11-16).

## 8. Headless on Windows

**Import before anything else in a fresh clone.** `.godot/` is not in
git, so nothing is imported yet; `--import` "starts the editor, waits
for any resources to be imported, and then quits" (command_line_tutorial.rst,
read 2026-11-16):

```powershell
& $godot --headless --path . --import
```

`--headless` is `--display-driver headless --audio-driver Dummy`.
**A smoke test is a script that extends `SceneTree`** (or `MainLoop`),
run by `--script`; `--check-only` with it parses and quits
(command_line_tutorial.rst, read 2026-11-16). `_initialize()` runs
once at start (MainLoop reference, read 2026-11-16); this script is
built from the references, not run here:

```gdscript
extends SceneTree


func _initialize() -> void:
	var scene: PackedScene = load("res://main.tscn")
	if scene == null:
		push_error("res://main.tscn failed to load")
		quit(1)
		return
	root.add_child(scene.instantiate())
	quit(0)
```

```powershell
& $godot --headless --path . --script res://tests/smoke.gd
$LASTEXITCODE
```

- **`quit(exit_code)` sets the process's exit code**, applied at the
  end of the frame; keep it within 0 to 125 for portability (SceneTree
  reference, read 2026-11-16). Quit non-zero on every failure the test
  finds.
- **Whether the console wrapper passes the exit code through is
  unchecked**, pending a doc check or a run: before trusting
  `$LASTEXITCODE`, run a script that calls `quit(3)` once on the pinned
  version and read `3` back.
- **The binary must be the editor**, not an export template, for
  `--import` and the exports below (command_line_tutorial.rst, read
  2026-11-16).

## 9. Export

- **Install the templates for the exact version**: Editor > Manage
  Export Templates, or a downloaded `.tpz` (exporting_projects.rst, read
  2026-11-16). They are looked up under a folder named for the full
  version, so an editor update without its templates fails with "No
  export template found at the expected path:"
  (`editor/export/editor_export_platform.cpp`, read 2026-11-16).
- **Export from the command line by the preset's name** in
  `export_presets.cfg`:

  ```powershell
  New-Item -ItemType Directory -Force build\windows | Out-Null
  & $godot --headless --path . --export-release '<preset name>' build/windows/game.exe
  ```

  The target directory must exist, and a relative path is relative to
  the project, not the current directory; `--export-debug` and
  `--export-pack` work alike, and each implies `--import`
  (command_line_tutorial.rst, read 2026-11-16).
- **Windows packs the project into a `.pck` beside the `.exe`**, which
  the page calls `data.pck`, unless the preset embeds it, up to about
  3.89 GB in all; `debug/export_console_wrapper` adds the console wrapper
  for a build that prints to a terminal; signing reads
  `GODOT_WINDOWS_CODESIGN_IDENTITY_TYPE`,
  `GODOT_WINDOWS_CODESIGN_IDENTITY` and
  `GODOT_WINDOWS_CODESIGN_PASSWORD` (exporting_for_windows.rst and the
  EditorExportPlatformWindows reference, read 2026-11-16).
- **A file or folder whose name starts with a period is never
  exported** (exporting_projects.rst, read 2026-11-16).

## 10. Steam through GodotSteam

Detail and sources in `references/steam.md`. In short:

- **The GDExtension build is an addon** in `addons/godotsteam/`, needs
  no enabling, and exports with the regular Godot templates, never
  GodotSteam's; the pre-compiled build is GodotSteam's own editor and
  templates instead.
- **Ship `steam_api64.dll` and the GodotSteam library** beside the
  `.exe`; **never ship `steam_appid.txt`**.
- **In development, app ID 480**, Valve's SpaceWar, set under Steam >
  Initialization in the project settings or passed to `steamInitEx()`.
- **`Steam.run_callbacks()` every frame in an autoload that never
  pauses**: an autoload is a child of the root, which is Pausable, so
  give it `process_mode = PROCESS_MODE_ALWAYS`.

## 11. Constraints

- **One pinned editor version**, named in the repo; never open the
  project in another.
- **Typed GDScript, and the warning on** to hold it so.
- **Never invent a `uid://`**; never move a script without its `.uid`.
- **Never trust `$LASTEXITCODE`** from the console build until § 8's
  check has passed on the pinned version.
- No Godot 3 syntax or APIs: the docs drilled are 4.7's.
- No unverified claims.
