# Activator: the definition, `ReflexEntities.json`

An Activator's definition shape, entity by entity. Every claim here is
from the Learn [Reflex
definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/reflex-definition)
page, drilled 2026-09-12 and read again 2026-10-20, except where marked
otherwise. The REST calls, their permissions and the error catalogue are
[rest-and-errors.md](rest-and-errors.md)'s; generic CRUD,
`getDefinition` and `updateDefinition`, long-running operations and
pagination are `rest-api`'s, § Definition APIs and § Long-Running
Operations.

| | |
| --- | --- |
| REST `type` | `Reflex`, under `/workspaces/{ws}/reflexes/{id}`; `Activator` is the portal name for the same item |
| Git folder | `<name>.Reflex/` (activator.md § 1) |
| Learn definition | [Reflex definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/reflex-definition) |
| Spec folder | [`reflex/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/reflex): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `a96c37a`, 2026-10-20: 8 operations |

## Definition

One format, `json`, and one payload type, `InlineBase64`. The parts:

| Path | Required | Holds |
| --- | --- | --- |
| `ReflexEntities.json` | yes | the whole configuration, as a JSON array of entities |
| `.platform` | no | the item's metadata; create respects it if given, `getDefinition` always returns it, and `updateDefinition` reads it only with `?updateMetadata=true` |

Learn's property tables for every entity are on its definition page and
are not transcribed in full below; what follows is the shape, and the
deltas measured against it.

## Git is not the live definition

The one measured difference is in the `kqlSource-v1` section: a source
the portal wrote held a database's `logicalId` and an all-zero
`workspaceId` in Git, and object IDs live (one client estate,
2026-10-13). Not always: another portal commit, of a rule set in the
same estate's Git-connected Dev workspace, wrote the object IDs into
Git (2026-10-21); why the two differ is unknown.
`.platform`'s `logicalId` is all zeros live
(`rest-api` § Definition APIs). Whether other entities carry IDs
that differ the same way is unmeasured, so normalize both sides before
diffing a live definition against its folder.

## The array

The file is a **JSON array**. Each element:

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `uniqueIdentifier` | string (GUID) | yes | Other entities reference this value |
| `payload` | object | yes | Shape varies by `type` |
| `type` | string | yes | One of the seven below |

Parent references, both inside `payload`:

| Property | References |
| --- | --- |
| `parentContainer.targetUniqueIdentifier` | a `container-v1`; present on all entities except the container |
| `parentObject.targetUniqueIdentifier` | an `Object` time series view; present on attribute and rule views |

Structure lives in the references between entities, not in nesting.
Seven entity types exist:

| `type` | Role |
| --- | --- |
| `container-v1` | Top-level grouping; everything else references one |
| `simulatorSource-v1` | Simulated data, for prototyping a rule |
| `kqlSource-v1` | A KQL query against an Eventhouse, on an interval |
| `realTimeHubSource-v1` | Workspace events from Real-Time hub |
| `eventstreamSource-v1` | A Fabric Eventstream |
| `fabricItemAction-v1` | A Fabric item a rule can invoke |
| `timeSeriesView-v1` | Events, objects, attributes **and** rules |

`timeSeriesView-v1` is the one that carries the logic, and it wears four
hats distinguished only by `payload.definition.type`: `Event`, `Object`,
`Attribute` or `Rule`. So counting rules means filtering the array on
that nested value, not on `type`.

The documented hierarchy:

```ascii
Container
├── Data Source (simulator, KQL, Real-time Hub, or Eventstream)
├── Event View (selects/transforms events from the data source)
├── Object View (represents an entity, e.g., "Package")
│   ├── Attribute View (identity field, e.g., "PackageId")
│   ├── Attribute View (measured value, e.g., "Temperature")
│   └── Rule View (trigger + action)
└── Action (optional Fabric item reference, e.g., a Pipeline to invoke)
```

## `container-v1`

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | yes | Display name |
| `type` | string | yes | Classification, e.g. `samples`, `kqlQueries` |

Note the collision: `payload.type` here is a *container classification*,
a different field from the entity's own top-level `type`.

## Data sources

### `simulatorSource-v1`

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | yes | |
| `runSettings.startTime` | ISO 8601 | no | |
| `runSettings.stopTime` | ISO 8601 | no | |
| `version` | string | no | e.g. `V2_0` |
| `type` | string | yes | Simulated data type, e.g. `PackageShipment` |
| `parentContainer.targetUniqueIdentifier` | GUID | yes | |

### `kqlSource-v1`

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | yes | |
| `runSettings.executionIntervalInSeconds` | number | no | Poll interval |
| `query.queryString` | string | yes | The KQL |
| `eventhouseItem.targetUniqueIdentifier` | GUID | yes | The Eventhouse, by Learn; the portal writes `eventhouseItem` otherwise (below) |
| `parentContainer.targetUniqueIdentifier` | GUID | yes | |

An interval of 60–300 s keeps the Eventhouse effectively always-on — see
activator.md §5.

**A portal-written source differs from Learn's table.** One made by
setting a rule on a KQL queryset, as the portal committed it, had no
`targetUniqueIdentifier` under `eventhouseItem`, which held `itemId`,
`workspaceId` and `itemType` `KustoDatabase`: the KQL database, not the
Eventhouse. In Git `itemId` was the database's `logicalId` and
`workspaceId` all zeros; live, both were object IDs. It also held
`runSettings.isStopped`, the source's own run switch beside the rule's
`shouldRun`; an empty `queryParameters`; and `metadata`, the
`workspaceId`, `querySetId` and `queryId` of the queryset tab the rule
came from (a committed file and two live `getDefinition` reads, one
client estate, 2026-10-13; unverified here). Learn still showed its own
shape that day, so copy a source from a `getDefinition` of one the
portal made, as § Template instances says of instances; whether an older or
API-written source takes Learn's form is unknown. How the two links
fared in a deploy: `deploy`'s `references/deployment-pipelines.md`,
§ *Item pairing and autobinding*.

**Re-pointing a running source moves its database, not its cluster.**
An `updateDefinition` setting an existing source's `eventhouseItem`
`itemId` and `workspaceId` to another stage's database was read back by
`getDefinition`, and the next run used the new database ID, but on the
old stage's eventhouse: a `Failed` row in that cluster's
`.show queries`, client `Activator;<item ID>`, reading
`Entity ID '<database ID>' of kind 'Database' was not found.` Setting
`runSettings.isStopped` to `true` and back the same way left the next
run failing alike. What worked, in two stages: give the `kqlSource-v1`
a new `uniqueIdentifier`, point the Event view's `SourceReference` row,
its `entityId` argument inside the escaped `instance`, at it, and
`updateDefinition`. The target database ran the query within a second
and the old source stopped (one client estate, 2026-10-21, failure and
fix twice each; that the cluster is resolved once, at creation, is
inferred). Neither Learn's Reflex definition nor its dependency-binding
page mentions the cluster (searched by that session, 2026-10-21).

### `realTimeHubSource-v1`

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | yes | |
| `connection.scope` | string | yes | e.g. `Workspace` |
| `connection.tenantId` | GUID | yes | |
| `connection.workspaceId` | GUID | yes | |
| `connection.eventGroupType` | string | yes | e.g. `Microsoft.Fabric.WorkspaceEvents` |
| `filterSettings.eventTypes[].name` | string | yes | e.g. `Microsoft.Fabric.ItemCreateSucceeded` |
| `filterSettings.filters` | array | no | |
| `parentContainer.targetUniqueIdentifier` | GUID | yes | |

### `eventstreamSource-v1`

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | yes | |
| `metadata.eventstreamArtifactId` | GUID | yes | The Eventstream |
| `parentContainer.targetUniqueIdentifier` | GUID | yes | |

## `fabricItemAction-v1`

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | yes | Display name of the action |
| `fabricItem.itemId` | GUID | yes | |
| `fabricItem.workspaceId` | GUID | yes | |
| `fabricItem.itemType` | string | yes | e.g. `Pipeline` |
| `jobType` | string | yes | e.g. `Pipeline` |
| `parentContainer.targetUniqueIdentifier` | GUID | yes | |

```json
{
  "uniqueIdentifier": "ffffffff-5555-6666-7777-aaaaaaaaaaaa",
  "payload": {
    "name": "Run alert pipeline",
    "fabricItem": {
      "itemId": "b1b1b1b1-cccc-dddd-eeee-f2f2f2f2f2f2",
      "workspaceId": "a0a0a0a0-bbbb-cccc-dddd-e1e1e1e1e1e1",
      "itemType": "Pipeline"
    },
    "jobType": "Pipeline",
    "parentContainer": {
      "targetUniqueIdentifier": "00aa00aa-bb11-cc22-dd33-44ee44ee44ee"
    }
  },
  "type": "fabricItemAction-v1"
}
```

`payload.fabricItem` is where the target lives. A `targetItem` shape is
reported upstream (`microsoft/skills-for-fabric` CHANGELOG `[0.3.13]`) as
accepted by `updateDefinition` while never resolving its target —
**unverified, and absent from every Learn page drilled**. Treat as a
warning, not a documented behaviour.

## `timeSeriesView-v1`

Four roles, distinguished by `payload.definition.type`. Shared payload:

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | yes | |
| `parentContainer.targetUniqueIdentifier` | GUID | yes | |
| `definition.type` | string | yes | `Event` / `Object` / `Attribute` / `Rule` |
| `definition.instance` | string | no | **JSON-encoded string**, see below |

### `Event`

`definition.instance` required. Templates: `SourceEvent` (select
directly from a source), `SplitEvent` (split by object identity).

### `Object`

Simplest entity in the file — `definition.type: "Object"` and nothing
else. Parent for attributes and rules.

### `Attribute`

`definition.instance` required; `parentObject` required. Templates:

| Template | Purpose |
| --- | --- |
| `IdentityPartAttribute` | Part of an object's identity |
| `IdentityTupleAttribute` | Combines identity parts into one identifier |
| `BasicEventAttribute` | Extracts a simple value from an event field |

### `Rule`

`definition.instance` required; `parentObject` optional. Templates:
`EventTrigger` (on any occurrence), `AttributeTrigger` (on a condition
over an attribute). Plus settings:

| Property | Type | Notes |
| --- | --- | --- |
| `definition.settings.shouldRun` | boolean | Whether the rule is **active**; set `true` to enable |
| `definition.settings.shouldApplyRuleOnUpdate` | boolean | Apply to historical data on update |

`shouldRun` is the field that separates a saved rule from a running one,
and a running rule bills rule uptime.

## Template instances

`definition.instance` is a **JSON-encoded string, not a nested object**,
and must be escaped inside the file. Decoded, every instance has the
same shape:

```json
{
  "templateId": "<template-name>",
  "templateVersion": "1.1",
  "steps": [
    {
      "name": "<step-name>",
      "id": "<step-guid>",
      "rows": [
        {
          "name": "<row-name>",
          "kind": "<row-kind>",
          "arguments": [
            { "name": "<arg-name>", "type": "<arg-type>", "value": "<arg-value>" }
          ]
        }
      ]
    }
  ]
}
```

`templateId` is one of `SourceEvent`, `SplitEvent`,
`IdentityPartAttribute`, `IdentityTupleAttribute`, `BasicEventAttribute`,
`EventTrigger`, `AttributeTrigger`. Row `kind` values seen in the
documented examples include `SourceReference`, `Event`, `EventField`,
`TypeAssertion`, `NumberSummary`, `NumberBecomes`, `TextValueCondition`,
`EachTime`, `TeamsMessage`, `AttributeReference`, `TimeDrivenWindowSpec`.

**Do not hand-author an instance.** The documented route is the reliable
one: configure the item in the portal, call `getDefinition`, then modify
the retrieved instance, which Learn recommends too. Editing one means
parsing a string out of JSON, parsing *that* as JSON, editing, and
re-serialising both ways.

**Cross-entity references live in arguments.** An `entityId` argument
holds another entity's `uniqueIdentifier` — that is how an event view
names its source and a rule names its attribute. A rename that misses an
`entityId` re-points the graph silently.

### Where a column name actually lives

In a `BasicEventAttribute`, the display name and the source column are
two independent places:

- `payload.name` — e.g. `"Temperature (°C)"`
- inside the escaped instance, an `EventFieldSelector` row of kind
  `EventField` with an argument `{"name": "fieldName", "value":
  "Temperature"}`

Clone an attribute and change only the first, and it still reads the
original column. Upstream reports this failing silently, with no error;
that symptom is an observation rather than documented, but the
two-places mechanism is confirmed by the `BasicEventAttribute` example
in the definition reference.

### An `AttributeTrigger` rule, decoded

The documented four-step example: average temperature over a rolling
10-minute window, above 20, filtered to one item type, sending Teams.

| Step | Row kinds | What it does |
| --- | --- | --- |
| `ScalarSelectStep` | `AttributeReference`, `NumberSummary` + `TimeDrivenWindowSpec` | Select the attribute; `op: Average`, `width`/`hop` 600000.0 |
| `ScalarDetectStep` | `NumberBecomes`, `EachTime` | `op: BecomesGreaterThan`, `value: 20.0`; fire each time |
| `DimensionalFilterStep` | `AttributeReference`, `TextValueCondition` | `op: IsEqualTo` against another attribute |
| `ActStep` | `TeamsMessage` | `messageLocale`, `recipients`, `headline`, `optionalMessage`, `additionalInformation` |

Note `width`/`hop` are milliseconds expressed as floats
(`600000.0` = 10 minutes) with `"type": "timeSpan"`.

## Action property tables

### `TeamsMessage`

| Property | Type |
| --- | --- |
| `messageLocale` | string |
| `recipients` | array |
| `headline` | array |
| `optionalMessage` | array |
| `additionalInformation` | array |

### `EmailMessage`

| Property | Type |
| --- | --- |
| `messageLocale` | string |
| `sentTo` | array |
| `copyTo` | array |
| `bCCTo` | array |
| `subject` | string |
| `headline` | string |
| `optionalMessage` | string |
| `additionalInformation` | string |

Note the shape difference: Teams takes arrays for the text fields,
email takes strings.

### `FabricItemInvocation`

Executes a Fabric item with optional parameters, referencing a
`fabricItemAction-v1` entity by `uniqueIdentifier`.

## Minimal valid file

The documented create-request example base64-decodes to a single
container:

```json
[
  {
    "uniqueIdentifier": "00aa00aa-bb11-cc22-dd33-44ee44ee44ee",
    "payload": {
      "name": "Package delivery sample",
      "type": "samples"
    },
    "type": "container-v1"
  }
]
```

An Activator created and never configured holds `[]` instead — measured
on a real Git-synced item, 2026-09-12.

## Definition payload over REST

```json
{
  "format": "json",
  "parts": [
    { "path": "ReflexEntities.json", "payload": "<base64>", "payloadType": "InlineBase64" },
    { "path": ".platform",           "payload": "<base64>", "payloadType": "InlineBase64" }
  ]
}
```

`format` is `json` and `payloadType` is `InlineBase64`, the only values
Learn lists. The calls that carry this body are in
[rest-and-errors.md](rest-and-errors.md).
