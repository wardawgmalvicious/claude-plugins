# Dataflow Gen2: definition and REST

A dataflow's definition shape and the REST operations it has beyond the
generic item set. Generic CRUD, `getDefinition` and `updateDefinition`,
long-running operations and pagination are `rest-api`'s, §
Definition APIs and § Long-Running Operations. No live tenant was used for
anything below, so every claim is documentation or spec, read as dated,
and nothing is measured.

| | |
| --- | --- |
| REST `type` | `Dataflow`, under `/workspaces/{ws}/dataflows/{id}` |
| Git folder | `<display name>.Dataflow/` |
| Learn definition | [Dataflow definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/dataflow-definition) |
| Spec folder | [`dataflow/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/dataflow): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `ec85f05`, 2026-11-18: 15 operations |

## Definition

Learn's definition page names no `format` and the spec types it as a free
string (read 2026-10-20); omit it, as Learn's example does (unmeasured
here). Three part kinds:

| Path | Required | Holds |
| --- | --- | --- |
| `mashup.pq` | yes | The Power Query document: every query, as M |
| `queryMetadata.json` | yes | Query options: load flags, groups, connections, compute settings |
| `<name>.mdf` | no | A Mapping Data Flow transform; there can be several |
| `.platform` | no | Item metadata: `displayName`, `logicalId`; see § "`updateDefinition` replaces everything" |

Serialization mechanics (end of file, CRLF/LF, `.gitattributes`) are
[git-serialization.md](../../git-serialization.md)'s. M style
conventions, such as naming and step layout, are not covered here.

A bound dataflow cannot be authored from Learn's examples alone, for the
reason in § "The composite `connectionId`".

### `queryMetadata.json`

```json
{ "formatVersion": "202502", "name": "SampleDataflowGen",
  "computeEngineSettings": { "allowFastCopy": true, "maxConcurrency": 1 },
  "queriesMetadata": { "publicholidays": {
      "queryId": "…", "queryName": "publicholidays", "loadEnabled": true } },
  "connections": [ { "path": "Lakehouse", "kind": "Lakehouse",
      "connectionId": "{\"ClusterId\":\"…\",\"DatasourceId\":\"…\"}" } ] }
```

- **`formatVersion` accepts exactly one value, `202502`.** The docs say
  so outright. Treat any other value as a broken file.
- **`name` is the mashup name** and `queriesMetadata` is keyed by query
  name, with the key repeated inside as `queryName`.
- **Defaults that bite**: `loadEnabled`, `allowNativeQueries` and
  `allowFastCopy` all default **true**; `fastCombine`, `isHidden`,
  `skipAutomaticTypeAndHeaderDetection` and `parametric` default false.
- **`parametric`** is the flag behind public parameters mode
  (dataflow.md § 10), and **`maxConcurrency`** caps concurrent evaluations
  for the whole item.

Top level, from Learn (read 2026-09-12; the page re-read 2026-10-20 and
unchanged):

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `formatVersion` | string | **yes** | Only `202502` is allowed |
| `name` | string | **yes** | The mashup name |
| `computeEngineSettings` | object | no | `allowFastCopy` (default true), `maxConcurrency` |
| `queryGroups` | array | no | `id`, `name`, `description`, `parentId`, `order` |
| `documentLocale` | string | no | BCP-47 |
| `gatewayObjectId` | string | no | |
| `queriesMetadata` | object | no | Keyed by query name |
| `connections` | array | no | `path`, `kind`, `connectionId` |
| `fastCombine` | bool | no | default **false** |
| `allowNativeQueries` | bool | no | default **true** |
| `skipAutomaticTypeAndHeaderDetection` | bool | no | default **false** |
| `parametric` | bool | no | default **false**; public parameters mode |

`queriesMetadata` entries:

| Field | Required | Notes |
| --- | --- | --- |
| `queryId` | yes | |
| `queryName` | yes | Matches the key |
| `queryGroupId` | no | |
| `isHidden` | no | default false |
| `loadEnabled` | no | default **true** |

`loadEnabled: true` is the default, so it can be absent on read-back.

### `mashup.pq`

```m
[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared publicholidays =
let  Source = Lakehouse.Contents([]),
  #"Navigation 1" = Source{[workspaceId = "…"]}[Data],
  #"Changed column type" = Table.TransformColumnTypes(…)
in  #"Changed column type";
[ItemType = "MDF"]
shared #"MDF transform" = "___ExternalResource-Placeholder___";
```

Three things carry meaning beyond ordinary M:

- **The leading `[StagingDefinition = [Kind = "FastCopy"]]` attribute**
  sits above `section Section1;` and declares the staging kind.
- **Each query is a `shared` member** of `Section1`. Names with spaces
  take the `#"…"` form, as M requires.
- **An `[ItemType = "MDF"]` member is a placeholder, not a query.** Its
  value is the literal `"___ExternalResource-Placeholder___"`, and the
  real content lives in the matching `<name>.mdf` part. Removing the
  `.mdf` part without removing this member leaves a dangling reference.

### `.mdf`: a Mapping Data Flow transform

JSON with `name` and `properties`, where `properties.type` is
`MappingDataFlow` and `properties.typeProperties` carries `sources[]`,
`sinks[]`, `transformations[]` and the required `scriptLines[]` array that
holds the actual flow script. Sources and sinks each take a `name` and an
optional `externalReferences.connection`.

MDF transforms run on Spark-backed compute. Pricing is being finalized and
they are **preview and not currently billed**.

### The composite `connectionId`

`connections[].connectionId` is **not a GUID**. It is a JSON object
serialized into a string:

```json
"connectionId": "{\"ClusterId\":\"b1b1…\",\"DatasourceId\":\"c2c2…\"}"
```

`path` and `kind` beside it identify the connector. `kind` is the **M
connector kind**, which is not the same spelling as a REST connection's
`connectionDetails.type`.

**No documented Fabric endpoint returns `ClusterId`.** The definition
format requires the value; the public REST surface does not hand it to
you. That is a real gap rather than a lookup this skill has omitted: the
only route known to work is an internal, undocumented Power BI v2.0
endpoint (`gatewayClusterDatasources`, undocumented by its own
description), which this skill does not use and does not recommend.

The practical consequence: **authoring a *bound* dataflow purely through
the definition API is not a supported path.** Create or bind connections
in the portal, then read the definition back to see the composite value.
An empty or absent `connections` array is not necessarily broken: a query
whose source is inline (`#table(…)`) has no external connection.

### Public parameter types

From `discover-dataflow-parameters` (Learn, read 2026-09-12). Each
parameter carries `name`, `type`, `isRequired`, `description` and
`defaultValue`.

| Type | Format of the value |
| --- | --- |
| `String` | |
| `Integer` | int64 |
| `Number` | double |
| `Boolean` | |
| `Date` | `yyyy-MM-dd` |
| `DateTime` | `yyyy-MM-ddTHH:mm:ss.xxxZ` |
| `DateTimeZone` | `yyyy-MM-ddTHH:mm:sszzz` |
| `Time` | `HH:mm:ss` |
| `Duration` | `P5DT14H35M30S` |

The endpoint paginates with `continuationToken`. A non-parametric
dataflow returns `DataflowNotParametricError`.

**Overriding at run time** uses `type: "Automatic"` in the execute
payload. The reference notes `Automatic` explicitly for Date,
DateTimeZone, Duration and Time.

**Required parameters must be supplied**, or the run fails. Optional ones
fall back to their current value. In the pipeline Dataflow activity,
required parameters carry an asterisk and cannot be removed from the
grid.

### `updateDefinition` replaces everything, and takes `.platform`

The house-wide rule applies: **`updateDefinition` replaces the entire
definition, so send every part you want to keep.** Omitted parts are
dropped. The `pbi-items` skill's
`references/tmdl/references/definition-api.md` owns this rule.

The documented sample sends `.platform` alongside the other parts, with
`?updateMetadata=True`. A semantic model takes it the same way (that
reference, measured 2026-11-16).

`?updateMetadata` and the `.platform` part require each other: without
the flag a `.platform` part is ignored, and the flag without one returns
400. That pairing is `rest-api`'s.

Every part is base64 with `payloadType: "InlineBase64"`. A malformed body
returns `CorruptedPayload`.

## Git is not the live definition

**The sensitivity label is no part of the definition.** The spec says a
`getDefinition` does not return it and an `updateDefinition` does not
affect it (`swagger.json`, read 2026-10-20), so a label never shows in
the Git folder or a diff. The composite `connectionId` above is what a
portal-bound dataflow's `queryMetadata.json` holds; whether a live
`getDefinition` returns the same string is unmeasured. `rest-api`
§ Definition APIs has what it holds for `.platform`.

## REST beyond the generic set

Under `https://api.fabric.microsoft.com/v1/workspaces/{ws}/dataflows/{id}/`,
bar the two Gen1 upgrade calls, which sit under `/workspaces/{ws}/`. The
table is `spec-ops.py`'s, at the SHA above, with *On
Learn* and *Measured* filled in; each operation's `examples/` file holds a
request and its response. Learn lists the parameters in its *Items*
group, the runs and schedules in *Background Jobs*, the upgrade calls in
*Upgrade* and the query in *Query Execution* (all read 2026-10-20,
*Upgrade* again 2026-11-18).
Nothing is measured: no live tenant was used.

| Method | Path tail | Does | Body | Flags | On Learn | Measured |
| --- | --- | --- | --- | --- | --- | --- |
| `GET` | `parameters` | Retrieves all parameters defined in the specified Dataflow | | | yes | no |
| `POST` | `jobs/execute/schedules` | Create a new execute schedule for a dataflow. A dataflow can create maximum 20 schedulers | `enabled`, `configuration`, `executionData` | | yes | no |
| `POST` | `jobs/applyChanges/schedules` | Create a new apply changes schedule for a dataflow. A dataflow can create maximum 20 schedulers | `enabled`, `configuration`, `executionData` | | yes | no |
| `POST` | `jobs/execute/instances` | Run on-demand execute job instance | `executionData` | LRO | yes | no |
| `POST` | `jobs/applyChanges/instances` | Run on-demand apply changes job instance | | LRO | yes | no |
| `GET` | `/workspaces/{workspaceId}/dataflows/gen1UpgradeReadinessResults` | Lists Gen1 dataflow upgrade readiness results in the specified workspace | | | yes | no |
| `POST` | `/workspaces/{workspaceId}/dataflows/gen1Upgrade` | Upgrades Gen1 dataflows in the specified workspace | `dataflows` | LRO | yes | no |
| `POST` | `executeQuery` | Executes a query against a dataflow and returns the result | `queryName`, `customMashupDocument` | LRO | yes | no |

What the spec adds to the table (`swagger.json`, read 2026-10-20):

- **`executeQuery` streams Apache Arrow and stops at 90 seconds.** The
  `Accept` header must be `application/vnd.apache.arrow.stream` with a
  required `pq-arrow-version` parameter: `1` works for every dataflow,
  `2` streams faster but not through an on-premises data gateway. The
  caller needs execute permission and `Dataflow.Execute.All` or
  `Item.Execute.All`; users and service principals alike.
- **The schedules cap at 20 per dataflow**, past which the call returns
  `ScheduleExceedsLimit`. They need member or higher, access to every
  connection the dataflow uses, `Dataflow.Execute.All` and
  `Dataflow.ReadWrite.All`, and a user: service principals are out.
- **`jobs/applyChanges/instances` is the publish.** It is the typed
  spelling of the just-in-time publish that dataflow.md § 8 describes, with
  `Dataflow.Execute.All`, member or higher, and no service principal.
- **The readiness list takes viewer or higher** and a service principal,
  evaluates every Gen1 dataflow in the workspace, supports no filtering or
  single-item selection, and pages 1 to 30 at a time. **`gen1Upgrade`
  takes 1 to 50 dataflows of that workspace** in a request body of at
  most 13 KiB (13,312 bytes, whitespace included), needs ownership of
  each or the admin role, evaluates each independently so a batch can
  partly succeed, and cannot be cancelled. Neither is preview since the
  spec at `ec85f05`, but both can still answer `FeatureNotAvailable`, the
  operation not enabled for the caller's tenant. The wizard's rules, and
  the Power BI `saveAs` call, are in [REFERENCE.md](REFERENCE.md) § 7.

### Permissions by operation

**Permissions are not uniform, and the split is the thing to know:**

| Operation | Workspace role | Delegated scope | Service principal |
| --- | --- | --- | --- |
| List | **viewer** | `Workspace.Read.All` | yes |
| Create | **contributor** | `Dataflow.ReadWrite.All` | yes |
| `getDefinition` | read **and write** | `Dataflow.ReadWrite.All` | yes |
| `updateDefinition` | read **and write** | `Dataflow.ReadWrite.All` | yes |
| Discover parameters | read | `Dataflow.Read.All` | yes |
| Execute | **member** | `Dataflow.Execute.All` | **no** |

**There is no read-only route to a definition.** `getDefinition` requires
write permission even though it only reads, the same shape
`rti-items`' Activator reference documents for `/reflexes`. Someone
auditing
definitions across a tenant needs write access to every item they read.

Both definition calls support long-running operations and can answer
`202` with `Location`, `x-ms-operation-id` and `Retry-After` instead of
`200`. Create can answer `201` or `202`. Branch on the status code;
`rest-api` has the polling pattern.

**A generic route exists too**, `/v1/workspaces/{wsId}/items/{itemId}`
and `/items/{itemId}/getDefinition`, and the Dataflow public-APIs article
documents the item surface that way. One documented quirk: when the type
is not specified, the API returns the CI/CD flavour.

### Running one: three spellings, one operation

This is where most confusion starts, because the same run is documented
three ways:

| Form | Shape |
| --- | --- |
| Typed | `POST /v1/workspaces/{ws}/dataflows/{id}/jobs/execute/instances` |
| Generic, current | `POST /v1/workspaces/{ws}/items/{id}/jobs/{jobType}/instances` |
| Generic, legacy | `POST /v1/workspaces/{ws}/items/{id}/jobs/instances?jobType=…` |

The job type moved **from a query parameter into the path**; the query
form still works for backward compatibility. The typed route spells the
job `execute`, while the public-APIs article documents `Refresh` and
`Publish` on the generic route, and `ItemJobEventLogs` records exactly
those two, `Refresh` for a refresh and `Publish` for a just-in-time
publish. All three describe the same machinery.

Every form answers `202` with `Location` and `Retry-After`. Poll the job
instance at `/items/{id}/jobs/instances/{jobInstanceId}`; cancel at
`…/cancel`.

**`executeOption` decides whether your unpublished edits run, and the
docs disagree about its default.** The API reference and the spec
(`definitions.json`, read 2026-10-20) mark `SkipApplyChanges` as the
default value; the CI/CD article reads as though `ApplyChangesIfNeeded`
is. **So pass it explicitly**: that is correct under either reading, and
it is the difference between running what you just saved and running the
last published version.

```json
{ "executionData": { "executeOption": "ApplyChangesIfNeeded",
    "parameters": [ { "parameterName": "OrderKey", "type": "Automatic", "value": 25 } ] } }
```

**Service principals cannot execute a dataflow.** The execute API
supports user identities only, and the public-APIs article lists service
principal authentication as unsupported outright. An unattended refresh
has to be driven another way: a pipeline Dataflow activity, or a
schedule.

### What the definition API cannot do

Five documented limitations, and the first decides architectures:

1. **A data destination cannot be authored through the definition API.**
   Add it in the portal. A dataflow defined purely through the API can
   stage and transform but never persists to a destination.
2. **Service principal authentication is not supported**, says the
   public-APIs article, while the API reference behind the permissions
   table marks every operation but Execute as service-principal capable.
   Test a service principal before relying on it for a definition call.
3. **`Get Item` and `List Item Access Details`** do not return correct
   information when filtered on the dataflow item type.
4. **An untyped call returns the CI/CD item.**
5. **Run APIs can be invoked but the run never succeeds**: stated as a
   current limitation on the public-APIs page.

Read 1 and 5 together before designing an API-first workflow.

## Measured deltas, and where to look next

Nothing about this item is measured: no live tenant was used, and every
claim above is Learn or the spec, read on the date beside it. Two things
read 2026-10-20 that earlier text of the skill missed: `executeQuery` has
a Learn page, in the *Query Execution* group, and the typed
`applyChanges` job and the schedule calls exist.

When this file runs out, read the spec's `swagger.json` and the
operation's `examples/` file, then Learn. Re-read the spec from the SHA
above: its commits are weekly, "Updating swagger files".
