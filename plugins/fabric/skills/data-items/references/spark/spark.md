# Spark / PySpark in Fabric

This file holds notebooks, lakehouses and the Spark item definitions.
Each job below has a reference of its own: read it before answering one.
An item's definition and REST calls have files of their own; past one,
the REST spec's folder, then Learn, by `microsoft-learn-mcp`, or with no server, `curl -sL -H 'Accept: text/markdown' <page URL>` (undocumented, read 2026-11-07). A live page that contradicts a line
here wins: say so, act on the page, and route the fix by
`capture-learning`, bar a dated measured line that names the page it
overrules and the call that measured it, which a page changed since its date
sends back to re-measure. An observed claim is cited or marked pending a doc
check, and stands, marked observed, only where no page covers it.

| The job | Read first |
| --- | --- |
| A notebook's definition, its cell shape, or its run, Livy session and job instance calls; testing Spark code from the CLI in a throwaway notebook | [notebook-api.md](references/notebook-api.md) |
| A Spark job definition's V1 or V2 definition, or its run and Livy calls | [spark-job-definition-api.md](references/spark-job-definition-api.md) |
| An environment's definition parts, or its staging, library and publish calls | [environment-api.md](references/environment-api.md) |
| A lakehouse's definition, shortcuts, `enableSchemas` create payload, or its table, maintenance and MLV calls | [lakehouse-api.md](references/lakehouse-api.md) |
| Workspace Spark settings and custom pools (the spec's `spark` folder, not an item) | Learn's [Workspace Settings](https://learn.microsoft.com/rest/api/fabric/spark/workspace-settings) and [Custom Pools](https://learn.microsoft.com/rest/api/fabric/spark/custom-pools); nothing here is measured |
| A Spark job queued, slow or failed; Livy sessions; the History Server | [spark-monitoring.md](references/spark-monitoring.md) |
| Error handling in a notebook's code | [error-handling.md](references/error-handling.md) |
| A materialized lake view | [mlv.md](references/mlv.md) |
| AI Functions on a DataFrame | [ai-functions.md](references/ai-functions.md) |

## Key Constraints

- Fabric Spark cannot access arbitrary external HTTP/HTTPS URLs — land data in lakehouse `Files/` first (via pipeline Copy activity, OneLake API, or curl)
- Use `abfss://` URI format for OneLake paths in Spark: `abfss://{workspace}@onelake.dfs.fabric.microsoft.com/{item}.Lakehouse/{path}`
- Use workspace GUIDs (not names) in ABFS URIs — spaces are not allowed
- `mssparkutils` for Fabric-specific notebook operations (credentials, secrets, file management)
- Use Delta Lake format for all Lakehouse tables

## Runtime Context vs Spark Session Config

Two different things that are often confused:

| Need | API |
|---|---|
| Workspace / item identity (workspace ID + name, notebook ID + name, default lakehouse ID + name, userId) | `notebookutils.runtime.context["currentWorkspaceId"]` (etc.) — a dict, documented public API, works in pure-Python notebooks |
| Spark session tuning (shuffle partitions, AQE, Delta settings, case sensitivity) | `spark.conf.set(...)` / `spark.conf.get(...)` |

`spark.conf.get("trident.workspace.id")` also returns the workspace ID but is internal Spark conf, not documented surface, and is unavailable in pure-Python notebooks. Prefer `notebookutils.runtime.context` for identity lookups; reserve `spark.conf.*` for session tuning.

## Python notebooks (no Spark)

A Python notebook runs no Spark session, so most of this file does not
apply to it. **Tell the two apart by the `# META` header first**: a
Python notebook has `kernel_info.name: "jupyter"`, a
`jupyter_kernel_name` such as `"python3.12"` and cells in
`language_group: "jupyter_python"`, where a Spark one has
`synapse_pyspark`. The rest is from Learn, read in full 2026-10-27
([Python experience](https://learn.microsoft.com/fabric/data-engineering/using-python-experience-on-notebook),
[known limitations](https://learn.microsoft.com/fabric/data-engineering/notebook-limitation),
[`notebookutils.fs`](https://learn.microsoft.com/fabric/data-engineering/notebookutils/notebookutils-file-system)).

- **Compute is one node, 2 vCores and 16 GB by default.** The kernel is
  Python 3.10, 3.11 or 3.12, defaulting to 3.12. `%%configure` takes
  only `vCores` (4, 8, 16, 32 or 64 recommended), `defaultLakehouse` and
  `mountPoints`: no Spark conf, no `retriableOptions` documented there.
  Put it first, or restart the session.
- **Libraries come from `%pip` or `%conda` inline**, which behave alike
  and restart no kernel. Restart with
  `notebookutils.session.restartPython()`, not `sys.exit(0)`. A custom
  wheel goes in Built-in resources. Learn's Known limitations says
  environment integration is not available on Python notebooks, so there
  is no Environment item to attach.
- **An inline install is off in a pipeline or API run, Spark notebooks
  too**, Learn's Known limitations says. Turn it on with the run
  parameter `_inlineInstallationEnabled`: on the Job Scheduler run's
  parameter map, `{"value": "true", "type": "bool"}`, which installed
  and imported a package on both kernels. The `"type": "Boolean"` of
  Learn's list-shaped sample was refused there at submit, value `true`
  and `"true"` alike, on a Python notebook; the list shape itself is
  untested (a client workspace, 2026-11-12, one run each;
  [notebook-api.md](references/notebook-api.md) § Running a notebook).
  With no parameter, a Python notebook's `%pip` installed anyway, once,
  and a Spark notebook's run failed, twice. It is unsupported in a
  `notebookutils.notebook.run()` reference run and in high concurrency,
  and kept across no run, so a dependency can change between runs.
- **A relative path in `notebookutils.fs` is the local
  `/home/trusted-service-user/work`, not the default lakehouse.** Spark
  reads `Files/x` from the lakehouse; here that finds nothing, so use
  `/lakehouse/default/Files/x`. `cp()` runs as `fastcp()`, and `mv()`
  defaults `create_path` to `True`, where Spark's is `False`.
- **Delta needs no Spark here: delta-rs and DuckDB come preinstalled
  to read and write it**, with Polars and scikit-learn, though "some
  Delta Lake features might not be fully supported" (Python experience, read 2026-11-12).
  pandas, pyodbc and `requests` imported with no install as well (observed 2026-11-07, a client workspace's probe runs).
- **`notebookutils.data.connect_to_artifact()` returns a T-SQL
  connection** to a lakehouse, a warehouse or a SQL database, in
  preview and on Python notebooks only (Python experience, read 2026-11-12).
- **The run's own job instance ID is not in `runtime.context`**:
  `currentRunId` is filled in a reference run only
  ([runtime context](https://learn.microsoft.com/fabric/data-engineering/notebookutils/notebookutils-runtime), read 2026-11-12).
  The environment variable `MSNOTEBOOKUTILS_SPARK_SYNAPSE_NBS_RUNID`
  held it in every probe run, which is undocumented, so check it
  against the Job Scheduler's list before relying on it (observed 2026-11-07, a client workspace's Python notebook; Spark untested).
- **A variable library's limits are in `variable-library`**, which
  this section does not repeat.

## Lakehouse Setup

- **`enableSchemas` is set at lakehouse creation time only** and cannot be retrofitted; the create payload is in [lakehouse-api.md](references/lakehouse-api.md) § Creating one.
- Schemas use lowercase names by convention (`bronze`/`silver`/`gold` for medallion). `DROP SCHEMA <name> CASCADE` removes the schema with all its tables.
- **Cross-lakehouse Spark SQL** uses 3-part names, `lakehouse.schema.table`, within a workspace and 4-part ones, `workspace.lakehouse.schema.table`, across workspaces. Verify access permissions on each lakehouse.
- Lakehouse delete cascades irreversibly: SQL Endpoint deleted, all OneLake data permanently removed, shortcuts pointing in become inaccessible, dependent notebooks fail at runtime.
- **Shortcuts as definition payload**: `shortcuts.metadata.json` and its target types are in [lakehouse-api.md](references/lakehouse-api.md) § Definition.

### Spark views

A Spark view stores no data: `CREATE OR REPLACE VIEW` saves its query,
and every read runs it
([Learn](https://learn.microsoft.com/fabric/data-engineering/lakehouse-spark-views)).
To keep the results, use a table or an MLV ([mlv.md](references/mlv.md)).

- **Only Spark and the lakehouse can read a Spark view.** The SQL
  analytics endpoint and semantic models, Direct Lake ones included,
  don't see it yet (Learn, 2026-10-24), so what a SQL query or a model
  must reach goes in a table or an MLV.
- **The notebook's default lakehouse decides where a view lands.** With
  schemas enabled, the view is a file in OneLake beside the tables, which
  a file property marks as a view, and after a refresh Lakehouse explorer
  lists it under its schema, where its menu renames or deletes it and
  Properties shows its query. Without schemas, the view goes to the
  metastore, and the explorer never shows it.
- **A non-schema lakehouse gets a OneLake view** from a session whose
  default lakehouse has schemas, with the target named in the view's name:

  ```sql
  CREATE OR REPLACE VIEW myworkspace.non_schema_lakehouse.my_view AS
  SELECT * FROM myworkspace.non_schema_lakehouse.my_table
  WHERE status = 'active'
  ```

- **A view can span lakehouses and workspaces.** Its query can join
  4-part names from any lakehouse you have access to, and a 4-part view
  name, `workspace.lakehouse.schema.my_view`, creates it outside the
  default lakehouse.

## Lakehouse Table Maintenance (impacts SQL Endpoint performance)

- Run `OPTIMIZE` regularly to compact small files (target 128 MB – 1 GB per file)
- Run `VACUUM` to remove unreferenced files
- V-Order write optimization is default — do not disable
- Avoid high-cardinality partition columns; aim for partitions ≥ 1 GB
- SQL Endpoint metadata sync lag is normally < 1 minute but increases with: many lakehouses per workspace, small-file fragmentation, large ETL volume, or SQLEP idle > 15 min (this describes the legacy background sync)

### New SQL analytics endpoint metadata sync (PREVIEW, May 2026)

Opt-in faster sync that keeps data queryable within seconds of landing. **Preview** — and applies to **NEW SQL analytics endpoints only**: existing endpoints in the workspace stay on the legacy sync above.

- **Enable**: Workspace settings → Warehouse → New metadata sync (preview). Only endpoints created *after* enabling get the new sync.
- **Architecture**: external-tables-based Delta-log parsing with decoupled schema-vs-data change detection (schema changes and data changes refresh separately), plus a periodic background refresh and on-demand refresh when a read query hits stale data.
- **New DMV** `sys.dm_db_external_tables_log_status` — `last_update_time_utc`, `latest_log_version`, `latest_checkpoint_version`, `is_blocked` (`1` = last update blocked, `0` = succeeded).
- **Targeted manual refresh** (new-sync endpoints only, for data-only changes):

  ```sql
  EXEC sys.sp_dw_refresh_ext_table 'dbo.<table>';
  ```

  For schema changes (add/drop tables or columns, type changes) use the full-item Refresh SQL endpoint metadata REST API instead.
- **Limitations**: no support for multi-part checkpoint (a deprecated Delta feature — tables containing them fail to update); cannot be enabled when the workspace uses workspace private link.

## Notebook REST API / UI Upload

The cell shape (`source` as an array of strings, or the upload fails with
`400 exceptionCulprit:1`), `outputs` and `execution_count`, and the default
lakehouse binding in `metadata.dependencies.lakehouse`:
[notebook-api.md](references/notebook-api.md) § Cells for the REST
definition APIs.

### Definition API gotchas

`getDefinition` as a POST with a `'{}'` body, the `{Location}/result` fetch
and `updateMetadata`: `rest-api` § Definition APIs.

## Notebook execution via REST

The run call, its `defaultLakehouse` and pool configuration, job states
and the retry rule: [notebook-api.md](references/notebook-api.md) §
Running a notebook.

### In-notebook auto-restart (`%%configure retriableOptions`)

For pipeline-driven notebook runs, the notebook itself can opt into automatic restart after system failures using `%%configure` (April 2026):

```python
%%configure
{
  "retriableOptions": {
    "enabled": true,
    "maxAttempt": 3
  }
}
```

`enabled` is the on/off switch; `maxAttempt` (singular) caps total attempts. Place it as the first cell, same as any other `%%configure`. This complements — does **not** replace — the pipeline activity-level retry; configure one layer or the other to avoid stacking retries that multiply CU consumption.

Distinct from the "never retry POST" rule in [notebook-api.md](references/notebook-api.md): that rule applies to **external orchestrators** submitting jobs via REST; `retriableOptions` is evaluated **inside** Fabric's notebook runtime. New feature — verify the schema against current Microsoft Learn before relying on it in production.

## Other Spark item definitions

### SparkJobDefinition

Formats, parts, the JAR limit, and the V2 update that deletes the main
file: [spark-job-definition-api.md](references/spark-job-definition-api.md).

### Environment

Parts, the default format and the live-pool limit:
[environment-api.md](references/environment-api.md).

## Reference

- Microsoft Learn: [What is a lakehouse in Microsoft Fabric?](https://learn.microsoft.com/fabric/data-engineering/lakehouse-overview)
- Microsoft Learn: [Apache Spark compute in Microsoft Fabric](https://learn.microsoft.com/fabric/data-engineering/spark-compute)
- Microsoft Learn: [NotebookUtils (formerly MSSparkUtils) for Fabric](https://learn.microsoft.com/fabric/data-engineering/notebook-utilities)
- Comprehensive MS Learn link bundle (concept / notebooks / lakehouse / performance / SJD / environments / runtime / best practices): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- rest-api skill — notebook definition upload API and LRO pattern
- [error-handling.md](references/error-handling.md) — Tier 1/2 convention for notebook code
- [warehouse's monitoring.md](../warehouse/references/monitoring.md) — Query Insights for SQLEP queries against lakehouse tables
- [spark-monitoring.md](references/spark-monitoring.md) — Livy session listings, Spark History Server mirror, notebook wall-clock attribution
