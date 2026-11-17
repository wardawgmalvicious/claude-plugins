# Semantic model: the MCP servers

Three Microsoft endpoints reach a semantic model: the Fabric IQ server
discovers models and reports and queries them with DAX, and Power BI
Authoring, one server with a remote and a local deployment, authors them.
Learn's list
([Choose a Microsoft Fabric MCP server](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/fabric-mcp-servers-list),
read 2026-11-07) names Fabric IQ and both Authoring deployments; the
earlier Power BI consumption endpoint below is no longer on it. From
Claude Code the two hosted ones take the
`headersHelper` entry in `rest-api`'s `references/fabric-mcp.md`
§ Connecting from Claude Code, with their URLs below, and the local one
a stdio entry, `npx @microsoft/powerbi-modeling-mcp`, which needs
Node.js 18.0 or later (npm `engines` at 1.0.0, 2026-11-03). The model's definition and REST calls are
[definition-api.md](definition-api.md)'s.

**Discover the tools, never hard-code them**: take each name and its
arguments from `tools/list`. The names below are as last seen, dated,
and Learn says of the authoring servers that the tools are grouped by
object type and that the way to list them is to ask the agent.

Two rules hold across all three:

- **Register one authoring server, not both.** Learn: the agent then sees
  two overlapping tool sets, which makes routing ambiguous and spends
  tokens on every request. Hosted for a model in a Fabric workspace,
  local for Power BI Desktop or PBIP files (Learn, read 2026-11-07).
- **Keep the two hosted Power BI URLs apart.** `/v1/mcp/powerbi` only
  queries; `/v1/mcp/powerbi/authoring`, one path segment further, writes.

## Power BI MCP server (remote): query with DAX

| | |
| --- | --- |
| Learn | [Power BI Consumption MCP server (preview)](https://learn.microsoft.com/power-bi/developer/mcp/remote-mcp-server-get-started), the earlier consumption endpoint, no longer on Learn's MCP list, which names the Fabric IQ server for this job instead (both pages read 2026-11-07) |
| Hosting | remote, Microsoft-hosted; HTTP |
| Endpoint | `https://api.fabric.microsoft.com/v1/mcp/powerbi`, one for the tenant: every tool takes a semantic model ID or report ID |
| Identity | the signed-in user, who needs **Build** permission on the model; RLS applies. A service principal is supported, but Power BI does not enforce RLS for one |
| Token scope | Microsoft Entra. An app registered for a client without its own takes delegated Power BI Service permissions on `https://analysis.windows.net/powerbi/api`: `Dataset.Read.All`, `MLModel.Execute.All` and `Workspace.Read.All` (Learn's *external MCP clients* page, read 2026-10-20). From Claude Code a `headersHelper` sends a `https://api.fabric.microsoft.com` bearer instead, measured connecting 2026-09-14 and 2026-10-07 |
| Status | preview (Learn, 2026-11-07). Its page calls it the earlier consumption endpoint and prefers the Fabric IQ MCP server for querying |
| Tools | `Execute Query`, `Get Semantic Model Schema`, `Get Report Metadata` and `Generate Query`, as Learn names them (read 2026-11-07); not listed from the server itself here |

Before it answers:

- The Fabric admin portal's tenant setting **Users can use the Power BI
  Model Context Protocol server endpoint (preview)** must be on.
- Build permission on at least one model. Preparing the model for AI
  improves the DAX it generates
  ([ai-instructions.md](ai-instructions.md)).
- `Generate Query` uses Copilot in Power BI and so needs a Copilot
  licence and consumes Copilot capacity; Learn says to disable that tool
  in the client to avoid it and let the client's model write the DAX.
- Each query is independent: the server keeps no state between requests.
- **`Execute Query` returns at most 1,000 rows, and marks no cut**: it
  answers inline as `executionResult.tables` whatever `maxRows` asks,
  and 1,002 rows, 20,000 rows and 1,000 rows of ~120 KB each came back
  as 1,000 (`PowerBIMCPServer` 1.0.0, seven direct calls, 2026-10-25).
  Read a 1,000-row answer as possibly cut; aggregate in the query. Learn
  names no limit.

## Power BI semantic model authoring (remote): hosted modeling

| | |
| --- | --- |
| Learn | [Power BI Authoring MCP server](https://learn.microsoft.com/power-bi/developer/mcp/power-bi-authoring-mcp), hosted deployment; setup for Claude Code and Codex in [skills-for-fabric `mcp-setup`](https://github.com/microsoft/skills-for-fabric/blob/main/mcp-setup/README.md), (read 2026-10-20); the list, read 2026-11-07, names the deployment *Power BI Authoring (remote)* and links the page's hosted-setup section instead |
| Hosting | remote, Microsoft-hosted; streamable HTTP |
| Endpoint | `https://api.fabric.microsoft.com/v1/mcp/powerbi/authoring` |
| Identity | Microsoft Entra, as the signed-in user, with **Write** permission on the model; Build alone allows DAX queries only |
| Token scope | Entra OAuth, signing in at the first tool call. An app registered for a client without its own takes delegated `SemanticModel.ReadWrite.All` and `Workspace.Read.All` on the Power BI Service API (Learn, read 2026-10-20). `skills-for-fabric` supplies an Azure CLI bearer for the Fabric resource, `--resource https://api.fabric.microsoft.com`, through a `headersHelper` (Claude Code) or `http_headers_helper` (Codex); unprobed here |
| Status | preview (Learn, 2026-10-20); the `skills-for-fabric` page states none |
| Tools | none recorded; read the groups by object type from `tools/list` |

Before it works:

- The same tenant setting as the query server, **Users can use the Power
  BI Model Context Protocol server endpoint**. Workspace permissions and
  tenant policies still apply.
- **A client that registers itself dynamically cannot sign in.** Entra ID
  does not support dynamic client registration; use a pre-registered
  Entra app, as Learn's *Register the hosted Power BI MCP servers with
  external MCP clients* describes, or a bearer from `headersHelper`.
- **It is stateful**: the client must return the `mcp-Session-Id` header
  it got at initialization on every later request. A client that opens a
  session per call makes the agent reconnect to the model before every
  operation.
- It has no transactions and no Analysis Services traces, and reaches
  neither Power BI Desktop nor PBIP files on disk.
- Learn's connect step is a prompt naming the model and workspace:
  `Connect to semantic model '[Semantic Model Name]' in Fabric workspace
  '[Workspace Name]'`.
- **It writes**, to the live model: back it up first.

## Power BI Modeling MCP server: local

| | |
| --- | --- |
| Learn | [Power BI Authoring MCP server](https://learn.microsoft.com/power-bi/developer/mcp/power-bi-authoring-mcp), local deployment; setup and tool reference in [`microsoft/powerbi-modeling-mcp`](https://github.com/microsoft/powerbi-modeling-mcp), (read 2026-10-20); the list, read 2026-11-07, names the deployment *Power BI Authoring (local)* and links the page's local-setup section instead |
| Hosting | local, `stdio`: the VS Code extension, the npm package `@microsoft/powerbi-modeling-mcp` or a standalone executable. Not on macOS |
| Endpoint | none; it connects to a model open in Power BI Desktop, to a Fabric workspace's model over the XMLA endpoint, or to a PBIP `definition/` folder on disk |
| Identity | the user's own credentials, by an interactive Entra sign-in (the default `--authmode`), or a service principal by `--authmode serviceprincipal` with the `AZURE_CLIENT_ID`, `AZURE_TENANT_ID` and secret or certificate variables the README names |
| Token scope | acquired by the Azure Identity SDK; the server stores no token |
| Status | GA (Learn, 2026-10-20), as the *Power BI Authoring MCP Server* since `v1.0.0`; the npm name is unchanged |
| Tools | 21, by object type, as the repository README lists them (read 2026-10-20, at `2b25def`): `connection_operations`, `database_operations`, `transaction_operations`, `model_operations`, `table_operations`, `column_operations`, `measure_operations`, `relationship_operations`, `dax_query_operations`, `trace_operations`, `partition_operations`, `user_hierarchy_operations`, `calculation_group_operations`, `security_role_operations`, `perspective_operations`, `named_expression_operations`, `function_operations`, `culture_operations`, `object_translation_operations`, `calendar_operations` and `query_group_operations`; plus `accept_eula`, which the README names beside the EULA |

Before it works:

- **Write permission on the model.** For a model in a Fabric workspace,
  the **XMLA endpoint set to Read Write** on the capacity. No tenant
  setting blocks this server; turning XMLA off blocks it and every other
  XMLA tool.
- **It refuses every other tool call until its EULA is accepted**
  (`accept_eula`, `--accepteula`, or `PBI_MODELING_MCP_ACCEPT_EULA=true`).
  Put neither of the last two in a committed `.mcp.json`, which would
  accept it for every collaborator; each is only for someone who has
  read the [EULA](https://github.com/microsoft/powerbi-modeling-mcp/blob/main/EULA.txt).
- `--readwrite` is the default, confirming per database; `--readonly`
  blocks writes.
- A GitHub account's **MCP servers in Copilot** option is off by default
  on enterprise accounts, for Copilot clients.
- DAX execution stops at 100,000 rows, and the server changes the model
  only: not report pages or diagram layouts (Learn, read 2026-10-20).
- **It writes**, in place and with no undo: back the model up first, and
  keep a PBIP model under Git so each change is a diff.

## Microsoft Learn

- [Power BI Authoring MCP server](https://learn.microsoft.com/power-bi/developer/mcp/power-bi-authoring-mcp)
- [Power BI Consumption MCP server (preview)](https://learn.microsoft.com/power-bi/developer/mcp/remote-mcp-server-get-started)
- [Register the hosted Power BI MCP servers with external MCP clients](https://learn.microsoft.com/power-bi/developer/mcp/remote-mcp-server-external-clients)
