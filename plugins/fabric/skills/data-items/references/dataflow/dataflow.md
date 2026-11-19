# Fabric Dataflow Gen2 (the `Dataflow` item)

Dataflow Gen2 is the Power Query item in Fabric Data Factory: a low-code
transformation surface that ingests, reshapes and loads data without
code. This reference covers the item as **Git and REST see it** — the files
on disk, the API that writes them, and the limits that decide whether a
design works.

**The product name and the item type differ, and both are load-bearing.**
Everything a user types says *Dataflow Gen2*; the `.platform` file, the
`ItemType` enum and the REST namespace all say **`Dataflow`**. The Git
folder is `<display name>.Dataflow`.

**"Gen2" no longer implies a choice.** Since April 2026 the option to
create a Dataflow Gen2 *without* CI/CD and Git support is gone, and every
new item is created with it. Items created before that keep working, and
the docs still split behaviour by which kind you have — so when a page
says "applies to Dataflow Gen2 with CI/CD support", that is now the
default case and the non-CI/CD case is legacy.

An item's definition, REST calls and MCP server have files of their own.
Read one first for its job; past it, the REST spec's folder, then Learn, by `microsoft-learn-mcp`, or with no server, `curl -sL -H 'Accept: text/markdown' <page URL>` (undocumented, read 2026-11-07):

| The job | Read first |
| --- | --- |
| The definition parts, `queryMetadata.json` fields, public parameter types, the `/dataflows` REST calls (run, schedules, `executeQuery`, Gen1 upgrade) and their permission split | [references/dataflow-api.md](references/dataflow-api.md) |
| The DataFactory MCP server | [data-pipeline-mcp.md](../data-pipeline/references/data-pipeline-mcp.md), which covers dataflows too |

A live page that contradicts a line here wins: say so, act on the page,
and route the fix by `capture-learning`, bar a dated measured line that
names the page it overrules and the call that measured it, which a page
changed since its date sends back to re-measure. An observed claim is cited
or marked pending a doc check, and stands, marked observed, only where no
page covers it.

## 1. What is on disk

Three parts and `.platform`: `mashup.pq`, `queryMetadata.json` and any
`<name>.mdf`. The parts table is in
[references/dataflow-api.md](references/dataflow-api.md) § Definition.

Serialization mechanics are
[git-serialization.md](../git-serialization.md)'s: `queryMetadata.json`
ends at its last character, with no final newline. M style conventions,
such as naming and step layout, are not covered here.

## 2. `queryMetadata.json`

The query options live in `queryMetadata.json`: `formatVersion` accepts
only `202502`, and `name`, `queriesMetadata`, the defaults that bite,
`parametric` (the flag behind public parameters mode, §10) and
`maxConcurrency` are in
[references/dataflow-api.md](references/dataflow-api.md) §
`queryMetadata.json`. The full field table is there too.

## 3. `mashup.pq`

The `[StagingDefinition]` attribute, the `shared` queries of `Section1`,
the `[ItemType = "MDF"]` placeholder and the `.mdf` part are in
[references/dataflow-api.md](references/dataflow-api.md) § `mashup.pq`.

## 4. The composite `connectionId`, and the gap underneath it

`connections[].connectionId` is a JSON object serialized into a string,
not a GUID, and **no documented Fabric endpoint returns its `ClusterId`**,
so authoring a *bound* dataflow purely through the definition API is not
a supported path: create or bind connections in the portal and read the
definition back. Detail in
[references/dataflow-api.md](references/dataflow-api.md) § The composite
`connectionId`.

## 5. REST — the typed `/dataflows` namespace

The operation list, the permission split (List needs viewer, but
`getDefinition` needs read **and write**, and Execute needs member and a
user identity) and the generic route are in
[references/dataflow-api.md](references/dataflow-api.md) § REST beyond the
generic set.

## 6. `updateDefinition` replaces everything — and takes `.platform`

`updateDefinition` replaces the whole definition, and for a Dataflow the
documented sample sends `.platform` with `?updateMetadata=True`: see
[references/dataflow-api.md](references/dataflow-api.md) §
`updateDefinition` replaces everything.

## 7. Running one — three spellings, one operation

The typed, generic-current and generic-legacy routes, and the
`executeOption` default the docs disagree about (pass it explicitly), are
in [references/dataflow-api.md](references/dataflow-api.md) § Running one.
**Service principals cannot execute a dataflow**, so an unattended refresh
needs a pipeline Dataflow activity or a schedule.

## 8. Save, publish, refresh

- **Save auto-publishes.** In a CI/CD dataflow the save operation
  publishes; there is no separate publish button to forget.
- **Validation is a zero-row evaluation** that checks query schemas
  without returning rows. If a schema cannot be determined within **10
  minutes**, it fails, and the last saved version is used for refreshes.
  A separate documented limit puts validation and publish at **10 minutes
  per query**.
- **Just-in-time publish**: a save makes changes available to the next
  refresh, which attempts a publish if needed.
- **A failed publish now fails the refresh.** For any dataflow last saved
  **after 1 February 2026**, a publish failure fails the run rather than
  silently falling back to the last good version — deliberately, so
  nobody unknowingly runs an outdated dataflow.
- **After a Git sync or a deployment**, open and save the dataflow, or
  call the publish job. Without that the changes do not reach a refresh.
- **A successful publish starts an on-demand refresh** by itself.

## 9. What the definition API cannot do

**A data destination cannot be authored through the definition API**, and
the public-APIs page states that run APIs can be invoked but the run never
succeeds: read those two together before designing an API-first workflow.
All five documented limitations are in
[references/dataflow-api.md](references/dataflow-api.md) § What the
definition API cannot do.

## 10. CI/CD — three patterns, one constraint they share

| Pattern | Binds by | Needs |
| --- | --- | --- |
| Public parameters | values passed per run | a caller — REST or a pipeline activity |
| Variable libraries | workspace-scoped variables | a library in the **same** workspace |
| Relative references | item **name** in the current workspace | matching names per environment |

**Connections are statically bound under all three.** Dataflow Gen2 does
not support dynamic reconfiguration of data source connections, so a
server or database named in a connection cannot be swapped by a variable
or a parameter. Deployment rules do not help — they modify some item
properties but not connections or mashup logic.

**A destination's name can vary, though its connection cannot** — in
preview. The dynamic expression editor builds a supported field, such as
**Table name** or **File name**, from text plus a parameter, a workspace
variable (a built-in such as `currentWorkspaceId`, or a variable-library
value) or the run's UTC date and time, resolved at each run; a resolved
name the destination rejects can fail validation or the run. How an
expression is written into `mashup.pq` is undocumented. Settings the
editor does not reach take advanced edit of the destination query's M,
also preview, after which only the advanced editor can change that
destination (Learn, 2026-10-07).

Two more constraints worth knowing before choosing:

- **Variables work only inside `mashup.pq`**, only for basic types
  (`boolean`, `datetime`, `guid`, `integer`, `number`, `string`), and
  lineage views do not show the link between a dataflow and the library
  it reads.
- **Public parameters block scheduling.** A dataflow with required
  parameters cannot be scheduled or manually triggered through Fabric,
  and the mode is incompatible with incremental refresh.

References are absolute by default. Git integration is recommended on the
first stage only; later stages can deploy without it.

## 11. Gen1 → Gen2: two routes, one of them one-way

| | Save As | Upgrade Wizard |
| --- | --- | --- |
| Original | **kept** | **replaced** |
| Item ID | new | **same** |
| Reversible | n/a — original survives | **no** |
| Schedule | copied only with `includeSchedule` | preserved |

**The wizard is in-place and irreversible.** It replaces the Gen1 item
with a Gen2 (CI/CD) item of the same ID and name. To keep the original,
use Save As instead. Three further gates:

- **Two reasons make the wizard report *Upgrade unavailable***: you
  do not own the dataflow, or one or more data source connections
  cannot be resolved. Take over first, then refresh the Gen1 and
  confirm it succeeds; recreate or rebind unresolved connections.
- **More than 50 enabled queries blocks it** — that one must be fixed
  before upgrading, unlike the other Needs-Attention reasons.
- **A failed upgrade cannot be retried for 24 hours**, and the upgraded
  item is soft-deleted for up to 30 days, during which outbound access
  protection cannot be enabled on the workspace.

**Afterwards, in order**: refresh each upgraded dataflow — it holds no
data until you do — then open and save every downstream dataflow that
reads it, which rebinds it.

**The legacy connector stops working, and it does not look like it.**
`PowerBI.Dataflows` cannot read a Gen2 (CI/CD) item; consumers must move
to `PowerPlatform.Dataflows`, which adds a `Workspaces` navigation step
and needs fresh credentials. An import-mode consumer keeps showing its
existing data until its next refresh, so nothing appears broken at first.
DirectQuery consumers need a storage-mode change as well, since
DirectQuery is unsupported against Gen2.

For bulk migration, Save As has a **preview** Power BI REST call,
`saveAsNativeArtifact`, which returns 200 **even when parts fail** —
check the `errors` array rather than the status code. Body fields and
error codes: [references/REFERENCE.md](references/REFERENCE.md).

## 12. Limits that decide designs

| Limit | Value |
| --- | --- |
| Refreshes per rolling 24 h | **300** CI/CD · **150** non-CI/CD |
| Scheduled refresh slots | 48 per day |
| Single query evaluation | 8 hours |
| Whole refresh | 24 hours |
| Staged or destination queries | **50 per dataflow** |
| Validation / publish | 10 minutes per query |
| Gateway versions supported | last **six** releases |
| OAuth2 refresh through a gateway | **1 hour** |

**The 50-query cap counts only queries that write** — staged, or with a
destination. Functions, helper queries and unstaged intermediate queries
do not count.

**Bursts throttle separately from the daily cap.** 300 refreshes spread
over 24 hours is fine; 300 in 60 seconds is rejected.

**A consistently failing schedule gets paused** and the owner emailed —
at 100% failure over 72 hours across at least 6 refreshes, or over 168
hours across at least 5.

## 13. Cost

| Engine | Rate |
| --- | --- |
| Standard compute, CI/CD | **12 CU/s** to 10 min, then **1.5 CU/s** |
| Standard compute, non-CI/CD | **16 CU/s** throughout |
| High-scale (staging enabled) | 6 CU/s |
| Fast copy (data movement) | 1.5 CU/s |
| MDF transforms (preview) | not currently billed |

**A non-CI/CD dataflow is not the cheaper one.** It pays a flat 16 CU per
second while a CI/CD item drops to 1.5 after ten minutes, so the gap
widens with query length.

**Fast copy bills aggregate core time, not wall clock** — the total
across every core the copy used. A copy that finishes in seconds can
still bill meaningfully, because the speed came from spreading work over
cores that are each billed.

## 14. Gotchas

- **Learn sends `The key didn't match any rows in the table`, from the
  Dataflows connector, to its staging guidance.** The connector page's
  limitations point it at *Data in staging items*, which says reading a
  dataflow's tables through the connector is fully supported, reading
  its staging storage directly is not, and staging is a cache, not a
  system of record. It recommends a Lakehouse or Warehouse destination
  for consumers "where possible", and says that is no requirement. The
  intermittent-timeout cause and workaround once cited here left the
  refresh page in October 2026, as outdated failure notes.
- **Two staging traps, both time-based.** A refresh failing with
  *insufficient permissions for accessing staging artifacts* means
  whoever created the workspace's **first** dataflow has not signed in
  for 90 days or has left; they must sign in. Separately, staging items
  untouched for 90 days need re-authentication, done by creating a new
  dataflow in the workspace.
- **Viewer cannot consume.** Reading dataflow data through the connector
  needs Admin, Member or Contributor. Viewer is enough to *see* the item
  and to download refresh logs, not to read its tables.
- **Delta has no case sensitivity**, so `MyColumn` and `mycolumn` are
  legal in M and collide as duplicate columns at a Lakehouse destination.
- **Lakehouse destinations reject** spaces and special characters in
  column or table names, and duration and binary columns.
- **Guest users are unsupported** for sources and destinations.
- **One gateway query makes every query use it.** If a single query is
  configured for a gateway, all queries in that dataflow use it.
- **Staging items are not yours to manage.** `DataflowsStagingLakehouse`
  and `DataflowsStagingWarehouse` are internal. They are hidden in shared
  workspaces but visible in *My Workspace* — do not rename or delete
  them.

## 15. Ownership

Dataflows are **carved out of** Fabric's generic item take-over feature —
the take-ownership article says both dataflow generations keep their own
pre-existing mechanisms — and there is no API for changing item
ownership at all. After taking over a Gen2 (CI/CD) item, repair its
connections through **Manage Connections → Edit Connection**. The
takeover does not transfer ownership of its existing schedules or
update their authentication context, so review the schedules
separately, even when an on-demand refresh succeeds.

## Reference

- Learn: [What is Dataflow Gen2](https://learn.microsoft.com/fabric/data-factory/dataflows-gen2-overview) ·
  [CI/CD and Git integration](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-cicd-and-git-integration) ·
  [Public APIs](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-public-apis) ·
  [Refresh](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-refresh) ·
  [Pricing](https://learn.microsoft.com/fabric/data-factory/pricing-dataflows-gen2) ·
  [Dataflows connector](https://learn.microsoft.com/fabric/data-factory/connector-dataflows#limitations-and-considerations) ·
  [Data in staging items](https://learn.microsoft.com/fabric/data-factory/data-in-staging-items#data-in-staging-items)
- Learn: [Dataflow definition schema](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/dataflow-definition) ·
  [Run On Demand Execute](https://learn.microsoft.com/rest/api/fabric/dataflow/background-jobs/run-on-demand-execute) ·
  [Discover parameters](https://learn.microsoft.com/rest/api/fabric/dataflow/items/discover-dataflow-parameters)
- Learn: [Upgrade Wizard](https://learn.microsoft.com/fabric/data-factory/migrate-to-dataflow-gen2-using-upgrade-wizard) ·
  [Save As](https://learn.microsoft.com/fabric/data-factory/migrate-to-dataflow-gen2-using-save-as) ·
  [Data Factory limitations](https://learn.microsoft.com/fabric/data-factory/data-factory-limitations#data-factory-dataflow-gen2-limitations)
- The destination support and data-type matrices, incremental refresh,
  fast copy, monitoring schemas, the wizard's Needs-Attention table and
  the worked cost formulas:
  [references/REFERENCE.md](references/REFERENCE.md)
- Parameter types and formats, with the definition and REST:
  [references/dataflow-api.md](references/dataflow-api.md)

## See also

- [git-serialization.md](../git-serialization.md) — line endings, end
  of file and what a portal commit deletes
- **rest-api skill** — LRO polling, `?updateMetadata`,
  pagination, rate limits; `fab` filesystem commands over the item, in
  its `references/cli.md`; the cross-product error index, in its
  `references/gotchas.md`
- **pbi-items skill**, `references/tmdl/references/definition-api.md` — the "include
  ALL parts" rule this item shares (restated for a dataflow in this
  skill's `references/dataflow-api.md`)
- **deploy skill** — deploying a dataflow between workspaces
- **variable-library skill** — the library this reads from
