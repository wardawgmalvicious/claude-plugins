# Fabric graph queryset: definition and REST

The graph queryset's definition shape, which neither Learn nor the spec
gives as the service returns it. Generic CRUD, `getDefinition` and
`updateDefinition`, long-running operations and pagination are
`rest-api`'s, § Definition APIs and § Long-Running Operations;
the graph model a queryset reads is
[graph-model-api.md](graph-model-api.md)'s.

| | |
| --- | --- |
| REST `type` | `GraphQuerySet`, under `/workspaces/{ws}/graphQuerySets/{id}` |
| Git folder | `<name>.GraphQuerySet/` |
| Learn definition | [Graph QuerySet definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/graph-queryset-definition) |
| Spec folder | [`graphQuerySet/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/graphQuerySet): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `a96c37a`, 2026-10-21: 7 operations, all generic |

## Definition

**A live `getDefinition` of a portal-made queryset returned one part,
`exportedDefinition.json`, and `.platform`, with no `format`**
(2026-10-21). The spec's examples send and return one part,
`graphQuerySet.json`, with `"format": "json"`. Learn's page names no
path: its *Definition part path* column holds the document's three
top-level properties, `graphInstanceObjectId`,
`graphInstanceFolderObjectId` and `queries` (both read 2026-10-21). Take
the path from a `getDefinition`, not from either.

| Path | Holds |
| --- | --- |
| `exportedDefinition.json` | an export envelope, the queryset inside it as a JSON string |
| `.platform` | the item's metadata |

**The queryset is a string inside the envelope.** The envelope's keys
are `dependencies`, `indirectDependencies`, `ArtifactContents` and
`ConfigurationCategories`. `dependencies` held one entry for the model:
`ArtifactType` `GraphIndex`, `ArtifactObjectId` and `FolderObjectId`.
`ArtifactContents` held one entry: `ContentType` `1`, `ContentId`
`null`, and `Value`, the queryset document serialized as a string.
Decode the part, then parse `Value` again.

The document in `Value`, against Learn's tables:

- **It opens with `$schema`**,
  `https://developer.microsoft.com/json-schemas/fabric/item/graphQuerySet/definition/1.1.0/schema.json`,
  which Learn's example lacks.
- **It names its model by `modelReference`**, `{ itemId, workspaceId }`.
  Learn's example has `graphInstanceObjectId` and
  `graphInstanceFolderObjectId`, and neither key was in the read.
- **A query** carried `displayName`, `id`, `queryMode` (`VisualDiagram`
  from the query builder), `nodes` and `edges`. Learn adds
  `gqlQueryText` for `GQLCode`, which the read did not exercise.
- **A node's `alias` is the model's node type alias**, the GUID in its
  `graphType.json`, beside `posX`, `posY`, `format` (`color` only) and
  `filters`.
- **A filter carries `operator`, which Learn's *Filter* table lacks.**
  The query builder wrote `{ propertyName, operator, value }` on the
  node: a property of that node type, `=`, and a string. Learn's table
  has `propertyName`, `sourceNodeAlias` and `value`. Other operators,
  and a filter on an edge, are unmeasured.

**A query builder filter is the queryset's, never the model's.** The
model's six parts were byte-identical before and after one was set
(2026-10-21), so a model's own `filter`, in
[graph-model-api.md](graph-model-api.md) § Definition, is another thing.

## Git is not the live definition

**The queryset document matched its Git copy; the envelope did not**:
one portal-made queryset, read and diffed 2026-10-21.

- **The envelope's model reference is rewritten for Git.**
  `dependencies[0].ArtifactObjectId` is the model's runtime ID live and
  its `logicalId` in Git, the one in the model's own `.platform`.
  `FolderObjectId` is the workspace ID live and all zeros in Git.
  `.platform`'s `logicalId` was all zeros live, as `rest-api` §
  Definition APIs says of every item.
- **`modelReference` in `Value` is not.** It holds the model's runtime
  item and workspace IDs in Git as well as live, so a folder synced to
  another workspace still names the source workspace's model. Whether a
  deployment pipeline rewrites it is unmeasured; deployment pipelines
  support the item (`deploy`'s `deployment-pipelines-tables.md`).

Normalize the envelope's two IDs and `.platform`'s `logicalId` before
diffing.

The spec adds three things in its descriptions (read 2026-10-21):
`getDefinition` leaves the sensitivity label out, `updateDefinition`
leaves it alone, and `updateDefinition?updateMetadata=true` applies a
sent `.platform`. Whether `updateDefinition` takes
`exportedDefinition.json` back, or the spec's `graphQuerySet.json`, is
unmeasured.

## REST beyond the generic set

None. The spec has only the generic seven at the
SHA above, with a `hardDelete` query parameter on `DELETE`; Learn's
*Items* group lists the same (read 2026-10-20).

## Measured deltas, and where to look next

`getDefinition` on a portal-made queryset answered `202`, succeeded on
the first poll, and returned § Definition's parts (2026-10-21). No other
call is measured.

When this file runs out, read the spec's `swagger.json` and the
operation's `examples/` file, then Learn. Re-read the spec from the SHA
above: its commits are weekly, "Updating swagger files".
