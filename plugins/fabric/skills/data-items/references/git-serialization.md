# Fabric Git serialization

How the portal writes an item's definition files to Git, and what a
portal commit keeps. Read it before editing a file in a
`<name>.<ItemType>/` folder of a Git-connected workspace, and before
merging a branch that carries portal commits. Git integration's REST
calls are `rest-api`'s, § Git Integration APIs; a KQL database's
`DatabaseSchema.kql` sync is `rti-items`',
`references/eventhouse/references/kql-database-api.md`.

Past this file, Learn's Git integration pages, by `microsoft-learn-mcp`,
or with no server, `curl -sL -H 'Accept: text/markdown' <page URL>`
(undocumented, read 2026-11-07). A live page that contradicts a line
here wins: say so, act on the page, and route the fix by
`capture-learning`, bar a dated measured line that names the page it
overrules and the call that measured it, which a page changed since its
date sends back to re-measure. An observed claim is cited or marked
pending a doc check, and stands, marked observed, only where no page
covers it.

## 1. End of file and portal formatting

The portal re-serializes an item's parts on every commit from the
workspace, so a local change it does not keep comes back as a
whitespace-only diff on the next round-trip.

- **JSON and SQL parts end at the last character**, with no final
  newline: `pipeline-content.json`, `variables.json`, eventstream and
  report JSON, Warehouse `.sql` scripts. **TMDL, `notebook-content.*`
  and `.kql` parts end with one**: every `notebook-content.py` and
  `notebook-content.sql` in 10 portal commits ended in exactly one
  (observed 2026-07-31 to 2026-09-15); `.ipynb` is unmeasured.
- **A User Data Functions `function_app.py` has no canonical end**: it
  is stored as the editor's text ended, no final newline after one
  publish and `\n\n\n` after the next (observed 2026-09-30, three
  portal commits).
- **Preserve each file's end exactly**: never add a final newline to a
  file that lacks one, never remove one that is there. A new JSON or SQL
  part ends at its last character; a new TMDL, notebook or KQL part ends
  with one newline.
- **Leave a Warehouse script's portal formatting alone.** The trailing
  space after each comma in table DDL and the
  `-- Auto Generated (Do not modify) <hash>` header on a view come back
  on every sync. The header is no content hash: the portal reapplied the
  same value after a view's schema name, comments and column list had
  all changed (observed 2026-09). Carry it forward verbatim across edits
  and moves. A new view cannot know its value: omit the header and
  accept one round-trip.

## 2. A portal commit serializes live state

A portal commit is no authored change but a serialization of that
workspace's live state, so a file the live item lacks is drift the
commit removes. Three ways it bit, each silent (observed 2026-09):

- **A hand-authored file in an item folder is deleted**: 13 `.sql`
  scripts, about 3,300 lines, left a trunk in one commit, since the live
  warehouse held no matching shared queries. Keep such scripts outside
  every folder Fabric syncs.
- **Deleting an item deletes its definition**: 35 files, about 2,000
  lines, in one commit. Recreating it commits back only `.platform`,
  `.gitignore` and `.sqlproj`, and the live item comes back empty too,
  so neither side warns.
- **A branch-out or sandbox workspace commits its own state onto the
  branch**: `shortcuts.metadata.json` went from 19 shortcuts to 1 and
  `DatabaseSchema.kql` from 19 tables to 1, since that sandbox held one
  table.

Three Git features guard these. **Selective branching**, *Select items
individually* at branch-out, builds a partial workspace on purpose,
though branching out into an existing workspace can still delete items
not saved to Git (Learn, *Development process using branch workspace*,
read 2026-11-17). The **compare dialog** marks every file new, modified
or deleted before a commit: read the deletions there. **File-level
commit**, in preview and only for supported items in the Modified
state, leaves unselected files uncommitted, and Fabric warns that a
partial commit can leave the definition incomplete (Learn, *Compare and
commit changes in Fabric*, read 2026-11-17).

**Recover a deleted definition** with
`git checkout <commit-before-the-delete> -- <item path>`, but **keep the
new `.platform`**: a recreated item has a different `logicalId`, and
restoring the old one points the folder at an item that no longer
exists. Sequence a deliberate delete-and-recreate as: note the commit,
delete, recreate, sync, restore the definition files, then rewire the
item's GUID wherever it is referenced.

**Before merging a branch carrying portal commits**, diff the
environment-bound files, such as shortcut manifests, database schema
and item bindings, against the target environment's live state, not
only the target branch. Repo CI is unlikely to catch it: a shortcut
naming a table the target lacks fails the whole Lakehouse Git update,
`InvalidShortcutPayloadBatchErrors`, "Target path doesn't exist", while
a live table with no shortcut is at most a warning.

## 3. An update from Git rewrites too

Git to workspace is no uniform no-op:

- **A KQL database's `DatabaseSchema.kql` is executed on sync**, its
  commands additive only, so a drop or a rename cannot travel by Git:
  `rti-items`, `references/eventhouse/references/kql-database-api.md`.
- **A notebook sync rewrites markdown.** In `notebook-content.py` each
  line of a `# MARKDOWN ****` cell is stored as `#`, a space, then its
  markdown, so a bare `#` is a blank line, `# ## text` an H2 and
  `# # text` an H1. **Every Git-to-workspace sync merges a bare `#`
  into the line after it**, turning a paragraph break into an H1 that
  outranks the cell's own `##` title, and a revert in Git loses: the
  portal reapplied it seven minutes after the revert merged (observed
  2026-09). Keep each markdown cell to one paragraph with a bold
  lead-in, or split it in two. Portal commits also add a second blank
  line after a markdown cell's last line and stop at two; that renders
  as nothing, so leave it. A bare `#` under `# CELL` is a Python comment
  the portal never touches, and `grep` cannot tell the two apart:
  classify each by the cell marker above it.

## 4. Line endings: a Fabric repo needs a `.gitattributes`

Fabric writes some lines CRLF and some LF **inside one file**. In
Warehouse table DDL the `GO` and `ALTER TABLE` constraint block is CRLF;
in a view, the auto-generated header, the last body line and the blank
line before the closing `GO` are, the body around them LF (observed
2026-10-01, three CRs in each of one warehouse's 10 views). A User Data
Functions `definition.json` is CRLF on every line, with no final
newline, beside an LF `function_app.py` and `.platform` (observed
2026-09-30, three portal commits).

With Git for Windows' default `core.autocrlf = true` and no
`.gitattributes`, a local commit strips those CRs, the next portal sync
puts them back, and the history fills with recurring "Auto formatted"
commits. Careful authoring cannot fix it: the translation sits under
the edit. Check `git config core.autocrlf` and for a `.gitattributes`
early in any Fabric repo, and where translation is on and nothing pins
the item folders, add a line scoped to each workspace folder:

```gitattributes
<workspace-folder>/** -text
```

`-text`, no translation at all, **not** `text eol=lf`, which strips the
portal's CRLF lines and restarts the ping-pong from the other side. It
does not mend blobs already committed: expect one more normalization
commit before it settles. `-text` keeps a notebook's CRs too, and the
portal will not drop them: its serializer writes its own marker and
`# META` lines LF but keeps cell text byte for byte, so a part committed
CRLF stays CRLF until converted locally (observed 2026-08-10, 1,040 of
1,128 lines back as CRLF).

**A view header's own line ending can differ by workspace.** In one
estate a sandbox workspace wrote it LF and the Dev workspace CRLF. On an
LF header the Dev sync rewrote the line and left the old one behind,
one dash short, `- Auto Generated …`, which fails with
`Incorrect syntax near '-'` and blocks every later sync; deleting the
line fixed it (observed 2026-08-17 and 2026-08-19, as that estate's
repo records them). The same repo records a second cause, whose line
returns after every sync: the live view's `sys.sql_modules` definition
embeds the header comment, and the portal half-strips it on export.
Re-create the view in each affected warehouse with `CREATE OR ALTER`,
its text starting at `CREATE`, with no header line.

Two CI checks guard it, as that repo's do, and neither depends on the
stack: fail on any `.sql` line starting `- Auto Generated`, and on a
view header whose ending differs from what the workspace synced to
`main` writes. Test the CR with `tr -cd '\r'`, not `grep`: Git Bash's
grep 3.0 matches no `\r$`, so a grep check flags every view there
(observed 2026-10-01).

**An exact-match edit can fail on a CRLF line** even when the text looks
identical. Match a smaller span that avoids the line break, or work on
bytes.
