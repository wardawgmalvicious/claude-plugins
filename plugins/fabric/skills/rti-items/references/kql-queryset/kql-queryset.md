# Fabric KQL queryset (KQLQueryset)

A KQL queryset is saved KQL: tabs of query text, each bound to one data
source, a KQL database, an Azure Data Explorer database or Azure Monitor
(Learn, *Query data in a KQL queryset*, read 2026-11-13). It runs
nothing on its own; an Activator rule set from one of its tabs copies the
query when the rule is made
([activator.md](../activator/activator.md) § 11. Git and lifecycle
management). The KQL a tab holds is
[eventhouse.md](../eventhouse/eventhouse.md)'s to write.

Past this file, the REST spec's
[`kqlQueryset/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/kqlQueryset)
folder, then Learn, by `microsoft-learn-mcp`, or with no server,
`curl -sL -H 'Accept: text/markdown' <page URL>` (undocumented, read
2026-11-07):

| The job | Read first |
| --- | --- |
| The definition's parts and fields | [KQL Queryset definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/kql-queryset-definition) |
| The synced folder | [KQL queryset integration](https://learn.microsoft.com/fabric/real-time-intelligence/git-kql-queryset) |
| REST calls | [KQLQueryset Items](https://learn.microsoft.com/rest/api/fabric/kqlqueryset/items) |

A live page that contradicts a line here wins: say so, act on the page,
and route the fix by `capture-learning`, bar a dated measured line that
names the page it overrules and the call that measured it, which a page
changed since its date sends back to re-measure. An observed claim is cited
or marked pending a doc check, and stands, marked observed, only where no
page covers it.

## Folder and definition

`<name>.KQLQueryset/` holds `.platform` and `RealTimeQueryset.json`, the
one required part (definition page, read 2026-11-13). The Git page's
heading calls the file `KQLQueryset.json` while its own tree shows
`RealTimeQueryset.json`, the name a synced folder carries (observed
2026-11-13, a client repo).

`RealTimeQueryset.json` is one `queryset` object:

- `version`: `"1.0.0"`.
- `dataSources[]`: each an `id` (a GUID the tabs point at), a
  `clusterUri` and a `type`.
- `tabs[]`: each `{id, title, content, dataSourceId}`, `content` the KQL
  text and `dataSourceId` one data source's `id`.

**A Fabric KQL database is `type: "Fabric"`, which the definition page
omits.** It lists only `AzureDataExplorer`, with `databaseName`; the Git
page adds `Fabric`, with `databaseItemId` and `databaseItemName` and an
empty `clusterUri` (Git page, read 2026-11-13). A synced folder's
`Fabric` source carried `databaseItemId`, an empty `clusterUri` and no
`databaseItemName` (observed 2026-11-13, a client repo). So copy a data
source from a synced or fetched definition rather than build one from
the definition page.

**In Git, `databaseItemId` is the KQL database's `logicalId`**: it
matched that database's `.platform` `logicalId` in the same repo
(observed 2026-11-13, a client repo). Live, a deployed queryset's
`getDefinition` held its database's item id and the eventhouse's query
URI in `clusterUri` (`deploy`'s `references/deployment-pipelines.md`,
one client estate, observed 2026-10-13), the split an eventhouse's
`parentEventhouseItemId` shows
([kql-database-api.md](../eventhouse/references/kql-database-api.md)
§ Git is not the live definition): normalize both before diffing live
against Git.

A KQL database's own synced folder holds an
`EmbeddedRealTimeQueryset.json` beside its schema, which is the
database's, not a queryset item (same section).

## REST

Under `https://api.fabric.microsoft.com/v1/workspaces/{ws}/kqlQuerysets`:
the generic seven, create, get, list, update, delete, get definition and
update definition, and nothing past them (Learn, KQLQueryset Items, read
2026-11-13). Update definition "overrides the definition" (same page),
so send every tab and data source, not only the changed one. The shared
conventions, long-running operations and `updateMetadata=true` for
`.platform`, are `rest-api`'s.

## Lifecycle

Git integration and deployment pipelines both support the item (Learn,
*Git integration and deployment pipelines*, read 2026-11-13). How a
deployment pipeline or fabric-cicd rebinds `databaseItemId` to the
target's database, which Learn's dependency-binding table says it does
not, is `deploy`'s: `references/deployment-pipelines.md` and
`references/fabric-cicd.md`. Workspace outbound access protection, in
preview, blocks only Copilot for writing KQL in a queryset (Learn,
*Workspace outbound access protection for KQL queryset*, read
2026-11-13).
