---
name: data-items
description: "Use for Microsoft Fabric data items, in Git or by REST, `fab` or a script: a Data Pipeline (`.DataPipeline`, `pipeline-content.json`, `.schedules`, activity JSON, `/dataPipelines`); a Dataflow Gen2 (`.Dataflow`, `mashup.pq`, `queryMetadata.json`, `/dataflows`, its execute job, Gen1 upgrade); Spark: a notebook (`.Notebook`), PySpark or Spark SQL, a plain Python notebook with no Spark, a lakehouse and its tables, a Spark job definition or environment, a Spark job slow, queued or failed, Livy, a materialized lake view, AI Functions; a Warehouse or SQL analytics endpoint (`.Warehouse`, `/warehouses`, `/sqlEndpoints`, its T-SQL surface and unsupported types, schema evolution, MERGE, Time Travel, snapshots, monitoring); and a Fabric SQL Database (`.SQLDatabase`, `/sqlDatabases`), the Azure SQL engine, which Warehouse's limits do not bind. Picks the item, then reads its reference."
when_to_use: "Use before a Read, edit or REST call on an item of type DataPipeline, Dataflow, Notebook, Lakehouse, SparkJobDefinition, Environment, Warehouse, SQLEndpoint, WarehouseSnapshot or SQLDatabase; before writing T-SQL for a Warehouse or SQL Database, or PySpark in a notebook; or when tracing a Warehouse query (labels, queryinsights, DMVs, KILL, a Capacity Metrics spike, result set caching, a stale SQL endpoint) or a Spark job."
# model: inherit  # any model: value blocks Copilot slash invocation
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Fabric data items

Fabric's data engineering, Data Factory and data warehouse workloads
hold the items below, and each has a reference here. Each reference
holds the depth, and this file picks the item and carries only what
crosses items. Take the steps in order: the wrong item sends every later
step to the wrong file, and Warehouse T-SQL rules applied to a SQL
Database, or the reverse, break code that would have run.

## 1. Pick the item

By the job asked for, or by the folder of the file in hand:

| The job | Folder | Read |
| --- | --- | --- |
| Orchestrating activities: the definition envelope, activity types, `policy`, deactivation, schedules | `<name>.DataPipeline/` | [data-pipeline.md](references/data-pipeline/data-pipeline.md) |
| Power Query transforms: `mashup.pq`, its execute job and publish, CI/CD patterns, a Gen1 upgrade | `<name>.Dataflow/` | [dataflow.md](references/dataflow/dataflow.md) |
| Spark: a notebook, plain Python ones too, a lakehouse and its tables, a Spark job definition, an environment, a slow or failed job, an MLV, AI Functions | `<name>.Notebook/`, `.Lakehouse/`, `.SparkJobDefinition/`, `.Environment/` | [spark.md](references/spark/spark.md) |
| T-SQL against a Warehouse or a SQL analytics endpoint, a warehouse snapshot, or tracing a query | `<name>.Warehouse/` | [warehouse.md](references/warehouse/warehouse.md) |
| T-SQL against a Fabric SQL Database, its SQL project, its OneLake replica | `<name>.SQLDatabase/` | [sql-database.md](references/sql-database/sql-database.md) |

Near these items, and not them:

- The REST conventions every item call shares, such as auth,
  long-running operations and the error catalogue: `rest-api`.
- Deployment pipelines, fabric-cicd and a workspace's Git integration:
  `deploy`.
- The variable library a pipeline or dataflow reads:
  `variable-library`.
- SQL `GRANT`, row- and column-level security: `security`.
- KQL, an Eventhouse and the other Real-Time Intelligence items:
  `rti-items`.
- A semantic model over a lakehouse or warehouse, Direct Lake among
  them: `pbi-items`.

## 2. What crosses items

- **A Warehouse and a SQL Database are two engines.** A Warehouse, and
  the SQL analytics endpoint every lakehouse carries, run the
  distributed engine with
  [warehouse.md](references/warehouse/warehouse.md)'s unsupported types
  and features; a SQL Database is Azure SQL Database, where those work
  ([sql-database.md](references/sql-database/sql-database.md) § Key
  Differences from Fabric Warehouse). Name the engine before writing
  T-SQL.
- **A pipeline runs the other items.** The activity's JSON is
  [data-pipeline.md](references/data-pipeline/data-pipeline.md)'s
  (§ 4: `TridentNotebook`, `RefreshDataFlow`,
  `SqlServerStoredProcedure`); what it runs is the item's own file, and
  a Warehouse procedure's call, by the Script or Stored procedure
  activity, is [warehouse.md](references/warehouse/warehouse.md)
  § Pipeline Integration's.
- **A lakehouse's tables are read by two engines.** Spark writes and
  maintains them ([spark.md](references/spark/spark.md) § Lakehouse
  Table Maintenance, with the endpoint's metadata sync); T-SQL reads
  them through the endpoint, whose metadata refresh is
  [sql-endpoint-api.md](references/warehouse/references/sql-endpoint-api.md)'s.
- **One MCP server serves pipelines and dataflows**, the DataFactory
  server, with one home:
  [data-pipeline-mcp.md](references/data-pipeline/references/data-pipeline-mcp.md).
  The Warehouse's remote server is
  [warehouse-mcp.md](references/warehouse/references/warehouse-mcp.md).
- **Every item's Git folder is the portal's serialization**: each
  part's end of file, what a portal commit deletes, and the mixed line
  endings a `.gitattributes` must leave alone are
  [git-serialization.md](references/git-serialization.md)'s.

## 3. Read the item's reference first

Read the file step 1 names before answering or editing: limits,
definition shapes and preview status live there, dated, and each names
its own *Read first* table for its definition, REST calls and MCP
server, then the REST spec's folder, then the live docs, Learn by
`microsoft-learn-mcp`, or with no server,
`curl -sL -H 'Accept: text/markdown' <page URL>` (undocumented, read
2026-11-07). A task that spans items, a pipeline that runs a notebook
and a warehouse procedure for one, reads each item's file.

A live page that contradicts a line here wins: say so, act on the page,
and route the fix by `capture-learning`, bar a dated measured line that
names the page it overrules and the call that measured it, which a page
changed since its date sends back to re-measure. An observed claim is
cited or marked pending a doc check, and stands, marked observed, only
where no page covers it.
