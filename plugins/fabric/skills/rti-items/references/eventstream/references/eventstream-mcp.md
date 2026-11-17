# Real-Time Intelligence: the local MCP server

A local, open-source MCP server for Real-Time Intelligence. It reaches
eventstreams, which have no hosted server of their own, and also
eventhouses, Activator, maps and Azure Data Explorer. This file is its
one home. The hosted per-database eventhouse server is
[remote-mcp.md](../../eventhouse/references/remote-mcp.md)'s. A stdio
entry runs it, as the
table's Hosting row says.

| | |
| --- | --- |
| Learn | [Get started with the local MCP server for Real-Time Intelligence](https://learn.microsoft.com/fabric/real-time-intelligence/mcp-local-server), listed as *Real-Time Intelligence MCP server (local)* in [Choose a Microsoft Fabric MCP server](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/fabric-mcp-servers-list), and the [overview](https://learn.microsoft.com/fabric/real-time-intelligence/mcp-overview) (all read 2026-10-20) |
| Source | [`microsoft/fabric-rti-mcp`](https://github.com/microsoft/fabric-rti-mcp/); installation and configuration are in that repo, not on Learn |
| Hosting | local, stdio; Learn says you install, host and manage it. Run as `uvx microsoft-fabric-rti-mcp`, which needs `uv` on `PATH` and fetches it from PyPI on first launch |
| Status | preview (Learn's page title, read 2026-10-20) |
| Identity | the signed-in user's Fabric role-based access: Learn says a client can invoke what the user's permissions allow. The sign-in flow and token scope are unrecorded |
| Spans | eventhouse (KQL databases), eventstreams, Activator, maps, and Azure Data Explorer clusters |
| Tools | none named on Learn; no names recorded here, so discover them by `tools/list` |

## What it does for eventstreams

Learn's account (read 2026-10-20) is that you can list the eventstreams in
a workspace, get their details and definitions, create new eventstreams,
"and more". The `and more` is not enumerated on either Learn page, so
whether it updates or deletes an eventstream, or pauses and resumes one,
is unmeasured here: read `tools/list`. Its definition calls are the REST
ones in [eventstream-api.md](eventstream-api.md), so the same warnings
carry: an update overrides the definition, and an Eventhouse destination
needs the property set of its `dataIngestionMode`.

It is the only server in Learn's list that names eventstreams: the
hosted servers cover Eventhouse, Activator and the operations agent, and
`rest-api`'s Fabric Core and local Fabric servers manage items
generically.

## The rest of its surface

- **Eventhouse and ADX**: KQL queries against the KQL databases in an
  eventhouse and against Azure Data Explorer clusters, with natural
  language to KQL and schema discovery (Learn). The hosted alternative for
  one eventhouse database is
  [remote-mcp.md](../../eventhouse/references/remote-mcp.md)'s.
- **Activator**: list Activator items, create trigger actions and set up
  notifications (Learn). The hosted alternative is Learn's *Activator MCP
  server*, pre-scoped to one reflex; see
  [activator-mcp.md](../../activator/references/activator-mcp.md).
- **Maps**: list, get details and definitions, create (Learn).

Learn's local-versus-remote guidance (read 2026-10-20): choose the local
server for full control, for ADX, or for offline or air-gapped use;
choose a hosted one for no infrastructure, automatic updates, or cloud
agent platforms such as Copilot Studio and Foundry.

## Risk

Learn warns (read 2026-10-20) that autonomous or misconfigured clients can
perform destructive actions within the user's permissions, and that flags
to prevent destructive operations are not part of the MCP specification
and may not be honoured by a client. An eventstream write through it is a
live change to a running stream, so review a write before approving it and
read the definition back first.

## Microsoft Learn

- [Get started with the local MCP server for Real-Time Intelligence](https://learn.microsoft.com/fabric/real-time-intelligence/mcp-local-server)
- [What is MCP in Real-Time Intelligence](https://learn.microsoft.com/fabric/real-time-intelligence/mcp-overview)
