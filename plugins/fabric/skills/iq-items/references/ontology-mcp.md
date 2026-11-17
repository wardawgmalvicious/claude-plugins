# Fabric Ontology: the MCP server (preview)

An ontology is itself an MCP server, the path for a custom agent outside
Fabric that needs the ontology's entities, relationships and
definitions. From Claude Code it takes the `headersHelper` entry in
`rest-api`'s `references/fabric-mcp.md` § Connecting from Claude
Code, with the URL below; that entry is unprobed against this endpoint.

| | |
| --- | --- |
| Learn | [Consume ontology (preview) as an MCP server](https://learn.microsoft.com/fabric/iq/ontology/how-to-use-ontology-mcp-server), listed as *Ontology MCP server* in [Choose a Microsoft Fabric MCP server](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/fabric-mcp-servers-list) (both read 2026-10-20) |
| Hosting | remote, Microsoft-hosted; HTTP |
| Status | preview (Learn, 2026-10-20) |
| Identity | a user; a service principal can't use it, a known issue (Learn, 2026-10-20) |
| Token scope | not stated on Learn's page (read 2026-10-20), which has VS Code sign in interactively. The `headersHelper` above mints an `az` token for `https://api.fabric.microsoft.com`, unprobed here |
| Tools | `list_ontology_entity_types` and `search_ontology`, as last seen on the Copilot Studio tool below (Learn, checked 2026-10-06); no `tools/list` against this endpoint is recorded here |

## Endpoint

```http
https://api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/<workspace-ID>/items/<ontology-item-ID>/ontologyEndpoint
```

Both IDs are in the ontology's portal URL,
`https://app.fabric.microsoft.com/groups/<workspace-ID>/ontologies/<ontology-item-ID>`.
The URL names one item, so the entry is per repo, never user scope.
Learn's setup is the ordinary MCP-over-HTTP flow: in VS Code,
`.vscode/mcp.json`, **Add Server**, **HTTP**, paste the URL, name it,
sign in interactively, then start the server from chat in agent mode.
Nothing in that config is Fabric-specific.

**Do not confuse it with the data agent's endpoint**,
`https://api.fabric.microsoft.com/v1/mcp/workspaces/{WorkspaceId}/dataagents/{DataAgentId}/agent`
([data-agent-mcp.md](data-agent/references/data-agent-mcp.md)), which
only resolves once that agent is **published**. Different path shape
(`dataPlane`, `items`, a trailing `ontologyEndpoint`), different item,
different prerequisite.

## Before it works

- A paid **F2 or higher** Fabric capacity, or Power BI Premium P1+ with
  Fabric enabled, and an ontology item (Learn, 2026-10-20).
- The tenant settings **Users can create ontology (preview) items** and
  **Users can create Fabric items**
  ([ontology-reference.md](ontology-reference.md) § 7 has the rest of the
  ontology's settings).
- The call is metered: dynamic **Ontology AI Reasoning** covers the MCP
  server and the ontology agent, **not billable while in preview** and
  billed once it reaches GA
  ([ontology.md](ontology.md) § The constraints that produce silent or
  confusing failures).
- **A service principal fails**, per Learn's known issue; the symptom is
  in [ontology-reference.md](ontology-reference.md) § 6. Use a user
  identity.

## The Copilot Studio tool is another path

Copilot Studio reaches an ontology through a tool listed as **Fabric IQ
MCP (preview)**: *Tools → Add a tool → Model Context Protocol*, search
*Fabric IQ Ontology*, pick it, then a connection taking **Workspace ID**
and **Ontology ID**; the tool exposes `list_ontology_entity_types` and
`search_ontology`. **It is not the GA Fabric IQ MCP server**, a different
server for Power BI reports and semantic models that "doesn't currently
support Fabric ontologies or data agents" (Learn, checked 2026-10-06).
Same name, different server: check which one a setup guide means.
Whether the Copilot Studio tool and the endpoint above are the same
server is not stated on either page.

## Discover the tools, never hard-code them

The two names above are as last seen on Learn on 2026-10-06. The client
must speak MCP (`initialize`, then `tools/list`, then `tools/call`):
take the names and each tool's arguments from `tools/list` and its input
schemas, which Learn does not give.
