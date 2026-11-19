## PBIR Theme Reference

Themes define default formatting inherited by all visuals. Review the theme BEFORE editing individual visuals.

### File Locations

| Theme | Path |
|---|---|
| Base (built-in) | `Report.Report/StaticResources/SharedResources/BaseThemes/<Name>.json` |
| Custom | `Report.Report/StaticResources/RegisteredResources/<Name>.json` |

Both referenced in `report.json`:

```json
"themeCollection": {
  "baseTheme": {"name": "CY24SU10", "type": "SharedResources"},
  "customTheme": {"name": "MyTheme.json", "type": "RegisteredResources"}
}
```

### Base Themes (verified 2026-09-08)

Custom themes layer on top of a base theme. Three are shipped:

| Base theme | Status | Notes |
|---|---|---|
| `Fluent 2` | **GA** — default for new reports, Desktop *and* service | Modern Fluent 2 styling. New pages default to **1920x1080**; that a new report's initial page stays 1280x720 dates from the preview and is unverified since GA (2026-10-07). Adds chart / button / slicer / small-multiples style presets. |
| `Classic 2026` | Previous default base theme | Incremental refresh of `CY24SU10`-era defaults. |
| `Classic 2018` | Legacy compatibility | Original base theme; reports created before 2026. |

Switch via **Design** ribbon → **Customize theme**, which opens the **Theme** pane → **Theme settings** → **Base theme** dropdown (Learn, 2026-10-07; on 2026-09-07 Learn gave a **View** ribbon toggle). The Theme pane replaced the Customize-theme dialog at GA; it is sectioned as **Theme settings** (import / export / remove), **Colors** (palette, data, structural, sentiment, divergent), **Text**, **Visual properties** (background, border, header icons, tooltip, shadow, padding), **Page** (canvas settings, background, wallpaper), **Filter pane**, and **Filter cards** — the same surface a custom theme JSON encodes. An "Update to the latest base theme" banner with an **Update theme** button appears when a newer base ships; the **Reset to default** tile in the Themes dropdown removes the custom theme without touching per-visual formatting.

Announced GA in the August 2026 update; page confirmed GA on 2026-09-07. No Desktop build number was verified.

The published theme JSON schema referenced by visualStyles tracks the
latest base. The newest on 2026-11-18 is
[`reportThemeSchema-2.159.json`](https://github.com/microsoft/powerbi-desktop-samples/blob/main/Report%20Theme%20JSON%20Schema/reportThemeSchema-2.159.json),
in `microsoft/powerbi-desktop-samples` on GitHub.

### Top-Level Theme Properties

| Property | Type | Notes |
|---|---|---|
| `name` | string | Theme name |
| `dataColors` | string[] | Palette hex strings, 0-indexed (referenced by `ColorId`) |
| `background` / `foreground` / `tableAccent` | string | Semantic colors |
| `good` / `bad` / `neutral` / `minimum` / `maximum` / `center` | string | Sentiment colors |
| `textClasses` | object | `title`, `label`, `callout`, `header` → `fontSize`, `fontFace`, `color` |
| `visualStyles` | object | `[visualType][stylePresetName]` formatting defaults and presets |

### Inheritance Hierarchy (broad → specific)

1. Wildcard `visualStyles["*"]["*"]` — all visuals
2. Visual type `visualStyles["lineChart"]["*"]` — overrides wildcard for that type
3. Visual instance — `objects` / `visualContainerObjects` in `visual.json` (see [visual-json.md](visual-json.md) for the `objects` vs `visualContainerObjects` split in schema 2.4.0+)

The Fluent 2 base theme carries **no per-visual font overrides**, so `textClasses` applies consistently across all visuals. A custom theme written against an older base may hold per-visual `visualStyles` font entries that existed only to beat that base's overrides; under Fluent 2 they are redundant.

### visualStyles Structure

Two-level keys: `[visualType][stylePresetName]`. The second level is
**`"*"`, the base visual style**, or a named style preset, not a state or
an instance selector (Learn, [Create custom report themes § Set
properties for visual
types](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom#set-properties-for-visual-types),
read 2026-11-18). A named preset inherits the base style and overrides
any property both set; `stylePreset` in the `"*"` entry names the
default preset.

```json
"visualStyles": {
  "slicer": {
    "*":         {"items": [{"fontColor": {"solid": {"color": "#000000"}}}]},
    "Blue text": {"items": [{"fontColor": {"solid": {"color": "#118DFF"}}}]}
  }
}
```

A theme can set the slicer's style (GA, November 2026, by Learn's
[November 2026 What's new](https://learn.microsoft.com/power-bi/fundamentals/whats-new)).
The theme schema's `slicer` definition holds it as `data` > `mode`,
taking the values [visual-json.md](visual-json.md) lists for `data.mode`
(§ August 2026 formatting properties > Slicer); `mode` was in schema
2.150 already, and `'RelativeDatePicker'` by 2.156:

```json
"visualStyles": {
  "slicer": {
    "*": {"data": [{"mode": "Dropdown"}]}
  }
}
```

By the November 2026 feature summary, a mode the slicer's column cannot
take falls back to a compatible one. Learn's
[custom report themes](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom)
page shows no `mode` example (read 2026-11-18), and no report here has
shown Desktop applying one, so check it against a saved report.

### Theme JSON Value Conventions

| Type | Theme JSON | visual.json |
|---|---|---|
| Integer | `14` | `{"expr": {"Literal": {"Value": "14L"}}}` |
| Float | `14.5` | `"14.5D"` |
| Boolean | `true` | `"true"` |
| Hex color | `"#e03131"` (bare) | `"'#e03131'"` (inner quotes) |
| ThemeDataColor | `{"solid": {"color": {"ThemeDataColor": {"ColorId": 0, "Percent": 0}}}}` | Same shape wrapped in `expr` |

**Never use `D` / `L` suffixes in theme JSON** — bare numbers only.

### ThemeDataColor

```json
{"solid": {"color": {"ThemeDataColor": {"ColorId": 5, "Percent": 0.4}}}}
```

| Property | Notes |
|---|---|
| `ColorId` | 0-based index into `dataColors[]` |
| `Percent` | `0` = exact, `0.1`..`1.0` = lighter, `-1.0`..`-0.1` = darker |

### Container Properties (visualContainerObjects)

Place under `visualStyles["*"]["*"]` or per visual type. Arrays of property objects.

| Object | Keys |
|---|---|
| `title` | `show`, `fontSize`, `fontFamily`, `fontColor`, `alignment` |
| `subTitle` | `show`, `fontSize`, `fontFamily`, `fontColor` |
| `background` | `show`, `color`, `transparency` |
| `border` | `show`, `width`, `color`, `radius` |
| `dropShadow` | `show`, `angle`, `distance`, `blur`, `color` |
| `padding` | `top`, `bottom`, `left`, `right` |
| `divider` | `show`, `color`, `style`, `width` |
| `visualHeader` | `show` |
| `visualTooltip` | `type`, `titleFontColor` |

### Visual Object Properties (objects)

Chart-specific formatting keys placed under `visualStyles["*"]["*"]` or per visual type: `categoryAxis`, `valueAxis`, `labels`, `legend`, `dataPoint`, `plotArea`, `lineStyles`, `markers`.

### textClasses

```json
"textClasses": {
  "title":   {"fontSize": 14, "fontFace": "Segoe UI Semibold"},
  "header":  {"fontSize": 12, "fontFace": "Segoe UI Semibold"},
  "label":   {"fontSize": 11, "fontFace": "Segoe UI"},
  "callout": {"fontSize": 45, "fontFace": "DIN"}
}
```

CY24SU10 defaults: `callout` 45 DIN, `title` 12 DIN, `header` 12 Segoe UI Semibold, `label` 10 Segoe UI. All `#252423`.

### Filter Pane Styling — outspacePane (owned here)

Location: `visualStyles["*"]["*"].outspacePane`. **Theme owns every styling property of the filter pane. Visibility / expansion state is separate — see [filters.md](filters.md) for `report.json → objects.outspacePane`.**

| Property | Type | Notes |
|---|---|---|
| `backgroundColor` | color | `{"solid": {"color": ...}}` or ThemeDataColor |
| `transparency` | integer | 0-100 (bare) |
| `border` | boolean | Show vertical separator |
| `borderColor` | color | Separator color |
| `fontFamily` | string | Fallback chain, each font name with spaces single-quoted: `"'Segoe UI Semibold', wf_segoe-ui_semibold, helvetica, arial, sans-serif"` |
| `foregroundColor` | color | Text, icons, buttons |
| `titleSize` | integer | Points |
| `headerSize` | integer | Points |
| `searchTextSize` | integer | Points |
| `inputBoxColor` | color | Input field background |
| `checkboxAndApplyColor` | color | Apply button, checkboxes |
| `width` | integer | Pixels |

### Filter Card Styling — filterCard

Location: `visualStyles["*"]["*"].filterCard` (array). Target specific card states via `$id`.

| `$id` | Targets |
|---|---|
| `"Available"` | Unapplied filters (filter pane list) |
| `"Applied"` | Actively applied filters |
| `"<GUID>"` | Specific filter by its `name` from filterConfig |

| Property | Type |
|---|---|
| `backgroundColor` | color |
| `transparency` | integer 0-100 |
| `border` | boolean |
| `borderColor` | color |
| `fontFamily` | string |
| `foregroundColor` | color |
| `textSize` | integer |
| `inputBoxColor` | color |

**Note**: `filterCard` without `$id` can also live at `visualStyles["page"]["*"].filterCard` as a base fallback.

### Wildcard + Override Pattern

```json
{
  "visualStyles": {
    "*": {
      "*": {
        "title": [{"show": true, "fontSize": 12}]
      }
    },
    "textbox": {
      "*": {
        "title":      [{"show": false}],
        "background": [{"show": false}],
        "border":     [{"show": false}],
        "dropShadow": [{"show": false}]
      }
    }
  }
}
```

### pbir CLI

```bash
pbir theme colors "Report.Report"                    # list palette
pbir theme set-formatting "Report.Report" ...        # set properties
pbir visuals clear-formatting "Report.Report/**/*.Visual" --keep-cf -f
```

Without CLI use `jq` with temp-file pattern:

```bash
THEME=$(jq -r '.themeCollection.customTheme.name' Report.Report/definition/report.json)
THEME="Report.Report/StaticResources/RegisteredResources/$THEME"
jq '.visualStyles["*"]["*"].title[0].fontSize = 14' "$THEME" > "$THEME.tmp" && mv "$THEME.tmp" "$THEME"
jq empty "$THEME"
```

### Clearing Visual-Level Overrides (Enforce Theme)

Stale `objects` / `visualContainerObjects` in visual.json override theme defaults.

- Clear container only (safe, preserves CF): `jq 'del(.visualContainerObjects)' visual.json`
- Clear all bespoke formatting (removes CF too): `jq 'del(.objects) | del(.visualContainerObjects)' visual.json`

The Format visual pane has two visual-wide resets, which Learn scopes as
[follows](https://learn.microsoft.com/power-bi/create-reports/power-bi-visual-style-presets#reset-formatting-pane-changes)
(read 2026-11-18), beside a reset per section and per group
([Get started formatting report visualizations § Reset to default
options](https://learn.microsoft.com/power-bi/visuals/power-bi-visualizations-format-visual#reset-to-default-options)):

- **Reset all style settings to default**: formatting changes only; it
  keeps conditional formatting, actions and added data such as custom
  and reference labels. The in-product counterpart of the first line.
- **Reset all settings to default**: every change in the pane, including
  conditional formatting, actions and data-bound items. The counterpart
  of the second line.

Whether either reset maps exactly onto its `jq` line is unmeasured. By
Learn, pane formatting is stored in `objects`, so the style reset also
clears chart formatting such as a legend position, which the first line
keeps; a visual with actions or reference labels may differ as well.
Learn says the pane's formatting outranks the visual's style preset,
which the style reset removes so the preset shows again.

### Gotchas

| Issue | Cause | Fix |
|---|---|---|
| `D`/`L` suffix rejected in theme | Used visual.json literal shape | Theme JSON uses bare numbers |
| Hex color rendered as literal text | Inner single quotes `"'#fff'"` in theme | Theme uses bare `"#ffffff"` |
| `id` key ignored in filterCard | Used `"id"` | Theme uses `"$id"` |
| Filter pane styling causes deploy error | Styling placed in `report.json` outspacePane | Only `visible`/`expanded` allowed in report.json — move styling to theme |
| Theme changes invisible after apply | Stale `visualContainerObjects` in visuals | Run `pbir visuals clear-formatting --keep-cf -f` |
| `ColorId` out of range | Palette has fewer entries than referenced | Check `dataColors[]` length |
| Font fallback chain broken | A font name with spaces not single-quoted, or visual.json's triple-quoted literal copied into a theme | `"'Segoe UI Semibold', wf_segoe-ui_semibold, helvetica, arial, sans-serif"` |
| Inheritance not applying | Put properties at wrong preset key | The base style is `"*"`, not `"default"`; another name makes a named preset |
| Third-level `"*"` catch-all confusing | Real themes sometimes nest another `"*"` for generic props | Treat as fallback; normal paths still work |
| `textClasses` not inheriting | Used `fontSize` as string | Must be bare integer |

### Reference

- Microsoft Learn: [Use report themes in Power BI Desktop](https://learn.microsoft.com/power-bi/create-reports/desktop-report-themes)
- Microsoft Learn: [Create custom report themes (full JSON reference)](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom)
- Microsoft Learn: [Set formatted text defaults (textClasses table)](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom#set-formatted-text-defaults)
- Microsoft Learn: [Visual defaults / base themes (Fluent 2, Classic 2026, Classic 2018)](https://learn.microsoft.com/power-bi/create-reports/power-bi-reports-visual-defaults)
- Comprehensive MS Learn link bundle (theme JSON file format / textClasses / style presets / inheritance / filter pane styling): § MS Learn link bundle, below

### MS Learn link bundle

Curated set of Microsoft Learn pages relevant to Power BI report themes — the JSON file format itself, the dataColors palette, sentiment colors, textClasses, visualStyles by visual type and style preset, the inheritance model, and how the file lives inside a PBIR project under `StaticResources/`.

The 3 highest-leverage entry points (use report themes / create custom themes / report theme JSON file format) are also linked in § Reference above for in-context use; this section holds the comprehensive set.

**Note on docs split:** The Power BI report theme JSON format is *one of the better-documented* PBIR-adjacent surfaces on MS Learn. The custom-themes article documents the file format directly; the parent skill adds the PBIR-specific bits (where the file lives in the project, how `visualStyles` overlays with `visual.json` `objects`/`visualContainerObjects`, the bare-numbers-no-D-suffix difference vs visual.json).

#### Theme JSON file format (canonical)

- [Use report themes in Power BI Desktop](https://learn.microsoft.com/power-bi/create-reports/desktop-report-themes) — apply / browse themes, the base-theme vs custom-theme inheritance the parent skill documents.
- [Create custom report themes in Power BI Desktop](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom) — full theme JSON reference: dataColors, sentiment colors (good/bad/neutral/minimum/maximum/center), structural colors (background/foreground/tableAccent/firstLevelElements/secondLevelElements), textClasses (title/header/label/callout + size variants), visualStyles, style presets.
- [Power BI Embedded — Apply Report Themes (Report Theme Object)](https://learn.microsoft.com/javascript/api/overview/powerbi/apply-report-themes) — the JS Embedded API surface that consumes the same theme JSON object; useful as a complete property reference.

#### Style presets (CY24SU10+ style swatches)

- [Create style presets in custom themes](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom#create-style-presets-in-custom-themes) — preset-per-visual-type pattern; how the Style dropdown surfaces in the visual format pane after import.
- [Use visual style presets](https://learn.microsoft.com/power-bi/create-reports/power-bi-visual-style-presets)
  — the Format pane's **Style presets** > **Save current formatting as**
  box writes into the report's custom theme, so a registered theme can
  hold presets nobody hand-wrote (page read 2026-11-18, no preview
  label). What a save writes under `visualStyles.<visual type>`: a new
  name adds a named preset beside the `"*"` entry; `*` updates the base
  visual style, which every named preset of that type inherits; a
  built-in preset's name stores a local override in the custom theme,
  and deleting the override restores the built-in definition. The pane
  cannot rename a preset: edit the theme JSON, and the default's name
  too if it is the `stylePreset` in the `"*"` entry. Download the theme
  to reuse its presets in another report.

#### Text classes

- [Set formatted text defaults](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom#set-formatted-text-defaults) — the canonical text-class table (title / largeTitle / header / label / semiboldLabel / largeLabel / smallLabel / lightLabel / boldLabel / largeLightLabel / smallLightLabel / callout) with default font / size / color and which visual elements consume each. Critical when the parent skill's `textClasses` overrides need to match the right class.

#### Inheritance and the visualStyles wildcard

- [Use report themes — how the report uses themes](https://learn.microsoft.com/power-bi/create-reports/desktop-report-themes#understand-how-the-report-uses-themes) — base theme vs custom theme vs per-visual override. Maps to the parent skill's `visualStyles["*"]["*"]` → `visualStyles[type][state]` → per-visual `objects` chain.
- [Customize report colors and mode showcase (Embedded sample)](https://learn.microsoft.com/javascript/api/overview/powerbi/showcase-themes) — Light/Dark mode patterns with theme objects.

#### PBIR file format (where themes live)

- [Power BI Desktop project — report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report) — `StaticResources/SharedResources/BaseThemes/` (built-in) vs `StaticResources/RegisteredResources/` (custom), and how `report.json → themeCollection` references both.
- [Report definition (Fabric REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/report-definition) — theme files round-trip via the `definition/` part.

#### Filter pane styling (cross-skill — owned by theme)

- [Format filters in Power BI reports — Theming for Filters pane](https://learn.microsoft.com/power-bi/create-reports/power-bi-report-filter#theming-for-filters-pane) — the theme keys (`outspacePane`, `filterCard`) where filter-pane colors/text/widths live (per the parent skill's split: `outspacePane` *visibility* on report.json, *styling* in theme).

### See also

- [visual-json.md](visual-json.md) — visual.json value conventions (`D`/`L`/`M` suffixes, inner-quoted hex)
- [filters.md](filters.md) — filter pane visibility (`visible`, `expanded`) on `report.json`
- [conditional-formatting.md](conditional-formatting.md) — `ThemeDataColor` in CF expressions
- [pbir-cli.md](pbir-cli.md) — `pbir theme` subcommands
