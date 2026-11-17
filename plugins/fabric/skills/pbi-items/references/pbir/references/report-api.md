# Report: definition and REST

A report's definition shape and what its REST calls take. The item has
exactly the seven generic operations and none of its own. Generic CRUD,
`getDefinition` and `updateDefinition`, long-running operations and
pagination are `rest-api`'s, § Definition APIs and § Long-Running
Operations. The files inside `definition/` are this skill's other
references: [pages.md](pages.md), [visual-json.md](visual-json.md),
[filters.md](filters.md), [bookmarks.md](bookmarks.md) and
[themes.md](themes.md).

| | |
| --- | --- |
| REST `type` | `Report`, under `/workspaces/{ws}/reports/{id}` |
| Git folder | `<display name>.Report/` |
| Learn definition | [Report definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/report-definition) |
| Spec folder | [`report/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/report): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `6f817cb`, 2026-11-03: 7 operations, all generic |

## Definition

Two formats, `PBIR` (the default) and `PBIR-Legacy`, never both in one
report, and a report is returned in the format it is stored in (Learn,
read 2026-10-20). `getDefinition` takes a `format` query parameter;
Learn's Power BI planner skill sends `?format=PBIR` and refuses a
definition that comes back `PBIR-Legacy`. What the parameter does to a
report stored the other way is unmeasured. The parts:

| Path | Required | Holds |
| --- | --- | --- |
| `definition/` | for `PBIR` | the report as a folder of JSON files: `version.json`, `report.json`, `pages/`, and optionally `bookmarks/` and `reportExtensions.json` |
| `report.json` | for `PBIR-Legacy` | the whole report in one JSON file; mutually exclusive with `definition/` |
| `definition.pbir` | yes | the report's core settings and its `datasetReference`, the semantic model it binds to; editing it rebinds the report |
| `StaticResources/` | no | custom themes, images and custom visuals the report loads |
| `semanticModelDiagramLayout.json` | no | the semantic model's diagram layout |

Learn's parts table lists no `.platform`, though a live definition
carries one (below), and `updateDefinition` reads it only with
`?updateMetadata=true` (`rest-api` § Definition APIs).

Learn's definition page has the example files; the Power BI Desktop
project's
[report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report)
page lists every file under `definition/` and the `definition.pbir`
versions. `PBIR` needs `definition.pbir` version `4.0` or higher.

**`datasetReference` is `byPath` or `byConnection`.** `byPath` is a
relative path to a semantic model folder; `byConnection` holds
`connectionString`, which for a REST deploy needs only
`semanticmodelid=<id>` (Learn's project page, read 2026-10-20).

## Git is not the live definition

A report's `datasetReference` is `byConnection` live and `byPath` in Git
(seen once, 2026-10-12), and `.platform`'s `logicalId` is all zeros
live. Git's `byPath` is as Learn's project page says: Git integration
always exports `byPath` where the model shares the report's workspace.
The zeroed `logicalId` appears in the
[ontology definition page](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/ontology-definition)'s
`.platform` sample for an ontology item; for a report it stays observed
(read 2026-11-07), as does the live `byConnection`. Normalize both
before diffing a live report against its folder.
`rest-api` § Definition APIs records both, and
[pbir-cli.md](pbir-cli.md) has the `pbir validate` error a `byPath` that
leads out of the report's parent folder raises.

**The single-item create and update-definition calls accept only
`byConnection`**, as Learn's project page says: a deploy through the
Fabric REST API "must use
`byConnection` references" (read 2026-10-20). Switch a `byPath`
`definition.pbir` before deploying one report. Learn's Bulk Import
example sends `byPath` beside its model in one request; that is a
documentation example, unmeasured here. A repo may hold a second file,
such as `definition-liveConnect.pbir`, beside `definition.pbir`: Fabric
Git integration reads only `definition.pbir` (Learn, read 2026-10-20).

**A create may send no definition at all.** Create Report takes
`definition` or `creationPayload`, never both, and one of the two is
required (spec at `6f817cb`; Learn's
[Create Report](https://learn.microsoft.com/rest/api/fabric/report/items/create-report),
read 2026-11-07, says the same). `creationPayload.semanticModelReference`
is an item reference by ID, `{"referenceType": "ById", "itemId": …,
"workspaceId": …}`, and makes an empty report connected to that model;
the `byConnection` rule above governs only a create that sends a
definition. The caller needs read access to the referenced model, in
another workspace too. The errors are `MutuallyExclusiveProperties`
(both sent), `MissingRequiredProperty` (neither sent) and
`SemanticModelNotFound` (the model does not exist or is not accessible).
Whether the empty report then carries a `definition.pbir`, and which
`datasetReference` form it holds, is unmeasured.

## REST

No operation past the generic seven: Create, Delete, Get, List, Update,
Get Definition and Update Definition, all on Learn's
[Report *Items* group](https://learn.microsoft.com/rest/api/fabric/report/items)
(read 2026-10-20), and the spec's 7 are the same. The table
`spec-ops.py` prints for the folder is empty, so there is none here.

Verifying a published report's rendering is not a Fabric REST call: it is
the Power BI `exportToFile` API, in `pbir.md` Step 12.

## Measured deltas, and where to look next

No measured delta is recorded. Of § Git is not the live definition, one
page covers Git's `byPath`; the live `byConnection` and the report's
zeroed `logicalId`, seen once by `getDefinition` on 2026-10-12, no page
covers, so they stand as observed, not as a delta. No Fabric MCP server
authors reports: Learn's MCP list (read 2026-11-07) has the Fabric IQ
server discover Power BI reports and inspect their metadata, read-only,
and the Power BI Authoring server author semantic models only. Both are
[tmdl.md](../../tmdl/tmdl.md)'s.

When this file runs out, read the spec's `swagger.json` and the
operation's `examples/` file, then Learn. Re-read the spec from the SHA
above: its commits are weekly, "Updating swagger files".
