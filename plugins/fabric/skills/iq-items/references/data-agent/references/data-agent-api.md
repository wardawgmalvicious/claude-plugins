# Fabric Data Agent: definition and REST

The data agent's definition shape and the REST operations it has beyond
the generic item set. Generic CRUD, `getDefinition` and
`updateDefinition`, long-running operations and pagination are
`rest-api`'s, § Definition APIs and § Long-Running Operations.

| | |
| --- | --- |
| REST `type` | `DataAgent`, under `/workspaces/{ws}/dataAgents/{id}` |
| Git folder | `<display name>.DataAgent/`; the portal's URL still says `/aiskills/` |
| Learn definition | [Data Agent definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/data-agent-definition) |
| Spec folder | [`dataAgent/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/dataAgent): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `6f817cb`, 2026-11-09: 38 operations |

## Definition

Learn names one format, JSON, and its example sends no `format`; the
spec types `format` as a free string. Omit it, as Learn's example does
(unmeasured here). The parts, each holding one configuration layer:

| Path under `Files/Config/` | Required | Holds |
| --- | --- | --- |
| `data_agent.json` | yes | `$schema` only |
| `draft/stage_config.json` | yes | layer 1, `aiInstructions`, and `experimental`, which holds the runtime |
| `draft/<prefix>-<source name>/datasource.json` | no | layers 2 and 3, `dataSourceInstructions` and `userDescription`, and `elements`, the schema selection |
| `draft/<prefix>-<source name>/fewshots.json` | no | layer 4; absent for a semantic model source |
| `publish_info.json` | once published | the publish description |
| `published/…` | once published | the same parts as `draft/`, written by a publish |

Each file's properties are in Learn's tables on the definition page;
[authoring-workflow.md § Where each layer lands](authoring-workflow.md#where-each-layer-lands-in-a-git-synced-repo)
has what each means for a diff or an edit.

**A source has three names, one per surface**, and each is right where
it is used:

| Surface | Lakehouse tables | Warehouse | SQL database | KQL database | Semantic model | Ontology |
| --- | --- | --- | --- | --- | --- | --- |
| Folder prefix | `lakehouse-tables-` | `warehouse-tables-` | `sql-database-` | `kusto-` | `semantic-model-` | `ontology-` |
| `datasource.json` `type` | `lakehouse_tables` | `data_warehouse` | `sql_database` | `kusto` | `semantic_model` | `ontology` |
| REST datasource `type` | `LakehouseTables` | `FabricItem` | `FabricItem` | `FabricItem` | `FabricItem` | `FabricItem` |

- **The folder prefix is the `type` with each `_` written `-`**, in the
  three portal exports read on 2026-10-20: `sql_database`, `kusto` and
  `ontology`, each in a different public repo. The warehouse column
  comes from Learn alone: its source-control page gives the prefix and
  its definition example the `type`, which do not follow that rule.
  Learn's definition example itself names a folder `lakehouse-RoutingLH`,
  a prefix no export carries.
- **Learn's `type` enum lags the exports.** It lists `unknown`,
  `lakehouse_tables`, `lakehouse`, `data_warehouse`, `kusto`,
  `semantic_model`, `graph`, `mirrored_database` and
  `mirrored_azure_databricks`, with no `ontology` or `sql_database`. Its
  element enum likewise lacks the exports' `ontology.entity`,
  `sql_database.schema`, `.table` and `.column` (read 2026-10-20).
- **The REST datasource calls take a third vocabulary.** A create sends
  `"type": "LakehouseTables"` with a `lakehouseReference`, or
  `"type": "FabricItem"` with an `itemReference`; the response's
  `fabricItemType` is the item's REST type, one of `SemanticModel`,
  `Lakehouse`, `KQLDatabase`, `Warehouse`, `SQLDatabase`,
  `MirroredDatabase`, `MirroredAzureDatabricksCatalog`, `GraphModel`,
  `Ontology` and `Report` (spec, `DataAgentSupportedItemType`).

**`$schema` is a URL in files, a version in Learn's tables.** The tables
give `"2.1.0"` and `"1.0.0"`; exports and Learn's own example payloads
carry `https://developer.microsoft.com/json-schemas/fabric/item/dataAgent/definition/<file>/<version>/schema.json`,
`<file>` being `dataAgent`, `dataSource`, `fewShots`,
`stageConfiguration` or `publishInfo`.

**Neither example is a template.** In Learn's definition example, the
`datasource.json` part's payload decodes to `data_agent.json`'s content,
`$schema` alone, missing the required `artifactId`, `workspaceId`,
`displayName` and `type`. The spec's `GetDataAgentDefinition.json`
returns placeholder parts, `DataAgentV1.json` and `.platform`. Start an
`updateDefinition` payload from a `getDefinition` of an agent made in the
portal.

## Git is not the live definition

In each portal export read on 2026-10-20, a source's `workspaceId` is
all zeros and its `artifactId` has a version nibble other than `4`, as a
logicalId usually does (`rest-api` § Item IDs). What a live
`getDefinition` holds there is unmeasured; `rest-api` § Definition
APIs has what it holds for `.platform`. Normalize both before diffing a
live agent against its folder.

## REST beyond the generic set

Under `https://api.fabric.microsoft.com/v1/workspaces/{ws}/dataAgents/{id}/`.
They accept `DataAgent.Read.All` or `DataAgent.ReadWrite.All` besides the
`Item.*` scopes, users and service principals alike, and list calls page
by `continuationToken`. Learn's REST reference lists every operation
here, in its *Items*, *Staging* and *Published* groups (read
2026-11-09). The table is the spec's,
at the SHA above, with *On Learn* and *Measured*
filled in; each operation's `examples/` file holds a request and its
response.

| Method | Path tail | Does | Body | Flags | On Learn | Measured |
| --- | --- | --- | --- | --- | --- | --- |
| `GET` | `staging/settings` | Returns the staging (draft) settings for the specified DataAgent | | preview | yes | 2026-10-15 |
| `PATCH` | `staging/settings` | Updates the staging settings for the specified DataAgent | `aiInstructions` | preview | yes | 2026-10-15 |
| `GET` | `staging/datasources` | Returns a list of staging datasources for the specified DataAgent | | preview | yes | no |
| `POST` | `staging/datasources` | Creates a datasource in the staging environment of the specified DataAgent | `type`, `itemReference`, `lakehouseReference` | LRO, preview | yes | no |
| `GET` | `staging/datasources/{datasourceId}` | Returns metadata for a specific staging datasource of the specified DataAgent | | preview | yes | no |
| `PATCH` | `staging/datasources/{datasourceId}` | Updates metadata for a specific staging datasource of the specified DataAgent | `instructions`, `description` | preview | yes | no |
| `DELETE` | `staging/datasources/{datasourceId}` | Deletes a datasource from the staging environment of the specified DataAgent | | preview | yes | no |
| `GET` | `staging/datasources/{datasourceId}/elements` | Returns schema elements at a level of the schema tree for a staging datasource | | preview | yes | no |
| `PATCH` | `staging/datasources/{datasourceId}/elements?id=` | Updates a specific schema element for a staging datasource | `isSelected`, `description` | preview | yes | no |
| `DELETE` | `staging/datasources/{datasourceId}/elements?id=` | Deletes a schema element that is no longer present in the live schema from a staging datasource | | preview | yes | no |
| `GET` | `staging/datasources/{datasourceId}/fewshots` | Returns a list of staging fewshots for a datasource of the specified DataAgent | | preview | yes | no |
| `POST` | `staging/datasources/{datasourceId}/fewshots` | Creates a new fewshot for a staging datasource of the specified DataAgent | `question`, `query` | preview | yes | no |
| `GET` | `staging/datasources/{datasourceId}/fewshots/{fewShotId}` | Returns a specific staging fewshot by ID | | preview | yes | no |
| `PATCH` | `staging/datasources/{datasourceId}/fewshots/{fewShotId}` | Updates a specific staging fewshot | `question`, `query` | preview | yes | no |
| `DELETE` | `staging/datasources/{datasourceId}/fewshots/{fewShotId}` | Deletes a specific staging fewshot | | preview | yes | no |
| `POST` | `staging/datasources/{datasourceId}/fewshots/deleteAll` | Deletes all fewshots for a staging datasource of the specified DataAgent | | preview | yes | no |
| `GET` | `staging/datasources/{datasourceId}/topics` | Returns a list of staging topics for a datasource of the specified DataAgent | | preview | yes | no |
| `PUT` | `staging/datasources/{datasourceId}/topics?fileName=` | Uploads a staging topic file | | preview | yes | no |
| `DELETE` | `staging/datasources/{datasourceId}/topics?fileName=` | Deletes a staging topic file | | preview | yes | no |
| `POST` | `staging/datasources/{datasourceId}/topics/format?fileName=` | Formats a staging topic file content | | LRO, preview | yes | no |
| `GET` | `settings` | Returns the published settings for the specified DataAgent | | preview | yes | 2026-10-15 |
| `GET` | `datasources` | Returns a list of published datasources for the specified DataAgent | | preview | yes | no |
| `GET` | `datasources/{datasourceId}` | Returns metadata for a specific published datasource of the specified DataAgent | | preview | yes | no |
| `GET` | `datasources/{datasourceId}/elements` | Returns schema elements at a level of the schema tree for a published datasource | | preview | yes | no |
| `GET` | `datasources/{datasourceId}/fewshots` | Returns a list of published fewshots for a datasource of the specified DataAgent | | preview | yes | no |
| `GET` | `datasources/{datasourceId}/fewshots/{fewShotId}` | Returns a specific published fewshot by ID | | preview | yes | no |
| `GET` | `datasources/{datasourceId}/topics` | Returns a list of published topics for a datasource of the specified DataAgent | | preview | yes | no |
| `POST` | `staging/publish` | Publishes the staging configuration of the specified DataAgent | `publishedDescription` | preview | yes | 2026-10-15 |
| `POST` | `staging/reset` | Reverts the staging environment of the specified DataAgent to the published state | | preview | yes | no |
| `GET` | `staging/datasources/{datasourceId}/topics/content?fileName=` | Downloads a staging topic file by file name | | preview | yes | no |
| `GET` | `datasources/{datasourceId}/topics/content?fileName=` | Downloads a published topic file by file name | | preview | yes | no |

**The seven `topics` rows serve a source's topics**, Markdown guidance
the agent searches per question, sending NL2SQL only the matching
sections: SQL sources on the preview runtime alone, up to 1 million
characters a source
([Use topics in a Fabric data agent (preview)](https://learn.microsoft.com/fabric/data-science/data-agent-topics),
read 2026-11-09). The spec added them between `a96c37a` and `6f817cb`.
A `PUT` replaces a file of the same name; `topics/format` returns the
content with YAML front matter (`name`, `description`) and changes
nothing until a `PUT` sends it back (spec, `6f817cb`). Where a topic
lands in the definition is unmeasured.

## Measured deltas, and where to look next

- **The settings carry `experimental`**, which the spec's
  `UpdateDataAgentSettingsRequest` and `DataAgentSettingsResponse` omit,
  each holding `aiInstructions` alone: both GETs return it, and the
  PATCH takes it (2026-10-15). It is how the runtime is read and
  switched:
  [authoring-workflow.md § Settings and publish, by REST](authoring-workflow.md#settings-and-publish-by-rest).
- **`getDefinition` needs the right to remove an encrypted sensitivity
  label** where one protects the agent, a limit the spec added on
  2026-10-20 (`a96c37a`); unmeasured here.

When this file runs out, read the spec's `swagger.json` and the
operation's `examples/` file, then Learn. Re-read the spec from the SHA
above: its commits are weekly, "Updating swagger files".
