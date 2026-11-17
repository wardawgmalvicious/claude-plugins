# Fabric's platform MCP servers: Core and local

Two Microsoft servers reach Fabric as a platform rather than one item:
the remote **Fabric Core MCP Server**, which manages workspaces, items,
folders and roles, plus OneLake shortcuts, data access roles and
workspace settings, and the local **Fabric MCP Server**, for development
work with API docs, OneLake and Data Factory. Each tool calls the REST
API this skill covers, under the caller's own permissions. § Connecting
from Claude Code has the entry that reaches the hosted Fabric endpoints
probed from Claude Code. A server for one item is that item's skill's, by
Learn's
[Choose a Microsoft Fabric MCP server](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/fabric-mcp-servers-list)
(read 2026-10-20); the index in `SKILL.md` § Definition APIs names each
item's owner.

**Discover the tools, never hard-code them**: take each name and its
arguments from `tools/list`. Learn's local tools page says names "can
vary by installed version and server configuration".

## Fabric Core MCP Server (remote)

| | |
| --- | --- |
| Learn | [Get started](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/core-remote/get-started-core), [overview](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/core-remote/overview-core-mcp-server), [tools reference](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/core-remote/tools-core-mcp-server) (tools reference read 2026-10-31, the others 2026-10-20) |
| Hosting | remote, Microsoft-hosted; streamable HTTP |
| Endpoint | `https://api.fabric.microsoft.com/v1/mcp/core`, one for the tenant |
| Identity | the signed-in Microsoft Entra identity, by OAuth 2.0; its own Fabric permissions, nothing more, and audit logs record that identity |
| Token scope | `https://api.fabric.microsoft.com/.default` |
| Status | GA since September 2026, as this skill has recorded; no Learn page read 2026-10-20 marks it preview |
| Tools | 43, as Learn's tools reference lists them (read 2026-10-31): 29 for the platform, then 14 for OneLake management. Platform: `search_catalog`; `list_workspaces`, `get_workspace`, `create_workspace`, `update_workspace`, `delete_workspace`; `add_workspace_role`, `list_workspace_roles`, `get_workspace_role`, `update_workspace_role`, `delete_workspace_role`; `list_items`, `get_item`, `create_item`, `update_item`, `delete_item`, `get_item_definition`, `update_item_definition`, `bulk_move_items`; `create_folder`, `list_folders`, `get_folder`, `update_folder`, `delete_folder`, `move_folder`; `list_capacities`; `get_operation_state`, `get_operation_result`; `get_knowledge`. OneLake, all prefixed `onelake_`: shortcuts `list_shortcuts`, `get_shortcut`, `create_shortcut`, `create_shortcuts_in_bulk`, `delete_shortcut`, `reset_shortcut_cache`; data access roles `list_data_access_roles`, `create_or_update_single_data_access_role`, `create_or_update_data_access_roles`, `delete_data_access_role`; workspace settings `get_settings`, `modify_default_tier`, `modify_diagnostics`, `modify_immutability_policy` |

Before it works, and what it does:

- The client must speak streamable HTTP and the server's Entra OAuth
  flow; Learn recommends VS Code with GitHub Copilot. From Claude Code a
  `headersHelper` sends an Azure CLI bearer instead, measured connecting
  2026-09-14 (§ Connecting from Claude Code).
- **It writes, and some writes cannot be undone.** Deleting a workspace
  removes every item in it permanently, and a folder must be empty to
  delete (Learn). Review each proposed call before allowing it.
- A long-running call returns an operation id: poll it with
  `get_operation_state`, then `get_operation_result`, as § Long-Running
  Operations does by hand.
- Role tools take user principal ids; Learn pairs the server with the
  Microsoft Graph MCP server to resolve email addresses.
- **The OneLake data access role tools are not the workspace roles**:
  `onelake_create_or_update_data_access_roles` replaces an item's whole
  role set, so a role left out loses its grants. Learn says to prefer the
  single-role tool and to read every page of existing roles first.

## Connecting from Claude Code

**Every hosted Fabric endpoint probed connects from Claude Code through
a `headersHelper`**, a command that prints the `Authorization` header:
the bare `core`, `dataPlane/sqlEndpoint`, `dataPlane/kqlEndpoint` and
`powerbi`, a workspace/item-bound `kqlEndpoint` and an Activator reflex
URL, measured 2026-09-14 on CLI 2.1.268, and the four bare ones again on
2026-10-07 on 2.1.292. Claude Code's automatic OAuth flow cannot register
with them: it registers by dynamic client registration, which Microsoft's
auth server does not support. The entry, in a repo's `.mcp.json`, with another
endpoint's `url` for another server:

```json
{
    "mcpServers": {
        "fabric-core": {
            "type": "http",
            "url": "https://api.fabric.microsoft.com/v1/mcp/core",
            "headersHelper": "az account get-access-token --resource https://api.fabric.microsoft.com --query \"{Authorization: join(' ', ['Bearer', accessToken])}\" --output json --only-show-errors"
        }
    }
}
```

- **The helper needs the Azure CLI and a live `az login`**, and runs on
  every connection. With no login it prints nothing, and Claude Code
  reports `Incompatible auth server: does not support dynamic client
  registration` on a bare URL and `Error dialing <url>` on a bound one,
  which read as an unsupported flow or a network fault. A token the
  server rejects reads `Server rejected the Authorization header minted
  by the configured headersHelper (HTTP 401)`. `MCP endpoint not found`
  is the one text that means a wrong URL (all measured 2026-09-14).
- **A project `.mcp.json` runs its helper only in a trusted folder**:
  untrusted, the helper is skipped and the error is the no-login one
  (the VS Code extension's log, 2026-10-02 and 2026-10-03).
- **A long call needs a `timeout`.** On `dataPlane/sqlEndpoint`,
  `dataPlane/kqlEndpoint` and `powerbi`, add `"timeout": 120000` to the
  entry: with none, a call past about a minute fails with `The operation
  timed out.`, and each endpoint ends a call itself at about 100 seconds
  (measured 2026-10-07, CLI 2.1.292).
- **The tenant must enable the Fabric MCP preview for the signed-in
  user**, and the `powerbi` endpoints a Power BI tenant setting of their
  own, in `pbi-items`' `references/tmdl/references/semantic-model-mcp.md`.
  An item-bound server
  adds settings of its own, in its skill's `-mcp.md` reference.
- **A URL carrying ids belongs in that repo's `.mcp.json`**, never in a
  user-scope config, which every repo would load.

## Fabric MCP Server (local)

| | |
| --- | --- |
| Learn | [Overview](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/pro-dev-local/overview-local-mcp-server), [get started](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/pro-dev-local/get-started-local), [tools reference](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/pro-dev-local/tools-local-mcp-server) (read 2026-10-20); source and tool catalog in [`microsoft/mcp`](https://github.com/microsoft/mcp/tree/main/servers/Fabric.Mcp.Server) |
| Hosting | local, stdio: the VS Code *Fabric MCP Server* extension, the npm package `@microsoft/fabric-mcp` (`server start --mode all`), or a .NET source build |
| Endpoint | none; the MCP host starts it as a subprocess |
| Identity | for live calls, the Azure CLI's `az login` user, or a service principal from `AZURE_TENANT_ID`, `AZURE_CLIENT_ID` and a certificate path or secret; the docs tools need none |
| Token scope | acquired by the server's Azure credential; not stated on the pages read |
| Status | open source; no Learn page read here marks it preview |
| Tools | four categories: API docs and best practices (`docs_list-item-types`, `docs_item-api-spec`, `docs_platform-api-spec`, `docs_item-definitions`, `docs_best-practices`, `docs_api-examples`, as Learn's tools reference names them, read 2026-10-20), OneLake, core Fabric, and Data Factory; the rest are in the GitHub catalog, unread here |

What sets it apart:

- **The docs tools work offline**, from bundled copies of the API specs,
  item definitions and examples: the same material as this skill's
  fallback order, the spec repository then Learn. Which spec version is
  bundled is not stated; check its age against the spec folder's SHA
  before trusting it over the clone.
- **OneLake tools live here**, not in a separate server: list, read,
  upload and download files, and read table schemas.
- **Its Data Factory tools overlap the DataFactory MCP server**, which is
  `data-items`'; Learn lists the two apart.
- A service principal needs the tenant setting [auth.md](auth.md)
  names, and works only where the API supports one.
- **Local hosting is not local processing**: the client and model still
  see what a tool returns, and the server writes no Fabric audit log of
  its own (Learn's *Security and compliance*).
