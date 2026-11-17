# Real-Time Dashboard: definition and REST

A Real-Time Dashboard's definition shape, how Git and `getDefinition`
differ, and the REST operations it has beyond the generic item set:
none. Generic CRUD, `getDefinition` and `updateDefinition`,
long-running operations and pagination are `rest-api`'s, §
Definition APIs and § Long-Running Operations. The file's contents
(anatomy, wiring rules, visuals) are `realtime-dashboard.md`'s.

| | |
| --- | --- |
| REST `type` | `KQLDashboard`, under `/workspaces/{ws}/kqlDashboards/{id}` |
| Git folder | `<display name>.KQLDashboard/` |
| Learn definition | [KQL Dashboard definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/kql-dashboard-definition) |
| Spec folder | [`kqlDashboard/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/kqlDashboard): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `a96c37a`, 2026-10-20: 7 operations, all generic |

## Definition

One format, `JSON`. The parts:

| Path | Required | Holds |
| --- | --- | --- |
| `RealTimeDashboard.json` | the only content part; Learn states no requirement | the whole dashboard: `queries`, `tiles`, `baseQueries`, `parameters`, `dataSources`, `pages`, `autoRefresh` |
| `.platform` | no | the item's metadata; the spec's `getDefinition` example returns it |

Learn's page shows no property table; its example payload is a
`schema_version` `"52"` shell with empty `tiles`, `queries` and
`dataSources`, and points to the portal's *export dashboards* for a full
file. The shape of that file is `realtime-dashboard.md`'s § File
anatomy, and the live JSON Schema is § Live JSON Schema. A Git folder
may name the part
`RealTimeDashboard-N.json`; the REST path in the spec's three definition
examples (create, get, update) is `RealTimeDashboard.json` (read
2026-10-20).

## Git is not the live definition

A dashboard's `dataSources[]` entry for a Fabric KQL database
(`kind: "kusto-trident"`) differs between a Git file and
`getDefinition` (`rest-api` § Definition APIs). A git file leaves
`clusterUri` empty, sets `workspace` to the all-zero GUID and puts the
database's `logicalId` in `database`; `getDefinition` returns the
cluster's query URI, the runtime item id in `database` (equal to
`databaseArtifactId`, as the schema says) and the workspace id or the
all-zero GUID (two dashboards, 2026-10-01).

Copy from the export the path takes: git's for a git file,
`getDefinition`'s for a REST create, which bound and ran its tiles; a REST
create in git's shape is untested. Learn's template shows the v63 shape
instead: `scopeId`, and no `databaseArtifactId` (schemas and seven public
exports, 2026-09-29). Normalize the source entry before diffing a live
dashboard against its folder. The fields schema v81 requires on the
entry, and how a deploy treats `databaseArtifactId`, are
`realtime-dashboard.md`'s § File anatomy.

## REST beyond the generic set

None. The spec's `swagger.json` has the seven generic operations (create,
get, list, update, delete, `getDefinition`, `updateDefinition`) and Learn's
[KQLDashboard *Items*](https://learn.microsoft.com/rest/api/fabric/kqldashboard/items)
group lists the same seven (both read 2026-10-20), so there is no table
here. The spec's `examples/` also holds a hard-delete example. **There is
no image or render API for a dashboard**: § What does not exist in
`realtime-dashboard.md`.

## MCP

Learn's [Fabric MCP servers list](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/fabric-mcp-servers-list)
names no server for dashboards (read 2026-10-20). The local Real-Time
Intelligence server's scope there is Eventhouse, Eventstreams, Activator,
maps and Azure Data Explorer.

## Where to look next

This file, then the spec's `swagger.json` and the operation's `examples/`
file, then Learn. Re-read the spec from the SHA above: its commits are
weekly, "Updating swagger files".
