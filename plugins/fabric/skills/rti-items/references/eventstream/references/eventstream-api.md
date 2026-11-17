# Eventstream: definition and REST

An eventstream's definition shape and the REST operations it has beyond
the generic item set, the topology reads and the pause and resume calls.
Generic CRUD, `getDefinition` and `updateDefinition`, long-running
operations and pagination are `rest-api`'s, § Definition APIs and
§ Long-Running Operations.

| | |
| --- | --- |
| REST `type` | `Eventstream`, under `/workspaces/{ws}/eventstreams/{id}` |
| Git folder | `<display name>.Eventstream/` |
| Learn definition | [Eventstream definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/eventstream-definition), with the property tables in [Eventstream REST API](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/eventstream-rest-api) |
| Spec folder | [`eventstream/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/eventstream): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `a96c37a`, 2026-10-20: 18 operations |

## Definition

The parts, as Learn lists them (read 2026-10-20). The page names no
`format` value, and the spec's optional `format` query parameter on
`getDefinition` lists none (read 2026-10-20), so send none.

| Path | Required | Holds |
| --- | --- | --- |
| `eventstream.json` | yes | the topology: `sources`, `destinations`, `operators` and `streams`, all four arrays required, and a `compatibilityLevel` |
| `eventstreamProperties.json` | no | `retentionTimeInDays`, 1 to 90, default 1, and `eventThroughputLevel`, `Low` (default), `Medium` or `High`; `getDefinition` also returns `schemaMode`, not in Learn's table, `"None"` on every one read (2026-11-17) |
| `.platform` | no | the item's metadata; `getDefinition` always returns it, create reads it, and `updateDefinition` reads it only with `?updateMetadata=true` |

Every part is `InlineBase64`. The property tables for each source,
destination and operator type, and the full example, are on the two Learn
pages above; Microsoft's
[`fabric-event-streams`](https://github.com/microsoft/fabric-event-streams)
repo holds API templates. None is transcribed here.

**Learn and the spec disagree on `compatibilityLevel`** (read
2026-10-20): the spec's enum holds `1.0` alone, Learn's definition page
example sends `1.0`, and Learn's REST page example sends `1.1`.
**`getDefinition` returns `1.1`**: on three eventstreams, two of them
made in the portal that day (measured 2026-11-17, the spec's enum). No
create was tried with either value, so whether one sending `1.0` is
stored as `1.1` is unmeasured. The field is not in Learn's property
table.

Three warnings Learn carries (read 2026-10-20):

- **`updateDefinition` overrides the current definition**, so send the
  whole topology, read back by `getDefinition` first.
- **An Eventhouse destination takes a different property set per
  `dataIngestionMode`.** `ProcessedIngestion` takes `workspaceId`,
  `itemId`, `databaseName`, `tableName` and `inputSerialization`;
  `DirectIngestion` takes `workspaceId`, `itemId`, `connectionName` and
  `mappingRuleName`. The wrong combination is accepted by the API and
  leaves the destination in a `Warning` state that ingests no rows and
  reports no error, so read the destination back after a write. The
  DirectIngestion setup end to end is Learn's
  [Create an Eventstream with an Eventhouse DirectIngestion destination by using APIs](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/api-kusto-pull-destination).
- **A `SampleData` source needs `properties.type`** (`Bicycles`,
  `YellowTaxi`, `StockMarket` or `Buses`, among others): an empty
  `properties: {}` is rejected.

A source whose cloud connection the caller cannot use fails the create:
the identity that gets the token needs permission on the connection, user
or service principal alike. Learn's `type` enums for sources (19 values),
destinations (`Activator`, `CustomEndpoint`, `Eventhouse`, `Lakehouse`)
and operators (`Filter`, `Join`, `ManageFields`, `Aggregate`, `GroupBy`,
`Union`, `Expand`) are shorter than the connector list in
[source-connectors.md](source-connectors.md); the page omits, for
instance, MQTT, Solace and Service Bus, while its own example sends
`SQLServerOnVMDBCDC`, which the enum lacks. Whether the API accepts a
source type missing from Learn's enum is unmeasured.

## Git is not the live definition

The Git folder holds `eventstream.json`, `eventstreamProperties.json` and
`.platform` (measured 2026-07-08, [cloudevents-producer.md](cloudevents-producer.md));
Learn's Git integration page lists only `.platform` and
`EventstreamProperties.json`. For a schema-associated eventstream the
definition carries `schemaMode` and the table template but never the
registry binding: `schemaMode: "None"`, an empty `CustomEndpoint`
source `properties` and `inputSchemas: [{"schema": {"columns": []}}]`
are its healthy shape (2026-09-14, [cloudevents-producer.md](cloudevents-producer.md)).
So neither the definition nor the Git folder shows what is running: the
topology call below does. `.platform`'s `logicalId` is all zeros live
(`rest-api` § Definition APIs). Whether `getDefinition` and the
Git folder differ in any other field is unmeasured.

## REST beyond the generic set

Under `https://api.fabric.microsoft.com/v1/workspaces/{ws}/eventstreams/{id}/`:
Learn's *Topology* group, all eleven on Learn (read 2026-10-20). Scope
`Eventstream.ReadWrite.All` or `Item.ReadWrite.All` on each; user,
service principal and managed identity all work (the spec's descriptions,
read 2026-10-20). The table is `spec-ops.py`'s, at
the SHA above, with *On Learn* and *Measured* filled in.

| Method | Path tail | Does | Body | Flags | On Learn | Measured |
| --- | --- | --- | --- | --- | --- | --- |
| `GET` | `topology` | Returns the topology of the specified eventstream | | | yes | 2026-09-14 |
| `POST` | `pause` | Pause running all supported sources and destinations of the eventstream | | | yes | no |
| `POST` | `resume` | Resume running all supported sources and destinations of the eventstream | `startType`, `customStartDateTime` | | yes | no |
| `GET` | `sources/{sourceId}` | Returns the specified source of the eventstream | | | yes | 2026-11-17 |
| `GET` | `destinations/{destinationId}` | Returns the specified destination of the eventstream | | | yes | no |
| `GET` | `sources/{sourceId}/connection` | Returns the connection information of specified source of the eventstream | | | yes | 2026-11-17 |
| `GET` | `destinations/{destinationId}/connection` | Returns the connection information of a specified destination of the eventstream | | | yes | no |
| `POST` | `sources/{sourceId}/pause` | Pause running the specified source in the eventstream | | | yes | no |
| `POST` | `sources/{sourceId}/resume` | Resume running the specified source in the eventstream | `startType`, `customStartDateTime` | | yes | no |
| `POST` | `destinations/{destinationId}/pause` | Pause running the specified destination in the eventstream | | | yes | no |
| `POST` | `destinations/{destinationId}/resume` | Resume running the specified destination in the eventstream | `startType`, `customStartDateTime` | | yes | no |

### Topology

`GET topology` shows the **running** stream, where the editor shows the
unpublished draft, and it carries error text the portal hides (measured
2026-09-14; the detail, including `ESComponentUpdateFailure` and
`ESComponentCreationFailure`, is in
[cloudevents-producer.md](cloudevents-producer.md) § "The destination
registers types at publish").

### Variable library references (preview)

A source or destination can take its connection or item from a variable
library. **`getDefinition` keeps the symbolic reference and the topology
call returns it resolved** (Learn, read 2026-10-31; not measured against
a tenant):

| Call | A source or destination holds |
| --- | --- |
| `POST getDefinition` | `connectionReference` or `itemReference`, as `"$(/**/MyVariableLibrary/MyVariable)"`; no identifier is substituted |
| `GET topology` | the resolved ids: `dataConnectionId` for a connection reference, `workspaceId` and `itemId` for an item reference; neither reference property appears |

- The public workload APIs and the Eventstream Swagger expose resolved
  values only, so the reference properties are in the definition alone.
- An Eventhouse destination's item reference must target the **KQL
  database**, not the parent Eventhouse.
- Not every contract has one: Learn's support table (audit stamped
  2026-08-27) gives 27 of 39 sources and 5 of 6 destinations a
  reference property, and `CustomEndpoint` has none either way. Some CDC
  sources and the Eventhouse destination also take `tableNameReference`
  or `tableNamesReference`.
- Only the active value set resolves. Whether the variable library
  skill's runtime limits reach an eventstream is not on Learn.

The variable side is `variable-library`'s. Page:
[Variable library integration with eventstreams](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/variable-library-support).

### Connection information

The two `/connection` calls are narrower than their names (the spec's
descriptions, read 2026-10-20): the source call supports **custom
endpoint, Cribl and SAP Datasphere** sources only, the destination call
**custom endpoint** destinations only. A custom endpoint answers its
`fullyQualifiedNamespace`, `eventHubName` and `accessKeys` (primary and
secondary key and connection string, per the spec's example): **secrets
in a response**, so keep the body out of logs and commits. How the
service names those parts is in
[cloudevents-producer.md](cloudevents-producer.md).

### Pause and resume

Pause takes no body. **Resume requires one**; omitting `startType` is the
easy mistake:

```json
{ "startType": "CustomTime", "customStartDateTime": "2026-09-11T08:00:00Z" }
```

`startType` is `Now`, `WhenLastStopped` or `CustomTime`; the optional
`customStartDateTime` is UTC, `YYYY-MM-DDTHH:mm:ssZ`. Learn marks the
enum open: "additional start types may be added over time". Which nodes
can pause, which resume options each offers, and that CI/CD does not
carry pause state are `eventstream.md` § Pause and resume.

## Measured deltas, and where to look next

- **The topology call shows the running stream** (2026-09-14), above.
- **No REST read tells a schema-aware eventstream from an existing
  one** (2026-11-17), by `getDefinition`, the item, topology, source and
  source-connection calls: [schema-aware.md](schema-aware.md) § 1. The
  source connection call answered as above for a custom endpoint.
- **`getDefinition` returns `compatibilityLevel` `1.1`** (2026-11-17),
  against the spec's enum of `1.0` alone, above.
- **A schema-associated eventstream's Eventhouse destination answered
  `422` on create and update** from 2026-09-10 to 2026-09-14 in one
  tenant, not re-checked since: `eventstream.md` § Gotchas has the row, and
  [cloudevents-producer.md](cloudevents-producer.md) the detail.

Nothing else here is measured against a tenant: the pause and resume
calls, the destination connection call and the Eventhouse property sets
are read from Learn and the spec on 2026-10-20.

When this file runs out, read the spec's `swagger.json` and the
operation's `examples/` file (it holds a Cribl and an SAP Datasphere
connection and a reference-Lakehouse source), then Learn. Re-read the
spec from the SHA above: its commits are weekly, "Updating swagger
files".
