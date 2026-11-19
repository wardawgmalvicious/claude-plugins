## PBIR visual.json Reference

Path: `Report.Report/definition/pages/{PageName}/visuals/{VisualName}/visual.json`

### Top-Level Structure

| Property | Type | Required | Notes |
|---|---|---|---|
| `$schema` | string | yes | `.../visualContainer/<version>/schema.json`; copy the version from another visual.json in the same report |
| `name` | string | yes | Stable visual ID — referenced by bookmarks, interactions |
| `position` | object | yes | `x`, `y`, `z`, `width`, `height`, `tabOrder` |
| `visual` | object | one of | Regular visual — mutually exclusive with `visualGroup` |
| `visualGroup` | object | one of | Group container |
| `parentGroupName` | string | no | Set on children of a `visualGroup` |
| `filterConfig` | object | no | Visual-scoped filters — sibling of `visual`, NOT nested |
| `isHidden` | boolean | no | Root-level. The saved visibility; the visual still processes data. A bookmark toggles its own `display.mode` instead ([bookmarks.md](bookmarks.md)) |

### position

```json
{"x": 100, "y": 50, "z": 1000, "width": 400, "height": 300, "tabOrder": 0}
```

`z` layer order: higher = front. Common values `0, 1000, 2000, 3000, 5000, 8000, 15000`.

### visual Object

| Property | Notes |
|---|---|
| `visualType` | See visual type table below |
| `query.queryState` | Role → projections map |
| `query.sortDefinition` | `sort[]` + `isDefaultSort` |
| `objects` | Visual-specific formatting (axes, legend, dataPoint, labels, lineStyles) |
| `visualContainerObjects` | Container formatting (title, subTitle, background, border, dropShadow, padding, divider, visualHeader, visualTooltip) |
| `drillFilterOtherVisuals` | boolean |
| `syncGroup` | Slicer cross-page sync: `groupName`, `fieldChanges`, `filterChanges` |
| `expansionStates` | pivotTable row/column expansion |

**Critical**: `objects` vs `visualContainerObjects` are distinct in schema 2.4.0+. Container properties in `objects` fail silently. `visualContainerObjects` at root errors.

### Expression Literal Suffixes

All formatting values inside `visual.json` use `{"expr": {"Literal": {"Value": "..."}}}` wrappers. Theme JSON uses bare values.

| Type | Example | Notes |
|---|---|---|
| String | `"'smooth'"` | Inner single quotes required |
| Double | `"14D"` | Font sizes, percentages, most numerics |
| Integer | `"14L"` | Pixel counts, enum values, `labelPrecision` |
| Decimal | `"2.4M"` | Money/decimal precision |
| Boolean | `"true"` | Lowercase, no quotes, no suffix |
| DateTime | `"datetime'2024-01-15T00:00:00.0000000'"` | Closing `'` required |
| Hex color | `"'#FF0000'"` | Inner single quotes; 6-digit RGB or 8-digit ARGB |
| Null | `"null"` | Lowercase, no quotes |

Non-literal expressions:

| Type | Shape |
|---|---|
| Theme color | `{"expr": {"ThemeDataColor": {"ColorId": 0, "Percent": 0}}}` |
| Extension measure | `{"expr": {"Measure": {"Expression": {"SourceRef": {"Schema": "extension", "Entity": "_Formatting"}}, "Property": "Color"}}}` |

**Gotchas**: `transparency` uses `D` normally but `L` inside `dropShadow`. `labelPrecision` always `L`, `labelDisplayUnits` always `D`. String escaping: single quotes doubled (`"'O''Brien'"`). Font fallback chains: `"'''Segoe UI Semibold'', helvetica, sans-serif'"`.
(Yes — three single quotes. The outer pair wraps the SQExpr string literal; the inner pair escapes the space-containing font name. Not a typo.)

### Field Reference Patterns

| Pattern | Shape |
|---|---|
| Column | `{"Column": {"Expression": {"SourceRef": {"Entity": "Table"}}, "Property": "Col"}}` |
| Measure (model) | `{"Measure": {"Expression": {"SourceRef": {"Entity": "Table"}}, "Property": "M"}}` |
| Measure (extension) | `{"Measure": {"Expression": {"SourceRef": {"Schema": "extension", "Entity": "_Fmt"}}, "Property": "M"}}` |
| Aggregation | `{"Aggregation": {"Expression": {"Column": {...}}, "Function": 0}}` |
| Hierarchy level | `{"HierarchyLevel": {"Expression": {"Hierarchy": {...}}, "Level": "Level"}}` |
| SparklineData | `{"SparklineData": {"Measure": {...}, "Groupings": [{"Column": {...}}]}}` |

`QueryAggregateFunction`: `0`=Sum, `1`=Avg, `2`=DistinctCount, `3`=Min, `4`=Max, `5`=Count, `6`=Median, `7`=StdDev, `8`=Var

**Filter SourceRef gotcha**: inside filter `Where` conditions, SourceRef uses `"Source": "alias"` (from `From`), NOT `"Entity"`. Query projections use `"Entity"`.

### Visual Types and Query Roles

| visualType | Roles |
|---|---|
| `card` | Values |
| `cardVisual` (new card) | Data |
| `tableEx` | Values |
| `pivotTable` | Rows, Columns, Values |
| `slicer` / `advancedSlicerVisual` | Values |
| `pieChart` / `donutChart` | Category, Y |
| `lineChart` | Category, Y, Y2 (combo) |
| `areaChart` / `stackedAreaChart` | Category, Y, Series |
| `barChart` / `clusteredBarChart` / `hundredPercentStackedBarChart` | Category, Y |
| `columnChart` / `clusteredColumnChart` / `hundredPercentStackedColumnChart` | Category, Y |
| `lineClusteredColumnComboChart` / `lineStackedColumnComboChart` | Category, Y, Y2 |
| `ribbonChart` / `waterfallChart` | Category, Y |
| `scatterChart` | Category, X, Y, Size, Tooltips |
| `gauge` | Y, TargetValue |
| `kpi` | Indicator, Goal, TrendLine |
| `textbox` | none (uses `objects.general.paragraphs`) |
| `shape` / `actionButton` / `image` | none |
| `scriptVisual` / `pythonVisual` | Values |
| `PBI_CV_<GUID>` | varies (custom visuals) |
| `deneb<GUID>` | dataset |

`cardVisual` also has a **Trend axis** well (preview, November 2026, by
Learn's
[November 2026 What's new](https://learn.microsoft.com/power-bi/fundamentals/whats-new),
read 2026-11-18) that adds a trend chart to each card. Its role's name is
unconfirmed: Learn's card page never names the well, and a theme schema
names formatting, not query roles. Read it from a saved `visual.json`
before authoring.

### Projection Properties

| Property | Notes |
|---|---|
| `queryRef` | `Table.Field` — internal reference |
| `nativeQueryRef` | Display label |
| `displayName` | Optional override |
| `active` | Boolean — hierarchy level expanded |

Visual calculations (`NativeVisualCalculation`) always have `queryRef: "select"`.

On a visual with small multiples, a visual calculation's axis can also
be `ROWPAGES`, the small-multiples field, alone or combined with `ROWS`
and `COLUMNS`; an axis the visual lacks is ignored (GA, September 2026).
Learn's [Visual calculations](https://learn.microsoft.com/power-bi/transform-model/desktop-visual-calculations-overview),
§ Parameters that control calculation flow, lists every order (read
2026-10-22).

### sortDefinition

```json
"sortDefinition": {
  "sort": [{
    "field": {"Measure": {"Expression": {"SourceRef": {"Entity": "Sales"}}, "Property": "Revenue"}},
    "direction": "Descending"
  }],
  "isDefaultSort": true
}
```

### Slicer Default Selected Values

Store in `objects.general.properties.filter` — NOT `filterConfig`. `filterConfig` filters data going *into* the slicer; `objects.general.properties.filter` pre-selects values.

### Hiding Visuals and Fields

- Hide whole visual: `"isHidden": true` at root (outside `visual`).
- Hide fields from display: omit from `queryState` — still referenceable by extension measures / filters.

### Visual Groups

```json
{
  "name": "kpi_group",
  "position": {"x": 0, "y": 0, "z": 0, "width": 800, "height": 400},
  "visualGroup": {
    "displayName": "KPI Section",
    "groupMode": "ScaleMode",
    "objects": {"background": [...], "general": [...], "lockAspect": [...]}
  }
}
```

`groupMode`: `ScaleMode` (scale contents) or `ScrollMode`. Children set `parentGroupName`. Group objects limited to `background`, `general`, `lockAspect`.

### Table / Matrix Column Widths

```json
"columnWidth": [{
  "properties": {"value": {"expr": {"Literal": {"Value": "215D"}}}},
  "selector": {"metadata": "Orders.Order Lines"}
}]
```

### mobile.json

Optional sibling file at `visuals/{VisualName}/mobile.json`. Mirrors `visual.json` position fields with mobile coordinates. Typically authored via Desktop.

### Gotchas

| Issue | Cause | Fix |
|---|---|---|
| Container props silently ignored | Placed in `objects` instead of `visualContainerObjects` | Move title/border/background/dropShadow/padding to `visualContainerObjects` |
| Root-level error on `visualContainerObjects` | Placed at `visual.json` root instead of inside `visual` | Nest under `visual` (container objects still live inside `visual`) |
| `filterConfig` ignored | Nested inside `visual` | Must be sibling of `visual` at root of visual.json |
| Slicer default values don't stick | Stored in `filterConfig` | Use `objects.general.properties.filter` |
| `transparency` parse error in dropShadow | Used `D` suffix | Use `L` inside `dropShadow` |
| String literal unterminated | Missing closing single quote on `datetime'...'` | Always close datetime literals with `'` |
| Filter Where condition broken | Used `SourceRef.Entity` instead of `SourceRef.Source` | Reference the alias from `From[]` |
| Font fallback chain broken | Single-level quotes | Triple-quote primary font: `"'''Segoe UI Semibold'', sans-serif'"` |
| `labelPrecision` rejected | Used `D` suffix | Always `L` |
| `labelDisplayUnits` rejected | Used `L` suffix | Always `D` |
| Sparkline formatting ignored | `selector.metadata` doesn't match projection `queryRef` | Copy exact `SparklineData(...)` queryRef into selector |
| `visual` and `visualGroup` both present | Mutually exclusive | Pick one per visual.json |

### Card, slicer and narrative visuals (verified April 2026)

| Visual | Behaviour | Authoring impact |
|---|---|---|
| `cardVisual` / `slicer` (button-slicer / list-slicer modes) | Multicard layout exposes a **Fixed size** toggle (exact pixel dimensions). Mutually exclusive with **Fit to space** (renamed from `Autogrid`). | Property names not yet documented as a JSON-schema keys — verify in a saved visual.json before authoring. Existing reports with `Autogrid` formatting will surface under `Fit to space` in the Format pane. |
| `cardVisual` | Theme JSON keys `paddingUniform` (default 12) and `backgroundTransparency` documented under `cardVisual` style preset. Category headers participate in Edit interactions; Multi-category layout `Autogrid` capped at 4 rows (toggle off for more). | When clearing legacy padding, write `"paddingUniform": 0`. `paddingUniform` arrived under `cardVisual` in theme schema 2.148; `backgroundTransparency` was there by 2.143. |
| `narrativeVisual` (smart narrative) | Defaults to **Copilot mode** for users with a Copilot license. The character limit for prompts in Copilot mode is **10,000** (April 2026). Custom mode gained a value picker (September 2026): pick a column or measure, a summarization and any filter to make a custom value; auto-generated values are unchanged, and values authored with Q&A stay, read-only. | The 10,000 limit is on Copilot prompts; Learn states no limit on a narrative's stored visual.json content (read 2026-11-07), so don't author to it. Treat default-mode probes carefully — un-licensed users still land in classic mode. The value picker's key is unverified — read it from a saved visual.json before authoring. |

### August 2026 formatting properties

Power BI's August 2026 release added the formatting settings below. Their
names come from Microsoft's report theme schema 2.157
([`reportThemeSchema-2.157.json`](https://github.com/microsoft/powerbi-desktop-samples/blob/main/Report%20Theme%20JSON%20Schema/reportThemeSchema-2.157.json)),
whose `visualStyles` use the object and property names that a
`visual.json` `objects` block does. No PBIP export has yet shown Desktop
writing them, so check a name against one saved report before relying on
it. Labels are the format pane's, as Learn and the schema's titles give
them.

`pbir set` refused every name tried that is new in 2.157, on 0.9.29 and
0.9.32 alike, while 0.9.29 took every one its bundled theme schema,
2.155, already had. Write the new ones into `visual.json` by hand
([pbir-cli.md](pbir-cli.md), Gotchas). 0.9.29's `pbir validate` passes
them; with `--semantic` it warns on the `dropdown` and `centerBackground`
objects, and lists as info the new properties its catalog lacks.

Types are the schema's, and a fill is a `solid.color` object, as in
[conditional-formatting.md](conditional-formatting.md). A type does not
settle a number's literal suffix: the schema types `labelDisplayUnits` as
an integer, yet it takes `D` (Gotchas, above). Which suffix Desktop
writes for these is open.

#### Matrix (`pivotTable`)

| Format pane | Property | Type |
| --- | --- | --- |
| Row headers > +/- icons | `rowHeaders.showExpandCollapseButtons` | boolean |
| Row headers > +/- icons > Color | `rowHeaders.expandCollapseButtonsColor` | fill |
| Row headers > +/- icons > Expand/collapse icon size | `rowHeaders.expandCollapseButtonsSize` | number, 8–60 |
| Column headers > +/- icons | the same three on `columnHeaders`, new in 2.157 | as for rows |
| Row or Column headers > Options > Auto expand | `autoExpand` on `rowHeaders` or `columnHeaders` | boolean |

**Layout** > **Freeze** > **Row headers**, the default freeze state, has
no property the schema ties to it. The one candidate is
`rowHeaders.unfrozen`, a boolean in the theme schema since 2.149 or
earlier and untitled there. `pbir`'s own gloss, "Allow row headers to
scroll horizontally instead of staying frozen/pinned", would make `true`
the toggle turned off. It is unconfirmed until an export shows it.

#### Bar, column and line charts

Learn puts the first three under **Layout** in the **Columns**, **Bars**
or **Lines** section.

| Format pane | Property | Carried by | Type |
| --- | --- | --- | --- |
| Outer padding | `categoryAxis.outerPadding`, new in 2.157 | every bar, column, line, area, combo, ribbon, scatter and waterfall type | integer, percent |
| Space between categories | `categoryAxis.innerPadding` | the same, less line and area | integer, percent |
| Space between series | `layout.stackedGapSize` | stacked and 100% stacked bar and column, ribbon, line and stacked column | number |
| Space between series | `layout.clusteredGapSize` | clustered bar and column, line and clustered column | number |
| Overlap series | `layout.clusteredGapOverlaps` | the three clustered types | boolean |
| Flip overlap | `layout.clusteredGapOverlapReverse` | the three clustered types | boolean |

The schema titles `outerPadding` "Space at edges". The two "Space
between" labels replaced Category spacing and Series spacing; the
properties, in the schema since 2.149, kept their names.

#### Slicer (`slicer`)

| Format pane | Property | Type |
| --- | --- | --- |
| Slicer settings > Options > Style | `data.mode` | string, below |
| Slicer settings > Selection controls > Single date | `selection.singleDate`, new in 2.157 | boolean |
| Dropdown > Border color | `dropdown.borderColor`, new in 2.157, as is all of `dropdown` | fill |
| Dropdown > Rounded corners | `dropdown.borderRadius`, or `borderIndividualCorners` with `borderTopLeftCorner` and its three siblings | integer; boolean, integers |
| Dropdown > Open icon | `dropdown.iconColor`, `iconTransparency`, `iconSize` | fill, number, number 8–60 |
| Dropdown > Accent bar | `dropdown.accentBarColor`, `accentBarPosition`, `accentBarTransparency`, `accentBarWidth` | fill; `'Left'`, `'Right'`, `'Bottom'` or `'Top'`; number; number |
| Hierarchy > Icon color | `items.expandCollapseIconColor`, new in 2.157 | fill |
| Hierarchy > Icon | `items.expandCollapseToggleType` | integer: `0` Chevron, `1` Plus/minus, `2` Caret |
| Selection icon > Color | `selectionIcon.color` | fill |

`data.mode` takes the style, the schema's title in brackets where it
differs: `'Dropdown'`, `'VerticalList'` (Vertical list),
`'HorizontalList'` (Tile), `'Basic'` (List), `'Between'`, `'Before'`,
`'After'`, `'Single'` (Single Value), `'Relative'` (Relative Date),
`'RelativeTime'` (Relative Time) and `'RelativeDatePicker'` (Date
Picker). `'Single'` is not the Single date toggle. 2.157 names no
property for the Date picker's **Anchor** or **Offset**. Learn puts the
Dropdown section on the Dropdown style alone, and Hierarchy and Selection
icon on Dropdown and Vertical list.

A new slicer takes its style from its column: **Vertical list**
(`'VerticalList'`) for text, **Between** (`'Between'`) for numbers and
**Date picker** (`'RelativeDatePicker'`) for dates, by Learn's
[slicer visual](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-slicer-visual)
page (read 2026-11-18). Date picker became the dates' default in
November 2026, GA by that month's feature summary; Learn's
[numeric or date range slicer](https://learn.microsoft.com/power-bi/create-reports/desktop-slicer-numeric-range)
page still gives a date field Between. What a `visual.json` with no
`data.mode` renders is untested here, so write it whenever the style
matters. Date picker slicers don't filter other Date picker slicers, even
when visual interactions are set to filter.

#### Donut chart (`donutChart`)

**Center value** is `centerValue.show`, a boolean. Its format is in four
objects that came with it in 2.157:

| Format pane | Object | Properties |
| --- | --- | --- |
| Value | `value` | `show`, `value`, `labelDisplayUnits`, `labelPrecision`, `showBlankAs`, `fontFamily`, `fontSize`, `fontColor`, `bold`, `italic`, `underline`, `textWrap` |
| Label | `label` | `show`, `text`, `position`, `gap`, `fontFamily`, `fontSize`, `fontColor`, `bold`, `italic`, `underline`, `textWrap` |
| Image | `image` | `show`, `image`, `altText`, `position`, `size`, `gap`, `transparency` |
| Background | `centerBackground` | `show`, `fillColor`, `image`, `fit`, `imageTransparency`, `padding`, `transparency` |

On `label` and `image`, `position` is `'Top'` (above the value) or
`'Bottom'`; `fit` is `'Fit'`, `'Stretch'` or `'Fill'`; `gap`, `size` and
`padding` are integers. How Learn's custom measure, **Value** >
**Field**, is written is not shown.

`pbir schema describe` shows other names for these, from version 0.1.1 of
Microsoft's visual capabilities catalog, published 2026-06-12, which
`pbir` bundles and notes may lag the product: a `background` object
holding the centre's fill, image and padding, and `valueBold`,
`valueFontColor`, `valueDisplayUnits`, `valuePrecision` and the like on
`value`. Theme schema 2.157 has none of these, its `background` being
the container's `color`, `show` and `transparency`. Write 2.157's names.

Sources, read 2026-10-12: the theme schema above, and Learn's
[matrix format settings](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-matrix-visual-format-settings),
[x-axis and y-axis](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-customize-x-axis-and-y-axis),
[slicer visual](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-slicer-visual)
and
[pie and donut chart](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-pie-donut-chart)
pages.

### September and October 2026 formatting properties

The September and October 2026 releases added the settings below. Their
names come from report theme schema 2.159
([`reportThemeSchema-2.159.json`](https://github.com/microsoft/powerbi-desktop-samples/blob/main/Report%20Theme%20JSON%20Schema/reportThemeSchema-2.159.json),
published 2026-10-15) and carry the August section's caveat: no PBIP
export has yet shown Desktop writing them, so check a name against one
saved report before relying on it. `pbir set` was not tried on them.
Settings and status are the monthly feature summaries'.

| Setting | Property | Carried by | Type |
| --- | --- | --- | --- |
| Slider on or off (GA, September) | `slider.show` | `slicer`, in the Between, Before, After and Date picker styles | boolean |
| Slider colors for the handles, selected range and track | `slider.handleFillColor`, `handleBorderColor`, `color`, `secondaryLineColor` | `slicer` | fill |
| Slider handle size | `slider.handleSize`, `handleWidth`, `handleHeight`, new in 2.158 | `slicer` | number |
| Axis Layout > Initial scroll position (GA, September) | `categoryAxis.initialScrollPosition` | every bar, column, line, area, combo, ribbon, scatter and waterfall type | `'start'` or `'end'` |
| List slicer dropdown mode (preview October, GA November) | `data.dropdownMode`, new in 2.159 | `listSlicer` | boolean |
| Show selected first (preview October, GA November) | `selectedOnly.show`, new in 2.159 | `listSlicer`, `advancedSlicerVisual` | boolean |
| Plot area fill color (GA, October) | `plotArea.color`, `colorTransparency`, new in 2.159 | every bar, column, line, area, combo, ribbon, scatter and waterfall type | fill, number |
| Hierarchy axis Auto expand (GA, October) | `categoryAxis.autoExpand`, new in 2.159 | the same, less scatter and waterfall | boolean |

`slider.show`, the four slider colors and `initialScrollPosition` were
in the schema before 2.157. The schema titles none of the four colors,
so which is the selected range and which the track is open, and it names
no handle style beyond the three sizes. With dropdown mode, `listSlicer`
also gained the objects `dropdownButton`, `dropdownMenu`, `pills`,
`selectionBox` and `search` in 2.159, unmapped here.

**Gantt** (preview, October) is a new core visual. Its theme key is
`ganttChart`, new in 2.159, and Learn's **Rows** > **Color** is
`row.color`, a fill. Whether `ganttChart` is also the `visualType` a
`visual.json` holds is unconfirmed — read it from a saved one before
authoring. Learn's
[Gantt chart](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-gantt)
page gives its limits: up to 1,000 rows, a required task label, **Start**
and **End**, a blank **End** drawing a milestone, and up to three
category levels.

Sources, read 2026-10-22: the theme schema above, diffed against 2.157
and 2.158, and the September and October 2026 feature summaries.

### November 2026 formatting properties

The November 2026 release's settings below are named only where theme
schema 2.159 names them: it was still the newest in
[`Report Theme JSON Schema`](https://github.com/microsoft/powerbi-desktop-samples/tree/main/Report%20Theme%20JSON%20Schema)
on 2026-11-18, so a setting it lacks is unmapped until a newer schema or
an export shows it. Names carry the August section's caveat. Status is
Learn's
[November 2026 What's new](https://learn.microsoft.com/power-bi/fundamentals/whats-new).
The slicer's November changes, the dates' default style and a theme's
`mode`, are under § August 2026 formatting properties > Slicer and in
[themes.md](themes.md).

The **list slicer**'s dropdown mode, show selected first and multi-line
selection box went GA. Learn's
[list slicer](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-list-slicer)
page lets selection pills wrap by turning off **Selection box** >
**Layout** > **Single line**. 2.159's `selectionBox` has no property for
it, so it is unmapped.

**Action buttons** (preview) add a **Filter** button to a table or
matrix, turned on under **General** > **Action buttons**; the button
counts the visual's active filters, leaving out page, report and slicer
filters. 2.159 adds `actionButtonSection`, titled Action buttons, to
`commonCards`, the container objects every visual shares, so it
presumably goes in `visualContainerObjects`, beside `title`.

| Format pane | Property | Carried by | Type |
| --- | --- | --- | --- |
| Action buttons | `actionButtonSection.show`, presumably | `tableEx`, `pivotTable` | boolean |
| Position | `actionButtonSection.position` | `tableEx`, `pivotTable` | `'withinTitle'`, `'aboveTitle'` or `'belowTitle'` |

The schema puts the object on every visual; Learn allows it on table and
matrix alone. Learn's **Position** > **Horizontal alignment**, left or
right, has no clear property: 2.159's one Horizontal alignment,
`textHorizontalAlignment`, takes `'left'`, `'center'` or `'right'` and
sits among the button-text properties. The rest of the object's 60
properties style the padding, background, icon, text, fill, border,
shadow and glow, the sections Learn lists.

**Gantt** (preview) gained **Columns** > **Totals** and **Rows** >
**Data labels**. 2.159's `ganttChart` has no object for either, its
objects being `axis`, `axisTick`, `bar`, `columnHeaders`, `columnPanel`,
`columnValue`, `columnWidth`, `general`, `milestone`, `progress` and
`row`, so both are unmapped.

Sources, read 2026-11-18: theme schema 2.159, and Learn's What's new
above and its
[list slicer](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-list-slicer),
[action buttons](https://learn.microsoft.com/power-bi/visuals/power-bi-visualizations-action-buttons)
and
[Gantt](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-gantt)
pages.

### Reference

- Microsoft Learn: [Visualizations overview in Power BI](https://learn.microsoft.com/power-bi/visuals/power-bi-visualizations-overview)
- Microsoft Learn: [Power BI Desktop project — report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report)
- Microsoft Learn: [Card visual — Fixed size, Fit to space, theme keys](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-card)
- Microsoft Learn: [Smart narrative visual](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-smart-narrative)
- Comprehensive MS Learn link bundle (visual catalog → visualType / per-visual articles / visualGroup / custom visuals / PBIR file format): § MS Learn link bundle, below

### MS Learn link bundle

Curated set of Microsoft Learn pages relevant to the per-visual JSON in PBIR — the canonical "what visualType X needs" reference (visual catalog), per-visual-type formatting docs, the visualGroup concept, and the PBIR file structure that holds `visual.json`.

The 3 highest-leverage entry points (visualizations overview, build-a-report intro, PBIR project file layout) are also linked in § Reference above for in-context use; this section holds the comprehensive set.

**Note on docs split:** The PBIR `visual.json` JSON internals (top-level `name`/`position`/`visual`/`visualGroup`/`filterConfig`, expression-literal suffix grammar with `D`/`L`/`M`/`'string'`/`datetime'...'`, `objects` vs `visualContainerObjects` split in schema 2.4.0+, `dataViewWildcard` selectors, `SourceRef.Source` vs `Entity` rule) are *not* documented narratively on MS Learn — the canonical machine-readable reference is at `developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/...`. The Power BI visual catalog and per-visual-type articles document what each `visualType` does and which roles it expects.

#### Visual catalog (mapping `visualType` → user-facing concept)

- [Visualizations overview in Power BI](https://learn.microsoft.com/power-bi/visuals/power-bi-visualizations-overview) — the visual catalog and entry point to the per-visual articles. Read this when you don't know which `visualType` corresponds to a given chart.
- [Cards (new card)](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-card) and the legacy [Card visualization](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-card) — `card` (legacy) vs `cardVisual` (new).
- [Tables](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-tables) — `tableEx` semantics.
- [Matrix](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-matrix-visual) — `pivotTable` semantics: rows / columns / values roles.
- [Slicers overview](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-slicers) — `slicer` vs `advancedSlicerVisual`; Learn has no page for the advanced slicer, and covers its sibling slicer visuals here.
- [Line charts](https://learn.microsoft.com/power-bi/visuals/power-bi-line-chart) — `lineChart` (Y/Y2/series).
- [Combo charts](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-combo-chart) — `lineClusteredColumnComboChart` / `lineStackedColumnComboChart`.
- [Bar and column charts](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-customize-title-background-and-legend) — variants for `barChart`/`columnChart` family.
- [KPI visual](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-kpi) — `kpi` indicator/goal/trendLine roles.
- [Buttons / shapes / images](https://learn.microsoft.com/power-bi/create-reports/desktop-buttons) — `actionButton` / `shape` / `image`.
- [Group visuals](https://learn.microsoft.com/power-bi/create-reports/desktop-grouping-visuals) — `visualGroup` concept.

#### Cross-visual interactions

- [Change how visuals interact in a Power BI report](https://learn.microsoft.com/power-bi/create-reports/service-reports-visual-interactions) — `NoFilter` / `Filter` / `Highlight` (matches the `visualInteractions` array on `page.json`).

#### Custom visuals (`PBI_CV_<GUID>` / `deneb<GUID>`)

- [Power BI custom visuals overview](https://learn.microsoft.com/power-bi/developer/visuals/power-bi-custom-visuals) — what `PBI_CV_<GUID>` represents.
- [Custom visuals for Power BI reports — Deneb](https://learn.microsoft.com/power-bi/guidance/powerbi-implementation-planning-integration-with-other-services#custom-visuals-for-power-bi-reports) — Learn's only mention of Deneb, the certified Vega / Vega-Lite visual; the `deneb<GUID>` visualType pattern is not documented there.

#### Conditional formatting touch points

- [Apply conditional table formatting in Power BI](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-table-formatting) — see [conditional-formatting.md](conditional-formatting.md) for full coverage.

#### Field references (Column / Measure / Aggregation / HierarchyLevel)

- [Calculation options: calculated columns and measures](https://learn.microsoft.com/power-bi/transform-model/desktop-calculations-options) — the model concepts the JSON references.
- [Hierarchy in Power BI semantic models](https://learn.microsoft.com/power-bi/transform-model/desktop-create-and-manage-relationships) — what `HierarchyLevel` references.

#### PBIR file format (where visual.json lives)

- [Power BI Desktop project — report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report) — `definition/pages/<page>/visuals/<visual>/visual.json` location, folder rename rules.
- [Report definition (Fabric REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/report-definition) — definition envelope and the canonical JSON-schema URL pattern.

### See also

- [themes.md](themes.md) — theme value conventions (bare vs wrapped literals)
- [conditional-formatting.md](conditional-formatting.md) — CF patterns inside visual.json `objects`
- [filters.md](filters.md) — filter body shape and `SourceRef.Source` rule
- [bookmarks.md](bookmarks.md) — bookmarks reference the visual's root-level `name`
- [pages.md](pages.md) — `page.json` / `pages.json` and `visualInteractions` reference
