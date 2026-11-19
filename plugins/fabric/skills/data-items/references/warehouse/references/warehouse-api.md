# Warehouse: definition and REST

A warehouse's create payload, what its definition is known to hold, and
the REST operations it has beyond the generic item set. Generic CRUD,
`getDefinition` and `updateDefinition`, long-running operations and
pagination are `rest-api`'s, § Definition APIs and § Long-Running
Operations. The SQL analytics endpoint is
[sql-endpoint-api.md](sql-endpoint-api.md)'s; the T-SQL surface is
[t-sql-surface.md](t-sql-surface.md)'s.

| | |
| --- | --- |
| REST `type` | `Warehouse`, under `/workspaces/{ws}/warehouses/{id}` |
| Git folder | `<display name>.Warehouse/`, a DacFx SQL project (`.sqlproj` and object scripts; the portal's byte behaviour is [git-serialization.md](../../git-serialization.md)'s) |
| Learn definition | [Warehouse definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/warehouse-definition) (ms.date 2026-03-09, updated 2026-10-28, read 2026-11-14): formats `dacpac` and `sqlproj`, the default; this URL returned nothing on 2026-10-20 |
| Spec folder | [`warehouse/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/warehouse): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `a96c37a`, 2026-10-20 (folder last changed `fdaf257`, 2026-10-13): 17 operations, 12 beyond the generic five |

## Definition

**Learn documents two formats, `sqlproj` and `dacpac`; no call has been
run here.** Learn's [Warehouse definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/warehouse-definition)
page (read 2026-11-14) says that with no format given, operations default
to `sqlproj`. Its parts, by format:

| Format | Part path | Required | Holds |
| --- | --- | --- | --- |
| `sqlproj` (default) | `sqldw.sqlproj` | yes | the Microsoft.Build.Sql project file, built to a `dacpac` and deployed; one `.sqlproj` per definition |
| `sqlproj` | `**/*.sql` | no | object scripts, by schema and object type (`dbo/Tables/Table1.sql`); all files the `.sqlproj` does not exclude |
| `sqlproj` | `.sharedqueries/*.sql` | no | shared queries, deployed to the database and shown in the editor; outside the build |
| `sqlproj` | `.platform` | no | the item's `PlatformDetails` JSON |
| `dacpac` | `sqldw.dacpac` | yes | the database model, deployed declaratively |
| `dacpac` | `.platform` | no | the item's `PlatformDetails` JSON |

The page has a payload example for each, every part `InlineBase64`.

The spec types a `WarehouseDefinition` as a free `format` string and a
list of parts (`path`, `payload`, `payloadType`) and names no path, so it
bounds nothing the page says. The folder has no `getDefinition` or
`updateDefinition` operation: Learn's *Warehouse Items* group lists only
create, delete, get, list, update and connection string (read
2026-10-20). Whether the generic `getDefinition` answers for a warehouse,
which format it returns, and whether create accepts a definition
(`creationPayload` is the spec's route, § Creating one) nobody has run
here.

What is known is the Git side, which holds the same project the sync
deploys. Its shape, by definition version (the item folder tells the
version, not `.platform`), is in
[platform-features.md](platform-features.md) § "Definition 2.0 and the
upgrade": `xmla.json` means 1.0, and a `.gitignore` beside the `.sqlproj`
means 2.0. What a sync does to a populated table is
[warehouse.md](../warehouse.md) § "Schema Evolution".

## Creating one

`POST /workspaces/{ws}/warehouses` answers `201` or `202` (a long-running
operation; the spec's example gives `Location`, `x-ms-operation-id` and
`Retry-After: 30`). The body takes `displayName`, and optionally
`description` (256 characters at most), `folderId`,
`sensitivityLabelSettings` and a `creationPayload`. Of `definition` and
`creationPayload` the spec's text says they can't be used together, and
the request type has no `definition` property; use `creationPayload`.

`creationPayload` has one field, **`collationType`**, required when the
payload is sent:

| Value | Means |
| --- | --- |
| `Latin1_General_100_BIN2_UTF8` | the default, case-sensitive |
| `Latin1_General_100_CI_AS_KS_WS_SC_UTF8` | case-insensitive |

The enum is open ("additional collations may be added over time"). Choose
it at create: [warehouse.md](../warehouse.md) § "Default Collation" has the
consequences, and
[platform-features.md](platform-features.md) the collation-mismatch
failure across Git and pipelines. Whether a collation can be changed
after create is unmeasured.

## REST beyond the generic set

Under `https://api.fabric.microsoft.com/v1/workspaces/{ws}/warehouses/{id}/`
unless the path tail is absolute. The table is `spec-ops.py`'s,
at the SHA above, with *On Learn* filled from Learn's
*Items*, *SQL Pools*, *SQL Audit Settings* and *Restore Points* groups
(all read 2026-10-20) and *Measured* from this skill's files, none of
which records one of these calls.

| Method | Path tail | Does | Body | Flags | On Learn | Measured |
| --- | --- | --- | --- | --- | --- | --- |
| `GET` | `/workspaces/{workspaceId}/warehouses/sqlPoolsConfiguration` | Gets the SQL Pools configuration in the specified workspace | | | yes | no |
| `PATCH` | `/workspaces/{workspaceId}/warehouses/sqlPoolsConfiguration` | Updates the SQL Pools configuration in the specified workspace | `customSQLPoolsEnabled`, `customSQLPools` | | yes | no |
| `GET` | `connectionString` | Returns the SQL connection string of the specified warehouse | | | yes | no |
| `GET` | `/workspaces/{workspaceId}/warehouses/{itemId}/settings/sqlAudit` | Returns the settings associated with the warehouse | | | yes | no |
| `PATCH` | `/workspaces/{workspaceId}/warehouses/{itemId}/settings/sqlAudit` | Update settings associated with the warehouse | `state`, `retentionDays`, `predicateExpression` | | yes | no |
| `POST` | `/workspaces/{workspaceId}/warehouses/{itemId}/settings/sqlAudit/setAuditActionsAndGroups` | Update the audit actions and groups for this warehouse | | | yes | no |
| `GET` | `restorePoints` | Returns all restore points for a warehouse | | | yes | no |
| `POST` | `restorePoints` | Creates a restore point for a warehouse at the current timestamp | `displayName`, `description` | LRO | yes | no |
| `GET` | `restorePoints/{restorePointId}` | Returns the properties of a restore point specified for a warehouse | | | yes | no |
| `PATCH` | `restorePoints/{restorePointId}` | Updates an existing restore point by renaming the name or description of it | `displayName`, `description` | | yes | no |
| `DELETE` | `restorePoints/{restorePointId}` | Deletes a restore point specified for a warehouse | | | yes | no |
| `POST` | `restorePoints/{restorePointId}/restore` | Restores a warehouse in-place to the restore point specified | | LRO | yes | no |

Three of these are workspace-wide or item-wide settings rather than
warehouse operations: the SQL pools configuration is per workspace, and
Learn's custom SQL pools pages say it covers warehouses and SQL analytics
endpoints alike, at most eight pools a workspace (read 2026-10-20), and
how to classify and watch them is [monitoring.md](monitoring.md) § SQL
Pool Pressure; `sqlAudit` has an endpoint twin
([sql-endpoint-api.md](sql-endpoint-api.md)).

**Restore points and the retention window.** Learn's data retention page
says the system makes a restore point every eight hours and keeps both
those and user-defined ones for the configured retention period, 1 to
120 days, 30 by default (read 2026-10-20). That window is the same one
[time-travel-and-recovery.md](time-travel-and-recovery.md) gives for
time travel, not the Recycle bin's.

**Delete takes `hardDelete`.** `DELETE .../warehouses/{id}?hardDelete=true`
deletes permanently with no recovery; omitted or `false`, the item is
soft-deleted where the type supports it, which is what the Recycle bin
recovers ([time-travel-and-recovery.md](time-travel-and-recovery.md) §
"Dropped warehouse recovery"). The parameter is in the spec and its
example only; the operation's Learn page was not read.

## Warehouse snapshots

A snapshot has a spec folder of its own, `warehouseSnapshot/`
(`24045be`, 2026-03-19), whose five operations are all generic; see [time-travel-and-recovery.md](time-travel-and-recovery.md) §
"Warehouse Snapshots (GA)" for what one is. Its create takes
`creationPayload` with a required `parentWarehouseId` and an optional
`snapshotDateTime`, and its update takes `snapshotDateTime` to roll the
snapshot forward (spec, read 2026-10-20; unmeasured).

## Measured deltas, and where to look next

None recorded. When this file runs out, read the spec's `swagger.json`
and the operation's `examples/` file, then Learn's REST group pages.
Re-read the spec from the SHA above: its commits are weekly, "Updating
swagger files".
