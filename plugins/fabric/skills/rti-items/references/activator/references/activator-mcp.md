# Activator: the remote MCP server (preview)

Fabric hosts an HTTP MCP endpoint scoped to **one** Activator item, for
creating and starting rules in natural language. § Endpoint says how
Claude Code reaches it.

| | |
| --- | --- |
| Learn | [Get started with the remote MCP server for Activator](https://learn.microsoft.com/fabric/real-time-intelligence/mcp-remote-activator), listed as *Activator MCP server* in [Choose a Microsoft Fabric MCP server](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/fabric-mcp-servers-list) (both read 2026-10-20) |
| Hosting | remote, Microsoft-hosted; HTTP |
| Status | preview (Learn, 2026-10-20) |
| Identity | OAuth against Entra: the client acquires an Entra ID token and passes it; Learn names VS Code with GitHub Copilot and the GitHub Copilot CLI as clients |
| Token audience | not stated on Learn's page (read 2026-10-20). The `headersHelper` entry (§ Endpoint) asks `az` for `https://api.fabric.microsoft.com`, and connected to a reflex-bound URL on 2026-09-14; no tool call through it is recorded |
| Tools | `create_rule`, `list_rules`, `start_rule`, `stop_rule` (Learn, 2026-10-20) |

## Endpoint

```http
https://api.fabric.microsoft.com/v1/mcp/workspaces/<Workspace ID>/reflexes/<Artifact ID>
```

Both IDs are in the item's portal URL, `.../groups/<Workspace ID>/reflexes/<Artifact ID>/...`.
The URL names one item, so a second Activator needs a second server
entry, and the entry is per repo, never user scope. Learn supports
manual client configuration only (read 2026-10-20). For Claude Code the
entry sends an `az` bearer through `headersHelper`, the entry in
`rest-api`'s `references/fabric-mcp.md` § Connecting from Claude
Code with this URL; Learn's own example is a bare `servers` entry in VS
Code's `mcp.json` with no helper.

## Before it works

- An Activator item in a workspace, and a **KQL data source** the rules
  can watch: a KQL database for Kusto (Azure Data Explorer), given by
  cluster URL and database name, or a Fabric eventhouse, given by its KQL
  database item ID and workspace ID (Learn, 2026-10-20).
- The prompt must carry the workspace ID and artifact ID, which the
  assistant needs to target the item.
- Learn recommends connecting the eventhouse MCP server beside it, so the
  agent can read the schema a rule watches before creating the rule;
  that server is
  [remote-mcp.md](../../eventhouse/references/remote-mcp.md)'s.
- Learn lists no tenant setting for this server (read 2026-10-20);
  whether one gates it is unmeasured.

## What it can and cannot do

**`create_rule` starts the rule automatically** (Learn, 2026-10-20),
where the definition path ships `shouldRun: false`. A rule made this way
is live, and billing, from creation.

Learn's limits, which are narrow enough to check before reaching for it:

- **KQL data sources only**, Azure Data Explorer or Fabric eventhouses.
- **One server entry per artifact.**
- **Teams and email actions only**: no webhook, no Power Automate flow,
  and no Fabric item action.
- **No multi-event correlation**: a rule monitors a single stream.
- **No aggregation**: conditions evaluate individual events, with no
  average, sum or count over a window.

So anything involving a Fabric item action, an Eventstream source or an
average over a window belongs in the definition
([reflex-entities.md](reflex-entities.md)), not here.

A rule has three parts: a stream (`splitColumn` to group per entity,
`filters` to narrow), a detection (`condition` and `occurrence`, such as
"every time" or "stays for 5 minutes") and an action. The detection
functions Learn names are numeric, text, Boolean and heartbeat
(`noPresenceOfData(600)` for ten minutes without data). State against
change matters here as it does in the portal: "rises above" fires on the
transition, "is above" on every matching event, and an action body takes
`{columnName}` placeholders.

## Discover the tools, never hard-code them

The four names above are as last seen on Learn on 2026-10-20; no
`tools/list` against the live server is recorded here. The client must
speak MCP (`initialize`, then `tools/list`, then `tools/call`): take the
names and each tool's arguments from `tools/list` and its input schemas,
which Learn's table does not give.
