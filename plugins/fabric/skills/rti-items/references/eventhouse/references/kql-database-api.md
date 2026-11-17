# KQL database: definition and REST

A KQL database's definition shape, its create payload and the REST
operations it has beyond the generic item set. Generic CRUD,
`getDefinition` and `updateDefinition`, long-running operations and
pagination are `rest-api`'s, § Definition APIs and § Long-Running
Operations; the query endpoint is
[programmatic-access.md](programmatic-access.md)'s.

| | |
| --- | --- |
| REST `type` | `KQLDatabase`, under `/workspaces/{ws}/kqlDatabases/{id}` |
| Git folder | `<display name>.KQLDatabase/`, or nested as `<eventhouse>.Eventhouse/.children/<display name>.KQLDatabase/` (the `fabric-git-serialization` rule) |
| Learn definition | [KQL Database definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/kql-database-definition) |
| Spec folder | [`kqlDatabase/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/kqlDatabase): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `a96c37a`, 2026-10-20: 11 operations |

## Definition

One format, `JSON`. The parts:

| Path | Required | Holds |
| --- | --- | --- |
| `DatabaseProperties.json` | yes | `databaseType`, `parentEventhouseItemId`, and the OneLake caching and standard storage periods, as ISO 8601 spans |
| `DatabaseSchema.kql` | no | a KQL script of management commands, run on create, on update and on a Git sync |
| `.platform` | no | the item's metadata; `getDefinition` always returns it, and `updateDefinition` reads it only with `?updateMetadata=true` |

The properties' table is on Learn's definition page.

**`DatabaseSchema.kql` runs in two situations that are easy to
conflate**: at deploy time for a REST create or update, and "when
syncing to your Fabric Workspace" under Git integration. Use it to seed
tables, materialized views, functions and ingestion mappings, as
`.create-merge table MyLogs (...)` blocks.

Under Git integration the supported commands are a closed list: table
*create-or-merge*; function, materialized view and ingestion mapping
*create-or-alter*; table update policy and column encoding policy
*alter*. **No drop and no rename appear anywhere in it**, so Git →
portal is additive-only and a subtraction cannot be represented at all.
The branching consequences, and the recreate-as-empty-tables corollary
after a live rename, are in the `fabric-git-serialization` rule.

## Creating one

`POST /workspaces/{ws}/kqlDatabases` takes **`creationPayload` or
`definition`, never both**, and answers `201` or `202`. The payload's
`databaseType` picks the shape, and both shapes need
`parentEventhouseItemId`:

| `databaseType` | Also takes | Makes |
| --- | --- | --- |
| `ReadWrite` | nothing | a database of its own |
| `Shortcut` | `sourceClusterUri` and `sourceDatabaseName`, or `invitationToken` alone | a read-only follower of a database in an eventhouse or an Azure Data Explorer cluster; to follow a KQL database in Fabric, `sourceDatabaseName` alone, a GUID in Learn's example, as a Fabric database's engine name is (`eventhouse.md` § Monitoring) |

**A follower is made only by `creationPayload`.** Learn's definition
page says `DatabaseProperties.json`'s `databaseType` "currently only
ReadWrite is supported", while the create page's examples make a
`Shortcut` database each way (both read 2026-10-20). Learn's create page
carries all five examples; the spec's `examples/` holds the same.

## Git is not the live definition

`parentEventhouseItemId` is the eventhouse's runtime id live and its
logicalId in Git, and `.platform`'s `logicalId` is all zeros live (each
seen once, 2026-10-12; `rest-api` § Definition APIs). Normalize
both before diffing a live database against its folder. A synced folder
also holds `EmbeddedRealTimeQueryset.json`, which Learn's parts table
does not list; whether `getDefinition` returns it is unmeasured.

## REST beyond the generic set

Under `https://api.fabric.microsoft.com/v1/workspaces/{ws}/kqlDatabases/{id}/`:
Learn's *Table Shortcuts* group, a shortcut being a OneLake shortcut
the database queries as an external table. The table is `spec-ops.py`'s,
at the SHA above, with *On Learn* and *Measured*
filled in.

| Method | Path tail | Does | Body | Flags | On Learn | Measured |
| --- | --- | --- | --- | --- | --- | --- |
| `GET` | `shortcuts` | Returns a list of all table shortcuts under a database | | | yes | no |
| `POST` | `shortcuts` | Creates a new table shortcut under a database | `name`, `enableQueryAcceleration`, `target` | LRO | yes | no |
| `GET` | `shortcuts/{shortcutName}` | Returns the properties of a table shortcut under a database | | | yes | no |
| `DELETE` | `shortcuts/{shortcutName}` | Deletes a table shortcut under a database | | | yes | no |

## Measured deltas, and where to look next

What a create does past its response is measured in `eventhouse.md`: Fabric
sets a database-level streaming ingestion policy on a database made by
REST, Git sync or a deployment pipeline (§ Ingestion), and a deployment
pipeline applies the schema as `.create-merge` would (§ Schema
Evolution).

When this file runs out, read the spec's `swagger.json` and the
operation's `examples/` file, then Learn. Re-read the spec from the SHA
above: its commits are weekly, "Updating swagger files".
