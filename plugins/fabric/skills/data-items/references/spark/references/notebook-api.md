# Notebook: definition and REST

A notebook's definition shape, what a cell must look like to upload, and
the REST operations it has beyond the generic item set. Generic CRUD,
`getDefinition` and `updateDefinition`, long-running operations and
pagination are `rest-api`'s, § Definition APIs and § Long-Running
Operations.

| | |
| --- | --- |
| REST `type` | `Notebook`, under `/workspaces/{ws}/notebooks/{id}` |
| Git folder | `<display name>.Notebook/` |
| Learn definition | [Notebook definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/notebook-definition) |
| Spec folder | [`notebook/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/notebook): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `a96c37a`, 2026-10-20: 12 operations |

## Definition

Two formats, `ipynb` and `FabricGitSource`. **When `format` is omitted,
Learn's definition page and the spec's `getDefinition` both say
`FabricGitSource`** (read 2026-10-20), though `ipynb` was long recorded
here as the default. Name the format on every call; which
one a call returns when it is omitted is unmeasured here. The spec spells
the query value `fabricGitSource`, Learn `FabricGitSource`. One content
part, plus the platform part:

| Path | Required | Holds |
| --- | --- | --- |
| `notebook-content.ipynb` | for `ipynb` | the notebook as Jupyter JSON |
| `notebook-content.py`, `.sql`, `.scala` or `.r` | for `FabricGitSource` | the notebook as source in its language: PySpark or Python, Spark SQL, Scala, SparkR |
| `.platform` | no | the item's metadata; `getDefinition` always returns it, and `updateDefinition` reads it only with `?updateMetadata=true` |

Learn's page names a single content part and shows `artifact.content.ipynb`
as its example path, which is neither of the names above; the Git folder
and `rest-api` use `notebook-content.*`. The Git folder can also
hold `notebook-settings.json` and `fs-settings.json`, and a `Resources/`
folder (Learn's notebook source control page, read 2026-10-20); whether
`getDefinition` returns them is unmeasured.

### Cells for the REST definition APIs

When creating notebooks via REST API, every code cell must include
`"outputs": []` and `"execution_count": null`.

**Cell `source` must be an array of strings, not a bare string.** nbformat
permits either, but Fabric's UI upload (`createArtifact`) and the REST
definition APIs reject the bare-string form with a generic
`400 exceptionCulprit:1` that gives no clue which field is wrong. Split on
`\n` and append `\n` to every line except the last — the standard nbformat
convention:

```json
"source": ["line one\n", "line two\n", "last line"]
```

Not:

```json
"source": "line one\nline two\nlast line"
```

Applies to every cell in the notebook, markdown and code. A single
bare-string source anywhere in the file fails the whole upload.

**Default lakehouse binding** uses `metadata.dependencies.lakehouse` in the
notebook content — auto-mounts at runtime so `spark.read.table("schema.table")`
resolves without 3-part naming:

```json
{
  "metadata": {
    "dependencies": {
      "lakehouse": {
        "default_lakehouse": "<lakehouse-id>",
        "default_lakehouse_workspace_id": "<workspace-id>",
        "default_lakehouse_name": "<lakehouse-name>"
      }
    }
  }
}
```

One default lakehouse per notebook. Additional lakehouses are reachable via
3-part names (`spark.md` § Lakehouse Setup). In `FabricGitSource` the same
block sits in the `# META` comments at the top of `notebook-content.py`,
with a `known_lakehouses` list beside the three ids (Learn's CI/CD best
practices page, read 2026-10-20).

## Git is not the live definition

A notebook committed to Git is stored as source files with no cell output,
and its attached lakehouse and environment are written as logical ids
rather than physical ones, so a diff can show metadata changing while the
code does not (Learn's notebook source control page, read 2026-10-20).
What a live `getDefinition` holds for those ids is unmeasured here;
`rest-api` § Definition APIs has what it holds for `.platform`.
Normalize both before diffing a live notebook against its folder.

## REST beyond the generic set

Under `https://api.fabric.microsoft.com/v1/workspaces/{ws}/notebooks/{id}/`.
The notebook-specific `updateDefinition` that `rest-api` § Definition
APIs names is the typed one of the generic set, at
`/workspaces/{ws}/notebooks/{id}/updateDefinition`. Learn lists the run
under *Background Jobs* and the sessions under *Livy Sessions*. The table
is `spec-ops.py`'s, at the SHA above, with *On Learn*
and *Measured* filled in. The Livy listings are measured in
[spark-monitoring.md](spark-monitoring.md), which also holds what a
session's fields mean; the logs behind a session are in
[spark-monitoring-apis.md](spark-monitoring-apis.md).

| Method | Path tail | Does | Body | Flags | On Learn | Measured |
| --- | --- | --- | --- | --- | --- | --- |
| `GET` | `livySessions` | Returns a list of livy sessions from the specified item identifier | | | yes | 2026-08-17 |
| `GET` | `livySessions?beta=true` | Returns a list of livy sessions from the specified item identifier (beta) | | beta | yes | no |
| `GET` | `livySessions/{livyId}` | Returns properties of the specified livy session | | | yes | no |
| `POST` | `jobs/execute/instances?beta=false` | Run on-demand notebook job instance | `executionData`, `parameters` | LRO | yes | no |
| `GET` | `jobs/execute/instances/{jobInstanceId}?beta=true` | Get one notebook's job instance | | beta | yes | 2026-10-23 |

The spec marks the `beta` query parameter of the run required, with a
deprecation: the default changes from `true` to `false` on 2028-04-01
(`notebook/swagger.json`, read 2026-10-20).

### Running a notebook

`POST /v1/workspaces/{ws}/items/{itemId}/jobs/instances?jobType=RunNotebook`
(see `rest-api` for the full jobType table). The rules below were
recorded in the skill before this file existed and carry no date.

- **`defaultLakehouse` requires both `id` AND `name`** in the execution
  config. Supplying only `id` returns 400 — common cause of
  "DefaultLakehouse: missing name" errors.
- **`executionData.parameters` is a map of name to `{value, type}`**,
  and `type` takes `bool`, not `Boolean`: `{"value": "true", "type":
  "bool"}` ran, and `"Boolean"` read `Failed` at submit, "Failed to run
  notebook due to invalid request. [Error: Unable to convert
  _inlineInstallationEnabled to Boolean.]", with the typed read
  answering `ItemNotFound`: a run refused at submit has no typed
  instance (a client workspace, 2026-11-12). Learn's *Develop, execute,
  and manage* page lists notebook parameters' types as `int`, `float`,
  `bool` and `string` (read 2026-11-12). The inline-install switch is
  `spark.md` § Python notebooks (no Spark).
- **Pool selection** via `executionData.configuration`: `useStarterPool:
  true` (dev/shared), `useWorkspacePool: true` (prod), or a custom pool name
  (high-memory/GPU). Starter pool falls back when the workspace pool is at
  capacity. **Custom live pools** (GA, September 2026) are a fourth option:
  pre-warmed clusters with ~5-second starts once hydrated, kept warm on a
  required schedule with an attached environment. They serve **notebooks
  only** — interactive, scheduled and pipeline-triggered — never Spark job
  definitions; they need a paid capacity, not a trial; and they're
  configured **in the portal only**, not through the Environment APIs or
  CI/CD. When every warm cluster is busy, a session falls back to on-demand
  provisioning. Members can manage them once an admin turns on *Customize
  compute configuration for items*; What's New lists delegated management
  as preview.
- **Job states**: `NotStarted → Running → Completed | Failed | Cancelled`.
  Poll `GET {Location}` from the 202 response, or
  `GET .../jobs/instances/{jobInstanceId}` if you captured the ID. **A
  cancel by `POST {Location}/cancel` read `Completed`**, not
  `Cancelled`, `failureReason` `null`, on both reads and both kernels:
  only a Spark notebook's typed read tells it apart, below (a client
  workspace, 2026-11-12, one cancel per kernel, about 51 s into
  `Running`).
- **Never retry POST after a network/timeout error.** Query
  `GET .../jobs/instances` filtered to the last 5 minutes first; if a recent
  run exists, monitor that. Retrying creates duplicate runs and burns CUs.
- Job stuck in `NotStarted` longer than ~2 minutes usually means pool
  warm-up or capacity SKU contention, not a notebook bug.

The spec's run lists `ComputeTypeMismatch` among its errors: the compute
type in the request does not match the one configured in the notebook
content (read 2026-10-20, unmeasured). The in-notebook
`%%configure retriableOptions` restart is code, not REST, and stays in
`spark.md` § Notebook execution via REST.

**The exit value is on the typed read only.** After `Completed`, the
generic `GET .../items/{id}/jobs/instances/{job}` carries `status`,
`failureReason` and the times, with no `exitValue`; the typed
`GET .../notebooks/{id}/jobs/execute/instances/{job}?beta=true` carries
`properties.exitValue`, the string `notebookutils.notebook.exit()` was
given, beside `properties.computeDetails`. A Spark notebook's holds
`livyId` and `monitoringInfo`: `executionSnapshotUrl`, `sparkUiUrl`,
`sparkJobDetailsUrl`, `driverLogUrl` and `activityDetails`, which has
`sparkApplicationId`, `cancellationReason` and `runtimeVersion`;
`livyId` and `sparkApplicationId` are the ids the driver log in
[spark-monitoring-apis.md](spark-monitoring-apis.md) takes. A Python
notebook's holds only `activityId` and
`monitoringInfo.executionSnapshotUrl` (a client workspace, 2026-11-12,
every run of a trial on both kernels). A job
posted on the generic route reads on the typed one by its id (a client
workspace, 2026-11-05, Runtime 1.3). `pbi-items`'
`references/tmdl/references/audit-notebook-tier.md` found
`properties.exitValue` in four runs of 2026-10-23, where Learn's
notebook API page shows it top-level.

**A raised exception fails the run without its text.** A notebook
ending in `raise RuntimeError(...)` read `Failed`, its `failureReason`
`System_Cancelled_Session_Statements_Failed`, "System cancelled the
Spark session due to statement execution failures", `isRetriable:
false`, with the exception's message nowhere in the job instance. A
passing run's typed read carries `cancellationReason`
`System_Cancelled_Session_Statements_Succeeded`, and `failureReason` is
`null` on both reads (a client workspace, 2026-11-05, one run each way).
The generic read's `failureReason` matched the typed read's in every
failed run of 2026-11-12.

**`Completed` alone is no success.** A cancel reads `Completed` too,
above; a Spark notebook's typed read says `User_Cancelled_Session` in
`activityDetails.cancellationReason`, and a Python notebook's has no
`cancellationReason`, so have the notebook `exit()` a value on success
and read `Completed` without an `exitValue` as no success.
`notebookutils.notebook.exit(json)` called from an `except` read
`Completed`, `exitValue` the JSON, on both kernels, Spark's
`cancellationReason` `System_Cancelled_Session_Statements_Succeeded`,
and no later cell ran (a client workspace, 2026-11-12, one run per
kernel). Learn's notebookutils run page says an `exit()` inside a
try-catch block takes no effect (read 2026-11-12); from the `except`,
it did.

**A handler cell keeps a failing cell's traceback.** Both kernels run
an IPython `ZMQInteractiveShell`, so a first cell can call
`get_ipython().events.register("post_run_cell", f)`, where `f(result)`
reads `result.error_in_exec` for a raise and `result.error_before_exec`
for a syntax error and writes a JSON record under
`/lakehouse/default/Files/`. Every record was in OneLake at the
terminal read and unchanged 30 s later. Match a record to its cell by
`result.info.raw_cell`: `info.cell_id` is `None`, and `execution_count`
is not cell order, as a Spark notebook runs two hidden statements before
each cell, `sc.setLocalProperty("spark.scheduler.pool", "default")` and
`sc.setJobGroup(...)`, which fire the hooks too; skip them by their
text. The registering cell fires `post_run_cell` with no `pre_run_cell`
before it (a client workspace, 2026-11-12: a raise and a syntax error
on each kernel, IPython 8.20.0 on Spark Runtime 1.3 and 9.7.0 on a
Python notebook).

**Testing Spark code from outside Fabric needs no Livy session.** Run
the code in a throwaway notebook and read its result:

1. `POST /v1/workspaces/{ws}/items`, type `Notebook`, an `ipynb`
   definition shaped as § Cells for the REST definition APIs says, its
   default lakehouse bound there. Give each run a unique `displayName`,
   a UTC stamp: a deleted item's name stays taken for a time
   (`rest-api`'s gotchas, `ItemDisplayNameNotAvailableYet`).
2. Run it with `defaultLakehouse` `{id, name}` and `useStarterPool:
   true`, and poll the `Location` to a terminal state. The run's binding
   is enough: with `{id, name, workspaceId}` there, a source whose
   `META` holds `"dependencies": {}` still mounted `/lakehouse/default`,
   on both kernels (a client workspace, 2026-11-12, one run each), so
   step 1 may bind none.
3. Assert in the notebook, and return detail as a JSON string by
   `notebookutils.notebook.exit()`, read on the typed read: a raise
   fails the run but loses its text, above, unless a handler cell
   keeps it.
4. `DELETE` the item in a `finally`: until then a Git-connected
   workspace lists it as an uncommitted change.

Lift the code under test from the repo's notebook source rather than
retyping it, so the run tests the branch. A test that only reads is
safe against a shared workspace. Three runs took 55 to 70 s each on the
starter pool, Runtime 1.3 (a client workspace, 2026-11-05).
`pbi-items/scripts/run-model-audit.py` is a worked example, on a
Python notebook in `fabricGitSource` format.

## Measured deltas, and where to look next

The measured notebook facts are the cell `source` shape above, undated;
the Livy listings in [spark-monitoring.md](spark-monitoring.md),
2026-08-17; and under § Running a notebook, the exit value's read,
2026-10-23 and 2026-11-05, and a failed run and the throwaway test,
2026-11-05; and the parameter map's types, where Learn's
known-limitations sample for inline installs uses `Boolean`, a cancel's
state, `exit()` from an `except`, the typed read's `computeDetails`,
the handler cell and a run-bound lakehouse, 2026-11-12.

When this file runs out, read the spec's `swagger.json` and the
operation's `examples/` file, then Learn. Re-read the spec from the SHA
above: its commits are weekly, "Updating swagger files".
