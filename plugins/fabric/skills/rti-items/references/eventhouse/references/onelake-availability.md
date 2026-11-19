# Schema evolution with OneLake availability ON

Enabling OneLake availability narrows the schema-evolution surface. `eventhouse.md`
carries the headline restriction; the full matrix and the off/on workaround
are here.

## With OneLake availability ON

When OneLake availability is enabled on the database or table, the supported schema-evolution surface narrows:

| Operation | Allowed with availability ON |
|---|---|
| Add column | ✅ (April 2026+) |
| Delete column | ✅ (April 2026+), turning the copy to column mapping (below) |
| Alter column type | ❌ |
| Rename table | ❌ |
| Apply Row-Level Security | ❌ |
| Delete / truncate / purge data | ❌ |

Pre-April 2026 behavior required disabling availability for *any* schema change. For unsupported ops (type change, rename, RLS, data deletes) the workaround is still: turn OneLake availability **off**, perform the change, turn it back on. Toggling off soft-deletes the OneLake mirror; toggling back on backfills.

**A `.drop column` with availability on turns the table's OneLake copy
to Delta column mapping, irreversibly.** On a sandbox table it raised
the copy to reader 3, writer 7, the feature written `COLUMN_MAPPING`
where the Delta protocol names it `columnMapping`, and DuckDB then
refused the table (observed 2026-10-15). Column mapping's protocol
upgrade can't be downgraded
(Learn, *Column mapping for Delta tables*, read 2026-11-18), and
Fabric's Python-notebook readers, `deltalake` and Polars, lack it
(Learn, *Delta Lake table format interoperability*, read 2026-11-18).
Learn's Eventhouse pages don't say a drop sets it, and whether Fabric
Spark reads a copy Kusto mapped is untested. Where a reader without
column mapping reads the copy, through a shortcut too, rebuild the table
rather than drop in place, and **keep the rows first: a row count keeps
none of them.** Copy them without the column,
`.set T_hold <| T | project-away Col`, check `T_hold`'s count against
`T`'s, and stop for the user's yes before `.drop table`, which deletes
the copy. Then `.create table` without the column, its columns in
`T_hold`'s order, since ingest from query matches columns by position,
not name; turn availability back on; run
`.clear table T cache streamingingestion schema` where streaming
ingestion feeds it; `.append T <| T_hold`; check the count again; and
only then drop `T_hold` (not run end to end here). Learn advises
`with (distributed=true)` past 1 GB and each ingest under 1 GB, split
across commands; `async` returns at once, its result in
`.show operations` (Learn, *Ingest from query*, read 2026-11-19).
`iq-items`' `references/ontology.md`, *No delta column mapping*, is the
same hazard from the reader's side.

**Turn availability off with the portal toggle or
`.alter-merge table T policy mirroring with (IsEnabled=false)` — never
`.delete table policy mirroring`.** The two sound interchangeable and
are not: disabling means *"the underlying mirroring data is
soft-deleted and retained in the database"*, whereas *"deleting or
dropping the table mirroring policy will permanently delete the delta
table in OneLake."* Both quotes are Microsoft's, and its
mirroring-policy page nonetheless describes `.delete table policy
mirroring` as the way "to soft-delete the current mirroring policy",
contradicting its own warning further up the same page. Trust the
warning. Where guidance says "toggle X off", name the safe command —
the destructive verb is the better-known one.

A rename attempted while availability is on does not report this
cleanly: it surfaces as a `520` claiming to be temporary. See
`rest-api`'s `references/gotchas.md`.
