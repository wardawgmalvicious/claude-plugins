# Fabric Activator (the `Reflex` item)

Activator watches data and takes an action when a condition is met. It
is the **deterministic, non-LLM** half of Fabric's reactive story.

**`Reflex` and `Activator` name the same item type.** Learn says so
outright, and the split is consistent: `Activator` is the portal and
product name, `Reflex` is what the REST API, the `ItemType` enum, the
`.platform` file and the Git folder suffix all use. Expect both in the
same sentence and do not treat a `Reflex` in a payload as a different
thing.

Three neighbours own adjacent ground:

| Adjacent work | How to get there |
| --- | --- |
| Wiring an Activator destination onto an Eventstream, or `Set alert` from one | [eventstream.md](../eventstream/eventstream.md) § Activator destination |
| The KQL database a `kqlSource-v1` queries | [eventhouse.md](../eventhouse/eventhouse.md) |
| LRO polling, `continuationToken` pagination, token audiences, `fab` invocation and `fab api` passthrough | `rest-api`; audiences are its `references/auth.md`, `fab` its `references/cli.md` |

An item's definition, REST calls and MCP server have files of their own.
Read one first for its job; past it, the REST spec's folder, then Learn, by `microsoft-learn-mcp`, or with no server, `curl -sL -H 'Accept: text/markdown' <page URL>` (undocumented, read 2026-11-07):

| The job | Read first |
| --- | --- |
| The definition: parts, entity payloads, template instances, a decoded rule | [references/reflex-entities.md](references/reflex-entities.md) |
| REST: the seven operations and their permissions, `queryActivations`, every error code | [references/rest-and-errors.md](references/rest-and-errors.md) |
| The remote MCP server: endpoint, tools, limits | [references/activator-mcp.md](references/activator-mcp.md) |

A live page that contradicts a line here wins: say so, act on the page,
and route the fix by `capture-learning`, bar a dated measured line that
names the page it overrules and the call that measured it, which a page
changed since its date sends back to re-measure. An observed claim is cited
or marked pending a doc check, and stands, marked observed, only where no
page covers it.

## 1. What is on disk

A Git-synced Activator is a `<name>.Reflex/` directory holding exactly
two files:

| File | Required | What it is |
| --- | --- | --- |
| `ReflexEntities.json` | yes | The whole configuration — sources, objects, attributes, rules |
| `.platform` | no (over REST) | Fabric platform metadata; `metadata.type` is `Reflex` |

`.Reflex` is the suffix Fabric actually writes — the Git-integration
docs show only that form, and so did the one real item measured for this
reference (2026-09-12). No export of Fabric's shows an `*.Activator/`
folder; do not read a glob or fixture for it as evidence the portal name
is ever used for a folder.

**Both files are JSON parts, so canonical form is LF with no final
newline.** `claude/rules/fabric-git-serialization.md` co-loads on these
same paths and owns that policy — follow it there rather than restating
it. Observed on a real item: LF-only, no trailing newline, both files.

**An Activator created but never configured serializes as `[]`.** Two
bytes. That is not an error and not an empty object — it is the empty
state of an array, which is the useful thing to know before you write a
parser against it.

## 2. `ReflexEntities.json` is a flat array

The top level is a **JSON array of entity objects**, not an object with
named sections. Every entity carries the same three properties:

```json
[
  { "uniqueIdentifier": "<guid>", "payload": { }, "type": "<entity-type>" }
]
```

Structure lives in the **references between entities**, not in nesting,
and one `timeSeriesView-v1` type wears four hats (event, object,
attribute, rule), so **count rules by filtering on the nested
`payload.definition.type`**, not on `type`. The seven entity types, the
parent references, per-entity payload tables, the template catalogue and
a full decoded example are in
[references/reflex-entities.md](references/reflex-entities.md).

## 3. `definition.instance` is an escaped string, not an object

The highest-value trap in the format. A time series view's logic lives
in `payload.definition.instance`, and Learn is explicit: it "stores the
template configuration as a **JSON-encoded string** (not a nested JSON
object). You must escape this string."

So the real logic is one level of escaping down. **Do not hand-author a
template instance**: configure the item in the portal, call
`getDefinition`, then modify the retrieved instance. And **a cloned
attribute has two places holding the column**, `payload.name` and a
`fieldName` argument inside the escaped `instance`; renaming only the
outer one leaves the clone reading the original column. The mechanics
are in [references/reflex-entities.md](references/reflex-entities.md),
§ Template instances.

## 4. REST — the `/reflexes` namespace

There is a dedicated Reflex service, not just Core Items. **Reading a
definition is not a read-only operation**, which inverts the obvious
assumption: List needs only a viewer role, but `getDefinition` needs
read *and write* on the item, with no `Reflex.Read.All` route to it.
Plan the identity accordingly, and say so rather than requesting write
silently. Also: send `displayName`, not `name`, on create; and
`updateDefinition` ignores `.platform` unless `updateMetadata=true`.
The operations, permissions and scopes, `queryActivations` and the full
error catalogue are in
[references/rest-and-errors.md](references/rest-and-errors.md).

## 5. Sources — query versus streaming

The split decides how a rule behaves, so establish which one you have
before debugging why a rule did not fire.

| Kind | Sources | How data arrives |
| --- | --- | --- |
| **Query** | Power BI, KQL Queryset, Real-Time Dashboard, Warehouse SQL query (preview) | Activator runs a query on a schedule and evaluates rules against the results |
| **Streaming** | Eventstream, Fabric events, Azure Blob Storage events | Events are pushed continuously as they occur |

Two consequences worth knowing up front:

- **KQL queryset alerts need an Eventhouse.** Only queries against KQL
  databases *within an Eventhouse* are supported; a queryset pointed at
  an external Azure Data Explorer cluster cannot carry an alert.
- **A frequent alert query defeats Eventhouse idle savings.** An alert
  query on a 1- or 5-minute interval "effectively keeps Eventhouse in an
  always-on state" — Eventhouse idles down only after more than five
  minutes with no queries or ingestion.

Query-based sources also bind data differently and may create objects
automatically; the object-assignment workflow is for streaming sources.

## 6. Actions

The definition knows three action types — `TeamsMessage`,
`EmailMessage`, and `FabricItemInvocation`, which references a
`fabricItemAction-v1` entity by its `uniqueIdentifier`. The portal
exposes seven runnable Fabric item types: Dataflow, Pipeline, Spark job,
Notebook, Function, Copy job, and Publish business event (preview).

- **A `fabricItemAction-v1` carries its target in
  `payload.fabricItem`** — `itemId`, `workspaceId`, `itemType` — with a
  sibling `jobType`. Upstream additionally reports that a `targetItem`
  shape is accepted by `updateDefinition` yet never resolves its target;
  **that is undrilled and appears nowhere in the docs**, so treat it as
  an unverified warning, not a rule.
- **Copy job accepts no parameters.** Every other runnable type does.
- **Bad parameter values coerce silently.** Activator takes string,
  boolean and number (float). `1,234.56` parses to 1234.56 and `1e3` to
  1000, but `123,45` yields **0**, and null, whitespace or any other
  string yields 0 or `false`. Nothing errors — the job runs with a wrong
  value. Define the parameter name and type exactly as the target item
  does.
- **User Data Functions take the full type set** the function supports,
  including `list[]` and `dict`.

## 7. Inspecting an existing Activator

1. `List Reflexes` for names and IDs — viewer role is enough.
2. `getDefinition` for the parts (needs write; see §4).
3. Base64-decode the `ReflexEntities.json` part.
4. Walk the array, indexing by `uniqueIdentifier`, then follow
   `parentContainer` and `parentObject` to rebuild the tree.
5. Filter `timeSeriesView-v1` on `definition.type == "Rule"` to find
   rules, and read `definition.settings.shouldRun` to tell a **running**
   rule from a merely saved one. The documented example ships
   `shouldRun: false`.

In a Git-synced repo, steps 1–3 are replaced by reading the file.

## 8. The remote MCP server (preview)

Fabric ships an HTTP MCP endpoint scoped to **one** Activator item, with
four tools. **`create_rule` starts the rule automatically**, where the
definition path ships `shouldRun: false`, so a rule made this way is live
and billing from creation. Its endpoint, limits (KQL sources and Teams or
email actions only) and wiring are in
[references/activator-mcp.md](references/activator-mcp.md).

## 9. Limits

| Limit | Value |
| --- | --- |
| Rules per Activator item | **500** (any source mix) |
| Incoming events/second/rule | **10,000** — past it, Activator **stops the rule** |
| Fabric item activations | 50/user/minute |
| Email | 500/item/hour; 30/rule/recipient/hour |
| Teams | 500/item/hour; 30/rule/recipient/hour; 100/recipient/hour; 50/tenant/second |
| Power Automate | 10,000 flow executions/rule/hour |

Exceeding the event rate **stops** the rule rather than shedding load,
which is the one to design around.

**Recipients are constrained too.** Email goes only to internal
addresses on the creator's tenant or a verified domain — never external
or guest. Teams **channels are not supported at all**, private channels
included, and a group chat must be recently active to be selectable.
Learn contradicts itself on channels (2026-10-06): `activator-limitations`
still says "Teams channels aren't currently supported", while the
warehouse SQL query alert page, for a preview source, documents a
**Channel post** action that takes a team and a channel.

Also unsupported: alerts on a report using Dynamic M parameters, alerts
from the Capacity Metrics app, and alerts from a SQL analytics endpoint.
In GCC High preview, Power BI report alert rules cannot be created,
edited or deleted.

## 10. Cost — stopping a rule does not stop the bill

Four meters, in CU-hours: **rule uptime** 0.02222/hour (a flat charge
while a rule is active), **event ingestion** 0.000011111/event, **event
computations** 0.00000278/computation, **storage** 0.00177/GB/hour with
all events retained 30 days.

**The one that surprises people, flagged Important on Learn:**

> Pausing or stopping a rule doesn't stop the event listener. The event
> listener continues to run and incur capacity consumption until the
> rule is removed.

So **delete** a test rule; stopping it is not enough. And "active rules
incur costs even if no data is ingested into them" — a stale rule on a
dead stream still bills rule uptime. Audit for stale and redundant rules
rather than assuming an idle Activator is free.

Stateful computations — lookbacks, cross-event calculations — are
materially more expensive than per-event evaluation. A Real-Time hub
subscription is owned by the Activator, so its listener and event
operations bill against the Activator item under the Azure/Fabric events
rates, not the table above.

## 11. Git and lifecycle management — the exclusion list

**An Activator using any of these cannot be committed or deployed:**

- Azure Blob Storage events as a data source
- Power BI as a data source
- Fabric User Data Functions as an action

Include one in a deployment pipeline or a Git-integrated workspace and
you get an error on commit or deploy. Support is stated as planned, not
present. This is the first thing to check when an otherwise healthy
workspace fails to sync one item — the failure is a property of the
Activator's *contents*, not of the repo, so nothing about the Git
configuration will explain it. Deployment pipelines themselves are
`deploy`'s subject, and the Git integration APIs are
`rest-api`'s.

One more ownership trap that survives a sync: a Power BI ingestion's
metric is owned by whoever created it, and only that user can query it.
Change the credentials or lose their access and ingestion stops —
recreate the ingestion and its rules under the new user.

**An update from Git rewrites a rule's stored definition, not the
running rule.** Learn tells whoever changes a rule to select **Update**
"to make sure that the running rule uses the new values" (*Create a
rule*, § *Start and stop your rule*), and an update from Git selects
nothing. In one client estate on 2026-10-13, Git brought a running rule
a new headline and message: the workspace read synced, and
`getDefinition` and the file both held the new text, yet the next two
activations sent the old text word for word. So after an update from
Git changes a running rule, open the rule and select **Update**, then
judge by the next activation, never by the definition. Unverified: that
**Update** takes up the definition Git wrote, and whether a REST
`updateDefinition` that changes a query or message on the same
entities, or a deployment into a stage running the rule, leaves it
behind the same way. A source's changed database ID did reach the next
run (below, 2026-10-21).

**A deployed rule polls in its new stage at once.** Deployed into a
stage that never had it, a rule read `shouldRun: true`, its source's
`isStopped` `false`, and the target database ran its query within two
seconds of the deploy (one client estate, 2026-10-13), so it billed
there from the start. Keep a stage quiet through the data its query
reads. `.show queries` rows whose `ClientActivityId` starts `Activator;`
show a source polling, with no portal.
A source written as a new entity by `updateDefinition` runs a second
after the write too, and either way that first run fixes the phase: a
900 s source kept its offset past the hour to within two seconds, and
stopping and starting it in place did not move it (four sources, one
client estate, 2026-10-13 to 2026-10-21; Learn's *Query frequency*
gives the interval, not its alignment, read 2026-10-21). So make a
source a few minutes after the data it reads lands.

**A running KQL source keeps the cluster it was made on.** Re-pointed
at another stage's database by `updateDefinition`, a `kqlSource-v1`
took the new database ID at its next run but sent it to the old
stage's eventhouse, to fail there unseen by the portal; stopping and
starting it changed nothing. Write the source under a new
`uniqueIdentifier` and re-point the Event view at it (one client
estate, 2026-10-21; the mechanics in
[references/reflex-entities.md](references/reflex-entities.md),
§ `kqlSource-v1`). A deploy can leave a source on the source stage's
database: `deploy`'s `references/deployment-pipelines.md`,
§ *Item pairing and autobinding*.

**A rule set from a KQL queryset or a Real-Time Dashboard tile runs a
copy of its query**, taken when the rule was created and run straight
against the Eventhouse: later edits to the queryset or tile "have no
effect on the rule", which runs on if the source is deleted, and the
only way to a new query is to delete the rule and set it again from the
changed source (Learn, *Ingestion from KQL Querysets* and *Ingestion
from Real-Time Dashboards*, read 2026-10-13). So an update from Git that
changes the query never reaches the rule, and neither does **Update**.
By REST there is a second way to a new copy: an `updateDefinition`
that wrote the source, with the new query, under a new
`uniqueIdentifier`, its Event view and rule new too, ran the new query
a second after the write (one client estate, 2026-10-21).
Whether a Power BI or Warehouse source copies its query is unchecked.

## 12. Gotchas

| Symptom | Cause | Fix |
| --- | --- | --- |
| `getDefinition` returns 401/403 for a user who can see the item | Definition read needs **write**, not read | Grant write, or stay with `List Reflexes` metadata |
| `getDefinition` fails on one item only | An encrypted sensitivity label: the caller needs Purview usage rights to remove it (spec, 2026-10-20) | Get the usage rights, or read it in the portal |
| Create returns 400 about `DisplayName` | `name` sent instead of `displayName` | Use `displayName` |
| Commit or deploy fails for one Activator | A Blob-events source, Power BI source, or UDF action | §11 — no workaround |
| An alert still sends its old text after an update from Git, though the definition reads new | Git rewrote the stored rule; the running rule keeps the values it was started or last updated with | §11 — select **Update**, then check the next activation |
| An alert set from a KQL queryset or dashboard tile still fires on the old query after the query changed and synced | The rule runs a copy of the query taken when it was created | §11 — delete the rule and set it again from the changed source, or write the source anew by REST |
| A KQL-sourced rule stops activating after its source was re-pointed; the old stage's `.show queries` holds `Failed` rows from `Activator;<item ID>`: `Entity ID '<database ID>' of kind 'Database' was not found.` | A running source keeps the cluster it was made on | §11 — write the source under a new `uniqueIdentifier` |
| Rule silently stopped | Over 10,000 events/s | Reduce event rate or narrow the rule |
| A job ran with a 0 or `false` parameter | Silent coercion of an unparseable value | Match the target item's parameter name and type exactly |
| A cloned attribute reads the wrong column | Only `payload.name` was changed, not the `EventFieldSelector` `fieldName` | Edit both, inside the escaped `instance` |
| Consumption continues after stopping every rule | Event listeners outlive stopped rules | Delete the rules |
| Alert spam on every matching event | A stateless operator where a transitional one was meant | Use `BECOMES` / `INCREASES` / `DECREASES` / `EXIT RANGE` |
| Rule never fires, no error | Field-name or type mismatch binding rule to data | Check the live sample; Activator can fail to bind silently |

Activator emails an error code when something breaks after creation, and
the recipients are configurable under **Home > Settings > Notifications**.
Every code, grouped by stage, with cause and fix, is in
[references/rest-and-errors.md](references/rest-and-errors.md).

## 13. Before activating a rule

- **Preview it.** Activator can show how often the rule *would* have
  fired on historical data. Use it on any high-volume stream.
- **Prefer stateful operators** so a value sitting past a threshold does
  not re-alert forever: `BECOMES`, `INCREASES`, `DECREASES`,
  `EXIT RANGE`, or absence of data, the heartbeat below (Learn,
  2026-10-06).
- **Add a heartbeat rule** to catch a stream going silent — a rule that
  never fires and a source that died look identical otherwise.
- **Check the ceiling**: 500 rules per item, and the per-recipient
  throttles, before designing a fan-out.

## Reference

- [references/reflex-entities.md](references/reflex-entities.md) —
  the definition: parts, per-entity payloads, template catalogue, decoded
  example
- [references/rest-and-errors.md](references/rest-and-errors.md) —
  the seven operations, `queryActivations`, and every error code
- [references/activator-mcp.md](references/activator-mcp.md) —
  the remote MCP server
- Learn: [Reflex definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/reflex-definition)
- Learn: [Activator limitations](https://learn.microsoft.com/fabric/real-time-intelligence/data-activator/activator-limitations)
- Learn: [Activator capacity consumption and billing](https://learn.microsoft.com/fabric/real-time-intelligence/data-activator/activator-capacity-usage)
- Learn: [Troubleshoot Activator errors](https://learn.microsoft.com/fabric/real-time-intelligence/data-activator/activator-troubleshooting)
- Learn: [Ingestion overview](https://learn.microsoft.com/fabric/real-time-intelligence/data-activator/ingestion/ingestion-overview)
- Learn: [Remote MCP server for Activator (preview)](https://learn.microsoft.com/fabric/real-time-intelligence/mcp-remote-activator)
- Learn: [Activator GitHub integration](https://learn.microsoft.com/fabric/real-time-intelligence/git-activator)

## See also

- `rest-api` — LRO polling, `continuationToken` pagination, the
  Git integration APIs; token audiences for Fabric REST, in its
  `references/auth.md`; `fab` and `fab api` passthrough, in its
  `references/cli.md`
- `deploy` — deploys, from a Git checkout or through deployment
  pipelines
- `claude/rules/fabric-git-serialization.md` — co-loads on these paths
- [eventstream.md](../eventstream/eventstream.md) and
  [eventhouse.md](../eventhouse/eventhouse.md) — the two items an
  Activator most often reads from
