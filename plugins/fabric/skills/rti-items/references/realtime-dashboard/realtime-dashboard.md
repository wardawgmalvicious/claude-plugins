# Fabric Real-Time Dashboard (KQLDashboard)

Hand-authoring and Git-editing the `RealTimeDashboard.json` definition. The
portal load endpoint validates beyond JSON Schema conformance — most of what
breaks a hand-authored dashboard is in the wiring rules below, not the syntax.
Facts verified against a live dashboard (schema_version 81, Aug 2026) and
[Real-time dashboard - Git integration](https://learn.microsoft.com/fabric/real-time-intelligence/git-real-time-dashboard).

The definition and REST calls have a file of their own. Read it first for
its job; past it, the REST spec's folder, then Learn, by `microsoft-learn-mcp`, or with no server, `curl -sL -H 'Accept: text/markdown' <page URL>` (undocumented, read 2026-11-07):

| The job | Read first |
| --- | --- |
| A Real-Time Dashboard's definition parts, how `getDefinition` differs from the Git file, its REST calls or MCP | [references/kql-dashboard-api.md](references/kql-dashboard-api.md): one JSON part, `RealTimeDashboard.json`; nothing past the generic seven operations; no MCP server |
| Display-edge formatting, base-query and multistat KQL, deterministic ids | [references/REFERENCE.md](references/REFERENCE.md) |

A live page that contradicts a line here wins: say so, act on the page,
and route the fix by `capture-learning`, bar a dated measured line that
names the page it overrules and the call that measured it, which a page
changed since its date sends back to re-measure. An observed claim is cited
or marked pending a doc check, and stands, marked observed, only where no
page covers it.

## File anatomy

Item folder: `<Name>.KQLDashboard/` with `.platform` + `RealTimeDashboard.json`
(portal may name it `RealTimeDashboard-N.json`). Top-level keys:
`schema_version`, `flavor` (`"RTDashboard_Regular"`), `autoRefresh`,
`changeDetection` (see *Auto refresh*), `tiles`, `baseQueries`, `parameters`,
`dataSources`, `pages`, `queries`, `embeddedApps` (+ portal-managed
`$schema`/`id`/`eTag`/`title`, which a Git-created shell may omit — leave them
however the portal wrote them). The live schema's top-level `properties` is
the whole list; v81's also allows `pagesNavWidth` (2026-10-12).

All KQL text lives in `queries[]`; everything else points at it:

- `queries[]` — `{id, dataSource: {kind: "inline", dataSourceId}, text, usedVariables}`
- `tiles[]` — `{id, queryRef: {kind: "query", queryId} | {kind: "baseQuery", baseQueryId}, title, visualType, pageId, layout, visualOptions}`
- `baseQueries[]` — `{id, variableName, queryId}`; the text is the referenced
  query object. Variable names must start with `_`. A tile query that uses one
  references the variable in its KQL text **and** lists it in `usedVariables`.
  Base queries must each be a single tabular expression (they are wrapped as
  `let _name = (<text>);`) — no scalar lambdas, no internal `let` statements.
- `parameters[]` — `kind: "duration"` exposes two variables via
  `beginVariableName` / `endVariableName` (commonly `_startTime` / `_endTime`).
  A tile added to a new page doesn't bring its parameter along: where
  `showOnPages.kind` is `"selection"`, append that page's `id` to
  `showOnPages.pageIds`, or the tile renders with the parameter's
  `defaultValue`, when it has a usable one (Learn, 2026-10-13).
- `dataSources[]` — a Fabric KQL database is `kind: "kusto-trident"`, on
  which schema v81 requires `id`, `name`, `clusterUri`, `database`,
  `workspace` and `databaseArtifactId` (the KQLDatabase item id). **Git and
  REST export it differently**, and Learn's template shows the older v63
  shape: both in
  [references/kql-dashboard-api.md](references/kql-dashboard-api.md#git-is-not-the-live-definition).
  Learn also lists Ontology (preview), Azure Data
  Explorer, Application Insights and Log Analytics sources; no `kind` but
  `kusto-trident` has been checked against a real dashboard (2026-10-06).

**Nothing is known to rebind `databaseArtifactId` between stages**, and
the portal reads it, on the cluster `clusterUri` names: a dashboard
published with the source stage's ID and the target's `clusterUri`
failed every tile `Entity ID '<id>' of kind 'Database' was not found.`
(a client fabric-cicd publish, 2026-11-17). It is no Variable Library
consumer and takes no deployment rule (Learn, 2026-10-12). fabric-cicd v1.4.0
rewrites `database`, `workspace` and an empty `clusterUri` to the target's
when the source's `name` is the database's display name, and leaves
`databaseArtifactId` as committed (`deploy`'s
`references/fabric-cicd.md`, 2026-10-16). So rewrite `databaseArtifactId` per
stage: in a build per environment, by `find_replace`, or in the portal after
each deploy. A deployment pipeline may rebind it anyway: a KQL
queryset, which Learn says binds the same way, rebound to the target's
database in one deploy (2026-10-13, `deploy`'s
`references/deployment-pipelines.md`), so read a deployed dashboard's
`dataSources` before rewriting them.

## Load-time validation rules

- **Every `queryId` referenced exactly once**, counted across
  `tiles[].queryRef.queryId`, `baseQueries[].queryId`, and
  `parameters[].dataSource.queryRef.queryId`. Duplicating a tile means
  duplicating its query with a fresh id too. A shared one fails the load
  with `/queries: Some query IDs are used in multiple query references
  (tiles, base queries, parameters)`.
- **A Fabric Maps tile (preview) has no query.** It embeds a pre-authored
  map item as-is and references it by item ID, so it stands outside both
  this rule and the `queries[]` rule above. Learn shows no JSON for it, so
  its tile shape is undocumented (2026-10-06).
- **Every `id` is an RFC-4122 UUID**, unique within its category. Readable
  pseudo-ids are rejected with `Needs to follow the UUID format as defined
  by RFC 4122`. For deterministic scripted edits use
  `uuid.uuid5(namespace, label)`.
- **Misleading error**: `/tiles/N/queryRef ... must have required property
  'baseQueryId'` almost always means a malformed `queryRef.queryId` — the
  schema's `oneOf` fails the `query` branch and reports the `baseQuery`
  branch's complaints instead. Fix the UUID and the cascade clears.
- **Identity preservation**: never change existing `id`s (top-level, tile,
  page, query, dataSource, parameter), the top-level `eTag` and
  `schema_version`, `pageId`, `queryRef.queryId`,
  `dataSource.dataSourceId`, a v63 source's `scopeId`, parameter
  `variableName`s (a duration's two names too), or `.platform`
  `logicalId`. A changed identifier is treated as delete + recreate on the
  next *Update from Git*, losing pinned references and share targets.

## Layout

24-column grid. `layout: {x, y, width, height}` in grid units; `x + width <=
24`. Typical: stat cards 4–6 wide × 4 tall, charts 8–12 wide × 7–9 tall.

## Visuals

`visualType` is a free string in the schema — the UI interprets it. Working
values: `card` (single stat), `multistat`, `bar`, `column`, `table`, `map`,
`kpi`, `multikpi`, `designTile`, `markdownCard` (plus line/area/pie/scatter/
anomalychart/funnel/heatmap/plotly). Options live in the flat
`visualOptions` bag, prefixed per visual (`multiStat__labelColumn`,
`map__latitudeColumn`, `kpi__valueColumn`, generic
`xColumn`/`yColumns`/`hideLegend`/…). Minimal or empty
`visualOptions: {}` is valid — column inference handles the simple cases.

What's New (2026-10-02) adds an AI custom visual builder (preview) that
generates HTML visuals from a natural-language description. Learn has no
page for it, and its link lands on the Copilot dashboard page, so its
`visualType` value is unknown (2026-10-06).

- **multistat**: rows = stats; `multiStat__labelColumn` / `multiStat__valueColumn`,
  `multiStat__displayOrientation`, `multiStat__slot: {width, height}` (inner
  grid of stat slots, 1×1 to 5×5). **The tile needs 3 grid columns per slot
  column and 3 rows per slot row**: five slots in a row need 15×3, a full
  5×5 grid 15×15, whatever the query returns or the orientation. A smaller
  tile loads, then fails only when drawn: *Current tile size (12, 5) is
  smaller than the minimum supported tile size (15, 3)*. No schema check
  catches it, and Learn gives no minimum (13 probe tiles, 2026-10-01).
- **kpi** (gauge/bar/donut/number via `kpi__visualType`): `kpi__minValue`,
  `kpi__maxValue`, and `kpi__referenceLines` take **static numbers only** — a
  dynamic (query-computed) target cannot be bound. For "actual vs computed
  target" use a multistat or fold the comparison into the query. Reference
  lines now reach eight visuals (anomaly, area, bar, column, KPI,
  multistat, scatter, time chart; GA per What's New, 2026-10-02), but
  Learn doesn't say whether a line can take a query value, so that
  doesn't settle this (2026-10-06).
- **KPI styling is the `kpi` visual's `kpi__styling` object**, not a new
  type: `arcAngle` (180, 220 or 270), `arcThickness` (a fraction of the
  radius), `capStyle` (`rounded` or `flat`) and `gradientFill`, all four
  required (schema v82 on). Written by hand as 270, 0.2, rounded and
  gradient, it drew so and a portal save kept it, but the styling pane
  showed 0.2 as a band thickness of 3: its scale is not the file's
  (observed 2026-11-17, schema v89).
- **multikpi**, lowercase: a row or grid of KPIs from one query (the
  type schema v86 on, its keys v84 on but `multiKpi__dataMapping`, v87
  on). **The schema also lists `multiKpi`, which REST accepts and the
  tile refuses when drawn**: *Visual formatting issue: Visual type
  multiKpi is not supported*. `multiKpi__dataMapping` (`rows` or
  `columns` of the result become items), `multiKpi__labelColumn` (null
  detects it), `multiKpi__limit` and `multiKpi__orientation` (`auto`,
  `horizontal`, `vertical`). Each item is a KPI, styled by the `kpi__*`
  keys, which a portal save fills in where they are missing: a gauge of
  0–100 with unit `%`, a 220° arc of thickness 0.3, no gradient, and zones
  at 0/33/67/100 written twice, as `kpi__conditionalFormatting`'s
  `zone1`–`zone3` and `kpi__conditionalFormatting_V2`'s `ranges`. So set
  them, or the items read as percentages. Three items in a row at 15×6
  failed *Current tile size (15, 6) is smaller than the minimum supported
  tile size (9, 7)*, and 15×7 drew; that size check runs before the type
  check, hiding it. Whether the minimum moves with the item count or the
  orientation is unmeasured (observed 2026-11-17, schema v89).
- **designTile**: a Title, Text Box or Divider, chosen by the required
  `designTile__kind` (`title`, `textBox`, `divider`), with no `queryRef`
  and no query (schema v86 on; below v86 a design tile breaks the
  declared schema, which requires a `queryRef` on every tile but
  `markdownCard`, and whether a portal save raises `schema_version` is
  unmeasured). Shared: `designTile__showBorder`,
  `__bgColor` (a `color--<n>` palette reference, or null for
  transparent), `__fontSize`, `__bold`, `__italic`, `__underline`,
  `__align` (`left`, `center`, `right`). Per kind: `title__text` and
  `title__textColor`; `textBox__html`, HTML up to 262,144 characters;
  `divider__label`, `divider__lineColor` and `divider__lineStyle`
  (`solid`, `dashed`, `dotted`). All three drew as written by hand, and a
  portal save kept their keys but cut the title's height from 2 to 1. A
  text box with a null `__bgColor` drew as a white box on the dark theme
  on one viewing load and blank on the next, the definition unchanged,
  while the editor always showed it (observed 2026-11-17, schema v89).
- `card` and `multistat` render **string** values fine — the basis of the
  display-edge formatting pattern below.

## Formatting at the display edge

There are no per-tile number-format options (only the kpi visual has
`kpi__valueFormat`). Currency / percent presentation is done in KQL by
emitting formatted strings — see [references/REFERENCE.md](references/REFERENCE.md)
for a validated `money()` lambda (`"$1,234,567.89"`, rounding carry,
negatives), which stops grouping at millions, and an unbounded one-liner
that groups the reversed digits. KQL has no `format_number()` and RE2 regex
has no lookahead, so comma grouping is hand-rolled either way. Numeric
axes (bar/column y-columns) must stay numeric — put the unit in the tile
title and column name
(`['Order Value ($)']`) instead. Related KQL pitfalls: `round()` returns
`real`, and `toint()` nulls on decimal strings. General KQL style is
not covered here, so these two are the whole of it.

## Auto refresh

`"autoRefresh": {"enabled": true, "defaultInterval": "5m", "minInterval": "30s"}`
— intervals from the enum `1s|10s|30s|1m|5m|15m|30m|1h|2h|1d`. `minInterval`
caps what viewers may select.

**Live refresh is a second object, `changeDetection`**, which the portal writes
between `autoRefresh` and `tiles`:
`{"kind": "liveUpdates", "minRefreshRate": "30s", "fallbackRefreshRate": "5m"}`,
or `{"kind": "manualUpdates"}`. By the v81 schema's descriptions the two rates
are Learn's **Refresh rate limit** and **Fallback refresh interval**, the latter
for visuals that cannot detect ingestion, each with its own enum. Learn turns
Live refresh on for new dashboards, so a generated file without the object
shows as drift at the next portal commit (2026-10-12).

## Live JSON Schema

`https://dataexplorer.azure.com/static/d/schema/{schema_version}/dashboard.json`
plus sibling `tile.json`, `query.json`, `baseQuery.json`, `parameter.json`.
The `$schema` URL embedded in Microsoft's own sample files
(`pbiadx.powerbi.com/static/d/schema/...`) returns 404 — swap the host.

## What does not exist

- **No image/render REST API.** The Power BI `exportToFile` API does not
  cover KQL dashboards; the RTDB REST surface is item CRUD + the JSON
  definition, and the portal's "export" is the JSON file. Visual verification
  means a browser (screenshot or automation with an authenticated session);
  data-level verification means running the tile queries directly against the
  cluster.
- No cross-tile dynamic references — a tile query sees base queries and
  parameter variables, nothing from other tiles.

## Editing workflow

Round-trip options: Git sync (*Update from Git*), or portal **Manage →
Replace with file** for immediate feedback. Test tile queries before shipping
by composing them exactly as the dashboard does: prepend
`let <variableName> = (<base query text>);` for each entry in
`usedVariables`, then run against the database. Serialization is CRLF with
**no final newline** (JSON item part) — see `data-items`,
`references/git-serialization.md`.

**A portal save rewrites more than the tiles it touched.** On a dashboard
made by REST, one save reset the item's description to its display name,
in `.platform` and on the live item, dropped the top-level `title`, and
moved each query's `id` after its `text`; a REST create's
`description` does not survive the first portal save (observed
2026-11-17, schema v89).
