# Fabric Eventstream

Streaming-data ingestion item that pulls events from a wide source surface (CDC / Event Hubs / Kafka / IoT / HTTP / MQTT) and routes them into Fabric destinations (Lakehouse, Eventhouse, Activator, derived stream, custom endpoint). Authoring is graph-based: source nodes → optional transformations → destination nodes, edited then **published** to go live.

## Read first

Read one first for its job; past it, the REST spec's folder,
`curl -s https://raw.githubusercontent.com/microsoft/fabric-rest-api-specs/main/eventstream/swagger.json`,
then Learn, by `microsoft-learn-mcp` (`microsoft_docs_search`, then
`microsoft_docs_fetch`), or with no server, `curl -sL -H 'Accept: text/markdown' <page URL>` (undocumented, read 2026-11-07). A live page that contradicts a line here wins:
say so, act on the page, and route the fix by `capture-learning`, bar
a dated measured line that names the page it overrules and the call that
measured it, which a page changed since its date sends back to re-measure.
An observed claim is cited or marked pending a doc check, and stands, marked
observed, only where no page covers it.

| The job | Read first |
| --- | --- |
| An eventstream's definition parts, its topology and pause calls, or the Eventhouse destination's property sets | [references/eventstream-api.md](references/eventstream-api.md) |
| The local Real-Time Intelligence MCP server: what it does for eventstreams, and its other surfaces | [references/eventstream-mcp.md](references/eventstream-mcp.md) |

## When to use vs not

Use Eventstream when the data is **arriving as events** and needs routing or transformation before it lands. Skip it when the data is bulk / batch (use a Data Pipeline Copy activity), already in the lake (use Spark / SQL directly), or when the only consumer is a Mirrored Database in append-only mode (mirroring lands data straight in OneLake without an Eventstream).

For real-time analytics on the resulting events, pair an Eventstream with an Eventhouse ([eventhouse.md](../eventhouse/eventhouse.md), KQL Database). For real-time **rules**, pair with an Activator destination (covered below).

## Authoring model

- **Edit mode** vs **Live mode**: changes only take effect after **Publish**. New nodes added in Edit mode produce no traffic until publish.
- **Sources** = where events come from. **Transformations** = inline filter / aggregate / GroupBy / Manage Fields / SQL, plus a join against a **reference data source** (preview): *Add source* → *Reference data sources*, a Lakehouse Delta table that adds context to each event. **Destinations** = where events go. Each destination can have its own format (Delta / JSON / Avro) where applicable.
- **Permissions**: workspace **Contributor** or higher to author; **Viewer** can read **Data insights** monitoring on a published stream.
- **Virtual-network injection** (private-network sources): use Eventstream connector VNet injection for sources behind a firewall — see Microsoft Learn.

## Sources

Grouped by what you have to get right, not by vendor. Full connector table with
per-source notes: [references/source-connectors.md](references/source-connectors.md).

| Family | Connectors | The thing that bites |
|---|---|---|
| **Database CDC** | Azure SQL, SQL MI, SQL Server on VM, PostgreSQL, MySQL, MongoDB, Cosmos DB | Azure SQL needs `sys.sp_cdc_enable_db`; you cannot enable Mirroring **and** Eventstream CDC on the same database; MongoDB (GA September 2026) has no Git integration or deployment-pipeline support |
| **Mirrored DB Delta CDF** | Mirrored Database (preview, April 2026) | Row-level CDC off a Mirrored DB's Delta Change Data Feed — opt in per database. What's New calls it GA (September 2026), but Learn's source list still says preview (2026-10-06), so it stays preview here |
| **Native Azure** | Event Hubs, IoT Hub | Auth is **Shared Access Key**; workspace-identity auth is preview (Aug 2026) and the UI leads the docs. A hub to use without a copy takes a **shortcut** instead (below) |
| **Kafka protocol** | Apache Kafka, Amazon MSK, Confluent Cloud | GA June 2026. Custom CA / mTLS GA July 2026, under **TLS/mTLS settings** — MQTT has the same block |
| **Other cloud / broker** | Kinesis, Service Bus, Google Pub/Sub, Solace PubSub+, Cribl, SAP Datasphere | Service Bus GA June 2026; Solace PubSub+, Cribl and SAP Datasphere GA September 2026. Cribl has no Git integration or deployment-pipeline support |
| **Protocol / pull** | MQTT, HTTP (preview), Azure Data Explorer, Real-time weather | MQTT is GA (August 2026) with its own TLS/mTLS settings, though Learn's source list still labels it preview (2026-10-06). HTTP ships predefined public feeds for testing |
| **Custom** | Custom stream connector (preview) | You upload a Kafka Connect **source** plugin; sources on private networks aren't supported |

**DeltaFlow** (preview) is the schema-handling mode that turns raw Debezium CDC
into a tabular shape mirroring the source table, plus an `Op` column, automatic
destination-table creation, and schema evolution. Available on **Azure SQL / SQL
MI / SQL Server on VM / PostgreSQL CDC** only; every other CDC source hands you
raw Debezium envelopes to flatten yourself.

**An Azure Event Hubs shortcut** (preview) makes a customer-owned event
hub the eventstream's **default stream**, with no copy into Eventstreams,
the hub staying the Azure owner's to manage. It is a separate experience
from the Event Hubs source, which ingests the hub's events, and replaces
it in nothing: to connect a hub someone already runs without copying it,
start from Real-Time hub's **Add data** or a new eventstream's canvas, by
**Create a shortcut to an Event hub**, never the **Azure Event Hubs**
tile. It carries data only once **Active**, after an approver with the
Azure approve action accepts it, unless the requester holds **Azure
Event Hubs Data Owner**; the namespace must allow public network access,
and while it exists the eventstream takes **no other source** (Learn,
read 2026-11-18). Approval, topology, limits and removal:
[references/source-connectors.md](references/source-connectors.md)
§ "Azure Event Hubs shortcuts (preview)".

Sources behind a firewall need [Eventstream connector VNet
injection](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/streaming-connector-private-network-support-guide).

A source's connection and a destination item can come from a **variable
library** (preview): the definition then holds `connectionReference` or
`itemReference` as `$(/**/Lib/Var)`, which survives Git and deployment
pipelines, and the topology returns it resolved. `CustomEndpoint` has none.
See [references/eventstream-api.md](references/eventstream-api.md)
§ "Variable library references".

## Destinations

| Destination | Use when |
|---|---|
| **Lakehouse** | Land events as Delta files for batch analytics |
| **Eventhouse / KQL Database** | Real-time KQL queries; pair with [eventhouse.md](../eventhouse/eventhouse.md) |
| **Activator** | Rule-based alerts and automation (see below) |
| **Derived stream** | Chain a downstream Eventstream — useful for fan-out and reusable transforms |
| **Custom endpoint** | Push to an external Event Hubs / Kafka / AMQP-compatible system |

## Activator destination

GA (August 2026). Add an Activator destination, then use the **alert icon** on it to view, add,
edit, and stop/start rules without leaving Eventstream. Conditions fire **on
each event**, **on each event when** (single-field condition), or **on each
event grouped by** a field. Actions: Teams, email, webhook, Power Automate,
custom. **Republish after wiring the destination or no rule fires.**

Pane walkthrough and condition detail:
[references/activator-destination.md](references/activator-destination.md).

## Workspace monitoring (preview)

Workspace monitoring itself, its two setups, access and retention, is
[workspace-monitoring.md](../eventhouse/references/workspace-monitoring.md)'s.
Eventstream logging
is then **opt-in per eventstream**: turn on **Log Eventstream activity** on each
one, because enabling monitoring for the workspace doesn't (Learn, 2026-10-06).
Four tables land in the monitoring database.
**Republish any Eventstream that existed before monitoring was enabled** —
pre-existing streams emit nothing until republished.

| Table | Cadence | What it tells you |
|---|---|---|
| `EventStreamNodeStatus` | ~6 hours | Each node's running / paused / failed state |
| `EventStreamMetrics` | 1 minute | Incoming / outgoing counts, bytes, watermark delay, backlog |
| `EventStreamErrorMetrics` | 1 minute | Error counts by type (runtime, deserialization, conversion) |
| `EventStreamDiagnosticLogs` | As conditions occur; repeats throttled or aggregated | The message behind an error: type, code, severity, whether it is fatal |

**Filter by the ID columns, never the name columns** — names cache at emission
time and go stale after a rename or move. The eventstream's ID column is
`ItemId` and a metric's number is `MetricsValue`: Learn's query samples filter
on `ArtifactId` and its column tables say `Value`, and no live table carries
either (2026-10-24). For live per-node numbers during authoring, the
editor's **Data insights** tab needs no monitoring setup.

Worked KQL queries and the full shared-dimension list:
[references/monitoring.md](references/monitoring.md).

## Pause and resume

Pausing (**Deactivate**) stops data flowing through a supported node without
touching its configuration; resuming (**Activate**) restarts it. In the portal
that is **Deactivate All** / **Activate All** on the menu bar, or the per-node
toggle. Over REST it is a `POST` per scope, whole stream, one source or
one destination, and **resume requires a body** (`startType`); the calls
are in [references/eventstream-api.md](references/eventstream-api.md)
§ "Pause and resume".

**Not every node can pause, and resume options differ per node.** The Custom
endpoint (source and destination alike) has no toggle at all. An Eventhouse
destination depends on its `dataIngestionMode`: `DirectIngestion` cannot pause,
while `ProcessedIngestion` — event processing before ingestion — offers all
three resume options. Most
CDC and Kafka-family sources resume only from when streaming was last stopped.
Check [Learn's per-node table](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/pause-resume-data-streams)
before picking a `startType`.

**CI/CD does not carry pause state.** After a Git sync or a deployment-pipeline
deploy, every node in the target eventstream comes back **active** unless it
fails on connection or configuration
([Eventstream CI/CD](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/eventstream-cicd)).
Re-pause after deploying if the stream should stay down.

## Kafka custom CA / mTLS

Kafka, Amazon MSK, and Confluent Cloud sources can take a custom CA certificate
and a client certificate from **Azure Key Vault** (GA July 2026), under the
source connection's **TLS/mTLS settings**. `SASL_SSL` needs a CA cert only when
the cluster uses a private CA; `SSL (mTLS)` needs both CA and client cert + key.

Certificates must be **PEM with LF line endings**, cert and private key
concatenated, `contentType: application/x-pem-file`, with `keySize` matching the
real key size — and whoever previews data needs Key Vault read access on them.
Full setup, the trusted-CA list, and seven failure modes:
[references/kafka-mtls.md](references/kafka-mtls.md).

## Schema-aware eventstreams (preview)

A second experience, chosen once, in the **New Eventstream** dialog, by
**Enable schema-aware eventstream (Preview)**. **It cannot be enabled on,
or converted from, an existing eventstream**, which keeps working as
before (Learn, read 2026-10-31). It carries schematized, classified and
untyped events in one eventstream, and Learn shows no badge afterwards:
the redesigned **Data preview** grid and its **Classify unschematized
events** button are the tell.

- **Classifier.** For unschematized events of different shapes, pick a
  discriminator field, such as `deviceType` (a nested field works), as the
  classifier column. Each value becomes a classified event type, and a new
  value adds one. An event missing the field, or null in it, stays untyped
  and flows on. Choose a bounded set of values: a unique ID makes too many
  types.
- **Registered types.** **Associate event schema**, on the ribbon once
  a source exists, maps a schema to sources for the whole eventstream,
  where the existing experience activates association per source on
  its Add source page (observed 2026-11-17, Fabric portal). Learn says a
  nonconforming event is dropped, with the error under the source node's
  **Runtime logs**; at the stream nothing was dropped, a wrong-typed
  field included, and the source offered no Runtime logs (measured
  2026-11-17, Learn's Use event schemas page:
  [schema-aware.md](references/schema-aware.md) § 4). A source with
  no association stays untyped in the same eventstream. Learn lists
  custom endpoint, Event Hubs, and Azure SQL, SQL MI, SQL Server on VM and
  PostgreSQL CDC as sources able to associate.
- **Input schema.** A no-code operator, or an Eventhouse, Lakehouse,
  custom endpoint or derived-stream destination, takes an **Input schema**
  choice: a schematized event, a classified one, or the untyped default.

**Learn documents the portal flow, not the definition, and the
definition holds neither the mode nor the association**: two
eventstreams made with and without the box matched on every REST read,
and Learn's create body has no field for it, so none can be authored
schema-aware by REST; a Git folder was not committed, so Git is
presumed the same, untested. **Over the Event
Hubs protocol, `cloudEvents:type` or `ce_type` names the registered
type, and Learn's `ce-type` leaves an event untyped.** A new schema
version showed nowhere and changed no event's type. Measured
2026-11-17, bar the Git half, with the detail in
[references/schema-aware.md](references/schema-aware.md).
Not the same as *Multiple-Schema Inferencing* in the existing experience.

Learn: [overview](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/schema-aware-eventstreams-overview),
[create](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/create-schema-aware-eventstream),
[classifier](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/process-events-with-classifier),
[use schemas](https://learn.microsoft.com/fabric/real-time-intelligence/schema-sets/use-event-schemas).

## Producing to a schema-associated custom endpoint

Only relevant when pushing events *into* a custom endpoint that has an
associated schema. Two facts decide whether it works at all:

- **CloudEvents binary mode is required.** Attributes go in the Event Hub
  message's application properties as `cloudEvents:*`; the body is the payload
  JSON alone. Structured mode is silently dropped with
  `CloudEventPropertyMissingException`.
- **Schema support is a creation-time flag** — it cannot be turned on for an
  existing eventstream, and schema-enabled eventstreams don't survive deployment
  pipelines with registries intact. Plan workspaces before you build.
  **It is not the *Enable schema-aware eventstream (Preview)* box**,
  whose limit Learn words the same way: an eventstream made without the
  box still offers **Schema association** on a custom endpoint's Add
  source page, and a schema-aware one does not (observed 2026-11-17,
  Fabric portal: [schema-aware.md](references/schema-aware.md) § 2).

The wire format, the `dataschema` URI anatomy, version-bump behaviour, table
naming, and the custom-endpoint connection-string conventions are all in
[references/cloudevents-producer.md](references/cloudevents-producer.md).
Of these, only versioning is on Microsoft Learn, and only for a portal
save, where
[an update mints a new version](https://learn.microsoft.com/fabric/real-time-intelligence/schema-sets/create-manage-event-schemas#update-an-event-schema)
(read 2026-09-30); what a Git sync does is not. The rest was undocumented
when verified.

## Gotchas

| Issue | Cause | Fix |
|---|---|---|
| Existing Eventstream emits no monitoring data | Stream was published before workspace monitoring was enabled | Open in editor and **Republish** — required once per pre-existing stream |
| Monitoring tables don't appear after enabling | **Log Eventstream activity** is off: enabling workspace monitoring doesn't turn it on | Turn it on per eventstream (§ Workspace monitoring); if it's on, allow for the database's refresh delay |
| `ItemName` / `WorkspaceName` show stale values | Name columns cached from emission time | Filter / join by `ItemId` / `WorkspaceId` only |
| A query copied from Learn answers HTTP 400 `General_BadRequest`, naming no column | Learn's samples and column tables name `ArtifactId`, `Value`, `Aggregation` and `Unit`, which no table carries (2026-10-24) | Use `ItemId` and the `Metrics*` columns: [references/monitoring.md](references/monitoring.md) |
| `EventStreamNodeStatus` shows old status after a node failed | Status is emitted ~every 6 hours | For real-time status, use the Eventstream editor's live view |
| `CorrelationId` maps to multiple nodes | Advanced processing (e.g. SQL operator with multiple destinations) | Disambiguate with `NodeDirection` and `CorrelationId`; the metrics tables carry no `NodeType`, which only `EventStreamNodeStatus` has (2026-10-24) |
| An error count with no message behind it | `EventStreamErrorMetrics` holds counts only | Query `EventStreamDiagnosticLogs`: error type and code, severity, `IsFatal` and a message. Repeated events can be throttled or aggregated, so rows don't equal errors |
| Mirrored DB CDC source rejected | Can't enable Mirroring AND Eventstream CDC on same DB | Pick one — the docs explicitly call this out |
| New Activator rule doesn't fire | Eventstream wasn't republished after adding the destination | Republish the Eventstream after wiring the destination |
| Connector behind firewall fails | Source not publicly reachable | Use [Eventstream connector VNet injection](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/streaming-connector-private-network-support-guide) |
| An Event Hubs shortcut reads **Request shortcut: Successful** but carries nothing | Successful is the request's submission; the shortcut stays **Pending** until an approver accepts it (Learn, 2026-11-18) | Have an Azure approver accept it on the event hub's **Shortcut to Fabric (preview)** blade, then confirm **Active**: [references/source-connectors.md](references/source-connectors.md) § "Azure Event Hubs shortcuts (preview)" |
| An eventstream won't take another source | It has an Event Hubs shortcut, and one with a shortcut takes no other source while it exists (Learn, 2026-11-18) | Put the other source in its own eventstream |
| DeltaFlow not available on a CDC source | Currently scoped to Azure SQL / SQL MI / SQL Server VM / PostgreSQL CDC | Use raw mode for other CDC sources and flatten Debezium yourself |
| Events pushed to a schema-associated custom endpoint are dropped | Wrong CloudEvents envelope, `dataschema` version, or per-environment registry host | See [references/cloudevents-producer.md](references/cloudevents-producer.md) — four distinct failure modes |
| A schema-aware eventstream's Data preview lists events as untyped though they carry `ce-type` | Over the Event Hubs protocol it reads `cloudEvents:type` or `ce_type`, not Learn's `ce-type` (measured 2026-11-17) | Send `cloudEvents:*` application properties: [references/schema-aware.md](references/schema-aware.md) § 3 |
| An Eventhouse destination fed by a variable-library item reference won't configure or never goes active | The reference targets the parent Eventhouse, not the KQL database (Learn, 2026-10-31) | Point the `ItemReference` variable at the KQL database |
| Paused nodes are running again after a deploy | Git integration and deployment pipelines don't carry pause/resume state — after CI/CD every node in the target eventstream becomes **active** | Re-pause after the deploy (portal toggle or the REST `/pause` calls — see Pause and resume) |
| Creating or updating an Eventhouse destination on a schema-associated eventstream answers `422` *"MessagingCatalogConfiguration is required …"* | A service-side fault, **observed 2026-09-10 to 2026-09-14** in one tenant and not re-checked since: a fresh eventstream, KQL database and schema set failed alike | None client-side. Published destinations keep routing, so don't republish or rebuild a working one. Re-test before relying on this row; reading the real state: [references/cloudevents-producer.md](references/cloudevents-producer.md) |
| A new event type lands zero rows, `.show ingestion failures` is empty, and the older types still land | The destination registers types at publish, so one added to the schema set since is dropped before Kusto (observed 2026-09-14) | Publish the destination after adding a type — see [references/cloudevents-producer.md](references/cloudevents-producer.md) |

## Reference

Detail lives in [references/](references/) — each section above links the file
that carries its full version.

- Microsoft Learn: [Add and manage an event source](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/add-manage-eventstream-sources)
- Microsoft Learn: [Set alert on an Eventstream with Activator destination](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/set-alerts-event-stream)

## See also

- [eventhouse.md](../eventhouse/eventhouse.md) — the natural KQL-Database pair for analytics on streamed events
- `rest-api` — Eventstream item REST endpoints, LRO polling, jobType values; the token audience for Fabric REST against Eventstream items in its `references/auth.md`
- `data-items`' `references/warehouse/references/monitoring.md` — Warehouse-side query monitoring; workspace-monitoring links in `monitoring-links.md`
