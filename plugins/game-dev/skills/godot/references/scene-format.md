# The `.tscn` and `.tres` text formats

Godot 4.7's text scene and resource formats, for a hand edit. Sources:
`engine_details/file_formats/tscn.rst` in `godotengine/godot-docs`
branch `4.7`, and `scene/resources/resource_format_text.cpp` at
`godotengine/godot` `4.7.2-stable`, both read 2026-11-16. The skill's
§ 4 holds the rules a hand edit breaks; this file holds the grammar.

## Shape

A `.tscn` has five sections, in this order, each a run of headings that
start with the same word (tscn.rst):

1. The file descriptor, first in the file:
   `[gd_scene format=3 uid="uid://cecaux1sm7mo0"]`. A scene saved before
   4.6 also has `load_steps=<int>`, deprecated and ignored.
2. External resources, `[ext_resource ...]`.
3. Internal resources, `[sub_resource ...]`.
4. Nodes, `[node ...]`.
5. Connections, `[connection ...]`.

A heading is `[<kind> key1=value1 key2=value2 ...]`, followed by zero or
more `key = value` lines that set properties, whose values can be
arrays, transforms, colors and the like. Whitespace outside strings is
not significant, and the editor drops extra whitespace and every `;`
comment when it saves.

## External resources

```ini
[ext_resource type="Texture2D" uid="uid://ccbm14ebjmpy1" path="res://gradient.tres" id="2_eorut"]
```

- `type`, `path` and `id` name the resource; `uid` maps it to a file
  that may move.
- **`path` is `res://`-absolute as the editor writes it**; a path
  relative to the `.tscn` is valid too.
- **`uid` is the target's own**: in its `[gd_scene]` or `[gd_resource]`
  header, or for a script or shader in the `<file>.uid` beside it. The
  docs' `.tres` example has an `ext_resource` with no `uid`.
- A property refers to it as `ExtResource("2_eorut")`.

## Internal resources

```ini
[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_fdxgg"]
radius = 1.0
height = 3.0
```

- No `path` and no `uid`; a property refers to it as
  `SubResource("CapsuleShape3D_fdxgg")`.
- **An internal and an external resource may share an id**, since the
  two are referred to differently.
- **Order matters**: the loader looks a `SubResource` id up among those
  already read and fails if it is not there
  (`resource_format_text.cpp`), so one used by another comes first.

## Nodes

```ini
[node name="Player" type="Node3D" unique_id=1155673912]
[node name="Arm" type="Node3D" parent="." unique_id=1010797352]
[node name="Hand" type="Node3D" parent="Arm" unique_id=536436825]
[node name="Finger" type="Node3D" parent="Arm/Hand" unique_id=1732647084]
```

- **The first node is the root and the only one with no `parent`.**
  "All scene files should have exactly *one* scene root. If it doesn't,
  Godot will fail to import the file."
- **`parent` is the path from the root, without the root's name**: `.`
  for a direct child.
- `unique_id` tracks a node through moves and renames, and appears only
  in scenes saved by 4.6 or later.
- Other keys: `instance` (an instanced scene, by `ExtResource`),
  `instance_placeholder`, `owner`, `index` (order in the tree; without
  it, inherited nodes come before plain ones), `groups`, and
  `node_paths`, which lists the properties exported as a Node type but
  stored as a `NodePath`.
- **A property at its default is not written**, and one written by hand
  at its default is dropped at the next save.

## Connections

The editor writes one line per connection made in its Signals dock
(`resource_format_text.cpp`):

```ini
[connection signal="pressed" from="Button" to="." method="_on_button_pressed"]
```

- `signal`, `from`, `to` and `method` are required; the loader rejects
  a line missing any of them.
- `from` and `to` are node paths from the root, `.` being the root.
- `flags` is written only when it differs from `CONNECT_PERSIST`, and a
  line without it loads with that flag.
- `unbinds=<n>` and `binds= [...]` carry `Callable.unbind` and
  `Callable.bind` arguments; `from_uid_path` and `to_uid_path` are the
  editor's.

## `.tres`

A resource file has the same shape with a different descriptor and its
own properties under `[resource]`:

```ini
[gd_resource type="ArrayMesh" format=3 uid="uid://dww8o7hsqrhx5"]

[ext_resource type="Material" path="res://player/model/playerobot.tres" id="1_r3bjq"]

[resource]
resource_name = "player_Sphere_016"
```
