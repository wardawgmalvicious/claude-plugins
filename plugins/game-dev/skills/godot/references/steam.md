# Steam through GodotSteam

GodotSteam binds the Steamworks SDK to Godot. Sources: GodotSteam's docs,
`godotsteam/godotsteam-docs` on Codeberg, `master` at `35d8f32`, read
2026-11-16 — `getting_started/what_are_you_making.md`,
`howto/gdextension.md`, `tutorials/initializing.md` and
`tutorials/exporting_shipping.md` — read live by
`curl -s https://codeberg.org/godotsteam/godotsteam-docs/raw/branch/master/docs/<path>.md`.
The GitHub repository `GodotSteam/GodotSteam-Docs` holds only a pointer
to Codeberg (observed 2026-11-16). Godot's own pages are in the skill's
§ 9; the skill's page-wins line holds here too.

## Which build

- **GDExtension**: an addon folder, `addons/godotsteam/`, dropped into
  the project, which "does not have to be enabled as it is always
  present if the addon is there". It runs in the regular Godot editor
  and **exports with the regular Godot templates**: "do not use the
  GodotSteam templates. That will cause a lot of issues."
  (`exporting_shipping.md`, `gdextension.md`).
- **Pre-compiled bundle or module**: GodotSteam's own editor and its own
  export templates, set in the preset's custom template fields. A
  non-GodotSteam template there gives an executable that crashes with
  "Parse Error: The identifier "Steam" isn't declared in the current
  scope." (`exporting_shipping.md`).
- The page lists GodotSteam 4.24 against the Steamworks SDK 1.65 for
  Godot 4.x (`what_are_you_making.md`). **Match GodotSteam's release to
  the pinned Godot version** by its release notes before adding it.

A single-player game, or one using Steam networking or Godot's own
multiplayer, takes the standard GodotSteam; the Server build is for a
master or dedicated server (`what_are_you_making.md`).

## Initializing

- **Outside the Steam client a game needs an app ID**; in development,
  app ID **480**, Valve's SpaceWar, or one of a game you own
  (`initializing.md`). The page gives four ways, in its order:
  1. **Project Settings, Steam > Initialization** (GodotSteam 4.14 and
     later), which also offers to initialize at start and to embed
     callbacks.
  2. **The first argument of `Steam.steamInitEx(app_id,
     embed_callbacks)`**.
  3. `OS.set_environment("SteamAppId", ...)` and `"SteamGameId"`, what
     the first two do underneath.
  4. A `steam_appid.txt` beside the editor, "not recommended", and never
     shipped: Valve recommends against it.
- **`steamInitEx()` returns a dictionary**: `status` 0 is success, 1 some
  other failure, 2 no connection to Steam, the client probably not
  running, 3 a Steam client out of date; `verbal` is the text. Check
  `status > Steam.STEAM_API_INIT_RESULT_OK` and either quit with a
  message or run without Steam features (`initializing.md`).
- **`steamInit()` returns only a bool** and leaves no failure reason.
- Since SDK 1.61 the client syncs stats and achievements itself: no
  `requestCurrentStats()`.

## Callbacks

**Nothing Steam sends arrives unless `Steam.run_callbacks()` runs**,
"preferably every frame": put it in `_process()` of an autoload, or pass
`true` as `embed_callbacks`. A `run_callbacks()` in a node that pauses
stops when it does (`initializing.md`). An autoload is a child of the
root, whose `process_mode` is Pausable, and a node inherits its
parent's by default (Node reference; `singletons_autoload.rst`; read
2026-11-16), so the autoload sets its own:

```gdscript
extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var result: Dictionary = Steam.steamInitEx()
	if result["status"] > Steam.STEAM_API_INIT_RESULT_OK:
		push_warning("Steam failed to initialize: %s" % result)


func _process(_delta: float) -> void:
	Steam.run_callbacks()
```

## What ships

From `exporting_shipping.md`:

- **The game's `.exe` and `.pck`, the GodotSteam library** that the
  GDExtension export copies beside them, **and `steam_api64.dll`** for a
  64-bit Windows build (`steam_api.dll` for 32-bit). The addon's
  `addons/godotsteam/win64/` holds
  `libgodotsteam.windows.template_release.x86_64.dll`, its debug twin
  and `steam_api64.dll` (`gdextension.md`).
- **Not `steam_appid.txt`**: the Steam client knows the game it runs.
- Upload by SteamCMD's `run_app_build` with an app VDF and one depot VDF
  per depot, by zips on the Steamworks site, or by Valve's SteamPipe
  GUI; then set the launch executable, add each depot to the beta and
  developer packages, and set the build live on a branch.
  `exporting_shipping.md` walks each, with Valve's own pages linked.
