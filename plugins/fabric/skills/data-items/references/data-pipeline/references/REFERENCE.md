# Fabric Data Pipeline — reference

Long-form detail behind [`data-pipeline.md`](../data-pipeline.md). Field tables are
transcribed from the [DataPipeline definition
reference](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/datapipeline-definition);
enum values and limits were cross-checked against live Git-synced
exports on 2026-09-02.

## `DataPipelineActivityTypes` — the full enum

36 values, as the REST definition lists them (re-counted 2026-10-06).
Activities newer than the enum, with no documented `type`, are in
[data-pipeline.md](../data-pipeline.md) §4. The ones marked **Fabric** have no Azure
Data Factory equivalent and are where an ADF-trained assumption goes
wrong.

| `type` | What it does |
| --- | --- |
| `Copy` | Copies data from a source to a destination |
| `Lookup` | Retrieves data for use in later activities |
| `GetMetadata` | Retrieves metadata from a data source |
| `Delete` | Deletes data from a data source |
| `Script` | Runs query or nonquery SQL against a database store; see below |
| `SqlServerStoredProcedure` | Runs a stored procedure in a T-SQL store; see below |
| `KustoQueryLanguage` | Executes a KQL query on Azure Data Explorer |
| `IfCondition` | Branches on a conditional expression |
| `Switch` | Branches on a switch expression |
| `ForEach` | Iterates a collection |
| `Until` | Repeats until a condition is met |
| `Filter` | Filters an array on a condition |
| `Wait` | Pauses execution for a duration |
| `Fail` | Explicitly fails the pipeline with a message and error code |
| `SetVariable` | Sets an existing variable |
| `AppendVariable` | Appends to an existing array variable |
| `ExecutePipeline` | **Legacy.** Executes another pipeline in the same workspace |
| `InvokePipeline` | Invokes another pipeline through a connection; the current one |
| `TridentNotebook` | **Fabric.** Executes a Fabric (Trident) notebook |
| `SparkJobDefinition` | **Fabric.** Executes a Spark job definition |
| `InvokeCopyJob` | **Fabric.** Invokes a Copy Job item |
| `RefreshDataFlow` | **Fabric.** Refreshes a dataflow |
| `PBISemanticModelRefresh` | **Fabric.** Refreshes a Power BI semantic model |
| `DatabricksNotebook` | Databricks notebook / Spark JAR / Spark Python |
| `AzureHDInsight` | Hive, Pig, MapReduce, Streaming or Spark on HDInsight |
| `AzureMLExecutePipeline` | Azure ML batch execution / update resource / pipeline |
| `AzureFunction` | Executes an Azure Function |
| `Custom` | Azure Batch — a custom command |
| `ExecuteSSISPackage` | Executes an SSIS package |
| `DataLakeAnalyticsScope` | Runs a Scope script on Data Lake Analytics |
| `WebActivity` | HTTP request to an external service |
| `WebHook` | Calls a webhook and waits for a callback |
| `Office365Email` | Sends mail via Office 365 |
| `Email` | Sends an email notification |
| `MicrosoftTeams` | Posts to Microsoft Teams |
| `Teams` | Posts to Teams |

Four rows depart from the REST page. It says `Script` "Executes
custom scripts (PowerShell, Python, etc.)" and `SqlServerStoredProcedure`
"Executes a stored procedure in SQL Server". The activities' own Learn
pages, read 2026-10-13, list only database stores for Script, Fabric
Data Warehouse among them, and seven T-SQL stores for the Stored
procedure activity, Fabric Data Warehouse and SQL database included.
The two pipeline rows reverse the REST page's "deprecated, use
ExecutePipeline": [data-pipeline-api.md](data-pipeline-api.md)
§ Measured deltas has why.

## `typeProperties` — the Fabric-specific activities

Only these five are transcribed. Copy activity internals
(`CopySource`, `CopySink`, `CopyTranslator`, `TypeConversionSettings`,
`StagingSettings`, `DatasetSettings`) and per-connector properties are
**not covered by this skill** — go to the definition reference.

### `TridentNotebook`

| Field | Type | Required |
| --- | --- | --- |
| `notebookId` | String | yes |
| `workspaceId` | String | yes |
| `parameters` | Object | no |
| `sessionTag` | String | no |

`parameters` entries are doubly wrapped — an outer `{value, type}` where
the inner `value` is itself an Expression object:

```json
"parameters": { "DRY_RUN": {
  "value": { "value": "@pipeline().parameters.DryRun", "type": "Expression" },
  "type": "bool" } }
```

A parameter the notebook does not declare is ignored; a declared
parameter left unset takes the notebook's own default. `sessionTag`
shares one Spark session across activities carrying the same tag, which
removes per-activity session start-up cost.

`externalReferences` is optional here.

### `ExecutePipeline` (legacy)

| Field | Type | Required |
| --- | --- | --- |
| `pipeline` | `PipelineReference` | yes |
| `parameters` | Object | no |
| `waitOnCompletion` | Boolean | no — **default `true`** |

`PipelineReference` is `{ "referenceName": "<child's logicalId>",
"type": "PipelineReference" }`: Learn's row says a name, and Git-synced
files hold the child's `.platform` `logicalId`
([data-pipeline-api.md](data-pipeline-api.md) § Measured deltas).
`policy` is marked **required** on this activity.

### `InvokePipeline`

| Field | Type | Required |
| --- | --- | --- |
| `workspaceId` | String | no |
| `pipelineId` | String | no |
| `operationType` | String | no — `InvokeFabricPipeline` in practice |
| `parameters` | Object | no |
| `waitOnCompletion` | Boolean | no — **default `false`** |

`externalReferences` is **required** here. The GUID pair is what makes
this form parameterizable from a Variable Library item reference:

```json
"pipelineId":  { "value": "@pipeline().libraryVariables.ItemRefChild.itemId",      "type": "Expression" },
"workspaceId": { "value": "@pipeline().libraryVariables.ItemRefChild.workspaceId", "type": "Expression" }
```

`ExecutePipeline` has no equivalent — it binds by `referenceName`,
which Git-synced files hold as the child's `logicalId`, in its own
workspace. That is the substance of moving between the two, not the
type string.

### `SqlServerStoredProcedure`

| Field | Type | Required |
| --- | --- | --- |
| `storedProcedureName` | String | yes |
| `database` | String | no |
| `storedProcedureParameters` | Object | no |

Accepts `externalReferences`, `linkedService` and `connectionSettings`.

### `PBISemanticModelRefresh`

| Field | Type | Required |
| --- | --- | --- |
| `groupId` | String | no — workspace ID |
| `workspaceId` | String | no |
| `datasetId` | String | no |
| `method` | String | no |
| `type` | String | no — refresh type |
| `commitMode` | String | no |
| `maxParallelism` | Integer | no |
| `retryCount` | Integer | no |
| `objects` | Array | no — table/partition scope |
| `waitOnCompletion` | Boolean | no — **default `false`** |
| `operationType` | String | no |
| `inputs` | `LogicAppsActivityInput` | no |

`externalReferences` is **required** — a Power BI connection. One that
signs in as a service principal is authorized by tenant settings and a
workspace role, not by API permissions (`rest-api`'s
`references/auth.md`).

`objects` scopes the refresh to named tables or partitions instead of
the whole model, and takes an expression, so the set can be computed
upstream:

```json
"objects": { "value": "@activity('FilterChangedTables').output.Value", "type": "Expression" }
```

With no `objects`, the whole model refreshes: two runs against a Direct
Lake model, one without `type` and one `Full`, each refreshed every
table as `Full` (2026-10-07), as Learn's enhanced refresh says, "If no
objects are specified, the entire model refreshes". A list naming a
table the model lacks fails the whole refresh within a second, its real
tables too: `The specified table '<T>' not found in the target model.`
(once, 2026-10-07; Learn is silent). Intersect a computed list with the
model's tables, or omit it, since framing makes a whole Direct Lake
refresh cheap.

`commitMode: "Transactional"` makes the refresh all-or-nothing.
`retryCount` here is the *refresh's* retry, distinct from
`policy.retry`, which retries the activity.

## Activity `policy`

| Field | Type | Default | Range |
| --- | --- | --- | --- |
| `timeout` | String / Expression | 7 days when absent; portal writes `0.12:00:00` | max 7 days |
| `retry` | Integer / Expression | 0 in schema, 1 in the portal | 1–1000 |
| `retryIntervalInSeconds` | Integer | 30 | 30–86400 |
| `secureInput` | Boolean | false | — |
| `secureOutput` | Boolean | false | — |
| `retryConditions` | Expression | none — retries on all failures | preview |

`timeout` pattern: `((\d+).)?(\d\d):(\d\d):(\d\d)`, i.e. `D.HH:MM:SS`.

**Retry interval types.** The portal offers Fixed (default — the same
wait every attempt) and Increasing Delay (exponential back-off: each
retry waits a random interval from a range that doubles per attempt,
bounded by a configured maximum). The randomization is deliberate — it
stops concurrent pipeline retries from colliding on the same upstream
system. That maximum, **Max retry interval (sec)**, defaults to 3,600.
**Retry interval fields take static integers only**; they accept no
dynamic expression (Learn, 2026-10-06).

**`retryConditions` matching fields** are error message, failure type
(user vs system error) and error code, combined with And/Or. The common
case is `Error code contains 429` for rate limiting. Supported on Copy,
Notebook, Dataflow and Stored procedure activities only.

## `.schedules` — full schema

Declared `$schema`:
`https://developer.microsoft.com/json-schemas/fabric/gitIntegration/schedules/1.0.0/schema.json`

The schema trails the portal three ways: it lacks `enabledControlType`
and `enabledVariableReference`; it requires `enabled`, which a bound
entry omits; and it puts `parameters` where no portal-written file does
(all below; the entry's definition re-read 2026-10-14). Read a
portal-written file before trusting the schema's shape.

Top level is `{ "schedules": [ … ] }`. Each entry:

| Field | Notes |
| --- | --- |
| `enabled` | Boolean, schema-required, and **absent on a bound entry** (`enabledVariableReference` below). Unbound, it survives Git sync and deployment — a disabled schedule promotes disabled — with no `enabledControlType` beside it |
| `enabledControlType` | **Not in the schema**, which sets no `additionalProperties`, so neither declares nor forbids it; no Learn page names it, and Learn's two `.schedules` screenshots lack it (all 2026-10-13). Two values seen: `"UserEnabled"`, which a portal edit wrote and beside which Git sync refused `enabled: false` (`data-pipeline.md` § 7), and `"VariableReferenceManaged"`, which a Controller binding writes (both a client estate, 2026-10-13). What turning a schedule off or the scheduler's auto-disable writes is unread |
| `enabledVariableReference` | **Not in the schema** either. A Controller binding's Boolean variable, as `$(/**/<library>/<variable>)`, the form of a shortcut's target, written with `enabledControlType: "VariableReferenceManaged"` in place of `enabled`. A portal binding changed only those two lines; Git sync kept them in a workspace whose schedule was unbound, and a deployment pipeline carried them (a client estate, 2026-10-13). Whether a notebook's or a user data function's `.schedules` takes it is unread |
| `jobType` | `"Execute"` for pipelines. The schema declares **no enum**, so treat this as observed rather than validated |
| `configuration` | Below; `type` is the only schema-required field |
| `parameters` | An array the portal writes **here, beside `configuration`**: `[]` on a schedule that passes none. The schema puts it under `configuration` instead (below) |

`configuration` fields, by `type`:

| Field | `Cron` | `Daily` | `Weekly` | `Monthly` |
| --- | --- | --- | --- | --- |
| `startDateTime` | ✓ | ✓ | ✓ | ✓ |
| `endDateTime` | ✓ | ✓ | ✓ | ✓ |
| `localTimeZoneId` | ✓ | ✓ | ✓ | ✓ |
| `interval` (minutes) | ✓ | — | — | — |
| `times[]` (`hh:mm`, ≤ 100) | — | ✓ | ✓ | ✓ |
| `weekdays[]` (≤ 7) | — | — | ✓ | — |
| `recurrence` | — | — | — | ✓ |
| `occurrence` | — | — | — | ✓ |

`occurrence` is `{ occurrenceType (required), dayOfMonth, weekIndex,
WeekDay }` — note the capitalized `WeekDay`.

The schema declares `parameters` only under `configuration`: an array of
`{ name, type, value }`, all three required, whose `type` takes one
value, `VariableReference` (schema 1.0.0, read 2026-10-13). Every
portal-written file read so far puts the array beside `configuration`
instead: a client pipeline's commit and its `getDefinition`, two public
pipelines' `[]`, and a public Dataflow's list of one item typed
`"Text"`, outside that enum (all read 2026-10-13). Write it where the
portal does. No pipeline schedule that passes parameters has been read,
so a pipeline item's shape is unconfirmed. Learn's job-scheduler page
warns that a Variable Library used in the parameters can sync late after
CI/CD. A Controller binding is no such parameter: it writes
`enabledVariableReference` and left the entry's `"parameters": []` as
it was (a client estate, 2026-10-13).

The schema marks only `configuration.type` required; the portal requires
both `startDateTime` and `endDateTime` and offers no open-ended option.

### Worked examples

```json
{ "enabled": true, "jobType": "Execute", "configuration": {
    "type": "Cron", "interval": 15,
    "startDateTime": "2026-01-01T00:00:00", "endDateTime": "9999-12-31T23:59:00",
    "localTimeZoneId": "Eastern Standard Time" } }
```

```json
{ "enabled": true, "jobType": "Execute", "configuration": {
    "type": "Daily", "times": [ "01:00" ],
    "startDateTime": "2026-01-01T00:00:00", "endDateTime": "9999-12-31T23:59:00",
    "localTimeZoneId": "Eastern Standard Time" } }
```

```json
{ "enabled": true, "jobType": "Execute", "configuration": {
    "type": "Weekly", "times": [ "06:00" ],
    "weekdays": [ "Monday", "Tuesday", "Wednesday", "Thursday", "Friday" ],
    "startDateTime": "2026-01-01T00:00:00", "endDateTime": "9999-12-31T23:59:00",
    "localTimeZoneId": "Eastern Standard Time" } }
```

```json
{ "enabled": true, "jobType": "Execute", "configuration": {
    "type": "Monthly", "times": [ "00:15" ], "recurrence": 1,
    "occurrence": { "occurrenceType": "DayOfMonth", "dayOfMonth": 1 },
    "startDateTime": "2026-08-01T00:00:00", "endDateTime": "9999-12-31T23:59:00",
    "localTimeZoneId": "Eastern Standard Time" } }
```

**Interval-based schedules (preview)** are a separate portal option, not
one of the four types above, and **they write no `.schedules` entry**.
Adding one left its pipeline unchanged in Git status for seven minutes,
where a `Cron` schedule made by REST on another pipeline showed it
Modified at once; `getDefinition` returned no `.schedules` part; and
both REST schedule routes, generic and typed, listed or by id, then
refused that pipeline, HTTP 400 `InvalidConfiguration`, "The requested
item schedule configuration is invalid" (a client sample workspace,
2026-11-16, as is the rest of this list). So Git holds none: make it
again by hand after a deploy from Git, and read the target's schedules
before adding one after a deployment-pipeline deploy, which Learn's
job-scheduler page says includes an item's schedules (unmeasured for
this type).

- Its form takes **Concurrent max updates** and drops the fixed form's
  **Controller**, so no Variable Library binding (`data-pipeline.md`
  § 7) switches it per environment.
- Its first run comes one interval after its start, not at it.
- It adds **Window start time** and **Window end time** under **Trigger
  parameters** in the expression builder, a downstream's with a Window
  coverage condition on it included. Window start time inserts
  `@pipeline()?.TriggerEvent?.windowStartTimeUtc`, not ADF's
  `@trigger().outputs.windowStartTime`, and in a window-coverage run it
  evaluated to that downstream's own window start, `2026-11-16T20:30:00Z`,
  not to the upstream window's, which began at 20:38. Window end time's
  insert is unread.

Learn's pipeline-runs page adds (2026-10-24):

- An interval-based schedule cannot be enabled, disabled or edited, only
  deleted and recreated.
- Time-slice monitoring and backfill are not yet available.
- It is the schedule a window-coverage run condition requires of each
  upstream pipeline (below).

## Run conditions (preview)

From Learn's [run conditions page](https://learn.microsoft.com/fabric/data-factory/pipeline-run-conditions),
read 2026-10-24 and re-read 2026-11-16, and a probe in a client sample
workspace (2026-11-16); the behaviours that bite are `data-pipeline.md`
§ 3. A run condition is set on the downstream pipeline, in the portal's
**Run conditions** tab, and a run dimension on the upstream, in the
bottom panel's **Run dimensions (Preview)** tab beside Parameters.

| Type | Holds the run until | Settings |
| --- | --- | --- |
| Custom | each selected upstream has a matching run on the run dimension | name, run dimension, connection, upstream pipelines |
| Data availability | files exist at a OneLake or ADLS path | name, connection, path with a prefix or suffix filter |
| Window coverage | the upstream windows covering this window have succeeded | name, connection, window size, upstream pipelines, offset |

The probe's definitions, as the portal wrote them and as Git and
`getDefinition` both returned them, each condition on its own
downstream:

```jsonc
// upstream, under properties
"runDimensions": { "Region": "@pipeline().parameters.region" }

// downstream, under properties: a Custom condition
"dependencies": [ { "type": "pipeline", "typeProperties": {
    "dependencyName": "rc_custom",
    "dependsOn": [ { "referenceName": "<upstream item id>", "type": "PipelineReference" } ],
    "matchOn": { "type": "label", "key": "Region" } } } ],
"dependencyConnectionId": "<connection GUID>"

// a Window coverage condition's entry
{ "type": "pipeline", "typeProperties": {
    "dependencyName": "rc_window",
    "dependsOn": [ { "referenceName": "<upstream item id>", "type": "PipelineReference",
                     "offset": "00:00:00" } ],
    "matchOn": { "type": "windowCoverage", "windowSize": "00:15:00",
                 "anchor": "2026-11-16T20:15:00Z" } } }
```

- **`runDimensions`** maps a name to a string. An expression is stored
  as a bare `@` string, not as an `{ "value", "type": "Expression" }`
  object, and what it evaluated to shows in neither a job instance nor
  an activity run read by REST.
- **`matchOn.type`** is `label` for Custom, its `key` the dimension's
  name, and `windowCoverage` for Window coverage. Data availability's
  entry is unread.
- **`referenceName`** is the upstream's workspace item id, so a
  promoted downstream needs it rebound (`data-pipeline.md` § 3).
- **`dependencyConnectionId`** sits beside the list. The portal took an
  organizational account, a service principal or a workspace identity,
  and every run a condition starts shows in monitoring as submitted by
  that identity, its job instance's `invokeType` `Manual`.
- **`offset`** defaulted to `-01:00:00` in the portal, and **`anchor`**
  to the current UTC time rounded down to the window size; the portal
  says editing the anchor later shifts every future window.

A **run dimension** is the key that pairs upstream and downstream runs
of one unit of work: Learn's example is `Region=WestEurope` with
`ProcessingDate=2026-09-18`. Learn says a downstream runs once per
value; measured, it ran on every repeat (`data-pipeline.md` § 3).

Window coverage matches windows or aggregates them, so a daily
downstream waits for every hourly upstream window it covers. A failed
upstream window blocks the downstream until a rerun of that window
succeeds (Learn). A window the upstream's did not cover, its schedule
starting eight minutes in, gave two runs that ran no activity and
failed six minutes later, `JobInstanceStatusNotFound`, "Job instance
not found"; the next window, covered, gave four runs, each succeeding.
Data availability tests only that files exist, not that any pipeline
succeeded. An upstream may sit in another workspace, given access to
both pipelines.

Unread on 2026-11-16: what the condition's connection authorizes; how
long a held run waits, and whether it counts toward the 100 queued runs
a pipeline may hold (Learn's Data Factory limits page); what a held run
costs in CU; and how two conditions on one downstream combine.

## A fixed gap between runs

No schedule gives a fixed gap between one run's end and the next start.
`Cron` is a fixed clock interval (`data-pipeline.md` § 7), interval-based
windows are fixed and non-overlapping, and no run condition waits on
the pipeline's own previous run (Learn, 2026-10-24). A loop in a
pipeline that an ordinary schedule starts once a day does it:

- An `Until` whose condition ends the day, such as the local hour
  reaching a cut-off, with its own `timeout` covering the whole window.
- Inside it, the child call with `waitOnCompletion: true` set explicitly
  (`data-pipeline.md` § 4), then a `Wait` for the gap.
- The `Wait` depends on `Completed`, not `Succeeded`. An inner failure
  does not stop an `Until` (Learn's Until activity page), so on
  `Succeeded` a failed child skips the gap and the next child starts at
  once.
- Give the child call a `policy.timeout` longer than any child run.
  Whether a timeout cancels the child is on no Learn page, and a child
  left running would overlap the next iteration.

A client estate runs this shape on a weekday schedule (read 2026-10-24).

## Microsoft Learn links

### Definition and activities

- [DataPipeline definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/datapipeline-definition) — schema of record for every field above
- [Activity overview](https://learn.microsoft.com/fabric/data-factory/activity-overview) — general settings, the 120-activity cap, deactivation semantics
- [Activity retries](https://learn.microsoft.com/fabric/data-factory/activity-retries) — retry counts, interval types, preview retry conditions
- [Debug pipelines in Microsoft Fabric](https://learn.microsoft.com/fabric/data-factory/how-to-debug-pipelines-in-microsoft-fabric) — the iterative deactivate-and-reactivate workflow

### Scheduling

- [Job scheduler in Microsoft Fabric](https://learn.microsoft.com/fabric/fundamentals/job-scheduler) — `.schedules` in CI/CD, scheduler auto-disable, the uncommitted-on-enable note
- [Run, schedule, or use events to trigger a pipeline](https://learn.microsoft.com/fabric/data-factory/pipeline-runs) — mandatory start/end dates, the 20-schedule cap, interval-based schedules
- [Run conditions in Fabric pipelines](https://learn.microsoft.com/fabric/data-factory/pipeline-run-conditions) — the three condition types, run dimensions, window coverage
- [Fabric CI/CD concepts and best practices](https://learn.microsoft.com/fabric/fundamentals/understand-best-practices-fabric-cicd) — `.schedules` as part of a data-orchestration strategy

### CI/CD

- [CI/CD for pipelines in Data Factory](https://learn.microsoft.com/fabric/data-factory/cicd-pipelines) — the known-limitations list (dataflow rebinding, OAuth connectors, workspace variables)
- [Variable library integration with pipelines](https://learn.microsoft.com/fabric/data-factory/variable-library-integration-with-data-pipelines) — the `libraryVariables` consumer side; property access for connection and item references

### Error handling

- [Errors and conditional execution](https://learn.microsoft.com/azure/data-factory/tutorial-pipeline-failure-error-handling) — Try-Catch / Do-If-Else patterns and the four conditional paths. Authored for ADF, applies unchanged
- [Fail activity](https://learn.microsoft.com/fabric/data-factory/fail-activity) — deliberate failure with a message and error code
