# MS Learn link bundle — PBIP project structure

Curated set of Microsoft Learn pages relevant to Power BI Project (PBIP) folder structure — the canonical Microsoft documentation for `.pbip` / `.pbir` / `.pbism` / `.platform` files, the SemanticModel and Report folders, the byPath vs byConnection thick-vs-thin distinction, PBIX → PBIP conversion, Git integration, and the Fabric REST item-definition envelope that mirrors the on-disk structure.

The 3 highest-leverage entry points (PBIP overview, model authoring, Fabric Git integration) are also linked in [pbip.md](../pbip.md)'s `### Reference` section for in-context use; this file holds the comprehensive set.

**Note:** This skill is one of the better-aligned PBIR-family skills with MS Learn coverage — Microsoft documents the PBIP project format directly under `learn.microsoft.com/power-bi/developer/projects/`. The parent skill adds details on PBIX internal extraction (UTF-16LE vs UTF-8 file mix, OPC ZIP layout) and the rename-cascade that the official docs gloss over.

## Power BI Project (PBIP) — the canonical reference

- [Power BI Desktop project (PBIP) overview](https://learn.microsoft.com/power-bi/developer/projects/projects-overview) — start here. Concept, when to use PBIP vs PBIX, model authoring vs report authoring, what's git-friendly vs not.
- [Power BI Desktop project — semantic model folder](https://learn.microsoft.com/power-bi/developer/projects/projects-dataset) — `definition.pbism`, the `definition/` folder (TMDL) vs `model.bim` (TMSL), `diagramLayout.json`, the `unappliedChanges.json` git-tracking choice, version → format mapping (1.0 = TMSL only; 4.0+ = TMSL or TMDL).
- [Power BI Desktop project — report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report) — `definition.pbir`, the `definition/` folder (PBIR JSON) vs `report.json` legacy, `pages/`, `visuals/`, `bookmarks/`, `StaticResources/`. Pairs with [pbir.md](../../pbir/pbir.md) and its references.
- [Save as a project](https://learn.microsoft.com/power-bi/developer/projects/projects-overview#save-as-a-project) — File → Save As workflow, and the folders it writes.
- [Model authoring in Power BI Desktop projects](https://learn.microsoft.com/power-bi/developer/projects/projects-overview#model-authoring) — the two external routes to a model's metadata: Desktop's Analysis Services instance through external tools, or TMDL files in `/definition`. TMDL view is [Work with TMDL view](https://learn.microsoft.com/power-bi/transform-model/desktop-tmdl-view)'s.
- [Edit PBIP files outside Power BI Desktop](https://learn.microsoft.com/power-bi/developer/projects/projects-external-editing) — the detection preview, the **Apply external changes** banner, and the four files it keeps from external editing. Behind the parent skill's "External Edits with Desktop Open".
- [What is the Power BI Desktop Bridge?](https://learn.microsoft.com/power-bi/developer/agentic/power-bi-desktop-bridge-overview) — the named-pipe JSON-RPC API a script reloads Desktop through: `application.state.get/v1`, `file.reload/v1`, the `powerbi-desktop` CLI.

## Entry-point file shapes

- [.pbip file format](https://learn.microsoft.com/power-bi/developer/projects/projects-overview#pbip) — the optional top-level wrapper: a pointer to a report folder, which opens the report and its model. The page names no keys; they are in the [pbip schema document](https://github.com/microsoft/json-schemas/tree/main/fabric/pbip/pbipProperties) (`version`, `artifacts[].report.path`, `settings.enableAutoRecovery`).
- [.pbir definitionProperties schema (developer.microsoft.com)](https://developer.microsoft.com/json-schemas/fabric/item/report/definitionProperties/2.0.0/schema.json) — canonical schema for `definition.pbir`, including `byPath` / `byConnection` shapes the parent skill documents.
- [.pbism definitionProperties schema (developer.microsoft.com)](https://developer.microsoft.com/json-schemas/fabric/item/semanticModel/definitionProperties/1.0.0/schema.json) — canonical schema for `definition.pbism`.
- [.platform schema (developer.microsoft.com)](https://developer.microsoft.com/json-schemas/fabric/gitIntegration/platformProperties/2.0.0/schema.json) — canonical schema for `.platform`.

## Direct Lake / live editing in Desktop (PBIP-specific)

- [Direct Lake in Power BI Desktop](https://learn.microsoft.com/fabric/fundamentals/direct-lake-power-bi-desktop) — PBIP + remote semantic model live-editing model, when local thick model can vs can't be saved.
- [Remote modeling with PBIP](https://learn.microsoft.com/fabric/fundamentals/direct-lake-power-bi-project) — Direct Lake-aware PBIP authoring; what's saved locally vs what stays in the workspace.

## Fabric Git integration (where PBIP lives in source control)

- [Introduction to Fabric Git integration](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration) — concept, supported items, what a workspace Git connection is.
- [Source code format in Git integration](https://learn.microsoft.com/fabric/cicd/git-integration/source-code-format) — item folder naming, the item definition files, and the automatically generated system files: `.platform` (v2), or `item.metadata.json` plus `item.config.json` (v1). The git-ignore guidance is on two other pages: [projects-overview](https://learn.microsoft.com/power-bi/developer/projects/projects-overview)'s default `.gitignore` (`**/.pbi/localSettings.json`, `**/.pbi/cache.abf`) and [projects-dataset](https://learn.microsoft.com/power-bi/developer/projects/projects-dataset), which says `unappliedChanges.json` is saved in Git by default.
- [Connect a workspace to a Git repo](https://learn.microsoft.com/fabric/cicd/git-integration/git-get-started) — wiring up Git → workspace.
- [Sync changes between Git and workspace](https://learn.microsoft.com/fabric/cicd/git-integration/git-integration-process) — pull/commit semantics.

## REST envelope (Fabric Items API)

- [Item definition overview (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/item-definition-overview) — definition-based APIs (`Get/Update/Create with Definition`), the `.platform` rules (only respected on Update with `?updateMetadata=true`).
- [Report definition (REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/report-definition) — exact `definition/` part shape that mirrors the on-disk Report folder.
- [SemanticModel definition (REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/semantic-model-definition) — `definition.pbism`, `definition/` (TMDL) vs `model.bim` (TMSL), `diagramLayout.json`.

## TMDL (the language inside the SemanticModel `definition/` folder)

- [TMDL overview](https://learn.microsoft.com/analysis-services/tmdl/tmdl-overview) — language, indentation, expressions, `///` comments. See [tmdl.md](../../tmdl/tmdl.md) for authoring rules.
- [Get started with TMDL](https://learn.microsoft.com/analysis-services/tmdl/tmdl-how-to) — TmdlSerializer API.

## PBIX format (for the parent skill's "extract a PBIX" section)

- (No first-party MS Learn doc covers the .pbix container or the internal `Version`/`Settings`/`Metadata`/`Connections`/`DataModel`/`SecurityBindings` structure. The parent skill's encoding table is the authoritative reference for that.)

## Forking, ALM, deployment pipelines

- [Deployment pipelines overview](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/intro-to-deployment-pipelines) — Dev / Test / Prod stage management, the workspace deployment flow that downstream of `pbir publish`.
- [ALM Toolkit (third-party)](http://alm-toolkit.com/) — schema-compare for semantic models. Referenced from MS Learn external-tools docs.

## See also (this repo)

- [pbir.md](../../pbir/pbir.md) — end-to-end report build using the project; its references hold the CLI that reads and writes the project, and the JSON shapes inside `Report.Report/definition/`
- [tmdl.md](../../tmdl/tmdl.md) — TMDL authoring rules inside `SemanticModel/definition/`; its `references/definition-api.md` holds the Fabric REST envelope for `getDefinition` / `updateDefinition`
