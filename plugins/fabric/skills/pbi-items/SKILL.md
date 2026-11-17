---
name: pbi-items
description: "Use for Power BI items, in the service or on disk: a PBIP project (`.pbip`, `definition.pbir`, `.pbism`, `.platform`, byPath or byConnection, PBIX conversion, forking, renames, git hygiene); a report in PBIR, a `.Report` folder, built or edited by the `pbir` CLI or by hand (`visual.json`, `page.json`, `report.json`, `reportExtensions.json`, themes, bookmarks, filters, conditional formatting), with its design and rendered pages; and a semantic model, a `.SemanticModel` folder, in TMDL: measures, relationships, calculation groups, roles, Direct Lake, AI instructions, its Definition API (getDefinition, updateDefinition), its MCP servers, and auditing or health-checking a finished model. Picks the item, then reads its reference. For reviewing a diff use review-code."
when_to_use: "Use when asked to build, lay out, redesign or critique a Power BI report or dashboard; to run any `pbir` command; before a hand edit of a report's JSON or a `.tmdl` file; to add measures, columns, relationships, calculation groups or RLS roles, or set up Direct Lake; to audit a model (star schema, relationships, cardinality, why slow or bloated, Best Practice Analyzer); or on .pbip, .pbism, logicalId, PBIX to PBIP, forking a report or a Power BI repo in git."
# model: inherit  # any model: value blocks Copilot slash invocation
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Power BI items

A Power BI project holds a report and its semantic model, each a folder
of text files, and a workspace holds the same two items in the service.
Each has a reference here, and the project's layout a third. Each
reference holds the depth, and this file picks the item and carries only
what crosses items. Take the steps in order: the wrong item sends every
later step to the wrong file.

## 1. Pick the item

By the job asked for, or by the file in hand:

| The job | Files | Read |
| --- | --- | --- |
| A project's layout and entry points: PBIX to PBIP, forking, renaming across it, byPath or byConnection, git hygiene | `*.pbip`, `definition.pbir`, `definition.pbism`, an item's `.platform` | [pbip.md](references/pbip/pbip.md) |
| A report: build, lay out, filter, theme, bookmark, format, validate, publish and check its pages, by the `pbir` CLI or by hand; its design | `<name>.Report/` | [pbir.md](references/pbir/pbir.md) |
| A semantic model: its TMDL, its AI instructions, its definition by the Fabric API, its MCP servers, or an audit of a finished one | `<name>.SemanticModel/`, `*.tmdl` | [tmdl.md](references/tmdl/tmdl.md) |

Near these items, and not them:

- The REST conventions every definition call shares, such as auth,
  long-running operations and the error catalogue: `rest-api`.
- Deployment pipelines, fabric-cicd and a workspace's Git integration:
  `deploy`.
- A data agent or an ontology built on the model: `iq-items`.

## 2. What crosses items

- **A report binds to its model one of two ways**: `byPath` to the model
  folder beside it, a thick project, or `byConnection` to a published
  model, a thin report ([pbip.md](references/pbip/pbip.md) § definition.pbir).
  The Fabric definition's side of it is
  [report-api.md](references/pbir/references/report-api.md)'s.
- **A rename crosses both items**: a table, column or measure name sits
  in TMDL, in the report's visual, page, bookmark and
  `reportExtensions.json` files, and in both `DAXQueries/` folders
  ([pbip.md](references/pbip/pbip.md) § Rename Cascade lists every
  place).
- **Each item's definition has its own API file**:
  [report-api.md](references/pbir/references/report-api.md) for a
  report,
  [definition-api.md](references/tmdl/references/definition-api.md) for
  a model. Both leave the generic REST conventions to `rest-api`.

## 3. Read the item's reference first

Read the file step 1 names before answering or editing: formats, limits
and preview status live there, dated, and each names the files past it,
then the live docs, Learn by `microsoft-learn-mcp`, or with no server,
`curl -sL -H 'Accept: text/markdown' <page URL>` (undocumented, read
2026-11-07). A task that spans items, a renamed measure for one, reads
each item's file.

A live page that contradicts a line here wins: say so, act on the page,
and route the fix by `capture-learning`, bar a dated measured line that
names the page it overrules and the call that measured it, which a page
changed since its date sends back to re-measure. An observed claim is
cited or marked pending a doc check, and stands, marked observed, only
where no page covers it.

## 4. The model audit's driver

The audit's notebook tier runs through a bundled driver, which creates a
temporary notebook in a workspace on a capacity, runs it, reads its
result back as JSON and deletes it
([audit.md](references/tmdl/references/audit.md) §2):

```bash
uv run ${CLAUDE_SKILL_DIR}/scripts/run-model-audit.py run <workspace> <model> --out <file>
```

It signs in as the Azure CLI's account, so set `AZURE_CONFIG_DIR` to the
model's tenant first. It writes one item to that workspace, so take the
workspace from the user, and write `--out` outside any tracked path.
`--read-data` adds the audit's checks 21–23, which read every table and
bill the capacity: pass it only when asked. The sections, their gates
and what a failure looks like are in
[audit-notebook-tier.md](references/tmdl/references/audit-notebook-tier.md).
