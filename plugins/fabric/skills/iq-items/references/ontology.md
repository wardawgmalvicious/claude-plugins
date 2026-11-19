# Fabric Ontology (preview): the item, its definition, and its bindings

An **ontology** is Fabric IQ's shared business vocabulary: *entity types*
(`Customer`), *properties* (`email`), and *relationships*
(`Customer places Order`), bound to real OneLake data so agents and
people reason in the same terms.

**Item type name: `Ontology`** — the `metadata.type` written into
`.platform`, so a Git-synced workspace serializes it as
`<display name>.Ontology`. Git integration lists it under **"IQ (preview)
items"** alongside Plan — *not* under Data Science or Real-Time
Intelligence, which is where people look first.

Everything below is **preview**, verified against the docs on
**2026-09-02** unless a section gives a later date. Re-check before
relying on a limit; this surface moves.

**Not here, deliberately.** The ontology graph is *provided by* [Graph in
Microsoft Fabric](https://learn.microsoft.com/fabric/graph/overview) — a
separate `GraphModel` item — and is **optional and opt-in**: every
ontology has a schema graph, but its instance data is materialized only
when you opt in through **Home > Manage > Graph**
(`how-to-use-ontology-graph`, read 2026-11-18). GQL, graph-type DDL and
`executeQuery` belong to
[graph.md](graph.md); this file only carries the graph constraints that
bite at **ontology** time. Agent configuration belongs to
[data-agent.md](data-agent/data-agent.md) (conversational, ≤5 sources)
and [operations-agent.md](operations-agent.md) (autonomous,
single-source) — ontology is one *source* for each of those.

**Old experience (legacy, retires 2027-01-31):** the graph is built
automatically, "a queryable instance graph built from your data bindings
and relationship definitions" that "follows a scheduled data refresh"
([old-experience overview](https://learn.microsoft.com/fabric/iq/ontology/old-experience/overview),
checked 2026-10-07).

## The Git definition layout

**Two formats, one per experience.** The **new ontology experience**, the
default for new items, writes its definition as **TMDL**: "flat,
item-folder-relative `.tmdl` text files plus the platform-owned
`.platform` metadata file" (Learn, checked 2026-10-06). The JSON layout
below is the **old experience**'s, which retires on
**2027-01-31**. A folder holding `database.tmdl` is new; one holding a
root `definition.json` and `EntityTypes/` is old.

The part list, the two-part minimal write, what `getDefinition` returns
that Git does not, and the REST calls are
[ontology-reference.md](ontology-reference.md)'s, § 1.

### Old experience (legacy): the JSON layout

The old experience **retires on 2027-01-31**. The Fabric UI no longer
creates it, but the ontology APIs and CI/CD still can, so an existing
item, or one created that way, uses its JSON layout until then.
Migration is the in-product **create a copy in the new experience**: a
separate item, so agents, dashboards and other consumers must be
reconnected and rules recreated.

Three things about the old layout surprise people reading a diff, and
the schemas are in [ontology-reference.md](ontology-reference.md) § 1:
entity and relationship type IDs are bigints used as directory names,
not GUIDs; a binding file names no property, only
`sourceColumnName` → `targetPropertyId`, so it is unreadable without the
entity type's `definition.json` beside it; and the root `definition.json`
is literally `{}`, which is not to be "fixed". Its `valueType` enum has
no `Decimal`: see the trap below.

## Generating an ontology from a semantic model

Generation creates the item, entity types from tables, properties and
their data bindings from columns, relationship types from model
relationships, and **metrics** from the model's DAX measures. The
overview adds calculated columns, and the source model stays "the owner
of the DAX expression" (both pages checked 2026-10-07). **What it does
not do** is bind time series data, review entity keys, bind
relationship types, or rename entity types and relationships to
friendly names — manual follow-ups, every time.

Generating, and querying the model through the ontology, needs both
**Read and Build** permissions on the semantic model, as binding one
does. You **cannot generate from `My workspace`** — move the semantic
model to a real workspace first (troubleshooting page, checked
2026-10-07). A second semantic model joins an existing ontology **only
through the ontology agent**, the built-in path under § "Consuming an
ontology".

**Old experience (legacy, retires 2027-01-31):** support depends
entirely on the **semantic model's storage mode**. This matrix and the
two paragraphs after it come from the old experience's generation page;
the new experience's (`how-to-generate-from-semantic-models`, checked
2026-10-07) carries no storage-mode matrix. The troubleshooting page,
checked the same day, still blames Import mode and disabled inbound
public access for a generated ontology with no data bindings, linking
that row to the old page, so whether the failure holds in the new
experience is unverified.

| | Import | Direct Lake | DirectQuery |
| --- | --- | --- | --- |
| Entity / property / relationship **definitions** | ✅ | ✅ | ✅ |
| Entity type **bindings to data** | ❌ | ✅ *conditional* | ❌ |
| Relationship type **bindings** | ❌ | ✅ *conditional* | ❌ |
| **Querying** through bindings | ❌ | ✅ (no measures or calculated columns) | ❌ |

**This is the failure worth knowing.** Direct Lake entity bindings work
*only* when the backing lakehouse sits in a workspace with **inbound
public access enabled**. When it does not, "the ontology item is created
successfully but that entity type has no data bindings." A green
checkmark and an empty ontology. Relationship bindings have their own
condition: they generate only where a **primary key is identified**.

So an Import-mode model generates a correct-looking *schema* and nothing
queryable, by design. Check the mode before blaming the data.

## The constraints that produce silent or confusing failures

- **Managed lakehouse tables only.** External tables that merely *appear*
  in a lakehouse are not supported, and the symptom is "entity type
  details shows no data" rather than an error at binding time
  (`resources-troubleshooting`, checked 2026-10-23).
- **OneLake security is enforced, not excluded.** Authoring and querying
  "respect access to bound data, including OneLake security" and
  source-enforced RLS, OLS and CLS (overview, checked 2026-10-07). The
  old rule that a lakehouse with OneLake security enabled cannot be a
  binding source was withdrawn in September 2026, and neither
  experience's binding page carries it.
- **No delta column mapping.** It is enabled *automatically* when column
  names contain `,` `;` `{}` `()` `\n` `\t` `=` **or a space**, and
  automatically on the delta tables backing **import-mode** semantic
  model tables. Symptom: the entity type details graph does not load
  (`resources-troubleshooting`, checked 2026-10-23). A KQL
  `.drop column` sets it on an Eventhouse table's OneLake copy too
  (`rti-items`, `references/eventhouse/references/onelake-availability.md`).
- **Duplicate property names must share a type** across entity types. A
  string `ID` on one and an integer `ID` on another is what makes entity
  types go missing from a generated ontology.
- **Renaming a source table after binding breaks it**: entity type
  details lose their connection (`resources-troubleshooting`, checked
  2026-10-23). Bindings carry `sourceTableName` as a string.
- **Changed upstream rows need a graph refresh; changed columns, a
  schema update.** Rows added, updated or deleted upstream leave a
  materialized graph stale until it refreshes, by the graph refresh
  controls rather than an agent request: the refresh icon on the *Last
  refresh* card under **Home > Manage > Graph**, or *Refresh now* (or a
  schedule) on the graph model in the workspace. A changed upstream
  column is a schema update instead: review the bindings, which the
  ontology agent can help with (`how-to-use-ontology-graph`, read
  2026-11-18).
- **Graph projection has its own eligibility.** *Home > Manage > Graph*
  marks an entity type *Ineligible* when it has no entity type key, no
  binding, more than one backing table, or data bound to a semantic
  model: only lakehouse and mirrored-database delta tables project.
  Binary and Variant properties project as String, and time-series ones
  as their base type. Two more change what a GQL query against the graph
  sees: an entity or relationship that uses a namespace gets the namespace
  added as a prefix to its node or edge label, and a derived entity's
  node type carries the properties it inherits from its base entity as
  well as its own (same page, read 2026-11-18).
- **Three meters, one billable**, in the new experience: **Ontology
  Discovery**, 1,000 CU-seconds per definition read, one about every 20
  minutes included while the item is open, so close it when done; the
  child Graph and Eventhouse items' usage at their own rates, graph
  refreshes included; and dynamic **Ontology AI Reasoning** for the MCP
  server and the ontology agent. Only the child items' meter, **Ontology
  Logic and Operations**, is billable. Discovery and AI Reasoning are
  metered and reported but **not billable while in preview**: they count
  toward no capacity limit and are not paid for until they reach GA,
  when billing starts (the Metrics app's considerations). For an
  evaluation, start with an **F8**, or an F4 for light testing
  (`resources-capacity-usage`, checked 2026-10-23).

  **Once Discovery and AI Reasoning bill**, three more things count.
  An application that writes through an API triggers none of the
  portal's post-save reads, but any metered definition reads it makes
  are counted separately, and metering "can differ among
  definition-access APIs", which Learn does not name. A binding saved
  without changes triggers no Discovery read. Learn's "example
  estimates" for AI Reasoning, which vary with "ontology size,
  workspace items, model usage, tool calls, validation, and retries",
  are about **0.5–1 CU-hours** to add `client` and `buyer` as synonyms
  for Customer, and about **20 CU-hours** to draft an ontology from the
  workspace, "depending on ontology complexity". Apart from all three
  meters, ontology definitions stored in OneLake incur OneLake's
  standard storage and read/write charges (same page).

  **Old experience (legacy, retires 2027-01-31):** its own capacity
  page meters *Ontology Modeling* per definition-hour and AI by tokens,
  and counts graph refreshes too.

**Verify these at the lakehouse, not in TMDL.** A semantic model's TMDL
`dataType` is not the delta column type and the TMDL table name is not
the delta table name, so grepping TMDL for `decimal` or for spaced column
names produces false confidence in both directions. The check belongs on
the delta tables.

## The `Decimal` trap, and its remedy

Fabric Graph does not support `Decimal`. Generate an ontology from a
model whose tables carry `Decimal` columns and those properties return
**null on every query** — no error, just nulls. `Decimal` is the natural
money type, so this hits currency columns first.

The remedy is documented and specific: **recreate the property as
`Double` in the ontology and bind it to the source data.** That works
because *manual* binding accepts a lakehouse `decimal` column as a source
for a `double` property — the type map is wider than the generator's
output. Full source-to-property type table in
[ontology-reference.md](ontology-reference.md); the one other trap in
it is that lakehouse `decimal(p, s)` maps to **string**, not double.

## Binding data: the ordering and cardinality rules

From the binding page, checked 2026-10-23:

- **Seven source types bind**: eventhouse, KQL database, lakehouse,
  mirrored database, semantic model, SQL database and warehouse. Binding
  a **semantic model** needs both **Read and Build** permissions on it.
- **The first source is primary; each one added later is secondary**,
  related to the primary on a common column picked from each table, its
  proposed properties reviewed beside the existing ones before the save.
  The page no longer says a column name both tables share gets a **`_2`**
  suffix, or states the old static-first rule below, and does not say a
  time-series source can bind without a static one (read 2026-11-18).
- **An entity type key is optional**, since the overview announces
  keyless entity types; when one is defined, its properties are
  `string` or `integer` only. A keyless entity type cannot be projected
  into a graph (see the constraints above).

Until 2026-10-19 the page also stated three rules that now stand on the
old-experience page alone, below: one static binding per entity type,
many time-series bindings, and columnar time series. It dropped them
with its Limitations section and does not say whether they were lifted.

**Old experience (legacy, retires 2027-01-31):** static data comes from
OneLake only and time series from OneLake or an eventhouse, bound in two
steps. **Static first**: a time-series binding needs an existing
statically bound property to contextualize against, and the static value
must **exactly match** a column in the time-series data. The key is set
while binding, with *Define entity type key*: one or more `string` or
`integer` columns, together unique. Each entity type takes **one static
binding**, with no union of static data from two sources, and **many
time-series bindings**, from lakehouse *and* eventhouse sources
together; time series data must be **columnar**, one row per timestamped
observation
([old-experience binding page](https://learn.microsoft.com/fabric/iq/ontology/old-experience/how-to-bind-data),
checked 2026-10-23).

## Semantic enrichment is what makes agents work

Descriptions, synonyms, and key-value metadata on entity types and
properties. It is not decoration: Learn says it "improves agent answer
correctness, especially for prompts that depend on contextual
information like units of measurement, sensitivity levels, or business
definitions" (`how-to-add-metadata`, checked 2026-10-07).

Scope it honestly, because the docs do: enrichment helps the agent during
**schema exploration and reasoning**, and **query generation does not use
the metadata directly**. Only entity types support synonyms — properties
and relationship types get descriptions and key-value pairs only, and
keys must be unique within each object.

**Old experience (legacy, retires 2027-01-31):** "Data agent doesn't use
the semantic enrichment fields"
([old-experience enrichment page](https://learn.microsoft.com/fabric/iq/ontology/old-experience/how-to-add-semantic-enrichment),
checked 2026-10-07).

## Consuming an ontology

Six agent paths, detailed in [ontology-reference.md](ontology-reference.md):
the built-in **ontology agent**, a chat that authors as well as consumes,
Fabric **operations agent** (monitoring + actions), Fabric **data agent**
(conversational Q&A), **Foundry IQ** agent, **Copilot Studio** agent, and
**custom agents over the ontology MCP server**. One consumer is not an
agent: a **Real-Time Dashboard** takes an ontology as a data source
(preview), through *Add data source* → *Ontology*.

The MCP path is the one that matters outside Fabric: **an ontology is
itself an MCP server**, at a `dataPlane/…/ontologyEndpoint` URL whose
shape differs from the data agent's. The endpoint, its capacity and
tenant-setting prerequisites and the service principal limit are
[ontology-mcp.md](ontology-mcp.md)'s.

One known agent behaviour worth carrying: a data agent's first few
queries after creation can fail while it initializes (wait, retry). The
old aggregation workaround, adding `Support group by in GQL` to the
agent instructions, is moot: the data agent consumes the ontology as
context, then "generates a source-native SQL, KQL, or DAX query, runs the
query against that source, and presents the result" (Learn, checked
2026-10-06).

## Before you start: tenant settings

Creating the item at all requires the **Users can create ontology
(preview) items** tenant setting, and a new-experience item also requires
**Users can create Fabric items**. Failure to create a new ontology is
*most commonly* one of these and not anything about your data. Data agent
and operations agent each need their own settings on top.
