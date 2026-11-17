# SQL analytics endpoint: definition and REST

A SQL analytics endpoint's REST operations beyond the generic item set,
chiefly the metadata refresh. Generic CRUD, long-running operations and
pagination are `rest-api`'s, § Long-Running Operations. The
warehouse item is [warehouse-api.md](warehouse-api.md)'s.

| | |
| --- | --- |
| REST `type` | `SQLEndpoint`, under `/workspaces/{ws}/sqlEndpoints/{id}` |
| Git folder | none of its own: an endpoint is a child of a lakehouse, warehouse or mirrored database, and the preview that versions its definition as a DacFx project has no dedicated Learn page ([platform-features.md](platform-features.md) § "Source Control and CI/CD") |
| Learn definition | none found (searched 2026-10-20) |
| Spec folder | [`sqlEndpoint/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/sqlEndpoint): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `a96c37a`, 2026-10-20 (folder last changed `8baaa4c`, 2026-09-15): 6 operations, 5 beyond the generic list |

## Definition

None in the spec: the folder has no definition type and no
`getDefinition` or `updateDefinition`, and Learn's *SQL Endpoint Items*
group lists only the connection string, the list and the refresh (read
2026-10-20). What the endpoint's CI/CD preview serializes is unmeasured
beyond [platform-features.md](platform-features.md)'s "What's New row
only" caveat. An endpoint is made by its parent item, not by a create
call.

## REST beyond the generic set

Under `https://api.fabric.microsoft.com/v1/workspaces/{ws}/sqlEndpoints/{id}/`
unless the path tail is absolute. The table is `spec-ops.py`'s,
at the SHA above, with *On Learn* filled from Learn's
*Items* and *SQL Audit Settings* groups (read 2026-10-20) and *Measured*
from this skill's files, none of which records one of these calls.

| Method | Path tail | Does | Body | Flags | On Learn | Measured |
| --- | --- | --- | --- | --- | --- | --- |
| `POST` | `/workspaces/{workspaceId}/sqlEndpoints/{sqlEndpointId}/refreshMetadata` | Refreshes tables within a SQL analytics endpoint | `timeout`, `recreateTables`, `tables` | LRO | yes | no |
| `GET` | `/workspaces/{workspaceId}/sqlEndpoints/{sqlEndpointId}/connectionString` | Returns the SQL connection string of the specified warehouse | | | yes | no |
| `GET` | `settings/sqlAudit` | Returns the settings associated with the SQL endpoint | | | yes | no |
| `PATCH` | `settings/sqlAudit` | Update settings associated with the SQL endpoint | `state`, `retentionDays`, `predicateExpression` | | yes | no |
| `POST` | `settings/sqlAudit/setAuditActionsAndGroups` | Update the audit actions and groups for this SQL endpoint | | | yes | no |

**`refreshMetadata` is the one worth knowing.** It refreshes the
endpoint's tables on demand (Learn: "Refreshes tables within a SQL
analytics endpoint"). The body, all optional (spec, read 2026-10-20):

| Field | Does |
| --- | --- |
| `timeout` | how long the request may run before timing out; 15 minutes by default, 24 hours at most |
| `recreateTables` | `true` drops and recreates the tables from their source definitions, to clear an inconsistency; with `tables`, the reset covers only those tables; `false` by default |
| `tables` | a list of `{ schema, tableNames }` to refresh only those; the schema must not be a reserved system schema |

With no body it refreshes every table. A `200` carries a `value` list, one
entry per table: `tableName` (as `schema.table`), `startDateTime`,
`endDateTime`, `status` (`Success` in the examples) and
`lastSuccessfulSyncDateTime`. The spec's examples are four: all tables,
selected tables, `recreateTables` with selected tables, and user-defined
schemas. The operation is flagged long-running, so a `202` is polled as
`rest-api` § Long-Running Operations says. Unmeasured here.

**`recreateTables` drops and recreates the endpoint's tables**, by the
spec's own wording. What that does to objects defined on them in the
endpoint (permissions, statistics) is not documented and unmeasured:
check on a non-production endpoint first.

Time travel on the endpoint is gated on the *New metadata sync* setting
([time-travel-and-recovery.md](time-travel-and-recovery.md)); no source
here says whether the REST refresh interacts with it.

## Measured deltas, and where to look next

None recorded. When this file runs out, read the spec's `swagger.json`
and the operation's `examples/` file, then Learn's REST group pages.
Re-read the spec from the SHA above: its commits are weekly, "Updating
swagger files".
