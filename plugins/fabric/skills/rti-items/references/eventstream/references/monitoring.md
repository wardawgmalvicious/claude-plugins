# Eventstream workspace monitoring

Monitoring table dimensions and worked KQL queries. `eventstream.md`
carries the four table names, their cadence, and the republish rule.

## Workspace monitoring (preview) — KQL tables

Workspace monitoring itself, its two setups, access and retention, is
[workspace-monitoring.md](../../eventhouse/references/workspace-monitoring.md)'s.
Eventstream
logging is opt-in per eventstream on top: turn on **Log Eventstream
activity** on each one, because enabling monitoring for the workspace
doesn't (Learn, 2026-10-06). Republish any Eventstream that existed
*before* monitoring was enabled — pre-existing streams emit nothing until
they're republished.

| Table | Cadence | What it tells you |
|---|---|---|
| `EventStreamNodeStatus` | ~6 hours | Each node's running / paused / failed state |
| `EventStreamMetrics` | 1 minute | Incoming / outgoing message counts, bytes, watermark delay, backlog |
| `EventStreamErrorMetrics` | 1 minute | Error counts by type (runtime, deserialization, conversion) |
| `EventStreamDiagnosticLogs` | As conditions occur; repeats throttled or aggregated | `Category`, `Severity`, `ErrorType`, `ErrorCode`, `IsFatal`, `Message` — the text behind an error count |

All four tables share these columns, read by `getschema` from a live
monitoring database on 2026-10-24: `Timestamp`, `ItemId`, `ItemKind`
(always `Event Stream`, per Learn), `ItemName`, `WorkspaceId`,
`WorkspaceName`, `CorrelationId`, `CapacityId`, `CustomerTenantId`,
`OperationId`, `WorkspaceMonitoringTableName` and `NodeDirection`. The two
metrics tables add `MetricsName`, `MetricsValue`, `MetricsAggregation`,
`MetricsUnit` and `MetricSpecificDimensions`; only `EventStreamNodeStatus`
has `NodeId`, `NodeName`, `NodeType` and `NodeStatus`. **Filter by the ID
columns** — name columns can lag after rename / move.

**Learn's column tables and query samples are wrong on three counts**
(read 2026-10-24): the samples filter on `ArtifactId`, which no table
carries; the metrics columns are listed as `Value`, `Aggregation` and
`Unit`; and `NodeType` is listed on the metrics tables. A query naming a
missing column answers HTTP 400 `General_BadRequest` over REST, with no
column named. The samples below ran clean against that database's empty
tables on the same day.

```kql
// Most-recent status per node in one Eventstream
EventStreamNodeStatus
| where ItemId == "<eventstream-item-id>"
| summarize arg_max(Timestamp, *) by NodeId
| project Timestamp, NodeName, NodeDirection, NodeType, NodeStatus
| order by NodeDirection asc

// Incoming vs outgoing in 5-minute windows
EventStreamMetrics
| where ItemId == "<eventstream-item-id>"
| where MetricsName in ("Incoming Messages", "Outgoing Messages")
| summarize TotalMessages = sum(MetricsValue)
    by TimeWindow = bin(Timestamp, 5m), MetricsName
| order by TimeWindow asc

// Recent errors grouped by type
EventStreamErrorMetrics
| where ItemId == "<eventstream-item-id>"
| where Timestamp > ago(24h) and MetricsValue > 0
| summarize TotalErrors = sum(MetricsValue)
    by TimeWindow = bin(Timestamp, 5m), MetricsName, NodeDirection
| order by TimeWindow desc
```

For ad-hoc per-node visualizations during authoring, the **Data insights** tab on the lower pane of the Eventstream editor surfaces metrics directly — works without workspace monitoring enabled but is per-node and not historical.

## Microsoft Learn

- [Workspace monitoring overview](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/fabric-workspace-monitoring)
- [Monitoring tables](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/fabric-workspace-monitoring#monitoring-tables)
- [Query monitoring data](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/query-fabric-workspace-monitoring-data)
- [Known limitations](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/fabric-workspace-monitoring-known-limitations)
- [Monitor status and performance](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/monitor)
