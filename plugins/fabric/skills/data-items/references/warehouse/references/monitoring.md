# Monitoring & diagnostics

## Query Labels

```sql
SELECT ... FROM ...
OPTION (LABEL = 'PROJECT_Module_Description');
```

Labels appear in `queryinsights.exec_requests_history.label`. Use for tracking, filtering, and performance analysis.

## Query Insights (30-day retention)

| View | Purpose |
|---|---|
| `queryinsights.exec_requests_history` | Every completed query: status, duration, CPU, data scanned |
| `queryinsights.exec_sessions_history` | Session history: login info, times |
| `queryinsights.long_running_queries` | Aggregated: median vs last-run time |
| `queryinsights.frequently_run_queries` | Run counts, execution times for recurring patterns |

**Gotcha**: Data appears with up to 15 minutes delay. After creating a new warehouse, views may return "Invalid object name" — wait ~2 minutes.

## Top Expensive Queries

```sql
SELECT TOP 10
    distributed_statement_id, query_hash, label,
    total_elapsed_time_ms, allocated_cpu_time_ms,
    data_scanned_remote_storage_mb, result_cache_hit
FROM queryinsights.exec_requests_history
ORDER BY allocated_cpu_time_ms DESC;
```

Aggregate by `query_hash` over the last 7 days to find recurring expensive patterns.

To find the queries behind a Capacity Metrics billing interval, start
with the app's **Monitor in warehouse** button on its Timepoint page
(Learn, read 2026-11-14): select a warehouse query operation in the
Background operations table and the button, gray until then, opens
Monitor for that item with the time range set from the operation. It
needs the workspace **Admin** role, appears only when the timepoint's
background operations include warehouse items, and covers Warehouse
Query, SQL Endpoint Query (both with an Accelerated variant) and
Warehouse Snapshot Query.

Without that role, or for an operation the button does not cover,
correlate by time, not by ID: the Metrics app's **Operation Id** no longer maps to `distributed_statement_id` (Learn, confirmed 2026-09-11). Take the interval's **Start** and **End** from the app's Background operations table, then select the requests that overlapped it:

```sql
DECLARE @Start_Time DATETIME2(0) = '2026-08-04 8:00:00'
        ,@End_Time DATETIME2(0) = '2026-08-04 9:00:00'

SELECT [database_name],
       sql_pool_name,
       distributed_statement_id,
       login_name,
       allocated_cpu_time_ms / 1000.0 AS vcore_seconds
FROM queryinsights.exec_requests_history
WHERE start_time < @End_Time
AND end_time > @Start_Time;
```

**Convert the app's Start and End to UTC first.** The Capacity Metrics
app shows times at the `UTC_offset` entered when it was installed, "your
organization's standard time" (Learn's install page, read 2026-10-24), so
subtract that offset before filtering. Learn's `exec_requests_history`
page names no zone for its columns: check the window against a query you
ran at a known time before trusting it.

**`vcore_seconds` ranks queries; it is not CU.** Capacity Metrics CU
seconds and Query Insights CPU time are different measurements, so never
convert one into the other (Learn's correlation page, read 2026-10-24).
Correlate only the period both sources still hold: Query Insights keeps
30 days.

Microsoft's
[Query Capacity Correlation report](https://learn.microsoft.com/fabric/data-warehouse/correlate-capacity-metrics-query-insights)
puts both sources on one time axis. It is a PBIP template from the
`fabric-toolbox` repo: `Configure-CustomerTemplate.ps1` builds it over an
`az login`, then it is opened, refreshed and published from Power BI
Desktop. Its Capacity Metrics source holds the latest seven days, and its
imported model caches every configured warehouse's SQL text and user
identities, so limit who can open it (read 2026-10-24).

## Workspace Monitoring: WarehouseExecutions (Preview)

**Workspace monitoring's `WarehouseExecutions.OperationId` does match
`queryinsights.exec_requests_history.distributed_statement_id`**, unlike
the Capacity Metrics app's **Operation Id** above. The two IDs are
different things: join this one, correlate that one by time (Learn,
read 2026-10-30).

Enabling workspace monitoring fills `WarehouseExecutions` in the
workspace's monitoring KQL database, one event per completed query, for
Warehouses, SQL analytics endpoints and warehouse snapshots. It suits a
workspace-wide view (duration percentiles, failure rate by `ResultCode`,
CPU by user), then drills into one query in Query Insights:

1. Take `ItemId`, `ItemKind` and `OperationId` from the event.
2. Open that warehouse or endpoint.
3. Select from `queryinsights.exec_requests_history` where
   `distributed_statement_id` equals the `OperationId`.

Query Insights can take up to 15 minutes to show a completed execution.

What the table holds and omits:

- **Only completed, user-initiated queries that run a distributed
  workload.** System-generated queries and SQL-front-end-only ones, such
  as many metadata lookups, never appear, nor do running queries. An
  absent row is not a missing query.
- **A cross-database query** is attributed to the item the user
  connected to.
- **`ItemName`, `WorkspaceName` and `CapacityName` are "Not supported
  for Data Warehouse events"**: they stay empty, so group by `ItemId` and
  `ItemKind`.
- **`CpuTimeMs` ranks workloads; it is not a charge.** Learn calls it
  "relative workload attribution", not a monetary or invoiced cost. For
  billing and utilization use the Capacity Metrics app.
- **No separate metrics table** in this release: count, failure rate and
  percentiles come from `WarehouseExecutions` itself.
- **Retention is 30 days** by default. Enabling takes the workspace
  **Admin** role; querying the monitoring database takes at least
  **Contributor**.

Setup, access and the other tables are `rti-items`'
`references/eventhouse/references/workspace-monitoring.md`; the Learn
page is linked in
[monitoring-links.md](monitoring-links.md).

## DMVs (Live State)

| DMV | Shows | Min Role |
|---|---|---|
| `sys.dm_exec_connections` | Active connections (session_id, client_address) | Admin only |
| `sys.dm_exec_sessions` | Authenticated sessions (login_name, login_time, status) | All roles (own sessions) |
| `sys.dm_exec_requests` | Active requests (command, start_time, total_elapsed_time) | All roles (own requests) |

```sql
-- Find long-running queries
SELECT request_id, session_id, command, start_time, total_elapsed_time, status
FROM sys.dm_exec_requests
WHERE status = 'running'
ORDER BY total_elapsed_time DESC;

-- Identify the user
SELECT login_name FROM sys.dm_exec_sessions WHERE session_id = <id>;

-- Kill a runaway query (Admin only)
KILL '<session_id>';
```

## SQL Pool Pressure

Every distributed request runs in a SQL pool: `SELECT` or `NON SELECT`
by default, or one of the workspace's custom pools.
`exec_requests_history` records each request's `program_name` and
`sql_pool_name`, and `queryinsights.sql_pool_insights` logs each pool's
configuration, capacity and pressure changes:

```sql
-- Which application ran in which pool, at what cost
SELECT program_name, sql_pool_name,
       SUM(allocated_cpu_time_ms) AS cpu_ms,
       SUM(data_scanned_remote_storage_mb) AS remote_mb
FROM queryinsights.exec_requests_history
GROUP BY program_name, sql_pool_name
ORDER BY cpu_ms DESC;

-- When a pool was under pressure in the past week
SELECT [timestamp], sql_pool_name, max_resource_percentage, is_pool_under_pressure
FROM queryinsights.sql_pool_insights
WHERE is_pool_under_pressure = 1
  AND [timestamp] > DATEADD(WEEK, -1, GETDATE())
ORDER BY [timestamp] DESC, sql_pool_name;
```

**The view is an event log, not a sample.** It records a pressure change
only once the pressure has held for a minute, and records nothing while
the warehouse is idle, so a gap is not evidence of calm. Reading it takes
Contributor, or Viewer with Monitor. A request overlapping a pressure
interval supports a correlation, not a cause (Learn, read 2026-10-24).

**Custom SQL pools** replace the two defaults with up to eight pools a
workspace, each capped at a percentage of the backend nodes. Only a
workspace Administrator configures them, in the portal or by the REST
call in [warehouse-api.md](warehouse-api.md), and they cover every
warehouse and SQL analytics endpoint in the workspace. The workspace
uses one classifier type: statement type, application name, or an
application-name regex. Take application names from the `program_name`
values above. Three behaviours to plan for (Learn, read 2026-10-24):

- A request matching two regex classifiers goes to one of them at random.
- Removing a pool fails its running queries with `Query canceled by
  user.`; resizing one fails nothing.
- A capacity downscale that leaves a pool no nodes fails its queries with
  "The assigned SQL pool for this query has no resources and must be
  reconfigured." until an admin reconfigures the pools.

## SQL Endpoint Metadata Sync (new sync — Preview, May 2026)

Diagnose slow/stale Lakehouse SQLEP reads when queries return data older than what has landed. On endpoints created under the **new metadata-sync preview** (opt-in, new endpoints only):

```sql
-- Inspect per-table sync freshness and blocked state
SELECT last_update_time_utc, latest_log_version, latest_checkpoint_version, is_blocked
FROM sys.dm_db_external_tables_log_status;   -- is_blocked: 1 = last update blocked, 0 = succeeded

-- Force a targeted refresh of one table's data (data-only changes)
EXEC sys.sp_dw_refresh_ext_table 'dbo.<table>';
```

Schema changes (add/drop tables or columns, type changes) need the full-item Refresh SQL endpoint metadata REST API instead. Full preview note — enablement, architecture, limitations — lives in **[spark.md](../../spark/spark.md)**; the slow-SQLEP gotcha cross-references it in the **rest-api skill**'s `references/gotchas.md`.

## Result Set Caching

**On by default for every Warehouse and Lakehouse SQL analytics endpoint** (GA; Learn and What's New, checked 2026-10-06). A [known issue](https://aka.ms/fabricdwrscki) reported it disabled as of 2026-09-11; whether that issue is closed was not confirmed on 2026-10-06, so check the setting before relying on the default:

```sql
-- Is it on for the connected item?
SELECT name, is_result_set_caching_on
FROM sys.databases
WHERE database_id = db_id();

-- Turn it off for the item
ALTER DATABASE <Fabric_item_name>
SET RESULT_SET_CACHING OFF;

-- Or for one query, e.g. to debug or A/B test it
SELECT ... FROM ...
OPTION ( USE HINT ('DISABLE_RESULT_SET_CACHE') );
```

`result_cache_hit` field in `exec_requests_history`: `2` = cache hit, `1` = the query created the cache, `0` = not applicable for cache creation or use. Learn documents only these three values.

Only a pure `SELECT` qualifies, and Learn lists 15 [disqualifiers](https://learn.microsoft.com/fabric/data-warehouse/result-set-caching#qualify-for-result-set-caching). The ones that bite most often: a result estimated above 10,000 rows; no referenced table of at least 100,000 rows; a cross-database reference; runtime constants (`GETDATE()`, `CURRENT_USER`), non-deterministic functions, window aggregates or `PARTITION BY … ORDER BY`; row-level security, dynamic data masking or another security feature; time travel; an explicit transaction or `WHILE` loop; a session with non-default `SET` options. Any change to a referenced table invalidates the cache, and a cache goes unused after 24 hours idle, or from a different connection, column list or alias set.

## Statistics

Auto-maintained for single-column histograms, average column length, and table cardinality. Manual `CREATE STATISTICS` / `UPDATE STATISTICS` available.

**Gotcha**: After a rolled-back transaction containing a large INSERT, auto-generated statistics can be inaccurate. Run `UPDATE STATISTICS` manually on affected columns to recover.

## Reference

- Microsoft Learn: [Monitor Fabric Data Warehouse (overview)](https://learn.microsoft.com/fabric/data-warehouse/monitoring-overview)
- Microsoft Learn: [Query insights in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/query-insights)
- Microsoft Learn: [Use query labels in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/query-label)
- Comprehensive MS Learn link bundle (per-view T-SQL refs / DMVs / capacity throttling / workspace monitoring): [monitoring-links.md](monitoring-links.md)

## See also

- rest-api skill — the cross-cutting error index, in its `references/gotchas.md`
