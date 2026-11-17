# SQL database: definition and REST

A SQL database's definition formats and parts, its create payload, and
the REST operations it has beyond the generic item set. Generic CRUD,
`getDefinition` and `updateDefinition`, long-running operations and
pagination are `rest-api`'s, § Definition APIs and § Long-Running
Operations. The T-SQL surface, security and mirroring behaviour are
[sql-database.md](../sql-database.md)'s and [REFERENCE.md](REFERENCE.md)'s.

| | |
| --- | --- |
| REST `type` | `SQLDatabase`, under `/workspaces/{ws}/sqlDatabases/{id}` |
| Git folder | `<display name>.SQLDatabase/`, a SQL project (`.sqlproj` and object scripts, organised by schema and object type) |
| Learn definition | [SQL database definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/sql-database-definition) |
| Spec folder | [`sqlDatabase/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/sqlDatabase): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `a96c37a`, 2026-10-20 (folder last changed the same commit): 13 operations, 6 beyond the generic seven |

## Definition

Two formats, chosen by the `format` query parameter of `getDefinition`
(Learn's page and the spec, read 2026-10-20): **`dacpac`, the default when
none is sent**, and `sqlproj`. A create or update body names the format in
`definition.format` (the spec types it as a string beside `parts`).

| Format | Part path | Required | Holds |
| --- | --- | --- | --- |
| `dacpac` | `sqldb.dacpac` | yes | the compiled database model, which the service diffs against the database declaratively |
| `sqlproj` | `sqldb.sqlproj` | yes | the Microsoft.Build.Sql project file; only one per definition |
| `sqlproj` | `**/*.sql` | no | object scripts, e.g. `dbo/Tables/Table1.sql`; everything the project does not exclude |
| `sqlproj` | `.sharedqueries/*.sql` | no | queries deployed as shared queries; excluded from the project and the build |
| both | `.platform` | no | the item's `.platform` details |

Learn's property tables and payload examples are the page above; they are
not transcribed here. Two spellings to hold apart:

- **The part is `sqldb.dacpac` on Learn's page, but `definition.dacpac`
  in the spec's `GetSQLDatabaseDefinition` and
  `CreateSQLDatabaseWithDefinition` examples** (both read 2026-10-20).
  Which the live service accepts or returns is unmeasured.
- **`.sharedqueries` is lowercase in the REST definition** (Learn's page,
  read 2026-10-20); [REFERENCE.md](REFERENCE.md) § "Source control,
  SqlPackage, CI/CD" records the Git folder as `.sharedQueries` for a
  SQL database. Whether the two differ, or only one source is mistyped,
  is unmeasured.

Create can carry a `definition` instead of a `creationPayload`: the
spec's `CreateSQLDatabaseWithDefinition` example sends one alone
(whether both together are refused is unmeasured).

## Git is not the live definition

Unmeasured. The Git folder is a `.sqlproj` project that Fabric generates
and rewrites on commit ([REFERENCE.md](REFERENCE.md) § "Source control,
SqlPackage, CI/CD"); what `getDefinition?format=sqlproj` returns beyond or
short of that folder, and whether `dacpac` (its default) carries anything
the project does not, nobody has run here.

## Creating one

`POST /workspaces/{ws}/sqlDatabases` answers `201` or `202` (a
long-running operation; the spec's example gives `Location`,
`x-ms-operation-id` and `Retry-After: 30`). `creationPayload` is
discriminated by `creationMode` (the enum is open, "additional
CreationMode types may be added over time"):

| `creationMode` | Fields | Notes |
| --- | --- | --- |
| `New` | `backupRetentionDays` (1 to 35), `collation` | the default; the only mode that takes them |
| `Restore` | `sourceDatabaseReference` (`referenceType: ById`, `itemId`, `workspaceId`), `restorePointInTime` | both required, nothing else accepted |
| `RestoreDeletedDatabase` | `restorableDeletedDatabaseName`, `restorePointInTime` | both required, nothing else accepted; the spec marks it **preview** |

`restorePointInTime` is UTC, `YYYY-MM-DDTHH:mm:ssZ`. All from the spec,
read 2026-10-20 and unmeasured. [REFERENCE.md](REFERENCE.md) § "Backup
and restore" has the retention default and the restore limits Learn gives.

## REST beyond the generic set

Under `https://api.fabric.microsoft.com/v1/workspaces/{ws}/sqlDatabases/{id}/`
unless the path tail is absolute. The table is `spec-ops.py`'s,
at the SHA above, with *On Learn* filled from Learn's
*Items*, *Mirroring* and, for audit, the *SQL Audit Settings* group and
its article (read 2026-10-20), and *Measured* from this skill's files,
none of which records one of these calls.

| Method | Path tail | Does | Body | Flags | On Learn | Measured |
| --- | --- | --- | --- | --- | --- | --- |
| `POST` | `startMirroring` | Starts the mirroring of the specified SQL database | | | yes | no |
| `POST` | `stopMirroring` | Stops the mirroring of the specified SQL database | | | yes | no |
| `POST` | `revalidateCMK` | Revalidate Customer-Managed Key (CMK) of the specified SQL database | | LRO | yes | no |
| `GET` | `settings/sqlAudit` | Gets the auditing settings on the specified SQL database | | | yes | no |
| `PATCH` | `settings/sqlAudit` | Updates the auditing settings on the specified SQL database | `state`, `retentionDays`, `auditActionsAndGroups`, `predicateExpression` | | yes | no |
| `GET` | `/workspaces/{workspaceId}/sqlDatabases/restorableDeletedDatabases` | Gets the list of restorable deleted databases in the workspace | | preview | yes | no |

**Mirroring.** Learn says mirroring to OneLake runs by default and gives
one reason to stop it: a clustered columnstore index cannot be created on
an existing table while it runs, so stop, create the index, then start
again, and that table is then not mirrored (Learn's *Start and stop SQL
database mirroring* and *Limitations for Fabric SQL database mirroring*,
read 2026-10-20). Unlike the mirrored database item, the SQL database
has no status operation in the spec.

**Audit.** Learn's REST audit article lists `auditActionsAndGroups`
(default `BATCH_COMPLETED_GROUP`, `FAILED_DATABASE_AUTHENTICATION_GROUP`,
`SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP`), `predicateExpression`,
`retentionDays` (`0` is indefinite), `state` (`Enabled` or `Disabled`) and
a read-only `storageEndpoint`; it advises a `GET` before every `PATCH`
(read 2026-10-20). Unlike the warehouse's, there is no
`setAuditActionsAndGroups` operation: the groups ride on the `PATCH`.

**Delete takes `hardDelete`.** `DELETE .../sqlDatabases/{id}?hardDelete=true`
deletes permanently; omitted or `false`, the item is soft-deleted where
the type supports it (spec, read 2026-10-20; the operation's Learn page
was not read).

## Measured deltas, and where to look next

None recorded. When this file runs out, read the spec's `swagger.json`
and the operation's `examples/` file, then Learn's REST group pages.
Re-read the spec from the SHA above: its commits are weekly, "Updating
swagger files".
