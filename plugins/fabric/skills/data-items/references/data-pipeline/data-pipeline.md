# Fabric Data Pipeline definitions

Covers the **Git-serialized** form of a DataPipeline item — the JSON an
agent edits when there is no portal to validate against.

**Not here, deliberately:** the expression language and its idioms
(`@concat`, `coalesce`, the ForEach variable race). Connection rebinding
across environments belongs to `deploy`. The `libraryVariables`
block's own mechanics belong to `variable-library`. Copy activity
source/sink/dataset internals are not covered at all.

An item's definition, REST calls and MCP server have files of their own.
Read one first for its job; past it, the REST spec's folder, then Learn, by `microsoft-learn-mcp`, or with no server, `curl -sL -H 'Accept: text/markdown' <page URL>` (undocumented, read 2026-11-07):

| The job | Read first |
| --- | --- |
| The definition parts, the REST calls past the generic seven (schedules, on-demand runs), or where Learn's page is wrong | [references/data-pipeline-api.md](references/data-pipeline-api.md) |
| The DataFactory MCP server: pipeline tools and their flag, and the dataflow and Airflow job tools it also serves | [references/data-pipeline-mcp.md](references/data-pipeline-mcp.md) |

A live page that contradicts a line here wins: say so, act on the page,
and route the fix by `capture-learning`, bar a dated measured line that
names the page it overrules and the call that measured it, which a page
changed since its date sends back to re-measure. An observed claim is
cited or marked pending a doc check, and stands, marked observed, only
where no page covers it.

## 1. What Git holds

The three files (`pipeline-content.json` required; `.platform` and
`.schedules` optional) are tabled in
[references/data-pipeline-api.md](references/data-pipeline-api.md).

Serialization mechanics are
[git-serialization.md](../git-serialization.md)'s: `pipeline-content.json`
ends at its last character, with no final newline.

## 2. The definition envelope

```json
{ "properties": {
    "activities": [ ... ],
    "parameters":       { "DryRun": { "type": "bool", "defaultValue": false } },
    "variables":        { "ChangedEntities": { "type": "Array", "defaultValue": [] } },
    "libraryVariables": { "EnvSuffix": { "type": "String",
        "variableName": "EnvironmentSuffix", "libraryName": "MyVarLib" } }
} }
```

**The REST schema page documents only `activities` and `description`**,
so do not delete `parameters`, `variables` or `libraryVariables` from a
file; the measurement is in
[references/data-pipeline-api.md](references/data-pipeline-api.md).
Leave any other `properties` key you do not recognise too: §3's run
conditions add `runDimensions`, `dependencies` and
`dependencyConnectionId`, which the page does not name either.

- `parameters` — set at trigger time, immutable during the run.
- `variables` — mutable, **pipeline-scoped, not iteration-scoped**.
- `libraryVariables` — Variable Library bindings; see
  `variable-library`. Read with
  `@pipeline().libraryVariables.<alias>`, and for the advanced types
  append `.connectionId`, `.itemId` or `.workspaceId`.

## 3. Activity anatomy

```json
{ "name": "IngestSource", "type": "TridentNotebook",
  "description": "…", "state": "Inactive", "onInactiveMarkAs": "Succeeded",
  "dependsOn": [ { "activity": "LookupConfig",
                   "dependencyConditions": [ "Succeeded" ] } ],
  "policy": { "timeout": "0.02:00:00", "retry": 1 },
  "typeProperties": { ... },
  "externalReferences": { "connection": "<guid or expression>" } }
```

`name` and `type` are required; `typeProperties` is required and its
shape is type-specific. `dependencyConditions` are `Succeeded`,
`Failed`, `Skipped`, `Completed` — an activity with several `dependsOn`
entries waits for **all** of them.

**Run conditions (preview)** are a pipeline-level layer above
`dependsOn`: they hold a pipeline's run until upstream runs, files or
time windows are ready, before any activity starts. **Learn publishes
no JSON for them, yet they serialize**, key for key the same in
`getDefinition` and in Git: the upstream's `properties.runDimensions`,
the downstream's `properties.dependencies` and
`dependencyConnectionId`, shaped in
[references/REFERENCE.md](references/REFERENCE.md), and a condition
written by `createItem` fired as a portal one did (a client sample
workspace, 2026-11-16, as is each bullet not marked Learn). Five
behaviours bite:

- **A condition starts the downstream on its own, more than once.** It
  needs no schedule, trigger or caller, against the pipeline-runs page's
  "Run conditions don't replace schedules or event triggers". Each
  upstream run gave two downstream runs, the first within a second of
  its last activity ending and the second within two seconds of its job
  closing; one covered window gave four. Make the downstream idempotent
  per value or window.
- **A repeated run-dimension value runs the downstream again.** Learn's
  run conditions page says a value "is evaluated once" and that a repeat
  doesn't "start another downstream run" (re-read 2026-11-16); five
  upstream runs carrying `A`, `A`, `B`, `C`, `C` ran it every time
  (downstream runs counted by `GET .../items/{id}/jobs/instances`, as
  are the counts above). Don't lean on that dedupe.
- **The upstream reference is a workspace item id**, not the
  `.platform` `logicalId` an `ExecutePipeline` reference holds
  ([references/data-pipeline-api.md](references/data-pipeline-api.md)),
  so a promoted downstream still points at the source workspace's
  upstream: rebind it (`deploy`) or set the condition again there.
- **An interval-based schedule does not serialize.** It writes no
  `.schedules` entry, so Git sync drops it, and with it the windows each
  Window coverage condition on that upstream waits for; whether a
  deployment pipeline carries one is unmeasured (REFERENCE.md
  § `.schedules`).
- **Several upstream pipelines means all of them**; there is no any-of
  (Learn, 2026-10-24).

No schedule type and no run condition gives a fixed gap between one
run's end and the next start; REFERENCE.md has the loop that does.

`externalReferences.connection` is a single connection GUID. It is not
source-controlled meaningfully across workspaces — parameterize it
(`deploy`) or bind it to a Variable Library connection reference.

## 4. Activity types

The REST definition's `DataPipelineActivityTypes` enum has 36 entries;
the full table is in [references/REFERENCE.md](references/REFERENCE.md).
Learn's activity overview lists more activities than the enum carries.

**Four newer activities have no documented `type` string**: Lakehouse
maintenance (GA), and Refresh SQL analytics endpoint, Business actions
and Fabric actions (all three preview), per What's New of 2026-10-02.
None is in the enum and no Learn page shows its JSON, and a guessed
string breaks the definition silently. Lakehouse maintenance doesn't yet
support lakehouses with schemas enabled (Learn, 2026-10-06).

The Fabric-specific enum entries and their required `typeProperties`:

| `type` | Required `typeProperties` | Notes |
| --- | --- | --- |
| `TridentNotebook` | `notebookId`, `workspaceId` | `parameters`, `sessionTag` optional; a `sessionTag` shares one Spark session across activities |
| `ExecutePipeline` | `pipeline` (`PipelineReference`) | **Legacy**, same workspace only; `waitOnCompletion` defaults **true** |
| `InvokePipeline` | — | The current one. A connection, `workspaceId` + `pipelineId`; `waitOnCompletion` defaults **false** |
| `SqlServerStoredProcedure` | `storedProcedureName` | `database`, `storedProcedureParameters` optional |
| `PBISemanticModelRefresh` | — | `groupId` + `datasetId`; `objects` scopes to partitions; `commitMode`, `maxParallelism` |
| `InvokeCopyJob` | — | Runs a Copy Job item |
| `RefreshDataFlow` | — | See the CI/CD trap in §8 |

**`InvokePipeline` is the current activity and `ExecutePipeline` the
legacy one**, though the REST page's enum calls `InvokePipeline`
deprecated, and moving between them is a rebinding, not a rename.
Learn's Invoke pipeline page names two: "The Invoke pipeline (Legacy)
only supports Fabric pipelines in the same workspace as your parent
pipeline", while the new one, which needs a connection, invokes across
workspaces, from ADF or Synapse, and monitors child pipelines (re-read
2026-11-16). No page maps either name to a `type`, and the portal probe
that would is not run; the evidence for this mapping is
[references/data-pipeline-api.md](references/data-pipeline-api.md)
§ Measured deltas. Three things change together:

- `InvokePipeline` targets a child by **GUID pair** (`workspaceId` +
  `pipelineId`) through a connection, which is what makes it
  parameterizable from a Variable Library item reference.
  `ExecutePipeline` targets by `pipeline.referenceName`, which Learn
  calls a name and Git-synced files hold as the child's `.platform`
  `logicalId`, with no workspace.
- `waitOnCompletion` flips default: **false** on `InvokePipeline`,
  **true** on `ExecutePipeline`. Set it explicitly either way; a
  fire-and-forget orchestrator silently becomes blocking, or the
  reverse.
- Cross-workspace calls, ADF and Synapse children and child monitoring
  are `InvokePipeline`'s alone.

So write `InvokePipeline` for a new call, and bulk-rewrite neither way:
each `InvokePipeline` needs a connection. Set `waitOnCompletion`
explicitly and confirm the child resolves.

## 5. `policy`

```json
"policy": { "timeout": "0.02:00:00", "retry": 1, "retryIntervalInSeconds": 60,
            "secureInput": false, "secureOutput": false }
```

`timeout` is `D.HH:MM:SS`. **Two different defaults apply and both are
correct.** The portal stamps an explicit `"0.12:00:00"` (12 hours) on
every activity it creates. Omit `policy.timeout` entirely — as
hand-written or generated JSON does — and the schema default is **7
days**. Omitting the field is not "taking the default"; it is a 14x
increase over what the portal writes. Set it explicitly.

- `retry` — portal default 1, schema default 0, range 1–1000.
- `retryIntervalInSeconds` — default 30, **min 30, max 86400**.
- `secureInput` / `secureOutput` — keep values out of monitoring logs.
  Set on any activity handling secrets or connection strings.

**`retryConditions` is preview and has a trap.** It gates retries on
error message, failure type or error code, so a retry is not spent on an
error that will never resolve:

```json
"retryConditions": { "type": "Expression",
  "value": "@equals(activity('Ingest').Error.FailureType, 'SystemError')" }
```

- Supported on **Copy, Notebook, Dataflow and Stored procedure**
  activities only. On any other type it is silently inert.
- **The retry interval elapses before the condition is evaluated.** A
  1-hour interval with a condition that does not match still costs the
  full hour before the run moves on. Keep intervals short where a
  condition is in play.
- With no `retryConditions`, the activity retries on **every** failure.

## 6. Deactivate rather than delete

Fabric has no separate debug mode — deactivation *is* the debugging
mechanism, and Microsoft recommends it over deletion for preserving
structure.

```json
"state": "Inactive", "onInactiveMarkAs": "Succeeded"
```

| `onInactiveMarkAs` | Branch that runs |
| --- | --- |
| `Succeeded` (default) | `UponSuccess`, `UponCompletion` |
| `Failed` | `UponFailure`, `UponCompletion` |
| `Skipped` | `UponSkip` |

The dependency edge **is** honoured — the value above chooses which
branch fires. What does not exist is the activity's output: an inactive
activity never runs, so it has **no `Error` field and no output
fields**, and any downstream expression reading
`activity('Skipped').output…` fails. Deactivating one activity can break
an expression two steps away.

An inactive activity is also excluded from validation, which is what
makes it usable as a placeholder before its connections exist.

**Spelling:** real files use `"state": "Inactive"`, not the REST schema
page's `InActive`, which the page's own prose and Azure Data Factory's
enum contradict
([references/data-pipeline-api.md](references/data-pipeline-api.md)).

## 7. `.schedules`

Creating a schedule in the portal writes this file into the item
definition, so schedules deploy with the pipeline, bar an
interval-based one, which writes nothing (§ 3).

```json
{ "$schema": "https://developer.microsoft.com/json-schemas/fabric/gitIntegration/schedules/1.0.0/schema.json",
  "schedules": [ { "enabled": true, "jobType": "Execute",
    "configuration": { "type": "Weekly",
      "startDateTime": "2026-08-17T00:00:00",
      "endDateTime": "9999-12-31T23:59:00",
      "localTimeZoneId": "Eastern Standard Time",
      "times": [ "06:00" ],
      "weekdays": [ "Monday", "Tuesday" ] } } ] }
```

`jobType` is `"Execute"` for a pipeline. **This is a different enum from
the run-on-demand REST API**, where a pipeline is `jobType: Pipeline`
(see `rest-api`). Do not copy one into the other.

`configuration.type` is `Cron`, `Daily`, `Weekly` or `Monthly`:

| Type | Fields |
| --- | --- |
| `Cron` | `interval` — **minutes**, not a cron expression |
| `Daily` | `times[]` (`hh:mm`, ≤ 100) |
| `Weekly` | `times[]` + `weekdays[]` |
| `Monthly` | `times[]`, `recurrence`, `occurrence{occurrenceType, dayOfMonth \| weekIndex + WeekDay}` |

Five traps:

- **`endDateTime` is mandatory and there is no open-ended schedule.** A
  schedule silently stops firing at its end date with no error and no
  alert. Use a far-future sentinel — `9999-12-31T23:59:00`. Treat any
  end date within a few years as a bug.
- **`Cron` means a fixed interval in minutes.** It accepts no crontab
  expression. Anything calendar-shaped needs `Daily`/`Weekly`/`Monthly`.
- **The scheduler auto-disables after consecutive failures** (threshold
  varies by item, typically 10) and must be restarted by hand. A
  pipeline that "stopped running" after a bad week is this, not a
  schedule that was deleted.
- **First commit after enabling CI/CD is noisy.** Every item that
  already had a schedule shows as uncommitted. Review rather than
  bulk-committing.
- **To switch a schedule per environment, bind it rather than flip
  it.** The *Edit schedule* pane's *Controller* binds on/off to a
  Variable Library Boolean, and the entry then holds
  `"enabledVariableReference": "$(/**/<library>/<variable>)"` and
  `"enabledControlType": "VariableReferenceManaged"` in place of
  `enabled`. Each workspace resolves the variable against its own active
  value set, and Git sync and a first deploy each kept the binding (a
  client estate, 2026-10-13; Learn names the Controller only for a user
  data function, 2026-10-14). A flip is then a value-set edit, timed in
  `variable-library`, and a script that flips `enabled` finds
  nothing to flip. **On an unbound entry, turning a schedule off in Git
  means deleting `enabledControlType`
  too.** A portal edit can add `"enabledControlType": "UserEnabled"`
  beside `enabled`, and an update from Git then refuses `false`:
  `'enabled' is required to be true when 'enabledControlType' is 'UserEnabled'`
  (`GitSyncFailed`). Set `false` and delete the line in one edit, and
  have a script that flips the flag do both and fail if the pair survives
  (seen in a client estate, 2026-10-13; on no Learn page).

Also: max **20 schedules** per pipeline; `enabled: false` with no
`enabledControlType` beside it is a real state that survives Git sync
and deployment, so a disabled schedule promotes as disabled. A bound
entry fails the published schema, which requires `enabled`, though the
portal writes it ([references/REFERENCE.md](references/REFERENCE.md)).

## 8. CI/CD limitations specific to pipelines

Parameterisation and `parameter.yml` are `deploy`'s. These four
are pipeline-shaped and bite after promotion:

- **A promoted pipeline that invokes a dataflow still points at the
  source workspace's dataflow.** The reference is not rebound:
  deployment pipelines list Dataflow Gen2 as supported but do not
  autobind it. Learn's pipeline CI/CD page still gives the older
  reason, that dataflows are unsupported (2026-10-09). Verify after
  every promotion.
- **Teams and Outlook activities need a manual sign-in per activity** in
  each target workspace — OAuth connections do not deploy.
- **Workspace variables are unsupported by CI/CD.**
- **A pipeline's activities run as its last modifier**, so a publish by
  a service principal makes every later run that principal's. A
  notebook a pipeline runs "runs under the identity of the pipeline's
  last modified user"
  (Learn, *How to use Microsoft Fabric notebooks*, read 2026-11-18), and
  a `PATCH` of name or description makes a principal that user
  (Learn, *Set a service principal as a pipeline owner*, read 2026-11-18).
  A fabric-cicd publish did, and a run started by hand then went through
  as the deploy principal (observed 2026-11-18, fabric-cicd 1.4.0).
  Grant it what the runs need: User on each connection an activity
  binds directly; User on the Fabric Azure Key Vault reference behind a
  connection whose secret it holds, whose lack failed an Invoke Pipeline
  activity `DMTS_UserIsNotAllowedToAccessAzureKeyVaultConnectionErrorCode`
  with User on the connection already (observed 2026-11-18), Learn
  documenting no roles on a reference, though its ⋯ menu offered User;
  and, for code reading secrets as the run identity, such as
  `notebookutils.credentials.getSecret`, a vault data role (`azure-core`'s
  `access`; inferred, not seen failing). Which identity a scheduled run
  takes is unmeasured: Learn gives a scheduled notebook its schedule's
  creator or last updater, and a publish without `.schedules` keeps the
  schedule's owner (`deploy`'s `references/fabric-cicd.md`, *Item-type
  caveats*).

## 9. Limits

| Limit | Value |
| --- | --- |
| Activities per pipeline | 120, inner container activities included |
| Schedules per pipeline | 20 |
| `retry` | 1–1000 |
| `retryIntervalInSeconds` | 30–86400 |
| `timeout` | max 7 days |
| `times[]` per schedule | 100 |

## Reference

- [DataPipeline definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/datapipeline-definition) — the authoritative schema
- [Activity overview](https://learn.microsoft.com/fabric/data-factory/activity-overview) — general settings, deactivation, the 120 cap
- [Invoke pipeline activity](https://learn.microsoft.com/fabric/data-factory/invoke-pipeline-activity) — the legacy and the current invoke activity
- [Activity retries](https://learn.microsoft.com/fabric/data-factory/activity-retries) — retry conditions and interval types
- Full activity-type enum, per-activity `typeProperties` tables, the
  complete `.schedules` schema and worked examples of all four
  configuration shapes: [references/REFERENCE.md](references/REFERENCE.md)
