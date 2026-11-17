# Fabric Data Warehouse MCP server (preview)

A hosted MCP server that runs T-SQL against a warehouse or a SQL
analytics endpoint. Claude Code reaches it by the `headersHelper` entry
in `rest-api`'s `references/fabric-mcp.md` § Connecting from
Claude Code, with the global URL below and a `timeout` (§ Before it
answers).

| | |
| --- | --- |
| Learn | [Fabric Data Warehouse MCP server](https://learn.microsoft.com/fabric/data-warehouse/data-warehouse-mcp-server), listed as *Fabric Data Warehouse MCP server* in [Choose a Microsoft Fabric MCP server](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/fabric-mcp-servers-list) (both read 2026-10-20) |
| Hosting | remote, Microsoft-hosted; HTTP |
| Status | preview (Learn, 2026-10-20) |
| Identity | the signed-in user's; it respects Fabric permissions and runs only what that identity may run |
| Token audience | Learn names none (its VS Code entries carry no header); a `headersHelper` bearer for `https://api.fabric.microsoft.com` connected from Claude Code (measured 2026-09-14, CLI 2.1.268) |
| Tools | exactly **one**, `executeSQL` (Learn, 2026-10-20); discover them by `tools/list` |

## Endpoint

Two forms, both HTTP:

```http
https://api.fabric.microsoft.com/v1/mcp/dataPlane/sqlEndpoint
https://api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/{WorkspaceId}/items/{ItemId}/sqlEndpoint
```

The first, global, takes the warehouse in the prompt or the tool
arguments. The second binds the connection to one warehouse item by its
workspace and item ids. Learn documents both (2026-10-20).

**Only the global form is known to serve from here.** The item-bound form
returned `MCP endpoint not found` for every item type tried, in one
tenant, while the bound `kqlEndpoint` beside it connected (measured
2026-09-14); Learn's description of it is unmeasured here. Because the bound form carries ids, it belongs in a repo's own
`.mcp.json` and never in a user-scope config.

## Before it answers

- **Access to a warehouse or SQL analytics endpoint**, and the Fabric
  workspace and SQL permissions for the statements asked for. Learn's
  prerequisites name Visual Studio Code and GitHub Copilot for its
  walkthrough, which are that walkthrough's client and not a server
  requirement (read 2026-10-20). It names no capacity or tenant setting,
  though the tenant must enable the Fabric MCP preview for the signed-in
  user, as for every hosted Fabric endpoint.
- **Claude Code needs a `headersHelper`**, not the automatic OAuth flow,
  which cannot register with this endpoint. The helper shells out to
  `az account get-access-token`, so it needs a live `az login`; with none,
  the failure reads as a DCR error or a network fault, not a missing
  credential. The entry and each failure's text are in
  `rest-api`'s `references/fabric-mcp.md` § Connecting from
  Claude Code.
- **A long query needs a `timeout`.** With none, a call past about a
  minute fails with `The operation timed out.`; with `timeout` set, a
  75-second query succeeded through Claude Code (2026-10-07, CLI 2.1.292),
  and the endpoint itself ends a call on its own side: a direct call
  succeeded at 91.3 s and failed with HTTP 500 and JSON-RPC `-32603` at
  100.6 s. So set `"timeout": 120000`, which clears that cap, so
  Claude Code's timer never cuts a call the endpoint would finish
  (decided 2026-10-07).
- **The only tool runs any T-SQL, writes included.** Review a `CREATE`,
  `ALTER`, `DROP`, `INSERT`, `UPDATE` or `DELETE` before approving it, and
  start read-only on a production warehouse (Learn, 2026-10-20). Whether
  a statement works is the warehouse's T-SQL surface
  ([t-sql-surface.md](t-sql-surface.md)), not the server's.
- **There is no schema tool.** The server exposes no listing of schemas,
  tables or query history; ask for `INFORMATION_SCHEMA` or the system
  views through `executeSQL` (Learn, 2026-10-20).

## Discover the tool, never hard-code it

The tool name above is as Learn lists it on 2026-10-20 and was not
checked against a live `tools/list` here. The server is a preview: take
the names and the input schema from `tools/list`, and expect the set to
change.
