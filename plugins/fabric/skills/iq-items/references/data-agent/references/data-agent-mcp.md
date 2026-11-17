# Fabric Data Agent: the MCP server

A published data agent is an MCP server, the programmatic query surface
and the replacement for the retired Assistants API path. From Claude
Code it takes the `headersHelper` entry in `rest-api`'s
`references/fabric-mcp.md` § Connecting from Claude Code, with the URL
below, which mints the token scope the table names; that entry is
unprobed against this endpoint.

| | |
| --- | --- |
| Learn | [Data agent as Model Context Protocol server](https://learn.microsoft.com/fabric/data-science/data-agent-mcp-server), listed as *Fabric data agent as an MCP server* in [Choose a Microsoft Fabric MCP server](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/fabric-mcp-servers-list) (both read 2026-10-20) |
| Hosting | remote, Microsoft-hosted; streamable HTTP |
| Status | GA (checked 2026-10-06) |
| Identity | a user or a service principal; no dynamic client registration or client identity metadata, so the client acquires its own token |
| Token scope | `https://api.fabric.microsoft.com/.default`, which the SPN query endpoint's scope is not ([authentication.md](authentication.md)) |
| Tools | exactly **one**, the agent itself; no name recorded here |

## Endpoint

```http
https://api.fabric.microsoft.com/v1/mcp/workspaces/{WorkspaceId}/dataagents/{DataAgentId}/agent
```

Copy it from **Settings → Model Context Protocol** on the published
agent, which also gives the tool name, the tool description and a
downloadable `mcp.json`, or build it from the two IDs. The token needs
permission on the workspace and the data agent.

## Before it answers

- An F2+ capacity, or P1+ with Fabric enabled; the **cross-geo
  processing and cross-geo storing for AI** tenant settings; and a
  source with data that the caller can read: a warehouse, lakehouse,
  semantic model, KQL database, mirrored database or ontology (Learn,
  read 2026-10-20).
- **It answers only after publish.** An unpublished agent returns an
  error, even at a correct URL.
- **The client must speak MCP**: `initialize`, then `tools/list`, then
  `tools/call`. A plain REST call that skips the handshake fails.
- **Discover the tool, never hard-code it**: take its name from
  `tools/list` and its argument from the tool's input schema, as
  `data-agent-eval.py` does.
- **The publish description becomes the tool description** the server
  advertises, so it is what an orchestrator reads to decide whether to
  call the agent: write it for that audience. Publishing by REST sets it
  ([data-agent-api.md](data-agent-api.md)).
- **Responses may leave Fabric's compliance boundary** and geographic
  region, handled under the MCP client's policies, as on M365 Copilot.

## Long-running questions become MCP tasks

A question that outlives the connection returns a task identifier
instead of the answer, following the `io.modelcontextprotocol/tasks`
extension: the client polls with `tasks/get` until the work finishes,
and stops it with `tasks/cancel`, which isn't instant. Only clients that
support the extension get a task; for every other client nothing
changes, and the answer comes back on the same connection. Whether a
given client supports the extension is the client's to say: check it
rather than assume.

## What an answer carries

**An answer carries text, never the query**: for the DAX, use the
Responses client
([consumption-surfaces.md](consumption-surfaces.md)). On the preview
runtime an answer also embeds its result as `file:///result_0.csv`, and
ends "File(s) result_0.json were generated as a result of the query.", a
line no instruction removes: the query tool's output tells the model
always to name the file, and "never mention a result file" kept the name
out of the rest of each answer but not that line. In one client estate
on 2026-10-15 the line ended 11 of 12 preview answers and none of 12
standard ones, and the preview answers embedded 13 CSVs, the standard
ones none. So only the client, or the standard runtime, keeps it from a
reader.

`data-agent-eval.py --route mcp` asks it as a consumer does and grades
each answer's text against the model's figures
([evaluation.md](evaluation.md)).
