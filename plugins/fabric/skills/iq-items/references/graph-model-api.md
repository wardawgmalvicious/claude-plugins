# Fabric graph model: definition and REST

The graph model's definition shape and the REST operations it has beyond
the generic item set. Generic CRUD, `getDefinition` and
`updateDefinition`, long-running operations and pagination are
`rest-api`'s, § Definition APIs and § Long-Running Operations; the
query endpoint's request and response contract is
[graph-reference.md](graph-reference.md) § 4's.

| | |
| --- | --- |
| REST `type` | `GraphModel`, under `/workspaces/{ws}/graphModels/{id}`; Learn's query examples write `GraphModels` |
| Git folder | `<name>.GraphModel/` |
| Learn definition | [Graph Model definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/graph-model-definition) |
| Spec folder | [`graphModel/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/graphModel): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `a96c37a`, 2026-10-20: 10 operations |

## Definition

A live `getDefinition` of a portal-made graph model returned five parts
and `.platform`, every path ending in `.json`, and no `format`
(2026-10-21). Learn's page names no `format` and four parts, all
required; the spec's `getDefinition` example returns `"format": "json"`
and the same four (Learn read 2026-10-21, spec `a96c37a`):

| Path | Required | Holds |
| --- | --- | --- |
| `dataSources.json` | yes | the `DeltaTable` sources: `{ name, type, properties: { path } }`, the path an `abfss://<wsId>@onelake.dfs.fabric.microsoft.com/<lakehouseId>/Tables/<T>` URL; `Tables/dbo/<T>` on the model read |
| `graphDefinition.json` | yes | `nodeTables` and `edgeTables`, the column-to-graph mapping |
| `graphType.json` | yes | `nodeTypes` and `edgeTypes`, the schema |
| `stylingConfiguration.json` | yes | `modelLayout`: node `positions`, `styles` (size), `pan`, `zoomLevel`; visual only |
| `graphSettings.json` | not listed | `scalingConfiguration.sku.tier`, `small` on the model read; named by neither Learn nor the spec |
| `.platform` | no | the item's metadata; the spec's `getDefinition` example returns it |

**The service emits the paths with `.json`, as the spec has them**;
Learn's table drops the suffix and has no `graphSettings` part (read
2026-10-21). Take the paths from a `getDefinition`, not from Learn.

Learn's property tables are on its definition page, with an example per
part. What they leave to a reader:

- **`graphType` and `graphDefinition` are joined by `alias`.** The graph
  type declares abstract aliases (`Customer_nodeType`) and labels; the
  graph definition binds each alias to a `dataSourceName` and maps
  `sourceColumn` → `propertyName`. A composite key is several
  `primaryKeyProperties` and matching `destinationNodeKeyColumns`.
  A portal-made model's aliases and table `id`s are GUIDs (2026-10-21);
  Learn's examples use readable names.
- **A node type can carry several labels**, and two edge types can share
  a label with different endpoints. Property `type` in Learn's examples
  is `STRING`, `INT`, `FLOAT`, `DATETIME` or `BOOLEAN`. A live read typed
  a date column `ZONED DATETIME`, which no example shows (2026-10-21).
- **`filter` sits on the node or edge table**, as in Learn's examples, a
  `{ "and": [ … ] }` shorthand or an explicit
  `{ "operator": "AND", "filters": [ … ] }`; Learn's property tables list
  it under `PropertyMapping` and leave it off `NodeTable` and `EdgeTable`
  (read 2026-10-20). Operators seen: `Equal`, `Contains`, `GreaterThan`,
  `In`; `value` may be a string, number, dateTime or an array of them.
  The service keeps and applies a node table's: `updateDefinition` took
  a single `{ operator, columnName, value }` filter there,
  `getDefinition` returned it in place, unchanged, and the refresh that
  followed loaded one node where the source table held 483 distinct key
  values (2026-10-21). The column and property shared a name, so which
  one `columnName` means is unmeasured, as are the group forms, an edge
  table's filter and one under `PropertyMapping`. Learn names no portal
  step that writes one (searched 2026-10-21); the query builder's filter
  is the queryset's and leaves these parts unchanged
  ([graph-queryset-api.md](graph-queryset-api.md), 2026-10-21).
- **Every part opens with a `$schema` URL**,
  `https://developer.microsoft.com/json-schemas/fabric/item/graphIndex/definition/<part>/<version>/schema.json`,
  and none carries a `schemaVersion` key. The live parts, `dataSources`
  included, were all at `1.0.0` (2026-10-21), where Learn's example puts
  `dataSources` at `1.1.0` (read 2026-10-21).
- **The live parts carry keys Learn's tables omit**:
  `stylingConfiguration` adds `modelLayout.layoutType` (`Preset`),
  `visualFormat` and `scenario` (`GraphClient`), and an edge table
  carries `edgeIdMapping`, `null` on the model read (2026-10-21).

## Git is not the live definition

**A live definition matched its Git folder byte for byte, bar
`.platform`**: one portal-made model, read and diffed 2026-10-21, and
again once an `updateDefinition` had added a filter and the workspace
was committed, with the filter in Git where it sits live. All
five content parts were identical, and `.platform`'s `logicalId` was all
zeros live, as `rest-api` § Definition APIs says of every item.
Normalize that one key before diffing.

**Nothing in the parts is rewritten to a `logicalId` for Git.**
`dataSources.json` holds the lakehouse's runtime workspace and item IDs
in its `abfss://` path in Git as well as live, so a folder synced to
another workspace still names the source workspace's lakehouse until the
path is rewritten. Whether a deployment pipeline rewrites it is
unmeasured; `find_replace` in `parameter.yml` is `deploy`'s.

The spec and Learn add two things. `getDefinition` on an item protected
by an encrypted sensitivity label needs the right to remove the label,
and `updateDefinition` leaves the label alone (spec descriptions, read
2026-10-20). And `updateDefinition` replaces the definition, so it sends
every part (`rest-api` § Definition APIs); whether it accepts a
definition without `graphSettings.json`, which Learn does not list, is
unmeasured.

## REST beyond the generic set

Under `https://api.fabric.microsoft.com/v1/workspaces/{ws}/graphModels/{id}/`.
The table is the spec's, at the SHA above, with
*On Learn* filled from Learn's *Items* group, which lists nine operations,
and its *Background Jobs* group, which lists the refresh (both read
2026-10-20; the GraphModel group index failed to fetch twice that day),
and *Measured* from § Measured deltas; this skill's other notes on
the query API are from Learn, dated by their own text.

| Method | Path tail | Does | Body | Flags | On Learn | Measured |
| --- | --- | --- | --- | --- | --- | --- |
| `POST` | `jobs/refreshGraph/instances` | Run on-demand RefreshGraph job model | | LRO, preview | yes | no |
| `POST` | `executeQuery?beta=true` | Executes a query on the specified graph model | `query` | preview, beta | yes | 2026-10-21 |
| `GET` | `getQueryableGraphType?beta=true` | Get the current queryable graph type | | preview, beta | yes | no |

- **`executeQuery`** takes a viewer workspace role and the
  `Workspace.Read.All` scope, users and service principals alike, and
  pages by `continuationToken`. The spec says `beta=true` is required and
  that `preview=true` still works. Its status codes, continuation
  polling, truncation and value encoding are
  [graph-reference.md](graph-reference.md) § 4 and § 5, and
  [graph.md](graph.md) § GQL Query API (REST) has the call.
- **`getQueryableGraphType`** returns the current queryable graph type;
  the spec's example has the `nodeTypes` and `edgeTypes` shape of the
  `graphType` part, with GUIDs as aliases. Nothing else is recorded
  about it (read 2026-10-20).
- **`jobs/refreshGraph/instances`** is the on-demand refresh, the REST
  form of a save or a schedule ([graph.md](graph.md) § Data load &
  refresh). It needs `Item.Execute.All`, answers `202` with a `Location`
  to poll as a job instance and a `Retry-After`. Learn has it as *Run On
  Demand Refresh Graph* in the *Background Jobs* group, not *Items*
  (read 2026-10-20). The job type is `RefreshGraph` there, while the
  item's `jobs/instances` list named both its jobs `Refresh`
  (2026-10-21); monitoring is in the Monitoring hub.

## Measured deltas, and where to look next

`getDefinition` on a portal-made model answered `202`, succeeded on the
first poll, and returned § Definition's parts (2026-10-21), each path
ending in `.json`, where Learn's definition page lists them without.
`updateDefinition` with the five content parts and no `.platform` did
the same, and two things followed it (2026-10-21):

- **It queued a refresh.** The item's `jobs/instances` list gained a
  `Refresh` job, `invokeType` `Manual`, within seconds, and it completed
  in under two minutes. So a definition update reloads data as a save
  does ([graph.md](graph.md) § Data load & refresh), and spends capacity
  the same way.
- **The service re-serializes the parts.** A part sent with LF line
  endings came back CRLF, so compare parsed JSON after an update, not
  bytes.

`executeQuery`, at Learn's `GraphModels` casing, answered `200` with
status `00000` and a `TABLE` result to `MATCH … RETURN` queries,
`count(DISTINCT …)` among them (2026-10-21). `getQueryableGraphType`
and the refresh job's own call are unmeasured.

When this file runs out, read the spec's `swagger.json` and the
operation's `examples/` file, then Learn. Re-read the spec from the SHA
above: its commits are weekly, "Updating swagger files".
