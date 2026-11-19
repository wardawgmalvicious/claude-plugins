# Eventstream source connectors

Full connector surface, Azure Event Hubs shortcuts and the DeltaFlow CDC
schema mode. Summarised in `eventstream.md`; this is the exhaustive list.

## Source connectors


| Source | Notes |
|---|---|
| **Azure SQL DB CDC** | Requires `sys.sp_cdc_enable_db`; do NOT also enable Mirroring on the same DB |
| **Azure SQL Managed Instance CDC** | Same shape as Azure SQL DB CDC |
| **SQL Server on VM CDC** | Public-net or VNet-injected |
| **PostgreSQL CDC** | Azure DB for PostgreSQL, Amazon RDS / Aurora PostgreSQL, GCP Cloud SQL — logical replication required |
| **MySQL DB CDC** | Azure DB for MySQL |
| **MongoDB CDC** | **GA (September 2026).** Specify collections to monitor; initial snapshot + tail. No Git integration or deployment-pipeline support |
| **Azure Cosmos DB CDC** | Container-level change feed |
| **Mirrored Database Delta CDF (preview, April 2026)** | New: stream row-level inserts/updates/deletes from a Mirrored Database's Delta Change Data Feed into Eventstream. Toggle via Mirrored DB config dashboard → **Delta table management** → **Enable delta change data feed**, or via `enableDeltaChangeDataFeed` in the [Mirrored DB REST API](https://learn.microsoft.com/fabric/mirroring/mirrored-database-rest-api#enable-delta-change-data-feed-for-a-mirrored-database). Connector reference: [extended capabilities](https://learn.microsoft.com/fabric/mirroring/extended-capabilities). Held as preview: What's New calls it GA (September 2026), but Learn's source list still says "Mirrored Database Change Feed (preview)" (2026-10-06). |
| **Azure Event Hubs / IoT Hub** | Native sources — no CDC layer. Event Hubs auth is **Shared Access Key** in both the basic and extended-features pivots; **workspace identity** (Entra ID) instead of shared access keys is in **preview (Aug 2026)** — announced in What's New, but not yet on the connector's Learn page, so expect the UI to lead the docs. Not the **Event Hubs shortcut** (preview), which makes the hub the default stream: [below](#azure-event-hubs-shortcuts-preview) |
| **Apache Kafka / Amazon MSK / Confluent Cloud Kafka** | Kafka-protocol sources — base connector **GA (June 2026)**; SASL_SSL / SASL_PLAINTEXT / Microsoft Entra auth. Custom-CA / mTLS also **GA (July 2026)** — see below |
| **Amazon Kinesis Data Streams** | Single-shard or multi-shard |
| **Azure Service Bus** | Queue or topic subscription — **GA (June 2026)** |
| **Google Cloud Pub/Sub** | |
| **Solace PubSub+** | **GA (September 2026)** |
| **Cribl** | **GA (September 2026).** Cribl Stream sends to the source; no Git integration or deployment-pipeline support |
| **SAP Datasphere** | **GA (September 2026).** An SAP Datasphere Replication Flow sends data to a dedicated source in the eventstream |
| **MQTT** | **GA (August 2026)**, though Learn's source list still labels it preview (2026-10-06). Has its own **TLS/mTLS settings**: a custom CA and client certificate from Azure Key Vault, as for the Kafka-protocol sources ([kafka-mtls.md](kafka-mtls.md)) |
| **HTTP (preview)** | Stream from external platforms via standard HTTP requests; predefined public feeds available |
| **Real-time weather** | Fabric-hosted demo source |
| **Azure Data Explorer** | Pull from an existing ADX table |
| **Custom stream connector (preview)** | Upload a Kafka Connect **source** plugin (sink plugins aren't supported); it then appears as a source in Real-Time hub. Sources on private networks, virtual or on-premises, aren't supported |

## Azure Event Hubs shortcuts (preview)

**A shortcut makes a customer-owned event hub an eventstream's default
stream**, with no copy into Eventstreams; the hub stays the Azure
owner's to manage, and a destination still stores what is routed to it.
It is a separate experience from the Event Hubs source above, which
ingests a hub's events, and replaces it in nothing. Every claim here is
from Learn, read 2026-11-18:
[overview](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/event-hubs-shortcuts-overview),
[create](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/create-event-hubs-shortcut),
[approve and manage](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/manage-event-hubs-shortcuts),
[troubleshoot](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/troubleshoot-event-hubs-shortcuts).

**Start** from **Real-Time hub** > **Add data** > **Create a shortcut to
an Event hub**, or from a new eventstream's canvas, under **Scenarios**,
by the same name; never the **Azure Event Hubs** connector tile, which
adds the source instead. Pick the subscription, namespace and event hub,
then **Create**.

**Learn gives the portal flows alone**: none of the four pages names a
REST call or a definition field, and the REST page's source `type` list
has no shortcut. How a definition holds one, and whether it survives
Git or a deployment pipeline, is undocumented and untested.

### Approval

| Who | Needs, at the event hub or an inherited scope such as its namespace |
| --- | --- |
| Requester | **Azure Event Hubs Data Receiver** plus `Microsoft.EventHub/namespaces/eventHubs/fabricShortcuts/write`, either alone failing; and workspace **Contributor** or higher |
| Approver | `Microsoft.EventHub/namespaces/eventHubs/fabricShortcuts/approve/action`, which **Azure Event Hubs Data Owner** includes; no Fabric role |
| A requester approved at once | **Azure Event Hubs Data Owner**, or effective permissions covering data read and both actions: the request approves itself at creation |

Azure **Reader** is not enough: a control-plane role, it grants no Event
Hubs data read. The approver works in the Azure portal: the event hub's
**Shortcut to Fabric (preview)** > **Event Hub shortcuts**, then the
row's **Approve** or **Reject**.

**Request shortcut: Successful means submitted, not approved.** The
statuses are **Pending**, **Active** and **Error** alone, with no
**Rejected** to wait for. Confirm **Active** in Azure and in Fabric,
then send fresh, uniquely identified events and query the destination:
a Data preview is a sample, not a count. With Azure **Active** and
Fabric **Pending**, record both and their UTC times rather than request
again. **Error** means access or connectivity is invalid or the hub is
unavailable: check that the hub and namespace exist, the permissions
stand and public network access is still on.

### Topology

- One Event Hubs namespace maps to **one** Fabric workspace: its hubs
  can back different eventstreams there, never in a second workspace.
- An event hub has at most one approved shortcut, to one eventstream.
  It can hold several unapproved requests, and **approving one cleans
  up the others**.
- An eventstream with a shortcut takes **no other source** while the
  shortcut exists.

### Requirements and limitations

| Area | Preview behavior |
| --- | --- |
| Availability | The preview must be available in the hub's Azure region and the Fabric environment |
| Namespace tier | Basic, Standard, Premium or Dedicated |
| Tenant | The hub and the workspace in one Entra tenant; no cross-tenant shortcut |
| Networking | Only namespaces with public network access enabled. Learn says not to open it to get round a policy, and to evaluate a supported alternative for a hub that must stay private |
| Disaster recovery | No Event Hubs metadata disaster recovery with a shortcut |
| Schema Registry | Its metadata doesn't transfer: schematized payloads arrive as bytes, for the destination to interpret |
| Partitions | Eventstream's default-stream partition sizing doesn't apply to the hub |
| Certificates | Workspace-managed certificates don't apply to the hub |
| Capacity and latency | Eventstream's volume limits still apply; Event Hubs-equivalent latency isn't guaranteed |

### Removal and deletion

| Action | Effect |
| --- | --- |
| Remove the shortcut, by **Remove shortcut** on the Azure portal's **Event Hub shortcuts** list | Delivery stops, and its relationship metadata and shortcut-owned consumer groups go. The eventstream's transformations, operations and destinations stay, receiving nothing; the hub and data already ingested stay |
| Delete the eventstream | The relationship metadata and shortcut-owned consumer groups are cleaned up too |
| Delete the backing event hub | Delivery stops and the shortcut goes to **Error**; the eventstream's configuration stays |

Approval permission doesn't by itself grant removal. Never delete the
hub to remove a shortcut, nor consumer groups by hand to finish its
cleanup.

## DeltaFlow — analytics-ready CDC events (preview)

Available on **Azure SQL CDC**, **Azure SQL MI CDC**, **SQL Server on VM CDC**, and **PostgreSQL CDC**. When the schema-handling step is set to **Analytics-ready events & auto-updated schema**, DeltaFlow transforms raw Debezium CDC events into a tabular shape mirroring the source table, enriched with:

- `Op` / change-type column: `insert` / `update` / `delete`
- Event-timestamp column

Extras you get for free:

- **Automatic destination table management** — when routing to a supported destination (e.g. an Eventhouse), tables are auto-created matching the source schema.
- **Schema evolution** — new source columns and new tables propagate to registered schemas and destination tables without manual intervention.

Without DeltaFlow you receive raw Debezium envelopes and have to flatten them yourself.
