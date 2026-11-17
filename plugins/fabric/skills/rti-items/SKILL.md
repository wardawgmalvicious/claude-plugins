---
name: rti-items
description: "Use for Microsoft Fabric Real-Time Intelligence items, in Git or by REST, `fab` or a script: an Eventhouse or KQL database (`.Eventhouse`, `.KQLDatabase`, `/eventhouses`, `/kqlDatabases`, KQL management commands, `.create-merge`, ingestion, materialized views, update policies, OneLake availability, KQL graph operators, its remote MCP server, workspace monitoring); an Eventstream (`.Eventstream`, `/eventstreams`, CDC, Event Hubs or Kafka sources, destinations, publish, pause and resume, a schema-associated custom endpoint and its CloudEvents producer format); an Event Schema Set (`.EventSchemaSet`, `EventSchemaSetDefinition.json`, Avro schemas, what mints a version); Activator, the Reflex item (`.Reflex`, `/reflexes`, `ReflexEntities.json`, rules and alerts); a Real-Time Dashboard, RTDB or KQL dashboard (`.KQLDashboard`, `RealTimeDashboard.json`, tiles, base queries); and a KQL queryset (`.KQLQueryset`, `RealTimeQueryset.json`, `/kqlQuerysets`). Picks the item, then reads its reference."
when_to_use: "Use before a Read, edit or REST call on an item of type Eventhouse, KQLDatabase, Eventstream, EventSchemaSet, Reflex, KQLDashboard or KQLQueryset; before writing KQL for a Fabric KQL database; or when events are accepted and then dropped, an eventstream needs republishing, a schema version did or did not bump, an Activator rule does not fire, or a dashboard tile fails to load."
# model: inherit  # any model: value blocks Copilot slash invocation
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Fabric Real-Time Intelligence items

Fabric's Real-Time Intelligence workload holds the items below, and each
has a reference here. Each reference holds the depth, and this file
picks the item and carries only what crosses items. Take the steps in
order: the wrong item sends every later step to the wrong file, and one
event's path can cross four of these items, from a schema set through
an eventstream into an Eventhouse and on to a dashboard or an Activator.

## 1. Pick the item

By the job asked for, or by the folder of the file in hand:

| The job | Folder | Read |
| --- | --- | --- |
| KQL against a KQL database: management commands, ingestion, policies, materialized views, OneLake availability, graph operators, workspace monitoring, the remote MCP server | `<name>.Eventhouse/`, `.KQLDatabase/` | [eventhouse.md](references/eventhouse/eventhouse.md) |
| Routing events: sources, operators, destinations, publish, pause and resume, producing to a custom endpoint | `<name>.Eventstream/` | [eventstream.md](references/eventstream/eventstream.md) |
| The schemas a custom endpoint validates events against: Avro, the four description stores, what mints a version | `<name>.EventSchemaSet/` | [event-schema-set.md](references/event-schema-set/event-schema-set.md) |
| Rules and alerts on data: `ReflexEntities.json`, sources, actions, limits and cost, what Git excludes | `<name>.Reflex/` | [activator.md](references/activator/activator.md) |
| A dashboard: `RealTimeDashboard.json`, its queries, tiles and base queries, load-time validation | `<name>.KQLDashboard/` | [realtime-dashboard.md](references/realtime-dashboard/realtime-dashboard.md) |
| Saved queries: `RealTimeQueryset.json`, its tabs and data sources, `/kqlQuerysets` | `<name>.KQLQueryset/` | [kql-queryset.md](references/kql-queryset/kql-queryset.md) |

Near these items, and not them:

- The REST conventions every item call shares, such as auth,
  long-running operations and the error catalogue: `rest-api`.
- Deployment pipelines, fabric-cicd and a workspace's Git integration:
  `deploy`.
- The variable library an eventstream source or destination reads:
  `variable-library`.
- The GraphModel item and GQL, which KQL's graph operators are not, and
  the operations agent: `iq-items`.
- A lakehouse an eventstream writes to, and Spark over it: `data-items`.

## 2. What crosses items

- **An eventstream routes events into the other items**: an Eventhouse,
  a Lakehouse, an Activator or a derived stream
  ([eventstream.md](references/eventstream/eventstream.md)
  § Destinations, § Activator destination). An Eventhouse destination
  takes a different property set per `dataIngestionMode`, and the wrong
  one is accepted and ingests nothing, with no error
  ([eventstream-api.md](references/eventstream/references/eventstream-api.md)).
- **A schema version is a contract across three items.** The set mints
  it
  ([event-schema-set.md](references/event-schema-set/event-schema-set.md)
  § 6. Versioning: the route decides), the producer pins it in
  `dataschema`
  ([cloudevents-producer.md](references/eventstream/references/cloudevents-producer.md)),
  and an Eventhouse destination names its tables
  `{CloudEventType}_{CloudEventSchemaVersion}`. A producer naming a
  version that is no longer current sees its events accepted, then
  dropped (§ 7. Why the version is load-bearing).
- **KQL is eventhouse.md's.** A dashboard tile's query and an
  Activator's `kqlSource-v1` both run against a KQL database, so its
  query patterns, permission model and gotchas bind both.
- **Workspace monitoring lands in an Eventhouse.** Its setup, access and
  retention are
  [workspace-monitoring.md](references/eventhouse/references/workspace-monitoring.md)'s;
  the eventstream tables, which each eventstream opts into, are
  [monitoring.md](references/eventstream/references/monitoring.md)'s.
- **Each MCP server has one home.** The local Real-Time Intelligence
  server, which also reaches eventhouses and Activator, is
  [eventstream-mcp.md](references/eventstream/references/eventstream-mcp.md)'s;
  the hosted per-database KQL server is
  [remote-mcp.md](references/eventhouse/references/remote-mcp.md)'s, and
  the hosted Activator server
  [activator-mcp.md](references/activator/references/activator-mcp.md)'s.
  A schema set and a dashboard have none.

## 3. Read the item's reference first

Read the file step 1 names before answering or editing: limits,
definition shapes and preview status live there, dated, and each names
its own *Read first* table for its definition, REST calls and MCP
server, then the REST spec's folder, then the live docs, Learn by
`microsoft-learn-mcp`, or with no server,
`curl -sL -H 'Accept: text/markdown' <page URL>` (undocumented, read
2026-11-07). A task that spans items, an eventstream that lands a
schema set's events in an Eventhouse for one, reads each item's file.

A live page that contradicts a line here wins: say so, act on the page,
and route the fix by `capture-learning`, bar a dated measured line that
names the page it overrules and the call that measured it, which a page
changed since its date sends back to re-measure. An observed claim is
cited or marked pending a doc check, and stands, marked observed, only
where no page covers it.
