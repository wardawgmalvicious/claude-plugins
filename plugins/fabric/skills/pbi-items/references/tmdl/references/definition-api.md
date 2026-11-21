# Semantic model: definition and REST

A semantic model's definition shape, the rules for sending it, and the
REST operations it has beyond the generic item set. Generic CRUD,
`getDefinition` and `updateDefinition` mechanics, long-running operations
and pagination are `rest-api`'s, § Definition APIs and §
Long-Running Operations. The three MCP servers that author or query a
model are [semantic-model-mcp.md](semantic-model-mcp.md)'s.

| | |
| --- | --- |
| REST `type` | `SemanticModel`, under `/workspaces/{ws}/semanticModels/{id}` |
| Git folder | `<display name>.SemanticModel/` |
| Learn definition | [SemanticModel definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/semantic-model-definition) |
| Learn REST | [Semantic Model Items](https://learn.microsoft.com/rest/api/fabric/semanticmodel/items) (8 operations, read 2026-10-20) |
| Spec folder | [`semanticModel/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/semanticModel): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `6f817cb`, 2026-11-03: 8 operations, one past the generic seven |

## Rules for the calls

- **Two audiences**: Fabric API (`api.fabric.microsoft.com`) for CRUD on definitions; Power BI API (`analysis.windows.net/powerbi/api`) for refresh, data sources, permissions
- **`updateDefinition` must include ALL parts** — modified AND unmodified. The API replaces the entire definition; omitting parts deletes them.
- **Send `.platform` only with `?updateMetadata=true`**, to change the
  model's name or description: `updateDefinition` ignores the part
  without the flag, and the flag without the part returns 400, as for
  every item type (`rest-api` § Definition APIs; measured 2026-11-16,
  § Measured deltas). Bulk Import's parts carry each item's `.platform`
  too
- **Base64-encode all TMDL content** in definition payloads
- **`getDefinition` is a POST** (not GET) — requires `--body '{}'`
- **Poll LRO to completion** — `createItemWithDefinition`, `getDefinition` and `updateDefinition` can each answer `202` instead of `200` (a create, `201`); branch on the status code, as rest-api says
- **A change that cannot keep the data needs `allowPurgeData`** —
  `updateDefinition` and a create with a definition take
  `"options": { "allowPurgeData": true }` beside `definition`. The
  default, `false`, refuses a change that requires clearing the model's
  data; `true` purges what cannot be kept, and the model needs a refresh
  afterwards (Learn's REST reference, [Update Semantic Model
  Definition](https://learn.microsoft.com/rest/api/fabric/semanticmodel/items/update-semantic-model-definition),
  read 2026-10-22)

## Definition

Two formats, never both in one model: `TMDL` (the default) and `TMSL`.
`getDefinition` takes it as the query parameter `?format=TMDL` or
`?format=TMSL`, case sensitive (spec, read 2026-10-20). The spec's own
create and update examples set no `format` on the body and name only
the part paths, so whether a body must carry it is unmeasured. The
parts, from Learn's definition page and `rest-api` § Definition
APIs:

| Path | Required | Holds |
| --- | --- | --- |
| `definition/database.tmdl` | TMDL | `database` declaration + `compatibilityLevel: 1702` |
| `definition/model.tmdl` | TMDL | Model properties + `ref` declarations for tables/roles/etc. |
| `definition/tables/<TableName>.tmdl` | TMDL | Per-table: measures, columns, partitions |
| `definition/` other files | no | `relationships.tmdl`, `expressions.tmdl`, `functions.tmdl`, `roles/`, `perspectives/`, `cultures/` |
| `model.bim` | TMSL, in place of `definition/` | the whole model as TMSL JSON; mutually exclusive with `definition/` |
| `definition.pbism` | yes | Semantic model connection settings (JSON): `version` and `settings` such as `qnaEnabled` |
| `diagramLayout.json` | no | the model diagram's metadata |
| `Copilot/` parts | no | listed in Learn's example (instructions, verified answers, schema, example prompts, settings), undescribed; see § Git is not the live definition |
| `.platform` | no | the item's metadata; see the rules above |

The properties' tables are on Learn's definition page, and the TMDL
objects' in [REFERENCE.md](REFERENCE.md). `definition.pbism`'s `version`
picks the format it allows: `1.0` TMSL only, `4.0` and later TMSL or
TMDL, `5.0` in Learn's example (the schema under
`microsoft/json-schemas`, § MS Learn link bundle).

`database.tmdl` starts with the `database` object declaration, not bare properties: a bare `compatibilityLevel:` fails with `InvalidLineType: Property!`.

## Git is not the live definition

Three differences are recorded for a semantic model, none a full diff of
a live `getDefinition` against a folder:

- **AI instructions** sit in `definition/cultures/<culture>.tmdl`, as the
  `CustomInstructions` key of `linguisticMetadata`, in Git and in
  `getDefinition`'s answer, with no `Copilot/` part there (2026-10-14).
  What writes Learn's `Copilot/Instructions/instructions.md` part is
  unverified. The evidence is in
  [ai-instructions.md](ai-instructions.md) § Testing and maintenance.
- **Verified answers** are stored in the model, yet Git integration, REST
  and deployment pipelines do not carry them (Learn, read 2026-10-08;
  [ai-instructions.md](ai-instructions.md) § Limitations).
- **Sensitivity labels** are no part of a definition, and an encrypted
  label needs usage rights to remove it before `getDefinition` answers
  (spec, read 2026-10-20).

A portal commit also adds `lineageTag`s to every object after an edit in
the service (`tmdl.md` § Syntax Rules). `.platform`'s `logicalId` is all
zeros live (`rest-api` § Definition APIs, seen once, 2026-10-12,
on another item type), and a REST-created model's read the same
(measured 2026-11-16, § Measured deltas); a portal-created model's is
unmeasured.
`getDefinition` needs read and write permission on the model, not read
alone (spec, read 2026-10-20).

## REST beyond the generic set

Under `https://api.fabric.microsoft.com/v1/workspaces/{ws}/semanticModels/{id}/`.
The table is the spec's, at the SHA above, with
*On Learn* and *Measured* filled in.

| Method | Path tail | Does | Body | Flags | On Learn | Measured |
| --- | --- | --- | --- | --- | --- | --- |
| `POST` | `bindConnection` | Binds a semantic model data source reference to a data connection | `connectionBinding` | | yes | no |

Per the spec, `bindConnection` answers `200`, not a long-running
operation; the caller must own the model; the same call **unbinds** a
reference (the spec has an unbind example); and it binds one reference
per request, so several references take several calls (read 2026-10-20).
Refresh, data-source and permission calls are the Power BI API's, not
this one's: rule 1 above.

### Create has three modes

Create Semantic Model takes only `displayName` as required, and has
three modes (spec at `6f817cb`; Learn's
[Create Semantic Model](https://learn.microsoft.com/rest/api/fabric/semanticmodel/items/create-semantic-model),
read 2026-11-07, says the same). `definition` and `creationPayload` are
mutually exclusive, and sending both fails with
`MutuallyExclusiveProperties`:

| Mode | Body | Makes |
| --- | --- | --- |
| Definition | `definition` | the model in the parts sent: `createItemWithDefinition`, rules above |
| Creation payload | `creationPayload.oneLakeTables` | a DirectLake model, its tables and columns inferred from the OneLake source |
| Neither | `displayName` only | an empty semantic model |

`oneLakeTables` is required inside `creationPayload`, holds at most 100
URLs, and takes either shape, mixed in one request and across
workspaces and data items:

```text
https://onelake.dfs.fabric.microsoft.com/{workspaceId}/{dataItemId}/Tables/{tableName}
https://onelake.dfs.fabric.microsoft.com/{workspaceId}/{dataItemId}/Tables/{schemaName}/{tableName}
```

The first is a table in the default `dbo` schema; the second names a
custom schema. Beyond the *contributor* workspace role, the caller needs
access to each source Lakehouse or data item, a cross-workspace one
too. A bad URL fails with `InvalidOneLakeTableUrl` and a repeated table
name with `DuplicateTableName`. Whether a `creationPayload` model is
Direct Lake on OneLake or on SQL, and what `getDefinition` returns for
it or for an empty model, is unmeasured.

## model.tmdl Required Properties

```tmdl
model Model
	culture: en-US
	defaultPowerBIDataSourceVersion: powerBI_V3
	discourageImplicitMeasures
```

`defaultPowerBIDataSourceVersion: powerBI_V3` is required for Import-mode models. Without it: `Import from JSON supported for V3 models only`.

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
- **Calculated columns / tables (April 2026 preview)**: Direct Lake on **OneLake** now supports unmaterialized calculated columns (and calculated tables that reference them). Direct Lake on **SQL** still does not. User-context-aware DAX (`USERCULTURE`, `USERPRINCIPALNAME`, `CUSTOMDATA`, etc.) requires `expressionContext: userContext` on the column. Authorable in **Power BI Desktop and web modeling**, without changing storage mode. See [REFERENCE.md](REFERENCE.md) for the storage-mode × Expression-Context support matrix.

## Measured deltas, and where to look next

What a semantic model's definition does past Learn's page is measured in
other files: a first refresh before a Git-synced Direct Lake model
answers (2026-10-07) and the lineage tags a portal commit adds
(2026-10-07) are `tmdl.md`'s; the AI instructions' place in
`getDefinition` (2026-10-14) is
[ai-instructions.md](ai-instructions.md)'s; the offline
`TmdlSerializer` load (2026-10-08) is [REFERENCE.md](REFERENCE.md)'s,
§ BIM ↔ TMDL Conversion. Nothing in this file is a measurement of
`bindConnection` or of `getDefinition?format=`.

**A semantic model takes `.platform` as every item type does**
(measured 2026-11-16, against Learn's [SemanticModel
definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/semantic-model-definition),
which lists no `.platform` part, and its item definition overview,
which gives the general rule). On a model created by
`POST /semanticModels` with `definition.pbism`, three TMDL parts and no
`.platform`,
`getDefinition` returned a fifth, `.platform`, its `logicalId` all
zeros. `updateDefinition` with all five parts and a `.platform` naming
another `displayName` and `description` answered `202`, operation
`Succeeded`, and left both unchanged; the same call with
`?updateMetadata=true` answered `202`, `Succeeded`, and set both. The
earlier "never include `.platform`; it causes errors" cited nothing and
reproduced no error.

When this file runs out, read the spec's `swagger.json` and the
operation's `examples/` file, then Learn. Re-read the spec from the SHA
above: its commits are weekly, "Updating swagger files".

## Reference

- Microsoft Learn: [Item definition overview (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/item-definition-overview)
- Microsoft Learn: [SemanticModel definition envelope](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/semantic-model-definition)
- Microsoft Learn: [Develop Direct Lake semantic models (TMDL partition mode)](https://learn.microsoft.com/fabric/fundamentals/direct-lake-develop)
- Comprehensive MS Learn link bundle (definition envelope / REST CRUD / TMDL language / required parts / Direct Lake configuration / refresh APIs): [§ MS Learn link bundle](#ms-learn-link-bundle), below

## MS Learn link bundle

Curated set of Microsoft Learn pages relevant to the Fabric Semantic Model Definition API — `createItemWithDefinition`, `getDefinition`, `updateDefinition`, the TMDL/TMSL definition envelope, and the Direct Lake partition configuration this file highlights.

The 3 highest-leverage entry points (Item Definition overview, Semantic Model definition envelope, Direct Lake develop/manage) are also linked in § Reference above for in-context use; this section holds the comprehensive set.

**Note on docs split:** The Fabric REST + definition envelope lives under `learn.microsoft.com/rest/api/fabric/`. TMDL language semantics and TOM/AMO authoring live under `learn.microsoft.com/analysis-services/tmdl/`. The Direct Lake concepts live under `learn.microsoft.com/fabric/fundamentals/direct-lake-*`. All three branches are linked.

### Definition envelope and REST API

- [Item definition overview](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/item-definition-overview) — concept: definition-based vs non-definition APIs (Get / Update / Create with Definition), the `.platform` part rules, the `?updateMetadata=true` requirement to *modify* `.platform` via Update Item Definition. Confirms platform file is *only* respected on Update if the URL parameter is set.
- [SemanticModel definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/semantic-model-definition) — full part list (`definition/` for TMDL, `model.bim` for TMSL — mutually exclusive; `definition.pbism` settings; `diagramLayout.json` optional) plus the `definition.pbism` schema example (`version: "5.0"`, `qnaEnabled` setting).
- [Get Item Definition (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/core/items/get-item-definition) — POST-with-empty-body endpoint; LRO behavior; returns base64 parts.
- [Update Item Definition (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/core/items/update-item-definition) — REPLACES entire definition (omitted parts are deleted); `?updateMetadata=true` flag for `.platform`.
- [Create Item with Definition (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/core/items/create-item) — combined POST that creates the item and seeds its definition in one LRO.
- [Bulk Import Item Definitions](https://learn.microsoft.com/rest/api/fabric/core/items/bulk-import-item-definitions) / Bulk Export — GA (September 2026), except Import's `options.deploymentPlan`, a beta (`?beta=true`, `ByLogicalId` only for now; read 2026-11-07); multi-item versions for migration scenarios. Bulk import takes SemanticModel parts, and `.platform` parts with them.
- [Long-running operations (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/articles/long-running-operation) — 202 → poll `/operations/{id}` → `/result` pattern for all three definition APIs.

### Two audiences (Fabric API for definitions vs Power BI API for refresh)

- [Microsoft Fabric REST API — overview](https://learn.microsoft.com/rest/api/fabric/articles/) — `api.fabric.microsoft.com` audience.
- [Power BI REST API — refresh dataset](https://learn.microsoft.com/rest/api/power-bi/datasets/refresh-dataset) — `analysis.windows.net/powerbi/api` audience for refresh.
- [Power BI REST API — datasources / data source bindings](https://learn.microsoft.com/rest/api/power-bi/datasets/get-datasources) — Power BI audience for data-source operations.
- See `rest-api`'s `references/auth.md` for the full token-audience table and `az login` flow.

### TMDL language reference

- [TMDL overview](https://learn.microsoft.com/analysis-services/tmdl/tmdl-overview) — language semantics: tabs-only indentation, sections, default property syntax, multi-line expressions with the indented-block rule, the triple-backtick literal block, `///` for descriptions.
- [Get started with TMDL](https://learn.microsoft.com/analysis-services/tmdl/tmdl-how-to) — `TmdlSerializer` API: read TMDL into a TOM model and write back. The C#/PowerShell entry point.
- [TMDL scripts](https://learn.microsoft.com/analysis-services/tmdl/tmdl-scripts) — `createOrReplace` command verb syntax for partial-model deployment.
- [TMDL VS Code extension](https://marketplace.visualstudio.com/items?itemName=analysis-services.TMDL) — syntax highlighting + IntelliSense.
- See [tmdl.md](../tmdl.md) for the in-house authoring rules.

### Required parts in detail

- [TMSL Database object reference](https://learn.microsoft.com/analysis-services/tmsl/database-object-tmsl) — the `database` object whose declaration `database.tmdl` MUST start with (the "InvalidLineType: Property!" rule above).
- [`compatibilityLevel` property](https://learn.microsoft.com/analysis-services/tabular-models/compatibility-level-for-tabular-models-in-analysis-services) — 1604 minimum for Direct Lake, 1702+ for DAXLib, 1604+ for Calendar Column Groups. Required in `database.tmdl`.
- [Power BI Desktop project semantic model folder](https://learn.microsoft.com/power-bi/developer/projects/projects-dataset) — folder layout reference (`definition/`, `model.bim`, `definition.pbism`, `diagramLayout.json`, `.platform`). The same structure the REST API expects.
- [`definition.pbism` schema](https://github.com/microsoft/json-schemas/tree/main/fabric/item/semanticModel/definitionProperties) — version → format mapping (1.0 = TMSL only, 4.0+ = TMSL or TMDL, current = 5.0).

### Direct Lake partition configuration

- [Direct Lake overview](https://learn.microsoft.com/fabric/fundamentals/direct-lake-overview) — concept: framing, Direct Lake on SQL vs OneLake, comparison vs Import/DirectQuery (hybrid tables and model table partitions unsupported in **both** DL modes; calculated columns/tables unsupported on DL on **SQL** but supported on DL on **OneLake** — User Context only, preview, unmaterialized).
- [Develop Direct Lake semantic models](https://learn.microsoft.com/fabric/fundamentals/direct-lake-develop) — TMDL-level details: `compatibilityLevel >= 1604`, `mode: directLake` partition property, the shared expression that points to the data source. Direct Lake on OneLake uses `AzureStorage.DataLake(...)`; Direct Lake on SQL uses `Sql.Database(...)` or `OneLake.SqlAnalytics()`.
- [Direct Lake in Power BI Desktop — migrate Direct Lake on SQL → OneLake](https://learn.microsoft.com/fabric/fundamentals/direct-lake-power-bi-desktop#migrate-direct-lake-on-sql-semantic-models-to-direct-lake-on-onelake) — exact TMDL edits to swap the source expression: `Sql.Database(...)` → `AzureStorage.DataLake("https://onelake.dfs.fabric.microsoft.com/<wsId>/<lakehouseId>")`. Also documents the `schemaName` removal for non-schema lakehouses.
- [How Direct Lake works (framing, automatic updates, fallback)](https://learn.microsoft.com/fabric/fundamentals/direct-lake-how-it-works) — what a "refresh" actually does for a Direct Lake model.
- [Integrate Direct Lake security (OLS / RLS)](https://learn.microsoft.com/fabric/fundamentals/direct-lake-security-integration) — what's supported when; the cloud connection, SSO versus a fixed identity (a fixed identity isolates users from the source item), and OLS / RLS across layers.

### Refresh operations (Power BI audience, complementary to definition APIs)

- [Refresh datasets (Power BI REST)](https://learn.microsoft.com/rest/api/power-bi/datasets/refresh-dataset) — kick off a refresh after `updateDefinition`.
- [Get refresh history](https://learn.microsoft.com/rest/api/power-bi/datasets/get-refresh-history) — poll status.
- [Refresh policy / incremental refresh](https://learn.microsoft.com/power-bi/connect-data/incremental-refresh-overview) — for Import partitions.
- [Process operations via XMLA endpoint](https://learn.microsoft.com/fabric/enterprise/powerbi/service-premium-connect-tools) — alternative refresh path via XMLA (Power BI audience).

## See also

- [tmdl.md](../tmdl.md) — TMDL authoring rules at the file level
- [semantic-model-mcp.md](semantic-model-mcp.md) — the MCP servers that query or author the model
- rest-api skill — LRO polling pattern, runtime item ID vs logicalId, the 201-or-202 create pattern; Fabric vs Power BI audience selection in its `references/auth.md`; `fab export` / `fab import`, which wrap these APIs, in its `references/cli.md`
