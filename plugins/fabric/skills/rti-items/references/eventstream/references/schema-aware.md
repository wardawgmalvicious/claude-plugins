# Schema-aware eventstreams: the definition and the wire

What Learn leaves out of the schema-aware experience: what its definition
holds, which headers name an event's type, and what a new schema version
does. The portal flow is Learn's, summarized in
[eventstream.md](../eventstream.md) § Schema-aware eventstreams.

**Measured 2026-11-17, in one tenant's sandbox workspace.** Two
eventstreams were made that day, one with **Enable schema-aware
eventstream (Preview)** ticked and one without, and the same
custom-endpoint source was added to each. Both were read by REST at
each step. Ten events were sent to the schema-aware one by the Event
Hubs SDK and read back in its stream's **Data preview**. The portal
readings are the user's.

## 1. Nothing read by REST tells the two apart

**The box writes nothing a REST read returns** (observed 2026-11-17,
Fabric REST). Empty, and again once each had a published custom
endpoint and the schema-aware one had `Orders` associated, the two
matched on every read but their names:

| Read | Both returned |
| --- | --- |
| `getDefinition`, `eventstream.json` | the same topology, `compatibilityLevel` `"1.1"`, the source's `properties` `{}` |
| `getDefinition`, `eventstreamProperties.json` | `retentionTimeInDays` 1, `eventThroughputLevel` `Low`, `schemaMode` `"None"` |
| `GET` the item, typed and generic | `type`, `description` and `sensitivityLabel` alone |
| `GET topology`, `GET sources/{id}` | the same nodes, each `Running` |
| `GET sources/{id}/connection` | `fullyQualifiedNamespace`, `eventHubName` and `accessKeys`; no `messagingcatalog` host |

So the definition carries neither the mode nor the association, as for
the existing experience's association
([cloudevents-producer.md](cloudevents-producer.md)). **A REST create
has no field that would make an eventstream schema-aware**: that is
inferred from the reads, and no create was tried. The Git folder was not
committed; it holds the same three parts
([eventstream-api.md](eventstream-api.md)), so it presumably carries no
marker either. An existing-experience eventstream with a
schema-associated endpoint, made by September 2026, read `schemaMode`
`"None"` too.

## 2. Where the association is set

Each experience sets it in a different place (observed 2026-11-17,
Fabric portal):

| | Existing experience | Schema-aware |
| --- | --- | --- |
| **Add source** page for a custom endpoint | **Schema association** (Preview), an **Activate** box, per source | the source name alone: no association, classifier or untyped choice |
| **Associate event schema** on the ribbon | absent | present once a source exists: **New event schema** or **Choose from event schema registry**, mapped to sources in its dialog |
| Where the association shows | the source | the eventstream tile's **Associated schema** tab: schema, set and mapped source, with no version |

The **New Eventstream** dialog holds the name and that one box, with
nothing else about schemas, and neither eventstream showed a difference
when it opened.

**The creation-time flag the producer reference observed is not this
box.** The existing experience still offers its own association, and
the eventstreams that flag was observed on were schema-associated by
July 2026. Learn's schema-aware pages were first read here on
2026-10-31.

**The schema-aware endpoint's sample code cannot route as given.** Its
Java and C# samples build `dataSchema = "undefined/versions/v3"` and
`source = "workspace//eventstream/"`, the base URL and the ids missing.

## 3. Which headers name the type

Sent by the Event Hubs protocol to the custom endpoint associated with
`Orders`, each event's body being the payload alone:

| Application properties | In Data preview |
| --- | --- |
| `cloudEvents:specversion`, `cloudEvents:type`, `cloudEvents:source`, `cloudEvents:id` | schematized, `Orders` |
| `ce_specversion`, `ce_type`, `ce_source`, `ce_id` | schematized, `Orders` |
| `ce-specversion`, `ce-type`, `ce-source`, `ce-id` | untyped |
| none: the whole CloudEvent in the body, `application/cloudevents+json` | untyped |
| none: the payload alone | untyped |

**A `ce-type` application property is not read over the Event Hubs
protocol** (measured 2026-11-17, Learn's
[schema-aware overview](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/schema-aware-eventstreams-overview)):
Learn names the `ce-type` header. Use `cloudEvents:type`, the producer
reference's form, or `ce_type`. The AMQP and Kafka protocols were not
tried. **No `dataschema` is needed to schematize**: none of these
events carried one.

## 4. Nothing is dropped at the stream

**An associated source's events are not validated at ingest**
(measured 2026-11-17, Learn's
[Use event schemas](https://learn.microsoft.com/fabric/real-time-intelligence/schema-sets/use-event-schemas)).
Learn says nonconforming events are dropped and the errors go to the
source's **Runtime logs**. But an event whose `amount` was a string,
against Avro `double`, came through schematized as `Orders`. Events
with no recognized type flowed on untyped, and all ten reached the
stream by its **Data insights**. The source node offered no Runtime
logs, only **Details**. Whether a destination drops such events was
not tried: the eventstream had none.

## 5. A new version shows nowhere and changes nothing

A portal **Update** minted `v4` of `Orders`, adding a required `channel`
string, and the eventstream was not republished. Then v3-shaped and
v4-shaped events were sent, each with no `dataschema` and with
`undefined/versions/v4`. **All four were schematized as `Orders`**
(observed 2026-11-17, Fabric portal):

- **No version is shown**, per event or per type, in Data preview or on
  the Associated schema tab, and neither offers an update.
- **The preview's columns follow the payload, not the schema.**
  `channel` appeared, blank on the v3-shaped rows, and the string
  `amount` showed as an ordinary value.

So at the stream a version is neither resolved nor checked: the type
comes from `type` alone. A destination was not tried. The existing
experience's Eventhouse destination names its tables
`{CloudEventType}_{CloudEventSchemaVersion}` from `dataschema`
([cloudevents-producer.md](cloudevents-producer.md)), so a version may
matter there.

## To reproduce

- **Connection**: `GET …/eventstreams/{id}/sources/{sourceId}/connection`,
  whose `accessKeys.primaryConnectionString` is a secret: keep it out of
  logs and commits.
- **Sender**: Python's `azure-eventhub`, one `EventData` per event, its
  body the payload JSON, `content_type` `application/json`, and the
  application properties in § 3's table.
- **Reading**: the stream node's **Data preview**, by its **Event type**
  filter, which splits schematized from untyped, and **Data insights**
  for the count.
