# Data Factory: the DataFactory MCP server

A local MCP server that manages Data Factory items from an agent:
connections, dataflows, pipelines and Apache Airflow jobs. This file is
its one home: [dataflow.md](../../dataflow/dataflow.md) points here, and Airflow jobs have no
skill of their own. A stdio entry runs it as
`dnx Microsoft.DataFactory.MCP --prerelease --yes`; § The `--pipeline`
flag says why no flag follows.

| | |
| --- | --- |
| Learn | [Choose a Microsoft Fabric MCP server](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/fabric-mcp-servers-list), the *DataFactory MCP server* row, with the [pipeline guide](https://learn.microsoft.com/fabric/data-factory/pipelines-manage-vs-code) and the [Airflow guide](https://learn.microsoft.com/fabric/data-factory/apache-airflow-jobs-manage-vs-code) (all read 2026-10-20) |
| Hosting | local, stdio; a NuGet package, `Microsoft.DataFactory.MCP`, which needs the .NET 10 SDK |
| Status | pipeline management is **preview** (the pipeline guide, read 2026-10-20); the package is `0.24.0-beta`, NuGet's latest, whose `serverInfo` reports `0.24.0.0` (2026-10-20) |
| Identity | the signed-in user, by Microsoft Entra ID interactive sign-in through the server's own authenticate tool; the token scope is unrecorded |
| Spans | gateways, connections, workspaces, dataflows, pipelines, copy jobs, Apache Airflow jobs and capacities; Learn's list says connections, dataflows, pipelines, copy jobs and Airflow jobs (read 2026-11-07) |
| Tools | 52 by `tools/list` at `0.24.0-beta` (2026-10-20); the pipeline, dataflow and Airflow job tools are below, and the copy job, connection, gateway and sign-in tools are unrecorded here |

## The `--pipeline` flag

**At `0.24.0-beta` the pipeline tools appear without `--pipeline`**:
`tools/list` returned the same 52 tools with and without it, and the
server's startup log names two feature flags only, `device-code-auth`
and `interactive-auth` (measured 2026-10-20). Learn's pipeline guide
still says the pipeline tools do not appear without it, configuring
`datafactorymcp` with `"args": ["--pipeline"]` after
`dotnet tool install --global Microsoft.DataFactory.MCP` (read
2026-10-20). The entry above runs the package with `dnx` and passes no
flag. If a later version gates the pipeline tools
again, pass the flag after `--`, where `dnx` takes a tool's own
arguments ([dotnet tool exec](https://learn.microsoft.com/dotnet/core/tools/dotnet-tool-exec),
read 2026-10-20).

## Pipeline tools

All share the `mcp_datafactorymc_` prefix in Learn's guide, call the
`dataPipelines` REST routes ([data-pipeline-api.md](data-pipeline-api.md)),
and were listed there on 2026-10-20. **Discover them by `tools/list`**,
never hard-code a name: the prefix is the one Copilot shows, and a client
may present another.

| Tool | Does |
| --- | --- |
| `list_pipelines` | List a workspace's pipelines, paginated |
| `create_pipeline` | Create a pipeline item |
| `get_pipeline` | Read a pipeline's metadata |
| `update_pipeline` | Change the display name or description |
| `get_pipeline_definition` | Read the activity definition |
| `update_pipeline_definition` | Push a new or changed definition |
| `run_pipeline` | Run on demand, with optional parameters |
| `get_pipeline_run_status` | Read a run's status and results |
| `create_pipeline_schedule` | Create a recurring schedule |
| `list_pipeline_schedules` | List a pipeline's schedules |
| `set_pipeline_schedule_enabled` | Turn a schedule on or off, keeping its configuration; in `tools/list` at `0.24.0-beta`, not in Learn's list |

- **No delete, and no schedule change beyond on and off.** Learn says
  pipeline deletion and schedule modification are not available through
  the server; at `0.24.0-beta` no tool deletes a pipeline or a schedule,
  or changes a schedule's timing (`tools/list`, 2026-10-20). Do those in
  the portal, or by REST.
- **`update_pipeline_definition` replaces the definition.** It submits the
  JSON to the Update Definition call, so send the whole pipeline, read
  back by `get_pipeline_definition` first. That it replaces rather than
  merges is the REST call's behaviour, not a server claim; the server
  itself is unmeasured here.
- **`run_pipeline` takes parameters**, where the typed REST run has no body
  ([data-pipeline-api.md](data-pipeline-api.md)); how the server sends
  them is unmeasured.
- Free and Premium Per User workspaces do not support pipeline execution
  (the pipeline guide, read 2026-10-20); the workspace needs a capacity.

## Dataflows and Airflow jobs

The same server serves them. Learn's Airflow guide lists seven tools for
Apache Airflow jobs, `list_airflow_jobs`, `create_airflow_job`,
`get_airflow_job`, `update_airflow_job`, `delete_airflow_job`,
`get_airflow_job_definition` and `update_airflow_job_definition`, over
`/workspaces/{ws}/apacheAirflowJobs` (read 2026-10-20); its delete moves
the job to the recycle bin and permanent deletion can't be undone. All
seven are in `tools/list` at `0.24.0-beta` (2026-10-20).

No Learn page read here lists the dataflow tools. At `0.24.0-beta`
`tools/list` names nine (2026-10-20): `list_dataflows`,
`create_dataflow`, `get_dataflow_definition`, `save_dataflow_definition`
(validates and persists an M section document),
`add_or_update_query_in_dataflow` (adds a query to `mashup.pq` and
registers it in `queryMetadata.json`), `add_connection_to_dataflow`
(adds, replaces or clears its connections), `refresh_dataflow_background`,
`refresh_dataflow_status`, and `execute_query`, which runs M against a
dataflow and returns every row as Apache Arrow.

## Not this server

Learn's *Fabric MCP Server (local)* also has Data Factory operations
(pipelines and Dataflow Gen2), and is `rest-api`'s.
