# Programmatic access and item definitions

Driving Eventhouse from `az rest` / Fabric REST: the query endpoint call.
`eventhouse.md` carries the cluster URI shape and token audience you need for
any of it.

## Connection

- **Cluster URI**: each KQL Database has a unique `queryServiceUri` of the form `https://<cluster>.kusto.fabric.microsoft.com`. Discover via Fabric REST: `GET /v1/workspaces/{wsId}/kqlDatabases` (returns `queryServiceUri` per item but no database name: pass the item `id` as `db`, `eventhouse.md` § *Connection*).
- **Token audience**: `https://kusto.kusto.windows.net/.default` for all direct access.
- **Query endpoint**: `POST {clusterUri}/v1/rest/query` with body `{"db":"<dbName>", "csl":"<KQL>"}`.
- **KQL `|` breaks shell escaping** — write the JSON body to a temp file and use `--body @<file>` (bash) or `@$env:TEMP\kql_body.json` (PowerShell).

```bash
cat > /tmp/kql_body.json << 'EOF'
{"db":"MyDB","csl":"MyTable | take 10"}
EOF
az rest --method POST \
  --url "${CLUSTER_URI}/v1/rest/query" \
  --resource "https://kusto.kusto.windows.net" \
  --body @/tmp/kql_body.json \
  | jq '.Tables[0].Rows'
```

## Item definition envelope (REST)

A KQL database's definition parts, its `creationPayload`, what
`DatabaseSchema.kql` may hold under Git, and its table shortcut calls:
[kql-database-api.md](kql-database-api.md). An eventhouse's single part
is a row in `eventhouse.md`'s *Read first* table.
