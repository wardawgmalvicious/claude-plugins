# Data pipeline: definition and REST

A data pipeline's definition parts, what Learn and live exports say about
their shape, and the REST operations it has beyond the generic item set.
Generic CRUD, `getDefinition` and `updateDefinition`, long-running
operations and pagination are `rest-api`'s, § Definition APIs and
§ Long-Running Operations.

| | |
| --- | --- |
| REST `type` | `DataPipeline`, under `/workspaces/{ws}/dataPipelines/{id}` |
| Git folder | `<display name>.DataPipeline/` |
| Learn definition | [DataPipeline definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/datapipeline-definition) |
| Spec folder | [`dataPipeline/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/dataPipeline): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `a96c37a`, 2026-10-20: 15 operations |

## Definition

One content part, plus the platform part. Learn's page names no `format`
value, and the spec's `getDefinition` takes `format` as a free query
string with no enum (both read 2026-10-20); `rest-api` § Definition
APIs lists the format as the item's default, so omit it.

| Path | Required | Holds |
| --- | --- | --- |
| `pipeline-content.json` | yes | The pipeline: activities, parameters, variables |
| `.platform` | no | Item metadata: `displayName`, `logicalId` |
| `.schedules` | no | Job-scheduler triggers, one file per item. **Git only on Learn's page**: its parts table lists the two rows above. `getDefinition` returned none for a pipeline holding only an interval-based schedule, which writes none to Git either (2026-11-16); for another type it is unmeasured. Schedules are read and written through the operations below |

The activity JSON inside `pipeline-content.json` is `data-pipeline.md`'s
(§ 2 to § 6), the activity-type enum and per-activity `typeProperties`
are in [REFERENCE.md](REFERENCE.md), and Learn's page holds the property
tables; none is transcribed here.

## Git is not the live definition

For `pipeline-content.json` the two agreed: three pipelines carrying
run conditions read key for key the same by `getDefinition` and from
the commit the workspace made, `runDimensions`, `dependencies` and
`dependencyConnectionId` included (a client sample workspace,
2026-11-16). `.platform` was not compared. `rest-api` § Definition APIs has the
cases measured on other items, among them `.platform`'s `logicalId`,
all zeros live. Item ids inside activities (`notebookId`, `pipelineId`,
`workspaceId`), and a run condition's `referenceName` (measured, as
above), are runtime ids in either form (`rest-api`, on the
two GUIDs every item has), so the Git diff for them is a rebinding question
(`deploy`), not a serialization one. Read a live definition back
before trusting a diff against the folder.

## REST beyond the generic set

Under `https://api.fabric.microsoft.com/v1/workspaces/{ws}/dataPipelines/{id}/`.
Learn lists all eight under *Background Jobs* of the DataPipeline group,
and its *Items* group lists only the generic seven (both read
2026-10-20). The table is the spec's, at the SHA
above, with *On Learn* and *Measured* filled in. These are the typed
twin of the generic `jobs/instances?jobType=Pipeline` and
`jobs/{jobType}/schedules` calls in `rest-api` (§ Job Execution,
§ Job Scheduling); the spec's job type here is `execute`. Whether the two
routes behave alike is unmeasured.

| Method | Path tail | Does | Body | Flags | On Learn | Measured |
| --- | --- | --- | --- | --- | --- | --- |
| `GET` | `jobs/execute/schedules` | Returns a list of execute schedules for the specified data pipeline | | | yes | 400 on an interval-based schedule, below |
| `POST` | `jobs/execute/schedules` | Create a new execute schedule for a data pipeline | `enabled`, `configuration` | | yes | no |
| `GET` | `jobs/execute/schedules/{scheduleId}` | Returns the specified execute schedule for a data pipeline | | | yes | 400 on an interval-based schedule, below |
| `PATCH` | `jobs/execute/schedules/{scheduleId}` | Updates the specified execute schedule for a data pipeline | `enabled`, `configuration` | | yes | no |
| `DELETE` | `jobs/execute/schedules/{scheduleId}` | Deletes the specified execute schedule for a data pipeline | | | yes | no |
| `GET` | `jobs/execute/instances` | Returns a list of execute job instances for the specified data pipeline | | | yes | no |
| `POST` | `jobs/execute/instances` | Runs an on-demand execute job instance | | LRO | yes | no |
| `GET` | `jobs/execute/instances/{jobInstanceId}` | Returns the specified execute job instance for a data pipeline | | | yes | no |

**An interval-based schedule breaks the schedule reads.** With one on
the pipeline, both `GET`s above and their generic twins,
`items/{id}/jobs/Pipeline/schedules` with and without the id, answered
HTTP 400 `InvalidConfiguration`, "The requested item schedule
configuration is invalid" (2026-11-16): a pipeline's schedules cannot be
listed by REST while it holds one, nor that schedule read.

**The typed run takes no body in the spec**, so it has no place to pass
pipeline `parameters`; the generic route does, below. Its documented
errors are
`InsufficientPrivileges`, `InvalidJobType`, `TooManyRequestsForJobs` and
`ItemNotFound` (`dataPipeline/swagger.json`, read 2026-10-20). The
schedule body's `jobType` and its `.schedules` shape are `data-pipeline.md`'s
§ 7; the `enabledDetail` that List Item Schedules returns is
`rest-api`'s, § Job Scheduling.

**The generic route takes `parameters` as an object**:
`POST .../items/{id}/jobs/instances?jobType=Pipeline` with
`{"executionData": {"parameters": {"<Name>": <value>}}}`, a boolean as a
JSON boolean, answers 202 with a `Location` to poll. An array of
`{name, type, value}`, the shape a dataflow run takes, fails within a
second as `RequestExecutionFailed`, `Failed to run the Pipeline:
Operation returned an invalid status code 'BadRequest'`: no activity
runs, and nothing names the parameters (five refusals and one completed
run on one pipeline, 2026-10-26; object-shape runs of another completed
on 2026-10-13). Learn's sample body carries `pipelineName` and two owner
fields and no parameters (read 2026-10-27); none of the runs above sent
owner fields, and whether a body with both is accepted is unmeasured.

## Measured deltas, and where to look next

- **Learn's definition page is incomplete.** It documents only
  `activities` and `description` under `properties`. Every real pipeline
  also carries `parameters`, `variables` and `libraryVariables` there, so
  do not "correct" a file by deleting them (verified against live exports
  2026-09-02). A pipeline with run conditions adds `runDimensions`,
  `dependencies` and `dependencyConnectionId`, which the page names
  nowhere (re-read 2026-11-16; shapes in REFERENCE.md § Run conditions).
  The envelope itself is `data-pipeline.md` § 2.
- **`Inactive`, not `InActive`.** The page's `ActivityState` table writes
  `InActive`, while its own `onInactiveMarkAs` row says "set to
  Inactive", and Azure Data Factory's
  [`KnownActivityState`](https://learn.microsoft.com/javascript/api/@azure/arm-datafactory/knownactivitystate)
  enum lists `Inactive` (both read 2026-11-07). Real files use
  `"state": "Inactive"`, which the portal emits and reads (live exports,
  2026-09-02; observed, no call recorded).
- **`ExecutePipeline` is the legacy activity, not `InvokePipeline`.**
  The page's enum row reads "Invokes another pipeline (deprecated, use
  ExecutePipeline)" (re-read 2026-11-16). Against it, all read
  2026-11-16: Learn's
  [Invoke pipeline activity](https://learn.microsoft.com/fabric/data-factory/invoke-pipeline-activity)
  page, "There are currently two Invoke pipeline activities. The Invoke
  pipeline (Legacy) only supports Fabric pipelines in the same workspace
  as your parent pipeline", where the new one alone needs a connection;
  the FabricUpgrader's
  [supported activities](https://learn.microsoft.com/fabric/data-factory/upgrade-pipelines-powershell-module-for-azure-data-factory-to-fabric#supported-functionality),
  "ExecutePipeline (converted to Fabric InvokePipeline Activity)"; and
  ADF's Execute Pipeline page, "The Fabric equivalent of Execute
  Pipeline activity is Invoke Pipeline activity." The page's own property
  tables agree: `InvokePipeline` requires `externalReferences`, and
  `ExecutePipeline` takes none. **No page maps either portal name to a
  `type`, and the portal probe that would is not run**: one client
  estate's older Git-synced pipelines hold 29 `ExecutePipeline`
  activities, none with a connection, and its newer ones 3
  `InvokePipeline`, each with a connection and `operationType`
  `InvokeFabricPipeline` (read 2026-11-16).
- **`referenceName` holds a `logicalId`, not a name.** The page's
  `PipelineReference` row says "Name of the referenced pipeline"; in
  that estate's Git-synced files, all 29 `ExecutePipeline` references
  equal a sibling item's `.platform` `logicalId` (2026-11-16). What a
  live `getDefinition` holds there is unmeasured.

Nothing else about the item's REST calls is measured here. When this file
runs out, read the spec's `swagger.json` and the operation's `examples/`
file, then Learn. Re-read the spec from the SHA above: its commits are
weekly, "Updating swagger files". The MCP server for pipelines is
[data-pipeline-mcp.md](data-pipeline-mcp.md).
