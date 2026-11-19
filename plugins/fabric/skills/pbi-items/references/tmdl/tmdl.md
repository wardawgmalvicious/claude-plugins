# Semantic models in TMDL

Four jobs have a reference of their own: read it before answering one.
Past it, the REST spec's folder, then Learn, by `microsoft-learn-mcp`, or with no server, `curl -sL -H 'Accept: text/markdown' <page URL>` (undocumented, read 2026-11-07). A live page that
contradicts a line here wins: say so, act on the page, and route the
fix by `capture-learning`, bar a dated measured line that names the
page it overrules and the call that measured it, which a page changed since
its date sends back to re-measure. An observed claim is cited or marked
pending a doc check, and stands, marked observed, only where no page covers
it.

| The job | Read first |
| --- | --- |
| Write the model's AI instructions, or edit a culture file's `linguisticMetadata` | [ai-instructions.md](references/ai-instructions.md) |
| Create, read or update the model's definition through the Fabric API: its formats and parts, what Git does not hold, `bindConnection`, the spec and measured deltas | [definition-api.md](references/definition-api.md) |
| Query or author the model through an MCP server: the remote Power BI query server, the hosted authoring server, or the local Power BI Modeling MCP server | [semantic-model-mcp.md](references/semantic-model-mcp.md) |
| Audit, review or health-check a finished model: shape, relationship health, memory, readiness for reports and agents. It reports; it never edits | [audit.md](references/audit.md) |

The audit's notebook tier runs through a bundled driver, by the command
in the skill's [SKILL.md](../../SKILL.md) § 4, with its cautions. The
sections, their gates and what a failure looks like are in
[audit-notebook-tier.md](references/audit-notebook-tier.md).

## TMDL Authoring Rules

### Syntax Rules

- **TMDL uses tab indentation** — every nesting level is exactly one tab (`\t`), NOT spaces. Spaces cause validation errors.
  - PowerShell: use `` `t ``
  - Bash: use `$'\t'` or literal tabs
- Objects declared by type + name: `table Customer`, `column ProductId`, `measure 'Total Sales'`
- Names with spaces or special chars (`.`, `=`, `:`, `'`) must be in **single quotes**: `column 'Order Date'`
- Descriptions use `///` placed ABOVE the object — do NOT use the `description` property
- `//` comments are **NOT supported** in TMDL
- Do NOT add `lineageTag` on new objects — it is auto-generated
  - Not at sync or refresh: the first portal commit after an edit in the
    service adds one to every table, column, measure and expression at
    once, and `annotation PBI_ProTooling` to `model.tmdl` (observed once,
    2026-10-07). Review that commit as the tags plus the edit, not drift.
- Multi-line DAX must be enclosed in triple backticks (` ``` `)
- Place **measures before columns** in table definitions
- `formatString` is required on every measure
- Never set `dataType` on measures — it is inferred from DAX
- Check a hand-authored `definition/` offline before a sync with TOM's
  `TmdlSerializer` from the `SqlServer` module: syntax and references,
  not DAX ([references/REFERENCE.md](references/REFERENCE.md) — *BIM ↔
  TMDL Conversion*)

### Naming Conventions

- **Tables**: business-friendly, no `Fact`/`Dim` prefixes. Plural for facts (`Sales`), singular for dimensions (`Product`)
- **Columns**: readable with spaces (`Order Date`, `Unit Price`)
- **Measures**: clear patterns (`Total Sales`, `# Customers`). Time intelligence: `[measure]`, `[measure (ly)]`, `[measure (ytd)]`)

### Column Rules

| Property | Rule |
|---|---|
| `dataType` | Required. Use `int64`, `decimal`, `string`, `dateTime`, `boolean`. Avoid `double` |
| `sourceColumn` | Must match partition source column name exactly |
| `isHidden` | Set for ID columns, foreign keys, system columns |
| `summarizeBy` | `none` for non-aggregatable numerics (IDs, postal codes, year numbers) |
| `isAvailableInMdx` | `false` for hidden columns not used in sort-by or hierarchies |
| `sortByColumn` | For text needing non-alphabetical sort (month names → month number) |

### Measure & DAX Rules

- Always set `formatString` — Currency: `$#,##0.00` | Percentage: `0.00%` | Integer: `#,##0` | Decimal: `#,##0.00`
- Use `DIVIDE()` instead of `/` for safe division
- **Never** use `IFERROR` — causes performance degradation
- Prefix `VAR` names with `_`: `VAR _totalSales = ...`
- Use `displayFolder` to organize measures into logical groups
- Add `///` descriptions to explain business logic
- **If a `scripts/data/dax.sh` wrapper is deployed in the repo** (an
  internal local-cli template), run a new measure against the published
  model before writing it into TMDL: `dax.sh -q 'DEFINE MEASURE …
  EVALUATE …'` returns what a report would show, after relationships
  and filter context, and its values say which `formatString` fits. It
  reads the **published** model, so a change on disk not yet deployed
  is not in it. It is an accelerator that happens to be present, never
  a dependency.

### Relationship Rules

- `fromColumn:` = many-side (fact); `toColumn:` = one-side (dimension)
- Create relationships BEFORE measures that depend on them
- Default: `crossFilteringBehavior: oneDirection`; add `bothDirections` only when needed
- **Role-playing dimensions: duplicate the table by default** — `Date`,
  `Ship Date`, `Delivery Date`, each with one active relationship.
  Microsoft recommends "defining active relationships whenever possible",
  which "means that role-playing dimension tables should be duplicated in
  your model"; the cost is model size, "rarely a concern" for dimensions.
  `isActive: false` + `USERELATIONSHIP()` is the *conditional* case —
  only when no visual needs two roles at once and you write the measures.
  In Direct Lake, confirm duplication is available first (see below).
- Both sides must have matching `dataType`
- Set `isKey: true` on dimension primary key columns
- Hide foreign keys on fact tables (`isHidden: true`)
- No composite keys — use a single surrogate integer key

### Calculation Groups

```tmdl
table 'Time Intelligence'
	calculationGroup
		calculationItem Current = SELECTEDMEASURE()
		calculationItem YTD = CALCULATE(SELECTEDMEASURE(), DATESYTD('Date'[Date]))
	column 'Time Intelligence'
		dataType: string
	partition 'Partition_Time Intelligence' = calculationGroup
```

- `calculationGroup` keyword has NO name — just the keyword indented under the table
- Partition type must be `= calculationGroup` (not `= m` or `= calculated`)
- Use `formatStringDefinition` (not `formatString`) for calc items that override measure format

### Security Roles

```tmdl
role RegionalManager
	modelPermission: read
	tablePermission Sales = [Region] = "East"
```

- `modelPermission:` required — use `read` or `readRefresh`
- **Members are set in the service, per model copy, not in TMDL**: on
  the model's **Security** page (workspace list > More options >
  Security), which a Contributor or higher sees once a role exists
  ([RLS § Manage security on your semantic model](https://learn.microsoft.com/fabric/security/service-admin-row-level-security#manage-security-on-your-semantic-model), read 2026-11-16).
  `POST .../datasets/{id}/users` grants dataset permission only, its
  body having no `roles`
  ([Post Dataset User In Group](https://learn.microsoft.com/rest/api/power-bi/datasets/post-dataset-user-in-group), read 2026-11-16);
  TMSL's `Roles` object over XMLA can script members, untried here.
- **A model's first role cuts off every reader in no role**: a user
  with only Read or Build then reads no data, while Write (Contributor
  and up) reads regardless
  ([Semantic model permissions § RLS](https://learn.microsoft.com/power-bi/connect-data/service-datasets-permissions#semantic-model-permissions-and-row-level-security-rls), read 2026-11-16).
  Map each environment's Viewer groups in the sitting that syncs or
  deploys the first role. Learn says it of RLS; a role with only OLS
  doing the same is unverified (2026-11-16).
- A deployment copies a role without its members: map each stage's
  groups on its own copy (`deploy`'s
  `references/deployment-pipelines.md` § Limits and gotchas).
- Service principals cannot be role members, and RLS and OLS do not
  bind them, so test a role as a user
  ([XMLA connectivity § Security](https://learn.microsoft.com/fabric/enterprise/powerbi/service-premium-connect-tools#security), read 2026-11-16).
- OLS on a column restricts every measure that references it: grep the
  model's measures and the report before hiding one
  ([Object-level security § Restrictions](https://learn.microsoft.com/analysis-services/tabular-models/object-level-security#restrictions), read 2026-11-16).
- Model RLS and OLS bind only queries through the model: a user who
  can read the source, as SSO requires, reads hidden columns through
  the SQL analytics endpoint. OneLake security closes it (`security`
  § OneLake Security)
  ([Integrate Direct Lake security § OLS and RLS](https://learn.microsoft.com/fabric/fundamentals/direct-lake-security-integration#object-level-security-ols-and-row-level-security-rls), read 2026-11-16).
- Do NOT use `INFO.ROLES()` / `INFO.ROLEMEMBERSHIPS()` via DAX — unreliable. Read members on the Security page.

### Annotations

- Do NOT add `PBI_*` annotations manually — they are Power BI internal metadata
- Custom annotations are fine for documentation/tooling
- Syntax: blank line before the first annotation; blank line between annotations; same indent as peer properties

```tmdl
column 'Product Name'
	dataType: string
	sourceColumn: Product Name

	annotation MyTool_Owner = analytics-team
```


---


## model.tmdl Required Properties

`model.tmdl` is the root of the `definition/` folder alongside `database.tmdl`, `expressions.tmdl`, `functions.tmdl`, `relationships.tmdl`, `roles/`, `perspectives/`, `cultures/`, and `tables/`.

```tmdl
model Model
	culture: en-US
	defaultPowerBIDataSourceVersion: powerBI_V3
	discourageImplicitMeasures
	sourceQueryCulture: en-US
	dataAccessOptions
		legacyRedirects
		returnErrorValuesAsNull
```

`defaultPowerBIDataSourceVersion: powerBI_V3` is required for Import-mode models — without it, `Import from JSON supported for V3 models only`.


---


## Direct Lake Configuration

- ALL partitions must use `EntityPartitionSource` — no M/Power Query
- A named expression pointing to the Lakehouse/Warehouse must be defined before tables:

  ```tmdl
  expression DL_Lakehouse =
  		let
  			Source = AzureStorage.DataLake("https://onelake.dfs.fabric.microsoft.com/<WorkspaceId>/<LakehouseId>", [HierarchicalNavigation=true])
  		in
  			Source
  ```

- Each table partition references the expression:

  ```tmdl
  partition Sales = entity
  	mode: directLake
  	source
  		entityName: Sales
  		schemaName: dbo
  		expressionSource: DL_Lakehouse
  ```

- `dataType: binary` columns are NOT supported in Direct Lake
- Columns map directly via `sourceColumn` — no transforms
- **A model new to a workspace answers no table until its first
  refresh.** Learn says Direct Lake tables an XMLA tool creates start
  unprocessed, and queries on them fail on OneLake; one that arrived by
  Git sync did the same (observed 2026-10-07). Refresh it once; the
  error text is in `rest-api`'s `references/gotchas.md`.
- **Adding the same source table twice is not supported** in Power BI
  Desktop or web modeling — XMLA tools can, but **Edit tables** and
  **refresh** then error. So the role-playing fix above usually has to
  happen upstream: add the role table to the lakehouse and bind it.
  Calculated tables are preview on Direct Lake on OneLake and unsupported
  on Direct Lake on SQL, bar the calculation groups, what-if and field
  parameters that create one implicitly. Calculated columns are preview
  on Direct Lake on OneLake, **User Context only**, and unsupported on
  Direct Lake on SQL; unmaterialized, they
  [can't be used in relationships](https://learn.microsoft.com/power-bi/transform-model/desktop-calculated-columns),
  so no calculated column can stand in for a surrogate key there either
  (Learn, read 2026-10-23).
- **A composite with Direct Lake depends on the tool**: an Import table
  joins a Direct Lake model only through web modeling, a DirectQuery
  table only through XMLA. Learn's table of which tool builds which
  composite is in [references/REFERENCE.md](references/REFERENCE.md),
  § `partition` (2026-10-22).
- **Desktop and web modelling pick a Direct Lake relationship's many side
  by row count**: "the table with more rows is considered as the many
  side", and nothing validates it. That sentence was Learn's *Edit
  tables* page; the page's path now redirects to
  [Develop Direct Lake semantic models](https://learn.microsoft.com/fabric/fundamentals/direct-lake-develop),
  which does not carry it (read 2026-11-07), so the rule stands as
  observed, with no page behind it, until one covers it again.
  So a date table longer than its fact, as one spanning a planning horizon
  over a small fact is, comes out reversed, the date column in
  `fromColumn`, as that rule implies (observed once in web
  modelling, 2026-09-30). Read
  `relationships.tmdl` back after creating one, since nothing errors:
  grouping by the reversed date table returned the fact's grand total on
  every year (DAX query view, 2026-09-30). The documented failure on a
  duplicate in a one-side column
  ([limitations](https://learn.microsoft.com/fabric/fundamentals/direct-lake-overview#considerations-and-limitations))
  presumably needs a query that filters across the relationship (untested).
- **Cross-environment rebinding (deployment pipelines):** Direct Lake on OneLake does **not**
  support data source rules — the dropdowns are simply greyed out. Both the [Direct Lake
  overview limitations table](https://learn.microsoft.com/fabric/fundamentals/direct-lake-overview#considerations-and-limitations)
  and [Develop Direct Lake semantic models § Use M parameters with deployment pipelines](https://learn.microsoft.com/fabric/fundamentals/direct-lake-develop#use-m-parameters-with-deployment-pipelines)
  say so (read 2026-11-07); the create-rules page doesn't. Instead, declare the workspace/lakehouse GUIDs as
  `IsParameterQuery` Text expressions (Learn's example adds `IsParameterQueryRequired = true`,
  `Type = "Text"`, and says parameters must be `Text`; use the lakehouse or warehouse item ID,
  never the SQL analytics endpoint ID; a single full-URL `OneLakeSourceUrl` parameter is an
  alternative needing one rule instead of two) and build the URL from them — concatenation works
  (`AzureStorage.DataLake("https://onelake.dfs.fabric.microsoft.com/" & WorkspaceId & "/" & LakehouseId, ...)`)
  — then rebind each target stage with **parameter rules** (verified live 2026-08-24).
  Several connections can share one workspace parameter, each with its own item-ID
  parameter. In a composite model the Text parameters can be created in Power Query
  instead, but the Direct Lake connection expression is not available there: edit it
  in TMDL view. Deploy the model to the target stage first if it isn't there yet, so
  the rules can be set (the Develop Direct Lake page, read 2026-11-18).


---


## Gotchas

| Issue | Cause | Fix |
|---|---|---|
| `InvalidLineType: Property!` in `database.tmdl` | Bare `compatibilityLevel:` without `database` declaration | Start the file with `database <Name>` on line 1 |
| `Import from JSON supported for V3 models only` | Missing `defaultPowerBIDataSourceVersion` | Add `powerBI_V3` to `model.tmdl` |
| Spaces-for-tabs validation errors | Editor converted tabs | Force literal tabs; configure editor not to expand |
| `//` comment ignored or invalid | Not supported | Use `///` on line above the object (descriptions only) |
| Measure has wrong inferred type | `dataType` was set manually | Remove `dataType` from measures — always inferred |
| Missing `formatString` errors | Measure without `formatString` | Always set per measure; use `formatStringDefinition` for dynamic |
| Calc item format ignored | Used `formatString` instead of `formatStringDefinition` | `formatStringDefinition` is DAX-based; only it overrides the selected measure's format |
| Broken report binding after column rename | Stale `lineageTag` left in place | Never edit `lineageTag`; let Power BI regenerate only on creation |
| Role members ignored | Authored `member` statically | Set members on the model copy's Security page |
| `INFO.ROLES()` returns stale/missing data | Known DAX surface unreliability | Read membership on the model's Security page |
| Calendar name collision | Name unique per-table but not per-model | Calendar names must be globally unique across the model |
| Direct Lake partition errors | `binary` column in source | Cast away in upstream Lakehouse/Warehouse; drop the column |
| `...transformations that can't be used for DirectQuery` refreshing a parameterized Direct Lake model | Model-page ribbon **schema-and-data** refresh re-evaluates the M; fires on any parameterized source shape | False alarm — data-only, workspace-page, scheduled, and pipeline refreshes just reframe and work (observed 2026-08-24, undocumented) |
| Perspective appears empty in Power BI | No `perspectiveTable` children | Add at least one table + column/measure, or `includeAll` on a table |
| `model.bim` and `definition/` both present | Forgot to delete `.bim` after TMDL conversion | Remove `model.bim`; they are mutually exclusive |
| TMDL conversion fails | Old `Microsoft.AnalysisServices.retail.amd64` | Upgrade NuGet package for `TmdlSerializer` |
| Hierarchy level references missing column | Column removed or renamed without updating level | `level.column:` must reference an existing same-table column |
| `PBI_*` annotation edits revert | Power BI rewrites on save | Do not hand-author PBI internal annotations |


---

## Additional reference

- Microsoft Learn: [TMDL language overview](https://learn.microsoft.com/analysis-services/tmdl/tmdl-overview)
- Microsoft Learn: [TMDL view in Power BI Desktop](https://learn.microsoft.com/power-bi/transform-model/desktop-tmdl-view)
- Microsoft Learn: [Power BI Desktop project semantic model folder (PBIP)](https://learn.microsoft.com/power-bi/developer/projects/projects-dataset)
- Companion [references/REFERENCE.md](references/REFERENCE.md): per-object property tables (`database`, `model`, `table`, `column`, `measure`, `relationship`, `hierarchy`, `partition`, `calculationGroup`, `role`, `perspective`, `cultureInfo`, `expression`, `function`, `dataSource`, `refreshPolicy`, `calendar`, `queryGroup`), BIM ↔ TMDL conversion procedure, enum value lists, and a comprehensive MS Learn link bundle (TMDL syntax / TMDL view / PBIP folder / calculation groups / Direct Lake / DAX / TMSL / TOM).
