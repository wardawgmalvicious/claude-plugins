# Workspace monitoring

Fabric's cross-item log store, in preview: one KQL database that
supported items write logs and metrics to, read with KQL. This file
holds what applies to every workload: the two setups, collection,
access, retention and the ready-made assets. A workload's own tables and
queries stay with its own reference, as the last section lists. Learn's
[overview](https://learn.microsoft.com/fabric/fundamentals/workspace-monitoring-overview)
and
[configuration page](https://learn.microsoft.com/fabric/fundamentals/enable-workspace-monitoring)
were read for all of it on 2026-10-24.

## Two setups

**The monitoring item** is the current form: Workspace settings →
**Monitoring** creates an item of type `Monitoring`. It provisions an
Eventhouse with a read-only KQL database, an Eventstream and an
Activator in the workspace, or sends to the Eventhouse of another
monitoring item in the same Azure region, to centralize several
workspaces. **The destination cannot be changed later**, and only one
monitoring item collects for a workspace. Creation offers two more
options: a custom endpoint on the Eventstream, which can be turned on
only then during the preview, and an Operations Agent, which can never
be turned off. The database is named
`<workspace>_<monitoring item>_Database`, with any character a KQL
database name refuses replaced by `_`.

**The legacy setup** is the old **Log workspace activity** toggle, which
creates a monitoring Eventhouse in the workspace itself. Moving off it is
manual: turn the toggle off, take the migration banner, configure the
monitoring item and turn collection on. Old data stays in the legacy
Eventhouse, and new telemetry can take an hour to arrive. Going back
means deleting the monitoring item.

**Tell them apart over REST** with
`GET /v1/workspaces/{wsId}/items?type=Monitoring`. One client workspace
returned none on 2026-10-24, and no monitoring Activator, yet listed an
Eventhouse `Monitoring Eventhouse`, a KQL database
`Monitoring KQL database` and an Eventstream `Monitoring_Eventstream`:
the legacy setup, by inference, though Learn's legacy section names only
the Eventhouse.

## Before it can be turned on

For the monitoring item, per Learn:

- A Premium or Fabric capacity on the workspace, and the caller a
  workspace admin.
- The tenant setting **Workspace admins can turn on monitoring for their
  workspaces**, which a Fabric administrator manages.
- **Users can create Fabric items** on for the caller. Without it the
  **Monitoring** option is unavailable, with no error.

A workload may need an opt-in of its own on top: an eventstream emits
only with **Log Eventstream activity** on
([eventstream.md](../../eventstream/eventstream.md)).
Learn documents setup in the portal only; a Learn search on 2026-10-14
found no REST route, though `Monitoring` is now in the REST `ItemType`
enum (read 2026-10-24).

## Collection

Collection is **off** when a monitoring item is created. Turn it on in
the item, which can also stop and resume it, keeping what it collected.
Nothing is backfilled. Learn says a table "might not appear" until its
item emits, yet the legacy database above held all 27 tables while every
one was empty (2026-10-24), so a `getschema` needs no data.

The legacy setup can miss a table Fabric added after its Eventhouse was
created: turn **Log workspace activity** off and on. It cannot filter
what it ingests, and its user data operation logs never arrive, though
the table exists.

## Reading it

- **Query it; there is no definition to read.** The database is
  read-only, and `getDefinition` on the monitoring Eventhouse, its
  database and its eventstream answered 401 (`rest-api`'s
  `references/gotchas.md`). Query with KQL as
[eventhouse.md](../eventhouse.md) § *Connection*
  says, `db` set to the database's item ID. On the legacy database,
  `PrettyName` was the Eventhouse's name, and `db` set to the item's
  own name failed (§ *Monitoring*).
- **Who can read.** Contributors and above query it, in either setup.
  The monitoring item's database can also be shared outside the
  workspace with **Share**; the legacy one only by a Member or Admin
  role.

## Retention, capacity and limits

- Retention is 30 days by default. Change it, and the caching period,
  which must not exceed it, under the database's **Manage** → **Data
  policies**.
- It runs on Fabric capacity. Its ingestion, Eventhouse operations,
  queries and Real-Time Dashboards keep running while the capacity is
  throttled; Power BI reports and Activator alerts over it are
  throttled. Learn recommends one central monitoring Eventhouse on a
  capacity of its own.
- Each workspace that sends to another monitoring item gets its own KQL
  database there, counting toward that workspace's 1,000-item limit.
- Private links: the monitoring item supports them (if setup fails,
  turn them off, enable monitoring, turn them back on); the legacy setup
  does not.

## Ready-made queries and dashboards

None covers every workload, and none covers Eventstream (all read
2026-10-24):

- **Built-in templates**: the monitoring Eventhouse's **Fabric
  Monitoring** ribbon button makes an Eventhouse or a Semantic Model
  Real-Time Dashboard.
- **[`fabric-toolbox` dashboards](https://github.com/microsoft/fabric-toolbox/tree/main/monitoring/workspace-monitoring-dashboards)**:
  a Real-Time Dashboard JSON and a `.pbit`. The dashboard queries the
  Eventhouse and `SemanticModelLogs` tables only.
- **[`fabric-samples` queries](https://github.com/microsoft/fabric-samples/tree/main/workspace-monitoring)**:
  folders for five Eventhouse log types, GraphQL, mirrored databases and
  semantic models.

## The tables, and who covers them

The 27 tables of one legacy database on 2026-10-24. The last row's five
are missing from Learn's supported-telemetry list.

| Tables | Learn | Covered here by |
| --- | --- | --- |
| `EventStreamDiagnosticLogs`, `EventStreamErrorMetrics`, `EventStreamMetrics`, `EventStreamNodeStatus` | [Eventstream](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/fabric-workspace-monitoring) | [eventstream's monitoring.md](../../eventstream/references/monitoring.md): measured columns, KQL |
| `EventhouseCapacityThrottlingStateLogs`, `EventhouseCommandLogs`, `EventhouseDataOperationLogs`, `EventhouseIngestionResultsLogs`, `EventhouseMetrics`, `EventhouseQueryLogs`, `EventhouseScaleoutEventsLogs`, `EventhouseSizeSuboptimalLogs` | [Eventhouse](https://learn.microsoft.com/fabric/real-time-intelligence/monitor-eventhouse) | Learn links in [REFERENCE.md](REFERENCE.md) § *Monitoring* |
| `ItemJobEventLogs` | [Item job events](https://learn.microsoft.com/fabric/fundamentals/item-job-event-logs) | `data-items`' `references/dataflow/references/REFERENCE.md` § *Workspace monitoring*, for dataflows |
| `WarehouseExecutions`, `SemanticModelLogs` | [Warehouse](https://learn.microsoft.com/fabric/data-warehouse/warehouse-workspace-monitoring), [semantic models](https://learn.microsoft.com/fabric/enterprise/powerbi/semantic-model-operations) | Learn links in `data-items`' `references/warehouse/references/monitoring-links.md` |
| `FabricDataPipelinesActivityRunsLogs` | [Pipelines](https://learn.microsoft.com/fabric/data-factory/workspace-monitoring) | none |
| `CopyJobActivityRunDetailsLogs` | [Copy job](https://learn.microsoft.com/fabric/data-factory/copy-job-workspace-monitoring) | none |
| `ActivatorRuleNotifications` | [Activator](https://learn.microsoft.com/fabric/real-time-intelligence/data-activator/activator-workspace-monitoring) | none |
| `EventSchemaSetOperations` | [Event schema set](https://learn.microsoft.com/fabric/real-time-intelligence/schema-sets/event-schema-set-operation-logs) | none |
| `GraphQLLogs`, `GraphQLMetrics` | [GraphQL](https://learn.microsoft.com/fabric/data-engineering/graphql-operations) | none |
| `MirroredDatabaseTableExecutionLogs` | [Mirroring](https://learn.microsoft.com/fabric/mirroring/monitor-logs) | none |
| `DataflowGen2Logs`, `FunctionSetMetrics`, `QuerysetOperationLogs`, `RawLogs`, `RealTimeDashboardOperationLogs` | not listed | none |
