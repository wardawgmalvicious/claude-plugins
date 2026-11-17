# Lakehouse: definition, create payload and REST

A lakehouse's definition parts, its create payload and the REST
operations it has beyond the generic item set. Generic CRUD,
`getDefinition` and `updateDefinition`, long-running operations and
pagination are `rest-api`'s, § Definition APIs and § Long-Running
Operations.

| | |
| --- | --- |
| REST `type` | `Lakehouse`, under `/workspaces/{ws}/lakehouses/{id}` |
| Git folder | `<display name>.Lakehouse/` |
| Learn definition | [Lakehouse definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/lakehouse-definition) |
| Spec folder | [`lakehouse/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/lakehouse): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `a96c37a`, 2026-10-20: 23 operations |

## Definition

One format, `LakehouseDefinitionV1`, which Learn says is the default when
`format` is omitted (read 2026-10-20, unmeasured). The parts:

| Path | Required | Holds |
| --- | --- | --- |
| `lakehouse.metadata.json` | yes | the lakehouse's properties: `defaultSchema`, `"dbo"` in Learn's example |
| `shortcuts.metadata.json` | no | an array of the OneLake shortcuts |
| `data-access-roles.json` | no | OneLake data access roles; respected only when `alm.settings.json` enables `DataAccessRoles`, which is off by default |
| `alm.settings.json` | no | which object types Git and deployment pipelines track: `Shortcuts` (on by default, with a `Shortcuts.<type>` sub-switch each) and `DataAccessRoles` |
| `.platform` | no | the item's metadata; `getDefinition` always returns it, and `updateDefinition` reads it only with `?updateMetadata=true` |

Each part's properties are in Learn's tables on the definition page.

**Shortcuts as definition payload**: when authoring a Lakehouse via REST,
`shortcuts.metadata.json` is an array of `{name, path, target}` objects.
Supported `target.type` values: `OneLake`, `AdlsGen2`, `AmazonS3`,
`GoogleCloudStorage`, `S3Compatible`, `Dataverse`. Each target type has its
own connection properties. Learn's definition page, read 2026-10-20, also
lists `AzureBlobStorage` and `OneDriveSharePoint`, each with a
`connectionId`, a `location` and a `subpath`. For a `OneLake` target, empty
GUIDs in `itemId` and `workspaceId` mean the lakehouse and workspace being
created or updated.

## Creating one

`POST /workspaces/{ws}/lakehouses` (or `/items`, with `type` `Lakehouse`)
answers `201` or `202`, and takes `creationPayload` or `definition`.

**`enableSchemas` is set at lakehouse creation time only** — cannot be
retrofitted. Without it the lakehouse only has the default `dbo` schema and
you must recreate to gain named schemas. Set via
`creationPayload: { "enableSchemas": true }` on
`POST /workspaces/{ws}/items`. The spec types `LakehouseCreationPayload`
with `enableSchemas` required, `true` the only value allowed, and calls
the property required "due to the schema enabled lakehouse being in
preview", which may go at GA (read 2026-10-20); its `examples/` holds a
create with it. Schema naming, 3-part names and what a schema-enabled
lakehouse means for Spark are `spark.md` § Lakehouse Setup.

## Git is not the live definition

Unmeasured. In `shortcuts.metadata.json` a OneLake target's empty GUIDs
stand for the current item and workspace on create and update (Learn,
above); whether a live `getDefinition` returns them or runtime ids is
unread. `rest-api` § Definition APIs has what `.platform` holds live.

## REST beyond the generic set

Under `https://api.fabric.microsoft.com/v1/workspaces/{ws}/lakehouses/{id}/`.
Learn's groups: *Tables*, *Background Jobs*, *Materialized Lake Views* and
*Livy Sessions*. The table is `spec-ops.py`'s, at the
SHA above, with *On Learn* and *Measured* filled in.

- **The MLV operations** (the `refreshMaterializedLakeViews` jobs and
  `mlvexecutiondefinitions`) have their bodies, status codes and two
  behaviours (a PATCH merges, a delete removes the definition's schedules)
  in [mlv.md](mlv.md) § REST API (job scheduler); that file records them
  from Learn's samples, undated. Its paths write the job type as
  `RefreshMaterializedLakeViews` where the spec's path says
  `refreshMaterializedLakeViews`.
- **The Livy listings** are measured in
  [spark-monitoring.md](spark-monitoring.md), and the logs behind a
  session are [spark-monitoring-apis.md](spark-monitoring-apis.md)'s.

| Method | Path tail | Does | Body | Flags | On Learn | Measured |
| --- | --- | --- | --- | --- | --- | --- |
| `GET` | `tables` | Returns a list of lakehouse Tables | | | yes | no |
| `POST` | `tables/{tableName}/load` | Starts a load table operation and returns the operation status URL in the response location header | `relativePath`, `pathType`, `fileExtension`, `mode`, `recursive`, `formatOptions` | LRO | yes | no |
| `POST` | `schemas/{schemaName}/tables/{tableName}/load?beta=true` | Starts a load table operation for a table within a schema enabled lakehouse and returns the operation status URL in the response location header | `relativePath`, `pathType`, `fileExtension`, `mode`, `recursive`, `formatOptions` | LRO, beta | yes | no |
| `POST` | `jobs/tableMaintenance/instances` | Run on-demand [table maintenance](/fabric/data-engineering/lakehouse-table-maintenance) job instance | `executionData` | LRO | yes | no |
| `POST` | `jobs/refreshMaterializedLakeViews/schedules` | Create a new Refresh MaterializedLakeViews schedule for a lakehouse | `enabled`, `configuration`, `executionData` | | yes | no |
| `GET` | `livySessions` | Returns a list of livy sessions from the specified item identifier | | | yes | 2026-08-17 |
| `GET` | `livySessions?beta=true` | Returns a list of livy sessions from the specified item identifier (beta) | | beta | yes | no |
| `GET` | `livySessions/{livyId}` | Returns properties of the specified livy session | | | yes | no |
| `POST` | `jobs/refreshMaterializedLakeViews/instances` | Run on-demand [Refresh MaterializedLakeViews](/fabric/data-engineering/materialized-lake-views/refresh-materialized-lake-view) job instance | | LRO | yes | no |
| `PATCH` | `jobs/refreshMaterializedLakeViews/schedules/{scheduleId}` | Update an existing Refresh MaterializedLakeViews schedule for a lakehouse | `enabled`, `configuration`, `executionData` | | yes | no |
| `DELETE` | `jobs/refreshMaterializedLakeViews/schedules/{scheduleId}` | Delete an existing Refresh MaterializedLakeViews schedule for a lakehouse | | | yes | no |
| `GET` | `mlvexecutiondefinitions` | Returns a list of materialized lake views execution definitions for a lakehouse | | | yes | no |
| `POST` | `mlvexecutiondefinitions` | Creates a materialized lake views execution definition | `displayName`, `description`, `settings`, `currentLakehouseExecutionContext`, `extendedLineageExecutionContext` | | yes | no |
| `GET` | `mlvexecutiondefinitions/{mlvExecutionDefinitionId}` | Returns the specified materialized lake views execution definition | | | yes | no |
| `PATCH` | `mlvexecutiondefinitions/{mlvExecutionDefinitionId}` | Updates the specified materialized lake views execution definition | `displayName`, `description`, `settings`, `currentLakehouseExecutionContext`, `extendedLineageExecutionContext` | | yes | no |
| `DELETE` | `mlvexecutiondefinitions/{mlvExecutionDefinitionId}` | Deletes the specified materialized lake views execution definition | | | yes | no |

**`GET tables` and `POST tables/{tableName}/load` refuse a schema-enabled
lakehouse.** Learn says both return HTTP 400 there, error code
`UnsupportedOperationForSchemasEnabledLakehouse` (Learn, read 2026-11-07;
unmeasured). To load a table, use the schema-scoped `load?beta=true` row
above; to list one, use the OneLake table APIs for Delta, which
[Learn's Lakehouse management API
page](https://learn.microsoft.com/fabric/data-engineering/lakehouse-api)
points at.

## Measured deltas, and where to look next

None measured for the definition or the table operations. The
schema-enabled create rule above is the skill's earlier statement,
undated.

When this file runs out, read the spec's `swagger.json` and the
operation's `examples/` file, then Learn. Re-read the spec from the SHA
above: its commits are weekly, "Updating swagger files".
