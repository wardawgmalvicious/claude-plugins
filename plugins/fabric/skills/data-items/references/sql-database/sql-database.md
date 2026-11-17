# Fabric SQL Database

Fabric SQL Database is an Azure SQL Database hosted within a Fabric workspace. It is a **completely different engine** from Fabric Warehouse and does NOT share the Warehouse's restrictions.

An item's definition and REST calls have a file of their own. Read it
first for its job; past it, the REST spec's folder, then Learn, by `microsoft-learn-mcp`, or with no server, `curl -sL -H 'Accept: text/markdown' <page URL>` (undocumented, read 2026-11-07):

| The job | Read first |
| --- | --- |
| The definition formats (`dacpac`, `sqlproj`) and parts, the create payload and restore modes, or the mirroring, audit and restorable-deleted calls | [references/sql-database-api.md](references/sql-database-api.md) |

A live page that contradicts a line here wins: say so, act on the page,
and route the fix by `capture-learning`, bar a dated measured line that
names the page it overrules and the call that measured it, which a page
changed since its date sends back to re-measure. An observed claim is cited
or marked pending a doc check, and stands, marked observed, only where no
page covers it.

No Fabric-hosted MCP server is named for this item on Learn's
[Fabric MCP servers list](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/fabric-mcp-servers-list),
so there is no `-mcp.md`. Its *Related integrations and samples* name a
customer-hosted one, **SQL MCP Server**, for SQL databases including
this one: a Data API builder feature (1.7 and later) that you host, whose
tools are DML over the entities a `dab-config.json` exposes, with no DDL
and no raw T-SQL
([SQL MCP Server](https://learn.microsoft.com/azure/data-api-builder/mcp/overview);
both read 2026-11-07).

## Key Differences from Fabric Warehouse

| Feature | Fabric Warehouse | Fabric SQL Database |
|---|---|---|
| Engine | Distributed Synapse DW | Azure SQL Database |
| `nvarchar`, `datetime`, `money` | Not supported | Fully supported |
| Triggers | Not supported | Fully supported |
| MERGE | Supported (GA) | Fully supported |
| ALTER COLUMN | Metadata-only widening, in preview | Fully supported |
| Recursive CTEs | Not supported | Fully supported |
| `FOR XML` | Not supported | Fully supported |
| Transaction isolation levels | Snapshot only | All levels |
| `CREATE USER` | Not supported | Fully supported |
| Temporal tables | Not supported | Fully supported |
| Full-text search | Not supported | Fully supported |
| Vector type, index and search | Not supported | GA; an index needs at least 100 rows with non-`NULL` vectors |

## Fabric-Specific Context

- **Authentication**: Entra ID only — SQL auth is not supported in Fabric
- **Token audience**: `https://database.windows.net/.default` (same as Warehouse)
- **OneLake replication**: Tables automatically replicate to OneLake as Delta/Parquet
- **SQL projects**: Uses standard `.sqlproj` format for schema-as-code
- **Do NOT apply Warehouse T-SQL restrictions** to Fabric SQL Database code
- **Plan system database**: `__fabric_plan_sys.SQLDatabase` is created with
  a Plan item (Fabric IQ) to store plan metadata
  ([planning prerequisites](https://learn.microsoft.com/fabric/iq/plan/overview-prerequisites)),
  and its `.platform` description opens `DoNotEdit` (observed 2026-09-30).
  Its `.sql` files look like any SQL database's: stand down, and don't edit,
  rename or delete them, in Git or the portal. Don't query the database
  either: Learn reserves it "strictly for system operations and app
  storage" and says to query writeback data in its configured destination
  ([persist data](https://learn.microsoft.com/fabric/iq/plan/planning-writeback/planning-how-to-persist-data),
  2026-10-01). Its SQL project in Git shows its shape

## Reference

- Microsoft Learn: [SQL database in Fabric (overview)](https://learn.microsoft.com/fabric/database/sql/overview)
- Microsoft Learn: [Limitations in SQL database in Fabric](https://learn.microsoft.com/fabric/database/sql/limitations) (holds the Azure SQL Database vs Fabric SQL database feature comparison)
- Comprehensive MS Learn link bundle (concept / create+connect / limitations / OneLake mirroring / security / backup / source control & SqlPackage / GraphQL / billing): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- [warehouse.md](../warehouse/warehouse.md) — the distributed DW engine with its own restrictions
- rest-api skill — `database.windows.net` token audience, in its `references/auth.md`
