# Fabric authentication & token audiences

All Fabric operations require Microsoft Entra ID OAuth 2.0 bearer tokens. **Using the wrong audience is the #1 cause of 401 errors.**

| Access Target | Token Audience / Scope |
|---|---|
| **Fabric REST API** | `https://api.fabric.microsoft.com/.default` |
| **Power BI REST API** (refresh, data sources, permissions, DAX) | `https://analysis.windows.net/powerbi/api/.default` |
| **OneLake** (DFS/Blob) | `https://storage.azure.com/.default` |
| **Cosmos DB in Fabric** (NoSQL data plane) | `https://cosmos.azure.com`, as `--resource` or a notebook's `getToken("https://cosmos.azure.com/")`; the `/.default` scope form is untested (2026-10-01) |
| **Warehouse / SQL Endpoint / SQL Database** (TDS) | `https://database.windows.net/.default` |
| **KQL / Kusto** | `https://kusto.kusto.windows.net/.default` |
| **XMLA Endpoint** | `https://analysis.windows.net/powerbi/api/.default` |
| **Azure Resource Management** | `https://management.azure.com/.default` |

```bash
az login
az account get-access-token --resource https://api.fabric.microsoft.com    # Fabric REST
az account get-access-token --resource https://database.windows.net        # SQL / TDS
az account get-access-token --resource https://analysis.windows.net/powerbi/api  # Power BI
```

OneLake accepts only `https://storage.azure.com/.default`; a token for `https://datalake.azure.net/` fails.

## `az login` flow variants

```bash
az login --allow-no-subscriptions --tenant <tid>     # Fabric tenant with no Azure subscription
az login --use-device-code --tenant <tid>            # headless / SSH / no-browser
az login --service-principal -u <appId> -p <secret> --tenant <tid>           # CI/CD with SPN secret
az login --service-principal -u <appId> --certificate /path/cert.pem --tenant <tid>   # SPN cert (preferred — no secret to rotate)
az login --identity                                  # system-assigned managed identity
az login --identity --username <clientId>            # user-assigned managed identity
```

Without `--allow-no-subscriptions`, Fabric-only tenants (no Azure subscription attached) get a confusing "No subscriptions found" error before any Fabric call runs.

## `az rest --resource` requirement

`api.fabric.microsoft.com` is not a built-in Azure cloud endpoint, so `az rest` cannot derive the audience from the URL. Always pass `--resource`:

```bash
az rest --method get \
  --resource "https://api.fabric.microsoft.com" \
  --url "https://api.fabric.microsoft.com/v1/workspaces"
```

Without `--resource`, you get `"Can't derive appropriate Azure AD resource from --url"` — the single most common `az rest` Fabric error.

**No allow rule makes `az rest` read-only.** `Bash(az rest --method get *)` also matches `az rest --method get --url … --method post`, and `az rest` sends the last `--method` it is given (POST, azure-cli 2.90.0, 2026-10-27); a URL pinned inside the rule still takes that appended `--method`, and `--resource` puts the token on whatever host `--url` names. For reads a session should run unprompted, allow a GET-only wrapper script instead: one path argument, the host pinned to `https://api.fabric.microsoft.com/` with its trailing slash, so `…microsoft.com.evil.com` and `…microsoft.com@evil.com` fail, and the token handed to `curl` on stdin (one client repo's wrapper, verified there 2026-10-26). Writes stay on `az rest`, where they prompt.

## Decoding a token to debug 401s

When you get an unexpected 401, decode the JWT to see what audience the token actually has:

```bash
TOKEN=$(az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv)
echo "$TOKEN" | cut -d'.' -f2 | base64 -d 2>/dev/null | jq .
```

Compare the `aud` claim against the table above. Other useful claims: `exp` (Unix expiry), `oid` (principal object ID), `tid` (tenant ID).

**Right audience, still 401 or 403, as a service principal?** Fabric
and Power BI authorize one themselves, by tenant settings scoped to a
security group that holds it (*Service principals can call Fabric public
APIs*, plus any the API adds) and by a workspace role or item
permission. API permissions on its app registration play no part, and
Learn advises adding none: "They're never used and can cause errors
that are hard to troubleshoot"
([Embed with a service principal](https://learn.microsoft.com/power-bi/developer/embedded/embed-service-principal),
read 2026-10-08).

## TDS connection essentials (Warehouse / SQL Database)

When connecting via `sqlcmd`, ODBC drivers, or any TDS client:

| Parameter | Value |
|---|---|
| **Port** | 1433 (TCP, must be open outbound) |
| **`Initial Catalog` / `Database`** | Item display name or ID (NOT the FQDN) |
| **Authentication** | Microsoft Entra ID only — SQL auth is not supported |
| **Encryption** | `Encrypt=Yes` required |
| **Token audience** | `https://database.windows.net/.default` |
| **MARS** | Not supported — remove `MultipleActiveResultSets` from connection strings (or set to `false`) |

**Gotcha**: `Login failed... database not found` usually means the connection string passed the FQDN as `Initial Catalog` instead of the workspace item display name.

**Through a firewall**, a Warehouse or SQL analytics endpoint needs the
Power BI and SQL service tags, since the FQDN alone is not enough, and a
protocol-aware firewall must treat port 1433 as MSSQL/TDS, not HTTPS, or the
connection can fail with the port open
([Warehouse connectivity](https://learn.microsoft.com/fabric/data-warehouse/connectivity),
read 2026-11-01).

## Reference

- Microsoft Learn: [Authenticate to Azure using Azure CLI](https://learn.microsoft.com/cli/azure/authenticate-azure-cli)
- Microsoft Learn: [MSAL overview](https://learn.microsoft.com/entra/msal/overview)
- Microsoft Learn: [Microsoft Entra authentication for Fabric SQL](https://learn.microsoft.com/fabric/data-warehouse/entra-id-authentication)
- Comprehensive MS Learn link bundle (concept / Fabric REST auth / Azure CLI / OAuth flows / MSAL by language / SPN & managed identity / scopes & claims / Fabric-specific): [auth-links.md](auth-links.md)
