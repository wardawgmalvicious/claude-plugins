---
name: iq-items
description: "Use for Microsoft Fabric IQ items, in Git or by REST, `fab` or a script: an ontology (`.Ontology`, `/ontologies`: entity types, properties, relationships, data binding, semantic enrichment, its MCP server), a graph model or graph queryset (`.GraphModel`, `/graphModels`, `.GraphQuerySet`, `/graphQuerySets`: GQL over a labeled property graph), a data agent (`.DataAgent`, `/dataAgents`: natural-language Q&A over Fabric data, its MCP server, evaluation) or an operations agent (`.OperationsAgent`, `/operationsAgents`, `Configurations.json`: watches live data and acts on it). Picks the item, then reads its reference."
when_to_use: "Use before a Read, edit or REST call on an item of type Ontology, GraphModel, GraphQuerySet, DataAgent or OperationsAgent, or before writing GQL for a Fabric graph model."
# model: inherit  # any model: value blocks Copilot slash invocation
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Fabric IQ items

Learn's IQ workload holds six items ("What is Fabric IQ?", read
2026-10-12). Four have a reference here, in the table below; Power BI
semantic models are `pbi-items`', and Plan has none. Each reference
holds the depth, and this file picks the item and carries only what
crosses items. Take the steps in order: the wrong item sends every later
step to the wrong file.

## 1. Pick the item

By the job asked for, or by the folder of the file in hand:

| The job | Folder | Read |
| --- | --- | --- |
| A shared business vocabulary bound to data: entity types, properties, relationships | `<name>.Ontology/` | [ontology.md](references/ontology.md) |
| GQL over a labeled property graph built from OneLake tables | `<name>.GraphModel/` | [graph.md](references/graph.md) |
| Natural-language Q&A over a domain's data, read-only, asked by a user | `<name>.DataAgent/` | [data-agent.md](references/data-agent/data-agent.md) |
| Watching live data and acting on it, unattended | `<name>.OperationsAgent/` | [operations-agent.md](references/operations-agent.md) |

[operations-agent.md](references/operations-agent.md) § 7 sets the two
agents side by side. Near these items, and not them:

- KQL's graph operators in an Eventhouse (`make-graph`, `graph-match`):
  `rti-items`, a different engine from the GraphModel.
- Rule-based alerting with no LLM: `rti-items`' Activator.
- The semantic model an ontology is generated from, or a data agent
  queries: `pbi-items`.

## 2. What crosses items

- **An ontology grounds both agents.** A data agent takes one as a
  source, with known issues of its own
  ([data-agent.md](references/data-agent/data-agent.md) § What a Data
  Agent is). An operations agent takes one as its single source, in the
  agent's own workspace
  ([operations-agent-reference.md](references/operations-agent-reference.md)
  § Data source constraints). Model the ontology in ontology.md, and
  configure each agent in its own file.
- **An ontology can generate a graph**: a child `GraphModel`, made only
  on opt-in through *Manage graph*, and only from eligible entity types
  ([ontology.md](references/ontology.md), its opening and § The
  constraints that produce silent or confusing failures). GQL itself is
  [graph.md](references/graph.md)'s.
- **Two MCP endpoints, two shapes.** An ontology is an MCP server
  ([ontology-mcp.md](references/ontology-mcp.md)), and so
  is a published data agent
  ([data-agent-mcp.md](references/data-agent/references/data-agent-mcp.md)).
  The URLs differ in shape, so neither is built from the other.
- **Each item has its own tenant settings**; check them first when an
  item won't create. The ontology's are in
  [ontology.md](references/ontology.md) § Before you start, and, with
  both agents', in
  [ontology-reference.md](references/ontology-reference.md) § 7. The data
  agent's are on the Learn page its § Reference links, and the
  operations agent's in
  [operations-agent-reference.md](references/operations-agent-reference.md)
  § Runtime, identity and availability. graph.md names none.

## 3. Read the item's reference first

Read the file step 1 names before answering or editing: limits,
definition shapes and preview status live there, dated. Each sends its
long detail one file further:
[ontology-reference.md](references/ontology-reference.md),
[graph-reference.md](references/graph-reference.md),
[operations-agent-reference.md](references/operations-agent-reference.md),
and the data agent's own [references/](references/data-agent/references/)
and [assets/](references/data-agent/assets/). A task that spans items, an
ontology-grounded agent for one, reads each item's file.

An item's definition, REST calls and MCP server have files of their own
where written. Read one first for its job; past it, the REST spec's
folder, then Learn, by `microsoft-learn-mcp`, or with no server, `curl -sL -H 'Accept: text/markdown' <page URL>` (undocumented, read 2026-11-07):

| The job | Read first |
| --- | --- |
| A data agent's definition parts, or a REST call past the generic item set | [data-agent-api.md](references/data-agent/references/data-agent-api.md) |
| A data agent's MCP server: endpoint, token, tool discovery | [data-agent-mcp.md](references/data-agent/references/data-agent-mcp.md) |
| An ontology's definition parts (TMDL, and the old JSON layout), or its REST calls (the generic seven only) | [ontology-reference.md](references/ontology-reference.md) § 1 |
| An ontology's MCP server: endpoint, prerequisites, tool names | [ontology-mcp.md](references/ontology-mcp.md) |
| A graph model's definition parts, or a REST call past the generic item set (`executeQuery`, `getQueryableGraphType`, the refresh job) | [graph-model-api.md](references/graph-model-api.md) |
| A graph queryset's definition (`exportedDefinition.json` live, named by neither Learn nor the spec) or its REST calls (the generic seven only) | [graph-queryset-api.md](references/graph-queryset-api.md) |
| An operations agent's definition (`Configurations.json`) or its REST calls (the generic seven only) | [operations-agent.md](references/operations-agent.md) |
| An operations agent's MCP server: its configure and query endpoints, token, tool discovery | [operations-agent-mcp.md](references/operations-agent-mcp.md) |

A live page that contradicts a line here wins: say so, act on the page,
and route the fix by `capture-learning`, bar a dated measured line that
names the page it overrules and the call that measured it, which a page
changed since its date sends back to re-measure. An observed claim is cited
or marked pending a doc check, and stands, marked observed, only where no
page covers it.

The data agent has two scripts, each run by `uv run` and its docstring
its usage: `${CLAUDE_SKILL_DIR}/scripts/data-agent-eval.py` grades the
agent's replies against its semantic model's figures, and
`${CLAUDE_SKILL_DIR}/scripts/data-agent-settings.py` reads and sets the
draft's instructions and runtime, and publishes it
([evaluation.md](references/data-agent/references/evaluation.md)).
