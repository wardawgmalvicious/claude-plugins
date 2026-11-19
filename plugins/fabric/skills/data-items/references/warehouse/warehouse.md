# Fabric Warehouse T-SQL surface area

**Note**: This reference applies to Fabric Warehouse only — the distributed Synapse-engine warehouse. Fabric SQL Database uses the full Azure SQL Database engine and does NOT have these restrictions. See [sql-database.md](../sql-database/sql-database.md).

An item's definition, REST calls, MCP server and monitoring have files of
their own. Read one first for its job; past it, the REST spec's folder, then
Learn, by `microsoft-learn-mcp`, or with no server, `curl -sL -H 'Accept: text/markdown' <page URL>` (undocumented, read 2026-11-07):

| The job | Read first |
| --- | --- |
| A warehouse's create payload, its definition, or its restore point, SQL pool and audit calls | [references/warehouse-api.md](references/warehouse-api.md) |
| A SQL analytics endpoint's metadata refresh, connection string or audit calls | [references/sql-endpoint-api.md](references/sql-endpoint-api.md) |
| A warehouse snapshot's REST calls | Learn's [Create and manage a warehouse snapshot](https://learn.microsoft.com/fabric/data-warehouse/create-manage-warehouse-snapshot): create takes `creationPayload.parentWarehouseId` and `snapshotDateTime`, and an update rolls `snapshotDateTime` forward; nothing past the generic five operations (spec [`warehouseSnapshot/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/warehouseSnapshot) at `a96c37a`, 2026-10-20); what one is: [references/time-travel-and-recovery.md](references/time-travel-and-recovery.md) |
| The remote MCP server: endpoint, `executeSQL`, wiring | [references/warehouse-mcp.md](references/warehouse-mcp.md) |
| A query to label, trace or tune: `queryinsights`, live DMVs and `KILL`, a Capacity Metrics interval, result set caching, statistics, a SQL endpoint serving stale data | [references/monitoring.md](references/monitoring.md) |

A live page that contradicts a line here wins: say so, act on the page,
and route the fix by `capture-learning`, bar a dated measured line that
names the page it overrules and the call that measured it, which a page
changed since its date sends back to re-measure. An observed claim is cited
or marked pending a doc check, and stands, marked observed, only where no
page covers it.

## Unsupported Data Types — Use These Alternatives

| Unsupported Type | Use Instead | Notes |
|---|---|---|
| `nvarchar` / `nchar` | `varchar` / `char` | UTF-8 collation handles Unicode |
| `money` / `smallmoney` | `decimal(19,4)` | |
| `datetime` / `smalldatetime` | `datetime2(6)` | |
| `datetimeoffset` | `datetime2(6)` | Timezone offset is lost |
| `xml` | `varchar(max)` | XML functions lost |
| `ntext` / `text` | `varchar(max)` | |
| `image` | `varbinary(max)` | |
| `tinyint` | `smallint` | |
| `geometry` / `geography` | `varbinary` (WKB) or `varchar` (WKT) | Cast as needed |
| `sql_variant` | No equivalent | |
| `hierarchyid` | No equivalent | |

## Unsupported T-SQL Features

- `FOR XML` — use `FOR JSON` instead (and only as last operator, not in subqueries)
- Recursive CTEs
- `SET ROWCOUNT` / `SET TRANSACTION ISOLATION LEVEL`
- Materialized views
- Triggers
- **Cursors** — replace with `WHILE` + `ROW_NUMBER()`. Row-by-row is slow on a distributed engine; prefer set-based whenever possible.
- `CREATE USER` — users auto-created on GRANT/DENY
- Multi-column manual statistics
- `PREDICT`
- Schema/table names with `/` or `\`
- MARS (Multiple Active Result Sets) — remove from connection strings

## Table Constraints and Limits

- **8,060-byte row limit** (error 511 / 611 on violation)
- **128-char limit** on table/column names
- **1,024-column max** per table
- No default value constraints; no computed columns (use views)
- **PK / UNIQUE / FK supported only as `NONCLUSTERED + NOT ENFORCED`** — metadata-only; the engine does not enforce them at DML time. They serve as optimizer hints, and Power BI uses FK relationships for automatic relationship detection.
- `DEFAULT` / `CHECK` not supported
- `NOT NULL` only via `CREATE TABLE` (cannot be added via `ALTER TABLE`)

## Schema Evolution

Adding a nullable column, dropping a column, and `sp_rename` on a column or
table all work (April 2025+), as does adding/dropping `NONCLUSTERED NOT
ENFORCED` constraints. What constrains you:

| Operation | Status | Syntax |
|---|---|---|
| ALTER TABLE inside `BEGIN TRAN ... COMMIT` | ✅ April 2026+ GA | All supported ALTER TABLE variants run atomically; any failure rolls every schema change back |
| `ALTER COLUMN` — **widen** type (metadata-only) | 🔶 Preview | `ALTER TABLE t ALTER COLUMN col wider_type`. Metadata-only type-widening only (see subsection below). No narrowing, no `NULL`→`NOT NULL`. |
| `ALTER COLUMN` — narrow type / `NULL`→`NOT NULL` / retype IDENTITY / change collation | ❌ | Not supported even in preview. CTAS workaround: create new table with desired schema, `DROP TABLE`, `sp_rename`, re-add constraints/security |

CTAS workaround **destroys time-travel history and security (GRANT/DENY)** on the original table — re-apply security after the swap.

**What a Git sync does to a populated table depends on the warehouse's
definition version**, told by the item folder: `xmla.json` means 1.0, and
`config.version` in `.platform` reads `2.0` either way. Under **2.0** (Aug
2026) DacFx deploys with `BlockOnPossibleDataLoss = true`, so a synced DDL
change dropping a column from a populated table **refuses**: `DataLoss: The
column [s].[t].[c] is being dropped`, then `Msg 50000 ... Rows were
detected. The schema update is terminating`. The generated guard is
`IF EXISTS (SELECT TOP 1 1 FROM [s].[t]) RAISERROR(...)` — it fires on **any
row in the table**, so nulling the column first changes nothing. Run the
destructive half by hand (`ALTER TABLE s.t DROP COLUMN c` on the live
warehouse), then sync: the plan then holds no drop and no guard is
generated. Nothing else is protecting that data, so capture it first.
Documented for deployment pipelines and VS Code publish; observed on Git
update Sept 2026, with the pre-drop remedy field-confirmed. The rest of the
2.0 surface — the upgrade, the fixed DacFx settings, and the build-time
failures that pass `sqlcmd` — is in
[references/platform-features.md](references/platform-features.md).

Under **1.0** the failure ran the other way: sync could drop the data
silently. Adding a nullable column to a table's DDL file and syncing from
Git wiped the table's rows (observed 2026-09-03; sibling tables in the same
schema untouched). The docs describe sync as DacFx incremental deployment
but warn of "limitations with adding table constraints or columns", and the
`IDENTITY_INSERT` bullet under *Limitations in Git integration* implies a
table rebuild with re-insert — mechanism not documented. On a 1.0 warehouse
treat any synced DDL change to a populated table as destructive: capture
what you need first (for a control table, `MAX(Watermark)` per entity from
its run log — only statuses that actually advance the cursor, not ones that
merely park a pending window), then re-register from that, not from the
script's seed values. Corollary: a register proc whose UPDATE branch assigns
every column unconditionally NULLs any column the caller omits, so
re-registration scripts must carry every column they mean to keep.

The `ALTER COLUMN` preview conversion matrix (what widening is actually allowed,
and the Delta type-widening consequence for external readers) is in
[references/schema-evolution.md](references/schema-evolution.md).

## IDENTITY Columns

**GA August 2026.**

- Must be `bigint`; anything else errors. **Cannot be added to an existing table
  via `ALTER TABLE`** — use CTAS or `SELECT ... INTO` (both preserve the IDENTITY
  property on the target). It need not be the first column in the definition.
- **No custom seed or increment.** The system manages values and always produces
  positive integers.
- **Values are unique but not sequential — gaps are normal and expected.** The
  distributed engine allocates ranges per compute node, so even two sequential,
  successful ingestion tasks get non-contiguous ranges. Surrogate keys only:
  never read the value as an ordering or a row count. A used value is never
  reissued unless `IDENTITY_INSERT` is involved.
- **`sys.identity_columns` lies here** — `seed_value` / `increment_value` are
  always `NULL`, and `last_value` flips permanently to `-1` after the first
  identity insert. Use `MAX()` for a high-water mark.

Declaration syntax, and inserting explicit values (`SET IDENTITY_INSERT` plus a
mandatory `DBCC CHECKIDENT(..., RESEED)`):
[references/schema-evolution.md](references/schema-evolution.md).

## Warehouse Authoring Rules

- **Snapshot isolation only** — write-write conflicts are detected at the table
  level. Serialize writes to the same table.
- **MERGE is GA (January 2026)** — it takes an Intent Exclusive (`IX`) lock like
  other DML, but under snapshot isolation it **conflicts with any concurrent DML
  on the same table**, even append-only.
  Serialize writes, or fall back to DELETE + INSERT where concurrency is high.
- **CTAS over CREATE TABLE + INSERT** — parallel, single-operation, faster. It
  differs from Synapse dedicated pools: no `DISTRIBUTION` or columnstore hints
  (both engine-managed), no explicit column definitions, no variables;
  `WITH (CLUSTER BY (...))` *is* supported. Full porting delta in
  [references/t-sql-surface.md](references/t-sql-surface.md).
- **TRUNCATE TABLE over DELETE FROM** (without WHERE) — faster, and preserves
  time-travel history.
- **INSERT...SELECT over singleton INSERT...VALUES** at scale — singletons
  create tiny Parquet files. Remediate existing fragmentation with
  `CREATE TABLE T_Clean AS SELECT * FROM T; DROP TABLE T; EXEC sp_rename 'T_Clean', 'T';`
- **Never put a hand-authored `.sql` inside a `*.Warehouse` folder.**
  Fabric treats that folder as the serialization of the live warehouse,
  so a script the warehouse does not contain is drift to be deleted —
  13 of them (~3,300 lines) left a trunk in a single portal commit.
  Keep them outside anything Fabric syncs. The rest of what a portal
  commit deletes: [git-serialization.md](../git-serialization.md).
- **Keep transactions short** to shrink the conflict window. Error 24556 / 24706
  = snapshot conflict → serialize and retry with exponential backoff.
- **Ingestion**: `COPY INTO` for external files (highest throughput), `OPENROWSET`
  in-engine. `bcp` is preview; `BULK LOAD` is **not supported**, while `BULK INSERT`
  works for compatibility, mapped to `COPY INTO` (Learn, 2026-10-06).
  Options and file-size guidance: [references/t-sql-surface.md](references/t-sql-surface.md).

## Snapshot Isolation Conflict Matrix

| Scenario | Outcome |
|---|---|
| INSERT vs INSERT (same table) | Usually safe (appends new Parquet files) |
| UPDATE / DELETE vs UPDATE / DELETE | First committer wins; others fail with error 24556 / 24706 |
| MERGE vs any DML | Always conflicts (even append-only MERGE) |
| DML vs background compaction | Compaction can trigger conflict if it commits first |

**Mitigation**: serialize writes per table, or use INSERT-only patterns (append then reconcile). Retry with TRY/CATCH around the DML and exponential backoff.

## Transactions

- ACID via **snapshot isolation exclusively** (`SET TRANSACTION ISOLATION LEVEL`
  is ignored).
- **DDL is allowed inside transactions** — `CREATE` / `DROP` / `TRUNCATE TABLE`,
  CTAS, `sp_rename`, and every supported `ALTER TABLE` variant (including on
  distributed temp tables, and several in one transaction). **GA April 2026**: any failure rolls every schema change
  back atomically.
- **That atomicity is yours only when you run the T-SQL.** Fabric's own Git
  sync and deployment pipelines generate DacFx scripts with
  `IncludeTransactionalScripts = false`, so a multi-statement schema change
  applied *by sync* can stop half-way. (The `deploy-pipelines` page still
  says warehouses "don't support wrapping DDL scripts inside transactions" —
  stale against the April 2026 GA, but the setting is real.)
- **DDL takes a Sch-M lock** at table level, blocking concurrent DML *and*
  SELECT — including queries against `sys.tables` / `sys.objects`. Schedule
  schema changes for maintenance windows; inspect contention with
  `sys.dm_tran_locks`.
- Cross-database transactions work within a workspace; rollbacks are fast
  (metadata-only).
- **Not supported**: savepoints, named transactions, distributed transactions,
  nested transactions.

```sql
-- Atomic multi-step schema migration (April 2026 GA)
BEGIN TRAN;
ALTER TABLE dbo.FactSales ADD UnitCostUSD decimal(19,4) NULL;
ALTER TABLE dbo.FactSales DROP COLUMN LegacyCost;
COMMIT;
```

## Time Travel



```sql
SELECT * FROM dbo.FactSales
OPTION (FOR TIMESTAMP AS OF '2026-03-01T08:00:00.000');
```

- 30 days of history by default — configurable 1–120 per warehouse (preview);
  the windows for all three mechanisms are in
  [references/time-travel-and-recovery.md](references/time-travel-and-recovery.md).
  No compute charge for retention; storage does bill.
- Timestamp must be **UTC**.
- Appears **once** per SELECT — all tables see the same point in time.
- **Cannot** be used in `CREATE VIEW` definitions (you can query views with it).
- Returns the **current schema** — dropped columns won't appear. Drop + recreate
  resets history.
- **DML time travel** (the hint on `INSERT...SELECT` / CTAS / `SELECT INTO`) is
  **Warehouse-only**.

Named **Warehouse Snapshots**, **SQL analytics endpoint** time travel (preview,
different retention rules), and **dropped-warehouse recovery** via the workspace
Recycle bin are three separate mechanisms with three different windows — see
[references/time-travel-and-recovery.md](references/time-travel-and-recovery.md).

## Default Collation


`Latin1_General_100_BIN2_UTF8` — case-sensitive, binary. Case-insensitive alternative: `Latin1_General_100_CI_AS_KS_WS_SC_UTF8`. Use explicit `COLLATE` in comparisons if case-insensitive is needed.
Choosing it at create, by REST, is
[references/warehouse-api.md](references/warehouse-api.md) § "Creating one".

Because it is case-sensitive, **write built-in type names lowercase in
item definitions** — `sysname`, never `SYSNAME`. The uppercase form
resolves as a missing user-defined type and fails the whole DacFx build:
`rest-api`'s `references/gotchas.md`, the `SQL71501` row.

## Pipeline Integration

- **The Script and Stored procedure activities both run Warehouse
  stored procedures** from a pipeline. The Stored procedure activity's
  own Learn page lists Fabric Data Warehouse, though the activity
  overview names only Azure SQL, Synapse and SQL Server (2026-10-13);
  until then this skill said the activity could not reach a Warehouse.
- **When a later activity reads the result, use Lookup or Script**, never
  the Stored procedure activity, which exposes no result set. Lookup
  hands a ForEach `output.value` and fails unless the procedure returns
  exactly one result set; Script keeps them all, as `resultSets[n].rows`,
  which the check-then-act pattern in
  [references/table-health-metrics.md](references/table-health-metrics.md)
  reads (Learn's Lookup page and Script output table, 2026-10-13).

## Beyond T-SQL authoring

- **Table maintenance** — check-then-act `OPTIMIZE` via
  `sys.sp_get_table_health_metrics`:
  [references/table-health-metrics.md](references/table-health-metrics.md).
- **Feature/GA matrix, GPU query acceleration, source control and CI/CD** —
  [references/platform-features.md](references/platform-features.md). Query
  Acceleration is a *workspace*-wide toggle on a higher billing meter that
  cancels running queries when flipped. Source control covers **definition
  2.0** (Aug 2026): the upgrade, the fixed DacFx deployment settings, and the
  build-time failures that pass `sqlcmd` and fail the sync.

## Reference

- Microsoft Learn: [What is Fabric Data Warehouse?](https://learn.microsoft.com/fabric/data-warehouse/data-warehousing)
- Full MS Learn link bundle (concept / connect / tables / ingestion / performance / monitoring / security / backup-restore / CI-CD): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- [sql-database.md](../sql-database/sql-database.md) — full Azure SQL engine inside Fabric, none of these restrictions apply
- security skill — GRANT/DENY/RLS/CLS/DDM SQL syntax for Warehouse
- rest-api skill — TDS connection essentials (port 1433, Initial Catalog vs FQDN, Encrypt=Yes) in its `references/auth.md`, and the cross-cutting error index in its `references/gotchas.md`
