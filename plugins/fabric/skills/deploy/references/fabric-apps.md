# Fabric Apps (the `AppBackend` item, built with Rayfin)

A Fabric app is a custom web app with Fabric as its backend: TypeScript
on the Rayfin SDK, scaffolded and deployed by the `npx rayfin` CLI, with
an app database, Entra sign-in, static hosting, optional Functions and
storage, and connectors to a lakehouse, warehouse, SQL database or
semantic model ([overview](https://learn.microsoft.com/fabric/apps/overview),
read 2026-11-18). Its Fabric item type is `AppBackend`
([source control](https://learn.microsoft.com/fabric/apps/source-control),
read 2026-11-18).

**This file holds the Fabric side alone**: wiring Claude Code to the
scaffold's own agent files, the deploy routes and what each carries,
and the stops. How to write a Rayfin app, its decorators, client,
connectors and Functions, is the scaffold's own version-matched skills',
which win over this file on Rayfin's API. Past them, Learn's
`fabric/apps/` pages by `microsoft-learn-mcp`, as `SKILL.md`'s fallback
line says, and a live page that contradicts a line here wins on the
same terms.

## 1. Wire Claude Code to the scaffold's agent files

**The CLI installs agent files Claude Code never reads.** On a scaffold
or `npx rayfin init` it installs managed agent files, the `.agents/skills/`
skills and the `mcpServers.rayfin` key in `.mcp.json`, recorded in
`rayfin/.lockfile.json`, and keeps a template's `AGENTS.md`
([author templates](https://learn.microsoft.com/fabric/apps/author-templates),
read 2026-11-18). CLI 2.0.0 installs five managed skills, `rayfin`,
`rayfin-functions`, `rayfin-connectors`, `rayfin-storage` and
`rayfin-auth-claims`, a sixth, `rayfin-schema-drift`, behind a feature
flag, each at `.agents/skills/<name>/SKILL.md`, and the templates add
their own beside them (`dist/services/agent-files/descriptors.js` in
`@microsoft/rayfin-cli` 2.0.0, read 2026-11-18). Claude Code lists a
project skill only from `.claude/skills/`
([skills](https://code.claude.com/docs/en/skills#where-skills-live),
read 2026-11-18): a skill under `.agents/skills/` alone was not listed,
and the same folder junctioned into `.claude/skills/` was (observed
2026-11-18, 2.1.327).

So, in a Rayfin project, before the first edit:

1. **Link each `.agents/skills/<name>/` into `.claude/skills/<name>`**,
   never copy it: the CLI owns and rewrites the managed files, so a copy
   keeps a stale version where a link follows the CLI. On Windows a
   junction needs no admin:

   ```powershell
   New-Item -ItemType Directory -Force .claude/skills | Out-Null
   Get-ChildItem .agents/skills -Directory | ForEach-Object {
     $link = Join-Path .claude/skills $_.Name
     if (-not (Test-Path $link)) { New-Item -ItemType Junction -Path $link -Target $_.FullName | Out-Null }
   }
   ```

   It made a junction per folder in a scratch repo (observed
   2026-11-18, pwsh 7.6). A project skill folder may be a symlink
   ([skills](https://code.claude.com/docs/en/skills#where-skills-live),
   read 2026-11-18); elsewhere, `ln -s`. A session picks up a new skill
   in a `.claude/skills/` it watched from its start; one that created
   the directory runs `/reload-skills`
   ([skills](https://code.claude.com/docs/en/skills#live-change-detection),
   read 2026-11-18). Commit no link without the repo's say: it wires
   this machine's Claude Code to files the CLI already manages.
2. **Instructions**: Claude Code reads `AGENTS.md` only where no
   `CLAUDE.md`, `.claude/CLAUDE.md` or `CLAUDE.local.md` sits in the
   working directory or above it, and nothing under `.agents/`
   ([memory](https://code.claude.com/docs/en/memory#agents-md), read
   2026-11-18). With a `CLAUDE.md`, an `@AGENTS.md` line in it imports
   the scaffold's file.
3. **The `rayfin` MCP server** is a stdio server,
   `npx -y @microsoft/rayfin-mcp start` (CLI 2.0.0's
   `assets/agent-files/mcp-server.json`, read 2026-11-18), at project
   scope in `.mcp.json`, so it asks for approval before first use.

## 2. Pick the route

The `SKILL.md` step 1 rule holds here: one route into each target
workspace.

| Route | What it moves | Read |
| --- | --- | --- |
| `npx rayfin up`, `--workspace <name>` for another stage | creates or reuses the app item, syncs `rayfin.yml`'s settings, applies the schema and storage folders, builds and uploads static content | [deploy](https://learn.microsoft.com/fabric/apps/deploy-app), [dev and prod](https://learn.microsoft.com/fabric/apps/dev-prod-workflow) |
| Git integration, then deployment pipelines | the item definition, versioned in Git and promoted between stages | [source control](https://learn.microsoft.com/fabric/apps/source-control) |
| Get, Create (`AppBackend`) or Update Item Definition | the same definition, scripted, with no commit, sync or pipeline run | the same page, § Automate with public APIs |
| fabric-cicd, `fab deploy` | nothing: `AppBackend` is missing from the library's `ItemType` enum | `src/fabric_cicd/constants.py`, `main` at `e044d1e1`, read 2026-11-18 |

All three Learn pages above were read 2026-11-18.

**`rayfin up --workspace` makes a second item, not a promotion.** It
creates a separate app item in the other workspace and records a second
deployment, which plain `npx rayfin up` then targets until
`npx rayfin up switch <name>` moves it back
([dev and prod](https://learn.microsoft.com/fabric/apps/dev-prod-workflow),
read 2026-11-18). Learn's pages disagree on the file that records the
active deployment, so read `npx rayfin up status` and
`npx rayfin up list` before a plain `up`, never the file.

**`npx rayfin dev` writes to Fabric too**: it starts the frontend's dev
server and deploys the backend to Fabric
([create with the CLI](https://learn.microsoft.com/fabric/apps/create-app-with-cli),
read 2026-11-18), so against a shared workspace it is a deploy.

**Git integration needs a capacity workspace and its Admin**: the
workspace on Fabric capacity holding a deployed app, and the workspace
Admin role to connect it
([source control](https://learn.microsoft.com/fabric/apps/source-control),
read 2026-11-18).

## 3. What a definition does not carry

On the Git, pipeline and definition-API routes, by
[source control](https://learn.microsoft.com/fabric/apps/source-control)
(read 2026-11-18):

- **No data**: database rows, uploaded storage objects, user accounts
  and secret values stay behind. The definition is no backup.
- **Secret names, not values**: set the values in each target after the
  first deploy and after any deploy that adds a secret; existing target
  values are kept.
- **No remapping**: connector workspace and item IDs and absolute
  authentication redirect URIs are copied as they are, so review them
  for the target.
- **Builds, not source**: `frontend/static-app.zip` and
  `functions/functions-app.zip` are deployable builds, so the source
  stays in its own repo; `functions-app.zip` travels with
  `deploymetadata.json`.
- **The schema does apply**: an import applies schema changes to the
  target, and a removed or changed entity or field can destroy data.
- **The exported `rayfin.yml` is runtime config**, not the project's
  `rayfin/rayfin.yml`, and keeps no local paths or build commands.

## 4. Stops and permissions

Add these to `SKILL.md` step 3's stops:

- **`npx rayfin up` into any stage past the first**: show the same
  command with `--dry-run` added, keeping its `--workspace` or
  `--workspace-id`, since a plain `up` targets the active deployment;
  Learn's dev and prod tutorial recommends a dry run before any prod
  deploy (read 2026-11-18).
- **`--force` on `npx rayfin up`, `up db apply`, `up storage apply` or
  `dev storage apply`, in any stage**: each lets through a destructive
  change, a dropped column, a renamed table or a removed storage folder
  that still holds files, whose files go for good
  ([deploy](https://learn.microsoft.com/fabric/apps/deploy-app),
  [storage](https://learn.microsoft.com/fabric/apps/storage#change-or-remove-folders),
  read 2026-11-18; `up`'s `--force`, "Allow destructive data schema
  changes that may result in data loss", and its storage step's "Use
  --force to apply storage changes that may result in data loss", in
  `dist/commands/up/up.js`, `@microsoft/rayfin-cli` 2.0.0, read
  2026-11-18). A refused command suggests `--force` itself: show the
  operations or folders it listed and wait for the user's yes.

Permissions, each read 2026-11-18:

- **Deploy**: at least Edit on the app item
  ([deploy](https://learn.microsoft.com/fabric/apps/deploy-app)), and
  Contributor, Member or Admin on the workspace to create one, in a
  tenant with the Fabric Apps workload enabled
  ([create with the CLI](https://learn.microsoft.com/fabric/apps/create-app-with-cli)).
- **Licence**: Power BI Pro creates an app from the Power BI portal in a
  Pro workspace, with a PostgreSQL database of at most 1 GB and no
  Functions, file storage, anonymous data access or public sites;
  Fabric capacity or a trial lifts those
  ([licensing](https://learn.microsoft.com/fabric/apps/licensing)).
- **Sign-in**: a deployed app takes only Fabric brokered authentication
  (Entra SSO); email and password work in local development alone
  ([deploy](https://learn.microsoft.com/fabric/apps/deploy-app)).
- **Functions act as the item's owner**: external calls through
  `ctx.Tokens.*` use the app identity, which in current Fabric apps is
  the app item owner, so grant that owner each resource, while
  `ctx.getDataClient()` keeps the caller's data policies
  ([create with the CLI](https://learn.microsoft.com/fabric/apps/create-app-with-cli)).
  An owner change moves that identity: name it in the plan.
- **Semantic model connectors are delegated only**: each user needs the
  model's permission and a Power BI entitlement for it
  ([licensing](https://learn.microsoft.com/fabric/apps/licensing)).

## 5. When it fails

Each from [deploy](https://learn.microsoft.com/fabric/apps/deploy-app),
read 2026-11-18:

| Symptom | Cause and fix |
| --- | --- |
| 401 or 403 from `npx rayfin up` | An expired session: `npx rayfin login`, then retry |
| `up`, `db apply` or `storage apply` refuses a change, suggesting `--force` | A destructive schema change, or a removed storage folder that still holds files (`up`'s storage step, `dist/commands/up/up.js`, CLI 2.0.0): § 4's stop |
| The static deploy is refused for size | The compressed archive is over 100 MB: drop source maps and large assets, or move binaries to the app's storage |
| A schema change made in the portal's SQL editor is gone | The next `rayfin up` overwrites it: change the data model instead |
