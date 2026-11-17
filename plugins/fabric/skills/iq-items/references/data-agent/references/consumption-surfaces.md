# Fabric Data Agent: consumption surfaces in full

Split out of [data-agent.md](../data-agent.md), which carries the
summary table. This file holds the prerequisites, endpoint anatomy, and
compliance caveats per surface.

Beyond in-product chat (GA), a published data agent can be consumed from several surfaces. The MCP endpoint and Copilot Studio's tool path are GA; Microsoft Copilot's page carries no label; the rest are **preview**; one retired on 2026-08-26:

- **Microsoft Copilot (Agent Store) — no label.** Learn retitled the page *Consume Fabric data agent in Microsoft Copilot* and dropped its preview label, stating no status in its place (read 2026-11-09): treat it as unconfirmed, not GA. At publish time, choose **Publish to Agent Store** to make the agent available in Microsoft Copilot. Users chat with it directly or `@`-mention it from the main Copilot chat in Teams, share it via link (1:1, group, or channel), and use the **code interpreter** to visualize results. Requires a paid **F2+** (or P1+ with Fabric enabled) capacity, a **Microsoft Copilot license** or Office 365 commercial subscription plus per-user licenses, the **cross-geo processing and cross-geo storing for AI** tenant settings enabled, a source the user can read holding data (warehouse, lakehouse, semantic model, KQL database, mirrored database or ontology), and the agent + Copilot on the **same tenant / same account**. An agent that never appears in the Agent Store points at Copilot extensibility, which a Microsoft 365 admin enables per account. The publish **description** becomes the `description_for_model` that steers the M365 orchestrator — you can instruct it to return the agent's output as-is, but the orchestrator still reasons over the grounding data, so some rephrasing is inevitable. RLS/CLS and underlying-source access are fully enforced per the calling user. **Compliance note:** responses may leave Fabric's compliance boundary / geographic region and be processed or stored under M365's data-handling policies. Separately, answering from **Power BI content** in Microsoft 365 Copilot Chat (Fabric IQ) is **GA**; it does not cover data agents, which answer there only through an explicitly published Microsoft 365 agent, this path (Learn, 2026-10-06).
- **MCP server endpoint — GA.** The programmatic query surface, one tool per published agent; its endpoint, token, conditions, tasks and what an answer carries: [data-agent-mcp.md](data-agent-mcp.md).
- **Python SDK's Responses client — preview.** `FabricOpenAIResponses`,
  in `fabric-data-agent-sdk`, asks the agent through the OpenAI
  Responses API and returns every step it took, so it is the scripted
  route to an answer's DAX. Learn's own route is the agent's step panel,
  where its semantic model best practices have the author review the DAX
  of each response (step 7, read 2026-10-16); this one a script can
  grade, and `data-agent-eval.py`'s default route does, keeping the
  rewritten question and the DAX beside each reply
  ([evaluation.md](evaluation.md)).

  ```python
  from azure.identity import AzureCliCredential
  from fabric.dataagent.client import FabricOpenAIResponses

  client = FabricOpenAIResponses(agent_id, workspace_id, ai_skill_stage="production", credential=AzureCliCredential())
  response = client.responses.create(input=question)
  ```

  `ai_skill_stage="production"` asks the published agent and `sandbox`
  the draft, and **`sandbox` is the default** (0.1.33a0 source, read
  2026-10-16), so a call that omits it tests the draft. An explicit
  `credential` needs the workspace passed too. With the Azure CLI
  credential it runs outside a notebook, and `AZURE_CONFIG_DIR` picks
  the tenant. `response.output` holds the steps, as seen on 0.1.33a0 in
  one client estate on 2026-10-15:

  - a `function_call` named `trace.analyze_semantic_model`, whose
    `arguments.query` is the question as the agent rewrote it for the
    DAX step;
  - on the preview runtime, `askPBI.tool.execute`, whose
    `arguments.code` is the DAX, inside a code fence tagged `dax`;
  - on the standard runtime, `analyze.database.nl2code`, which writes
    DAX variations, then `analyze.database.execute`, whose
    `arguments.code` is the DAX run;
  - `function_call_output` items, the result the model saw: the preview
    tool's begins "The dataset contains N rows", and the standard
    tool's can begin "Note: This result is incomplete. The query matched
    at least 1001 rows, but only the first 200 are included here.";
  - a final `message`, the reply.

  **Each call runs the agent anew.** Asked the same question minutes
  apart, this client and the MCP endpoint named different months as the
  lowest (four runs, two per runtime, 2026-10-15): grade a run, not a
  question.
- **Copilot Studio tool — GA.** In a Copilot Studio agent built on the GitHub Copilot harness, add the **Fabric IQ Data MCP** tool, pick a published data agent from the OneLake catalog, write the description the orchestrator routes on, and set the auth mode: **User** or **Maker** (see [authentication.md](authentication.md)). Repeat per data agent.
- **Copilot Studio connected agent / Azure AI Foundry (Agent Service) — preview.** The earlier path, adding the data agent from the **Agents** category as a connected agent. Identity passthrough (On-Behalf-Of); see [authentication.md](authentication.md). Foundry now connects through MCP.
- ~~**Copilot in Power BI**~~ — **retired 2026-08-26.** Was: add the agent via **Add items for better results → Data agents**, or let Copilot search rank it alongside semantic models and reports. If you have an existing wiring here, it is gone; move it to one of the surfaces above. (The retirement was announced through the Fabric What's New / Fabric Updates blog; the Learn page that described the path is gone, its URL failing on 2026-11-09.)

## Learn pages

- [Consume Fabric data agent in Microsoft Copilot](https://learn.microsoft.com/fabric/data-science/data-agent-microsoft-365-copilot)
- [Data agent as Model Context Protocol server](https://learn.microsoft.com/fabric/data-science/data-agent-mcp-server)
- [Add a Fabric data agent as a tool in Microsoft Copilot Studio](https://learn.microsoft.com/fabric/data-science/data-agent-microsoft-copilot-studio-tool)
