# MS Learn link bundle — PBIR Report Workflow

Curated set of Microsoft Learn pages relevant to building Power BI reports end-to-end — design guidance (3-30-300 hierarchy is in-house, but the underlying visual-design and accessibility principles map to MS Learn), the workflow this skill encodes (model field discovery → scaffold → page rename → row-by-row layout → bind + sort + filters → CF → validate + publish), and the canonical pbir CLI / publish path.

The 3 highest-leverage entry points (Power BI reports overview, design-effective-reports guide, design for accessibility) are also linked in [pbir.md](../pbir.md)'s `### Reference` section for in-context use; this file holds the comprehensive set.

**Note on docs split:** The pbir CLI per-command reference lives in [pbir-cli-commands.md](pbir-cli-commands.md). The PBIR JSON shape per artifact lives in [visual-json.md](visual-json.md), [pages.md](pages.md), [filters.md](filters.md), [bookmarks.md](bookmarks.md) and [themes.md](themes.md), each with its own MS Learn bundle. This bundle covers the upstream MS Learn content for the *design and workflow* aspects.

## Report-design principles

- [Power BI reports overview](https://learn.microsoft.com/power-bi/create-reports/power-bi-reports-overview) — entry point covering pages, visuals, filters, bookmarks, themes, slicers — the surface this workflow assembles.
- [Tips and tricks for creating reports in Power BI Desktop](https://learn.microsoft.com/power-bi/create-reports/desktop-tips-and-tricks-for-creating-reports) — design guidance: audience, one-screen stories, biggest-first hierarchy, choice of visual. Pairs with the in-house 3-30-300 viewing-distance hierarchy.
- [Design reports for accessibility](https://learn.microsoft.com/power-bi/create-reports/desktop-accessibility-creating-reports) — color/contrast, tab order, alt text, screen reader. Use when the audience requires accessibility compliance.

## Layout, canvas, and page

- [Apply page size and settings in a Power BI report](https://learn.microsoft.com/power-bi/create-reports/power-bi-report-display-settings) — base values for the parent skill's "measure the scaffold first" rule. Default 16:9 at 1280x720; 4:3, Letter, Tooltip and Custom types.
- [Group visuals in a report](https://learn.microsoft.com/power-bi/create-reports/desktop-grouping-visuals) — `visualGroup` for related visuals.

## Field discovery and DAX query view

- [Use DAX query view](https://learn.microsoft.com/power-bi/transform-model/dax-query-view) — `EVALUATE` queries against the model that `pbir model -q "..."` wraps. Useful for confirming distinct categorical values before adding a slicer.
- [Performance Analyzer](https://learn.microsoft.com/power-bi/create-reports/performance-analyzer) — when the laid-out page is slow.

## Visual selection and binding

- [Visualizations overview in Power BI](https://learn.microsoft.com/power-bi/visuals/power-bi-visualizations-overview) — full visual catalog, for picking the right `visualType` per role (KPI, trend, breakdown, detail).
- [Get started formatting report visualizations](https://learn.microsoft.com/power-bi/visuals/power-bi-visualizations-format-visual) — the Format visual pane: colors, labels, reset to default. It states no precedence rule between visual and theme.

## Filters and slicers

- [Filters in Power BI Desktop reports](https://learn.microsoft.com/power-bi/create-reports/power-bi-report-add-filter) — add filters at report / page / visual scope.
- [Slicers in Power BI](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-slicers) — slicers as visuals (NOT filters).

## Conditional formatting + theme tokens

- [Apply conditional table formatting in Power BI](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-table-formatting) — see [conditional-formatting.md](conditional-formatting.md) for the PBIR-side implementation.
- [Create custom report themes](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom) — `good`/`bad`/`neutral` sentiment colors that the workflow's extension-measure pattern returns.

## Publish to Fabric / Power BI workspace

- [Power BI Desktop project (PBIP) overview](https://learn.microsoft.com/power-bi/developer/projects/projects-overview) — what gets uploaded.
- [Fabric Git integration](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration) — Git → Fabric workspace deployment, the typical destination for a `pbir publish`.
- [Report items REST API (Fabric)](https://learn.microsoft.com/rest/api/fabric/report/items) — programmatic deploy alternative to `pbir publish`.

## Time-granularity and dates (relevant to step 7 trend visuals)

- [Auto date/time in Power BI Desktop](https://learn.microsoft.com/power-bi/transform-model/desktop-auto-date-time) — implicit date hierarchy used when no explicit date table.
- [Use the relative date slicer / filter](https://learn.microsoft.com/power-bi/visuals/desktop-slicer-filter-date-range) — RelativeDate + DateSpan / DateAdd time-unit semantics; the parent skill's "infer granularity from the active date filter" rule.

## See also (this repo)

- [pbir-cli-commands.md](pbir-cli-commands.md) — full CLI command reference
- [pages.md](pages.md) — page JSON structure (canvas, tooltip, drillthrough)
- [visual-json.md](visual-json.md) — per-visual JSON shape
- [filters.md](filters.md) — filterConfig at all three scopes
- [themes.md](themes.md) — theme JSON file format
- [conditional-formatting.md](conditional-formatting.md) — measure-driven CF + theme tokens
- [pbip.md](../../pbip/pbip.md) — full project file layout
