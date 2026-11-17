# TMDL Reference

Property tables per object type, BIM↔TMDL conversion procedure, and enum value lists.
Used by [tmdl.md](../tmdl.md) as lookup material — loaded on demand when specific property values or enum members are needed.

---


## TMDL Object Reference

Complete property tables per object type. All property names are lowercase camelCase as they appear in TMDL. Types referencing enums resolve against the enum tables at the end of this section. `lineageTag` / `sourceLineageTag` are auto-generated and listed for completeness — never author them manually.

### `database`

| Property | Type |
|---|---|
| `compatibilityLevel` | integer (use `1702` for UDFs, `1604+` for calendars) |
| `compatibilityMode` | `analysisServices` \| `powerBI` \| `excel` |
| `id` | string |
| `language` | integer |
| `model` | model |
| `name` | objectName |
| `readWriteMode` | `readWrite` \| `readOnly` \| `readOnlyExclusive` |
| `storageLocation` | string |
| `unicodeCharacterBehavior` | `codeUnits` \| `codePoints` |

### `model`

| Property | Type |
|---|---|
| `culture` | string (e.g. `en-US`) |
| `sourceQueryCulture` | string |
| `collation` | string |
| `defaultPowerBIDataSourceVersion` | `powerBI_V1` \| `powerBI_V2` \| `powerBI_V3` (Import requires V3) |
| `defaultMode` | `import` \| `directQuery` \| `directLake` \| `dual` \| `default` \| `push` |
| `directLakeBehavior` | `automatic` \| `directLakeOnly` \| `directQueryOnly` |
| `defaultDataView` | `full` \| `sample` \| `default` |
| `defaultMeasure` | string |
| `discourageImplicitMeasures` | flag |
| `discourageCompositeModels` | boolean |
| `disableAutoExists` | integer |
| `forceUniqueNames` | boolean |
| `maxParallelismPerQuery` | integer |
| `maxParallelismPerRefresh` | integer |
| `valueFilterBehavior` | `automatic` \| `independent` \| `coalesced` |
| `dataAccessOptions` | object (`legacyRedirects`, `returnErrorValuesAsNull`) |

### `table`

| Property | Type |
|---|---|
| `name` | objectName |
| `isHidden` | flag |
| `isPrivate` | boolean |
| `dataCategory` | string (e.g. `Time` for date tables) |
| `excludeFromModelRefresh` | boolean |
| `excludeFromAutomaticAggregations` | boolean |
| `showAsVariationsOnly` | boolean |
| `measure` | array (authored first) |
| `column` | array |
| `partition` | array |
| `hierarchy` | array |
| `calculationGroup` | calculationGroup |
| `calendar` | array |
| `refreshPolicy` | refreshPolicy |
| `defaultDetailRowsDefinition` | detailRowsDefinition |

### `column`

| Property | Type |
|---|---|
| `name` | objectName |
| `dataType` | `string` \| `int64` \| `decimal` \| `double` \| `dateTime` \| `boolean` \| `binary` |
| `sourceColumn` | string |
| `formatString` | string |
| `displayFolder` | string (use `\` for subfolders) |
| `description` | via `///` above |
| `isHidden` | flag |
| `isKey` | flag (dimension PK only) |
| `isNullable` | boolean |
| `isUnique` | boolean |
| `isAvailableInMdx` | boolean |
| `isDataTypeInferred` | boolean |
| `isNameInferred` | boolean |
| `summarizeBy` | `none` \| `sum` \| `min` \| `max` \| `count` \| `average` \| `distinctCount` \| `default` |
| `sortByColumn` | string (same-table sibling) |
| `dataCategory` | string (e.g. `Image URL`, `Web URL`, `Address`) |
| `encodingHint` | `default` \| `hash` \| `value` |
| `alignment` | `default` \| `left` \| `right` \| `center` |
| `type` | `data` \| `calculated` \| `rowNumber` \| `calculatedTableColumn` |
| `expression` | DAX (calculated columns only) |
| `expressionContext` | `standard` (default) \| `userContext` — opts a calculated column into dynamic evaluation of `USERCULTURE` / `USERPRINCIPALNAME` / `USEROBJECTID` / `USERNAME` / `CUSTOMDATA`. Forces unmaterialized evaluation; check storage-mode support matrix. |
| `alternateOf` | alternateOf block |
| `relatedColumnDetails` | `groupByColumn` array |
| `variation` | array |
| `stringIndexingBehavior` | `auto` \| `full` \| `explicit` \| `off` — preview, CL 1707+; see the indexing note below |
| `fullTextIndexingBehavior` | `full` \| `explicit` \| `off` — preview, CL 1708+; no `auto` |

**Calculated columns × storage mode support matrix** (per [MS Learn](https://learn.microsoft.com/power-bi/transform-model/desktop-calculated-columns)):

|Storage mode|Standard (default)|User Context|
|---|---|---|
|Import|Materialized|Unmaterialized|
|Direct Lake on OneLake|N/A|Unmaterialized (preview)|
|Direct Lake on SQL|N/A|N/A|
|DirectQuery|Unmaterialized|Unmaterialized|
|Dual|Materialized (Import) / Unmaterialized (DirectQuery)|Unmaterialized|
|DirectQuery on Power BI semantic models|Unmaterialized|N/A|

Direct Lake on OneLake gained calculated-column support in April 2026 (preview), User Context only (Learn, read 2026-10-23). What that closes, and Direct Lake on SQL's limits, are in [tmdl.md](../tmdl.md#direct-lake-configuration), § Direct Lake Configuration.

**String and full-text indexing** (both preview; Learn, read 2026-10-22):
`stringIndexingBehavior` speeds `CONTAINSSTRING` and `SEARCH` without
changing a result, and `fullTextIndexingBehavior` is the index
`TEXTCONTAINS` and `TEXTSIMILARITY` need. Each takes a `string` column on
an Import, Dual or Direct Lake table, never pure DirectQuery, and needs
compatibility level 1707 (string) or 1708 (full-text), an upgrade that
cannot be undone. In preview both are set in TMDL on the web or over
XMLA; Desktop support is planned, not shipped (September 2026 summary).
`auto`, string only, builds lazily on first use, `full` on every
refresh, and `explicit` only on an `indexes` refresh, which in preview
runs over the XMLA endpoint alone, not from the Power BI refresh UI or
REST refresh API. See [Configure string
indexing](https://learn.microsoft.com/analysis-services/azure-analysis-services/string-indexing?view=power-bi-premium-current)
and [Configure full-text
indexing](https://learn.microsoft.com/analysis-services/azure-analysis-services/full-text-indexing?view=power-bi-premium-current).

**Column data types:**

| Value | Use For |
|---|---|
| `string` | Names, codes, categories |
| `int64` | Keys, counts, year numbers |
| `decimal` | Currency, precise financial values |
| `double` | Ratios, percentages (avoid where possible) |
| `dateTime` | Date/timestamp columns |
| `boolean` | Flags |
| `binary` | Rare; **not supported in Direct Lake** |

**`summarizeBy` decision rules:**

- `none` for: all keys, all strings, all dates/booleans, non-additive numerics (rates, %, rankings), sort-key columns, year numbers
- `sum` for: additive fact columns only
- When in doubt, `none` — force users to author explicit measures

### `measure`

| Property | Type |
|---|---|
| `name` | objectName |
| `expression` | DAX (single-line `= <expr>` or multi-line in triple backticks) |
| `formatString` | **required** string |
| `formatStringDefinition` | DAX expression producing a format string (dynamic) |
| `displayFolder` | string |
| `isHidden` | flag |
| `isSimpleMeasure` | boolean |
| `dataCategory` | string |
| `detailRowsDefinition` | detailRowsDefinition |
| `kpi` | kpi block (`statusExpression`, `targetExpression`, `trendExpression`, graphics) |
| `description` | via `///` above |

Never set `dataType` on a measure — inferred from the expression.

### `relationship`

| Property | Type |
|---|---|
| `name` | objectName (usually GUID-style, auto-generated) |
| `fromColumn` | `Table.Column` |
| `toColumn` | `Table.Column` |
| `fromCardinality` | `one` \| `many` \| `none` |
| `toCardinality` | `one` \| `many` \| `none` |
| `type` | `singleColumn` |
| `crossFilteringBehavior` | `oneDirection` \| `bothDirections` \| `automatic` |
| `securityFilteringBehavior` | `oneDirection` \| `bothDirections` \| `none` |
| `joinOnDateBehavior` | `dateAndTime` \| `datePartOnly` |
| `isActive` | boolean |
| `relyOnReferentialIntegrity` | boolean |

```tmdl
relationship 0e6e4252-95c4-4e0e-a4c8-874e5463ec4c
	fromColumn: Invoices.'Billing Date'
	toColumn: Date.Date
```

### `hierarchy`

| Property | Type |
|---|---|
| `name` | objectName |
| `isHidden` | flag |
| `displayFolder` | string |
| `hideMembers` | `default` \| `hideBlankMembers` |
| `level` | array |

```tmdl
table Brands
	hierarchy 'Brand Hierarchy'
		displayFolder: 1. Brand Hierarchy

		level Class
			column: Class

		level Flagship
			column: Flagship

		level Brand
			column: Brand
```

Levels have `ordinal` (auto by declaration order), `column`, and optionally `name`. The referenced `column:` must exist on the same table.

### `partition`

| Property | Type |
|---|---|
| `name` | objectName |
| `mode` | `import` \| `directQuery` \| `directLake` \| `dual` \| `default` \| `push` |
| `source` | object (M expression, entity, calculated expression, or calculationGroup) |
| `sourceType` | `query` \| `calculated` \| `m` \| `entity` \| `policyRange` \| `calculationGroup` \| `inferred` \| `none` |
| `dataView` | `full` \| `sample` \| `default` |
| `dataCoverageDefinition` | DAX expression (for hybrid / aggregation coverage) |
| `queryGroup` | string reference |

Partition source forms:

```tmdl
# Calculated table (measures home)
partition __Measures = calculated
	mode: import
	source = {1}

# Direct Lake from named Lakehouse expression
partition Sales = entity
	mode: directLake
	source
		entityName: Sales
		schemaName: dbo
		expressionSource: DL_Lakehouse

# Calculation group
partition 'Partition_Time Intelligence' = calculationGroup
```

**Composite models × tooling** (per [MS Learn](https://learn.microsoft.com/power-bi/transform-model/desktop-composite-models), read 2026-10-22):

| Composite model type | Tooling available | Notes |
| --- | --- | --- |
| DirectQuery to another Power BI semantic model with or without additional tables in import or DirectQuery storage mode | Power BI Desktop only | Connect to a Power BI semantic model, then choose **Make changes to this model** or connect after adding a table in import or DirectQuery storage mode. |
| DirectQuery tables coming from different data sources | Power BI Desktop and Power BI service | For example, *Table A* comes from *SQL database A* and *Table B* comes from *SQL database B* |
| Import and DirectQuery tables in the same semantic model | Power BI Desktop and Power BI service | |
| Import and Direct Lake tables in the same semantic model | Power BI web modeling only | Import or Direct Lake tables can be added in Desktop, but only combined in web modeling. |
| DirectQuery and Direct Lake tables in the same semantic model | XMLA only | Combine using an XMLA script or XMLA community based tools. Can be opened in web modeling for semantic model edits only without any refresh or tables change options. |

The table's Direct Lake is Direct Lake on OneLake: Direct Lake on SQL is
single source and joins no composite model (same page). Since September
2026 the service also creates and edits DirectQuery models and switches
a table's storage mode from DirectQuery to Import or Dual, with no
Desktop (September 2026 feature summary).

### `calculationGroup` / `calculationItem`

| `calculationGroup` Property | Type |
|---|---|
| `precedence` | integer (higher = applied outer when multiple groups stack) |
| `description` | via `///` |
| `calculationItem` | array |
| `noSelectionExpression` | calculationExpression block |
| `multipleOrEmptySelectionExpression` | calculationExpression block |

| `calculationItem` Property | Type |
|---|---|
| `name` | objectName |
| `expression` | DAX |
| `formatStringDefinition` | DAX expression producing format string |
| `ordinal` | integer |
| `description` | via `///` |

### `role`

| Property | Type |
|---|---|
| `name` | objectName |
| `modelPermission` | `none` \| `read` \| `readRefresh` \| `refresh` \| `administrator` |
| `tablePermission` | array (`name`, `filterExpression`, `metadataPermission`, `columnPermission`) |
| `member` | array — **set members on the model's Security page; do not author statically** |

Column-level security:

```tmdl
role Restricted
	modelPermission: read
	tablePermission Customers
		columnPermission Email
			metadataPermission: none
```

### `perspective`

| Property | Type |
|---|---|
| `name` | objectName |
| `perspectiveTable` | array |

`perspectiveTable` holds `perspectiveColumn`, `perspectiveMeasure`, `perspectiveHierarchy` child arrays; `includeAll` toggles full table inclusion.

```tmdl
perspective 'Finance Only'
	perspectiveTable Invoices
		includeAll
	perspectiveTable Date
		perspectiveColumn Year
		perspectiveColumn 'Year Month'
	perspectiveTable __Measures
		perspectiveMeasure 'Total Revenue'
		perspectiveMeasure 'Total Cost'
```

An empty `perspective 'X'` declaration with no children is a valid placeholder.

### `cultureInfo` (Translations)

| Property | Type |
|---|---|
| `name` | objectName (culture code, e.g. `en-US`) |
| `linguisticMetadata` | block with `content` (JSON string) + `contentType: json`; its `CustomInstructions` key holds the model's [AI instructions](ai-instructions.md) |
| `translations` | object keyed by object reference |

```tmdl
cultureInfo en-US

	linguisticMetadata = {"Version":"4.2.0","Language":"en-US","Entities":{...}}
		contentType: json
```

Place culture files in `definition/cultures/<code>.tmdl`. Linguistic metadata is typically generated by Power BI — manual editing is rare and brittle.

### `expression` (Named M Expression)

| Property | Type |
|---|---|
| `name` | objectName |
| `expression` | M (default kind) |
| `kind` | `m` |
| `expressionSource` | string |
| `parameterValuesColumn` | string (for bound parameters) |
| `queryGroup` | string (folder-like grouping) |
| `mAttributes` | string |

Parameters use M `meta` record syntax:

```tmdl
expression SqlEndpoint = "server.database.windows.net" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]
	queryGroup: Parameters

expression RangeStart = #datetime(2023, 1, 1, 0, 0, 0) meta [IsParameterQuery=true, Type="DateTime", IsParameterQueryRequired=true]
	queryGroup: Parameters
```

Multi-line M goes in triple backticks. Place shared parameters and functions in `definition/expressions.tmdl`.

### `function` (DAX UDF, CL 1702+)

| Property | Type |
|---|---|
| `name` | objectName (bracket-callable) |
| `expression` | DAX UDF body |
| `isHidden` | boolean |
| `description` | via `///` |

UDF parameter types: `STRING`, `INT64`, `NUMERIC VAL`, `SCALAR EXPR`, `ANYVAL`, `ANYREF EXPR`, `COLUMN`. `VAL` = eager, evaluated once before the call. `EXPR` = lazy, evaluated inside the body in caller context — required for measure references.

```tmdl
function 'MyLib.SafeDivide' = ```
	(numerator: SCALAR EXPR, denominator: SCALAR EXPR) =>
	DIVIDE(numerator, denominator)
	```
```

Author UDFs in `definition/functions.tmdl`. Call from measures like `[MyLib.SafeDivide]([Revenue], [Qty])`.

### `dataSource`

| Property | Type |
|---|---|
| `name` | objectName |
| `type` | `provider` \| `structured` |
| `connectionString` | string (provider) |
| `connectionDetails` | object (structured) |
| `credential` | object |
| `impersonationMode` | `impersonateAccount` \| `impersonateAnonymous` \| `impersonateCurrentUser` \| `impersonateServiceAccount` \| `impersonateUnattendedAccount` \| `default` |
| `isolation` | `readCommitted` \| `snapshot` |
| `maxConnections` | integer |
| `timeout` | integer |
| `provider` | string |

Modern models rarely author `dataSource` directly; M expressions + credentials managed via the Fabric/Power BI REST APIs are preferred.

### `refreshPolicy` (Incremental Refresh)

| Property | Type |
|---|---|
| `policyType` | `basic` |
| `mode` | `import` \| `hybrid` |
| `rollingWindowGranularity` | `day` \| `month` \| `quarter` \| `year` |
| `rollingWindowPeriods` | integer |
| `incrementalGranularity` | `day` \| `month` \| `quarter` \| `year` |
| `incrementalPeriods` | integer |
| `incrementalPeriodsOffset` | integer |
| `sourceExpression` | M expression (with `RangeStart`/`RangeEnd` filters) |
| `pollingExpression` | M expression |

Used with `RangeStart` / `RangeEnd` parameter expressions (see `expression` section).

### `calendar` / `calendarColumnGroup` (CL 1604+)

| `calendar` Property | Type |
|---|---|
| `name` | objectName (must be globally unique across model) |
| `calendarColumnGroup` | array |

| `calendarColumnGroup` Property | Type |
|---|---|
| `timeUnit` | `year` \| `semester` \| `quarter` \| `month` \| `week` \| `date` \| `dayOfYear` \| `dayOfMonth` \| `dayOfWeek` \| `monthOfYear` \| `quarterOfYear` \| `weekOfYear` \| ... |
| `primaryColumn` | string (sort key) |
| `associatedColumn` | array (display labels) |

Rules:

- Each calendar uses columns from a single host table
- Names unique at **model** scope
- Do not repeat a time unit within a calendar
- A column mapped to a unit in one calendar must use the same unit in every other calendar it joins
- Only one `TimeRelatedGroup` per calendar — combine `IsWeekend`, `Season`, `RelativeMonth`, etc.
- Week-based calendars (ISO / 4-4-5): pair ISO weeks with ISO year; map `Period` to the `Month` unit

### `queryGroup`

| Property | Type |
|---|---|
| `folder` | objectName (folder path for Power Query) |
| `description` | via `///` |

```tmdl
queryGroup Parameters
queryGroup 'Scalar Values'
queryGroup Tables
```


---


## BIM ↔ TMDL Conversion

A PBIP semantic model uses either the legacy `model.bim` (single TMSL JSON file) or the modern `definition/` folder (TMDL files). They are **mutually exclusive**. Format is controlled by `definition.pbism`: `"version": "1.0"` → TMSL only; `"version": "4.0"` or higher → TMDL allowed.

**Prefer TMDL** for source control: smaller diffs, per-table files, readable conflicts.

| From | To | Via |
|---|---|---|
| `model.bim` | `definition/` | `TmdlSerializer.SerializeModelToFolder($db.Model, "<path>")` (PowerShell + TOM) |
| Live model | `definition/` | Same `TmdlSerializer` call against a live TOM `$db.Model` |
| `definition/` | `model.bim` | `TmdlSerializer.DeserializeModelFromFolder(...)` then `JsonSerializer.SerializeDatabase(...)` |

After conversion:

1. Delete `model.bim` from `.SemanticModel/` (mutually exclusive with `definition/`)
2. Bump `definition.pbism` version to `4.0`+
3. Reopen the `.pbip` in Power BI Desktop to validate

Both `…Model…` methods exist on `Microsoft.AnalysisServices.Tabular.TmdlSerializer`
(the TOM API reference, read 2026-11-07, package 19.118.3):
`SerializeModelToFolder(Model, string)` and `DeserializeModelFromFolder(string)`, which
returns a `Model`. The TMDL overview page lists only the `…Database…` pair,
`SerializeDatabaseToFolder(Database, string)` and
`DeserializeDatabaseFromFolder(string)`, which take and return a `Database`; the
overview's list is the incomplete one.

`TmdlSerializer` requires a recent `Microsoft.AnalysisServices.retail.amd64` (or newer `Microsoft.AnalysisServices`) NuGet package. If the type is missing, upgrade.

Without NuGet, the `SqlServer` PowerShell module carries it: 22.4.5.1
ships TOM 19.96 as `coreclr\Microsoft.AnalysisServices.Tabular.dll`. In
pwsh 7, `Add-Type -Path` that file, then
`[Microsoft.AnalysisServices.Tabular.TmdlSerializer]::DeserializeDatabaseFromFolder('<…>\definition')`
loads a hand-authored folder offline, before a Git sync can stop on it:
a bad line fails `TMDL Format Error`, an unresolved reference
`TmdlDeserializationWithReferenceErrorsException`, and no DAX is
evaluated. The DLL's file version reads `17.0.21.18`, which looks too
old; its assembly version,
`[Reflection.AssemblyName]::GetAssemblyName('<dll>').Version`, is
`19.96.1.0` (measured 2026-10-08).

---


## Enum Reference

**aggregateFunction**: `default`, `none`, `sum`, `min`, `max`, `count`, `average`, `distinctCount`
**alignment**: `default`, `left`, `right`, `center`
**columnType**: `data`, `calculated`, `rowNumber`, `calculatedTableColumn`
**compatibilityMode**: `unknown`, `analysisServices`, `powerBI`, `excel`
**crossFilteringBehavior**: `oneDirection`, `bothDirections`, `automatic`
**dataType**: `string`, `int64`, `double`, `decimal`, `dateTime`, `boolean`, `binary`, `automatic`, `variant`, `unknown`
**dataViewType**: `full`, `sample`, `default`
**directLakeBehavior**: `automatic`, `directLakeOnly`, `directQueryOnly`
**encodingHintType**: `default`, `hash`, `value`
**evaluationBehavior**: `automatic`, `static`, `dynamic`
**expressionKind**: `m`
**extendedPropertyType**: `string`, `json`
**hierarchyHideMembersType**: `default`, `hideBlankMembers`
**impersonationMode**: `default`, `impersonateAccount`, `impersonateAnonymous`, `impersonateCurrentUser`, `impersonateServiceAccount`, `impersonateUnattendedAccount`
**metadataPermission**: `default`, `none`, `read`
**modeType**: `import`, `directQuery`, `directLake`, `dual`, `default`, `push`
**modelPermission**: `none`, `read`, `readRefresh`, `refresh`, `administrator`
**partitionSourceType**: `query`, `calculated`, `m`, `entity`, `policyRange`, `calculationGroup`, `inferred`, `none`
**powerBIDataSourceVersion**: `powerBI_V1`, `powerBI_V2`, `powerBI_V3`
**refreshGranularityType**: `day`, `month`, `quarter`, `year`, `invalid`
**refreshPolicyMode**: `import`, `hybrid`
**refreshPolicyType**: `basic`
**relationshipEndCardinality**: `none`, `one`, `many`
**relationshipType**: `singleColumn`
**securityFilteringBehavior**: `oneDirection`, `bothDirections`, `none`
**summarizationType**: `groupBy`, `sum`, `count`, `min`, `max`
**timeUnit**: `year`, `semester`, `semesterOfYear`, `quarter`, `quarterOfYear`, `quarterOfSemester`, `month`, `monthOfYear`, `monthOfSemester`, `monthOfQuarter`, `week`, `weekOfYear`, `weekOfSemester`, `weekOfQuarter`, `weekOfMonth`, `date`, `dayOfYear`, `dayOfSemester`, `dayOfQuarter`, `dayOfMonth`, `dayOfWeek`, `unknown`
**tmdlRoleMemberType**: `auto`, `user`, `group`, `activeDirectory`
**unicodeCharacterBehavior**: `codeUnits`, `codePoints`
**valueFilterBehaviorType**: `automatic`, `independent`, `coalesced`


---


## MS Learn link bundle

Curated set of Microsoft Learn pages relevant to authoring TMDL — the language itself, the Power BI Desktop TMDL view, the PBIP project folder structure, the semantic model item definition format, and adjacent topics (calculation groups, Direct Lake, DAX, TMSL, TOM).

The 3 highest-leverage entry points (TMDL overview, TMDL view in Desktop, PBIP semantic model folder) are also linked in [tmdl.md](../tmdl.md)'s `## Additional reference` section for in-context use; this section holds the comprehensive set.

### TMDL language and tooling

- [Tabular Model Definition Language (TMDL)](https://learn.microsoft.com/analysis-services/tmdl/tmdl-overview) — authoritative TMDL spec: syntax (whitespace, indentation, casing, `ref` keyword, value delimiters), folder structure, full TOM compatibility. Read first when authoring or debugging TMDL.
- [TMDL scripts (createOrReplace, etc.)](https://learn.microsoft.com/analysis-services/tmdl/tmdl-scripts) — TMDL command syntax used by tooling and the TMDL view to apply object changes (the same commands the Power BI Desktop TMDL view emits).
- [Work with TMDL view in Power BI Desktop](https://learn.microsoft.com/power-bi/transform-model/desktop-tmdl-view) — Desktop's in-app TMDL editor: scripting objects, multi-tab workflow, object renaming and how `sourceColumn` interacts with Power Query queries.
- [Configure string indexing in Power BI semantic models (preview)](https://learn.microsoft.com/analysis-services/azure-analysis-services/string-indexing?view=power-bi-premium-current) — the `stringIndexingBehavior` column property: its four values, CL 1707, supported storage modes, the XMLA-only `indexes` refresh.
- [Configure full-text indexing in Power BI semantic models (preview)](https://learn.microsoft.com/analysis-services/azure-analysis-services/full-text-indexing?view=power-bi-premium-current) — the `fullTextIndexingBehavior` column property behind `TEXTCONTAINS` and `TEXTSIMILARITY`: CL 1708, no `auto`, what turning it off breaks.

### Power BI Project (PBIP) and semantic model files

- [Power BI Desktop project semantic model folder](https://learn.microsoft.com/power-bi/developer/projects/projects-dataset) — PBIP layout: `definition/` folder structure (TMDL format; replaces `model.bim`), `definition.pbism` versions, external editing flow, TMDL errors on open.
- [Power BI Desktop project overview](https://learn.microsoft.com/power-bi/developer/projects/projects-overview) — broader PBIP project layout (semantic model + report folders), supported write operations outside Desktop.
- [SemanticModel definition (Fabric REST item)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/semantic-model-definition) — definition envelope used by `createItemWithDefinition` / `getDefinition` / `updateDefinition`. TMDL vs TMSL is mutually exclusive at the item level. Pair with [definition-api.md](definition-api.md).

### Calculation groups

- [Calculation groups (Analysis Services reference)](https://learn.microsoft.com/analysis-services/tabular-models/calculation-groups) — concept reference, calc-item ordering, selection expressions (`multipleOrEmptySelectionExpression`, `noSelectionExpression`), the `selectionExpressionBehavior` model setting.
- [Create calculation groups in Power BI](https://learn.microsoft.com/power-bi/transform-model/calculation-groups) — Power BI-specific authoring guidance, TMDL view path, the `discourageImplicitMeasures` requirement.

### Direct Lake

- [Direct Lake overview](https://learn.microsoft.com/fabric/fundamentals/direct-lake-overview) — concept, the two flavors (Direct Lake on OneLake vs Direct Lake on SQL endpoint), considerations and limitations, fallback behavior.
- [Understand Direct Lake query performance](https://learn.microsoft.com/fabric/fundamentals/direct-lake-understand-storage) — Delta table tuning (V-Order, file size, row groups) for transcoding and query speed.
- [Integrate Direct Lake security](https://learn.microsoft.com/fabric/fundamentals/direct-lake-security-integration) — workspace-role / item-level / OneLake security alignment, SSO vs fixed identity, OLS / RLS interaction.

### DAX (for measures, calculated columns, RLS)

- [DAX overview](https://learn.microsoft.com/dax/dax-overview) — language reference: measures, calculated columns, calculated tables, row-level security formulas.
- [DAX queries](https://learn.microsoft.com/dax/dax-queries) — `EVALUATE` syntax for testing measures and calc items.

### Sister formats and underlying object model

- [TMSL reference](https://learn.microsoft.com/analysis-services/tmsl/tabular-model-scripting-language-tmsl-reference) — the JSON-based predecessor format. PBIP files using TMSL store as `model.bim`. Useful when reading legacy models or porting to TMDL.
- [Tabular Object Model (TOM) introduction](https://learn.microsoft.com/analysis-services/tom/introduction-to-the-tabular-object-model-tom-in-analysis-services-amo) — the .NET object model TMDL maps onto. Every TMDL property name and type aligns with a TOM property; the BIM ↔ TMDL conversion procedure above relies on this mapping.
- [Roles in Analysis Services tabular models](https://learn.microsoft.com/analysis-services/tabular-models/roles-ssas-tabular) — role authoring, `tablePermission` filter syntax, RLS context.

### Guidance and ecosystem

- [Power BI implementation planning — develop content and manage changes](https://learn.microsoft.com/power-bi/guidance/powerbi-implementation-planning-content-lifecycle-management-develop-manage) — when to use TMDL vs TMSL for source control, dev workflow patterns, multi-developer collaboration.
- [TMDL Visual Studio Code extension (Microsoft)](https://marketplace.visualstudio.com/items?itemName=analysis-services.TMDL) — official Microsoft VS Code extension for editing TMDL files outside Desktop. Provides syntax highlighting, autocomplete, and validation. Note: this is a Visual Studio Marketplace link, not Learn.
