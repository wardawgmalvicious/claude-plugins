# Operations agent: the remote MCP server (preview)

Fabric hosts two HTTP MCP endpoints for **one** operations agent:
**configure**, which reads and writes its instructions, knowledge
sources, actions and playbook and starts or stops it, and **query**,
which reads its state and its operations. § Endpoint says how Claude
Code reaches them.

| | |
| --- | --- |
| Learn | [Get started with the remote MCP server for operations agents (preview)](https://learn.microsoft.com/fabric/real-time-intelligence/mcp-remote-operations-agent); listed as *Operations agent MCP server* in [Choose a Microsoft Fabric MCP server](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/fabric-mcp-servers-list), whose row still links [What is MCP in Real-Time Intelligence (preview)?](https://learn.microsoft.com/fabric/real-time-intelligence/mcp-overview), which links the setup page (all read 2026-11-09) |
| Hosting | remote, Microsoft-hosted; HTTP, two endpoints per agent |
| Status | preview (the setup page's title, 2026-11-09) |
| Identity | OAuth against Entra: the client acquires an Entra ID token and passes it. The user needs Contributor or Admin on the agent's workspace, and the write tools act with that user's permissions. Learn names VS Code with GitHub Copilot and the GitHub Copilot CLI as clients |
| Token audience | not stated on Learn's page (read 2026-11-09). The `headersHelper` entry (§ Endpoint) asks `az` for `https://api.fabric.microsoft.com`, as Activator's does; no connection to either endpoint is recorded |
| Tools | sixteen on configure, five on query, in § What it can and cannot do (Learn, 2026-11-09) |

## Endpoint

```http
https://api.fabric.microsoft.com/v1/mcp/workspaces/<Workspace ID>/operationsAgents/<Item ID>/configure
https://api.fabric.microsoft.com/v1/mcp/workspaces/<Workspace ID>/operationsAgents/<Item ID>/query
```

Both IDs are in the item's portal URL, `.../groups/<Workspace ID>/operationsagents/<Item ID>`,
which spells the segment in lower case where the MCP path has
`operationsAgents`. A URL pair names one agent, so a second agent needs
two more server entries, and the entries are per repo, never user scope.
Learn supports manual client configuration only, and names the two
entries `operations-agent-configure` and `operations-agent-query` (read
2026-11-09). For Claude Code each entry sends an `az` bearer through
`headersHelper`, the entry in `rest-api`'s `references/fabric-mcp.md`
§ Connecting from Claude Code with these URLs; Learn's own example is a
bare `servers` pair in VS Code's `mcp.json` with no helper.

## Before it works

- An operations agent in a workspace where the user holds Contributor
  or Admin, and a data source connection (Learn's prerequisites, read
  2026-11-09).
- **A knowledge source before a playbook**: `generate_playbook` returns
  an error until one is connected, in the agent editor's *Knowledge
  Source* or by `add_or_update_eventhouse_knowledge_source` (a KQL
  database or eventhouse) or
  `add_or_update_fabric_ontology_knowledge_source`. Learn supports no
  other source type.
- Learn recommends connecting the eventhouse MCP server beside it when
  the source is an eventhouse, so the agent can read the schema and
  sample data and validate KQL; that server is `rti-items`', in its
  Eventhouse reference's `remote-mcp.md`.
- Learn lists no tenant setting for this server (read 2026-11-09);
  whether one gates it is unmeasured. The agent has its own, in
  [operations-agent-reference.md](operations-agent-reference.md) §
  Runtime, identity and availability: the operations agent, Microsoft
  Copilot and Azure OpenAI tenant settings, a non-trial capacity, and
  availability limits.

## What it can and cannot do

The tools as Learn lists them (read 2026-11-09):

- **configure, read**: `get_agent_instructions`,
  `get_agent_knowledge_sources`, `get_agent_actions`,
  `get_playbook_summary`, `get_playbook_rules`, `get_rule_details`,
  `get_generate_playbook_status`.
- **configure, write**: `set_agent_instructions`,
  `add_or_update_eventhouse_knowledge_source`,
  `add_or_update_fabric_ontology_knowledge_source`,
  `remove_knowledge_source`, `add_or_update_agent_action`,
  `remove_agent_action`, `generate_playbook`, `start_agent`,
  `stop_agent`.
- **query**: `get_agent_summary`, `get_agent_state` (`Active`,
  `Inactive` or `Unconfigured`), `get_monitored_rules`,
  `get_operation_details`, `query_operations`. Learn's table gives these
  no read or write type; each description is a get or a search.

**`start_agent` starts a meter.** A running agent bills continuously,
whatever it finds ([operations-agent.md](operations-agent.md) § 5), so
read `get_agent_state` first, as Learn advises, and treat a start as a
spend. Learn's warning covers every write: the tools act with the
signed-in user's permissions, so apply least-privilege roles and review
each call before approving it.

**Configure, then generate.** `generate_playbook` answers with a
playbook ID at `InProgress`, and `get_generate_playbook_status` reads
`Completed` typically one to three minutes later; changing the instructions,
actions or sources after that needs a new playbook (Learn, 2026-11-09).

**The writes change the live item.** Whether `start_agent` sets the
definition's `shouldRun`, and whether these writes surface in a
Git-synced workspace as a `Configurations.json` change to commit, is
unmeasured; [operations-agent.md](operations-agent.md) § 3 has that
file's schema.

Learn's other limits: one URL pair per agent, and manual configuration
only, with no automatic discovery.

## Discover the tools, never hard-code them

The names above are as last seen on Learn on 2026-11-09; no
`tools/list` against either live endpoint is recorded here. The client
must speak MCP (`initialize`, then `tools/list`, then `tools/call`):
take the names and each tool's arguments from `tools/list` and its
input schemas, which Learn's tables do not give.
