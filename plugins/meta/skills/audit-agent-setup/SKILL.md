---
name: audit-agent-setup
model: inherit
effort: xhigh
disable-model-invocation: true
argument-hint: "[hooks|permissions|skills|agents|plugins|mcp]"
allowed-tools: Read Grep Glob Bash(git rev-parse *) Bash(git ls-files *) Bash(git check-ignore *) Bash(git remote *) Bash(uv run --no-project ${CLAUDE_SKILL_DIR}/scripts/plugin-inventory.py *)
description: "Audits a repo's Claude Code setup on this machine and reports what to fix and what to add: hooks, permission rules, skills, subagents, plugins and MCP servers. Edits, writes and connects nothing. Runs the checks a generic recommender cannot: plugins declared off and the payload's reason for it, .mcp.json placeholders, literal header values and tracking, servers at the wrong scope, tenant pins that MCP servers ignore, and CLAUDE.md rules nothing enforces. Reuses the deployed agents and skills and microsoft-learn-mcp before proposing anything new, names scope-instructions, /doctor and /fewer-permission-prompts where one owns the question, and places each item in the repo, the repo the user's own config is authored in (through capture-learning from another repo) or nowhere. Typed only: audit-agent-setup [category]."
---

# Audit agent setup: what a repo's Claude Code configuration lacks

A generic recommender reads a codebase and proposes popular servers and
format hooks. On this machine the faults that cost time sit elsewhere: a
plugin switched off on purpose and proposed again, a `.mcp.json` URL
still holding a template placeholder that fails every session start, a
server at user scope that belongs to one tenant, an `az` tenant pin no
MCP server honours, a `CLAUDE.md` rule that nothing enforces. This skill
checks those first, then recommends from the code, reuse first. It
**reports and stops**: nothing is edited, written or connected.

Its neighbours own the rest. **Where a line of guidance lives** (root,
a rule, a nested file, a skill) is `scope-instructions`'. **Install
health and unused extensions against their context cost** are
`/doctor`'s. **Allowlists drawn from past sessions** are
`/fewer-permission-prompts`'. Applying a recommendation is
`/update-config`, `/permissions`, `/plugin` or `/mcp`, on the user's
request.

Past `references/`, the live page: code.claude.com by the
`claude-code-docs` MCP server or
`curl -s https://code.claude.com/docs/en/<page>.md`, and another tool's
line, as husky's, by that tool's own markdown source, else `WebFetch`,
saying it read a summary. A live page that contradicts a line here wins:
say so, act on the page, and route the fix by `capture-learning`, bar
a dated measured line that names the page it overrules and the call that
measured it, which a page changed since its date sends back to re-measure.
An observed claim is cited or marked pending a doc check, and stands, marked
observed, only where no page covers it.

## 0. Whose setup

```bash
git rev-parse --show-toplevel
git remote get-url origin
printenv CLAUDE_CONFIG_DIR
printenv CLAUDE_CODE_PLUGIN_CACHE_DIR
```

- **The account is a config directory.** `CLAUDE_CONFIG_DIR`, else
  `~/.claude`. Its `.claude.json` sits inside it when the variable is
  set, else at `~/.claude.json` (measured on 2.1.293, 2026-10-16). Its
  plugins root is `CLAUDE_CODE_PLUGIN_CACHE_DIR`, else `<config>/plugins`
  (plugins loading reference). A work-root session and a personal one
  read different directories, so name the one read in the report.
- **The config source is the repo the user's own config is authored
  in**, where they keep one: a repo holding `claude/CLAUDE.md`, the
  source of their user-scope instructions, at its root. There a payload
  recommendation is a proposed edit in this tree; anywhere else it goes
  through `capture-learning` (step 5) where it is installed, and with
  neither the report names it for the user to place.
- **Not a git repo**: audit the account alone, and say so.
- **An argument narrows the run** to that category's findings and
  recommendations, three to five of them instead of one or two.

## 1. Read the repo's setup, with Read

Read each that exists, **one Read per file**:

- `.claude/settings.json`, `.claude/settings.local.json`, `.mcp.json`
- `.claude/launch.json`, the desktop app's Browser pane config (3.6)
- root `CLAUDE.md`, `.claude/CLAUDE.md`, `CLAUDE.local.md`
- `.pre-commit-config.yaml`, `.gitignore`
- `package.json`, for its `scripts` and a `lint-staged` key, and each
  hook file in `.husky/`

**`.gitignore` names what no Glob finds.** A credentials file kept
outside the checkout, or ignored in it, may show only as a pattern
there: one run's strongest finding, a vendor credentials file holding a
client secret, came from its extension in `.gitignore` alone (observed
once, 2026-10-21). Count each credential-shaped pattern as the
catalog's credentials-file signal.

A Read of `.mcp.json` or a settings file loads the user-scope rule
`claude-config-scoping.md` by its glob, a Read of a `CLAUDE.md`
`agent-instructions-scoping.md`, and a pipe or multi-file `cat` neither:
this skill applies their tables, and where one did not load, as for a
plugin's user, its copy in `references/`, saying the findings stand on it.

List `.claude/agents/`, `.claude/skills/` and `.claude/rules/` by Glob;
Read one only when a finding turns on it. Then whether each config file
is shared:

```bash
git ls-files -- .mcp.json .claude/settings.json .claude/settings.local.json CLAUDE.local.md .claude/launch.json
git check-ignore -v -- .mcp.json .claude/settings.local.json CLAUDE.local.md .claude/launch.json
```

**A commit gate is configured, armed and passing: three facts, read
apart.** Configured is a file: `.pre-commit-config.yaml`, a `.husky/`
folder, a `lint-staged` key, or a CI step running the tests or a linter.
Armed is a hook where git runs them:

```bash
git rev-parse --git-path hooks
```

It prints `.git/hooks` with `core.hooksPath` unset, and `.husky/_` once
husky has set it (git 2.55, 2026-10-28). Read `pre-commit` in that
folder, from the repo root: missing, or only `pre-commit.sample`, the
gate is configured and not armed. Passing, this skill never measures
(3.5). Configured and not armed is a finding to explain, its likeliest
cause a baseline that fails, not a one-command fix.

**Codebase signals by Glob**, not a chain of `ls`: manifests
(`pyproject.toml`, `package.json`, `*.csproj`, `*.sqlproj`), CI
(`.github/workflows/*`, `azure-pipelines.yml`), infrastructure
(`**/*.bicep`, `azure.yaml`), deploy scripts (`**/deploy*.ps1`,
`**/deploy*.sh`), Fabric items (`**/.platform`), PBIP (`**/*.pbip`),
a Salesforce DX project (`sfdx-project.json`, `.forceignore`,
`force-app/`), `.env*` files, an MCPB `manifest.json`, and format or
lint configs.
`references/catalog.md` says which signal leads where.

## 2. Read the account's user scope

- `<config>/settings.json`: `enabledPlugins`, `hooks`, `permissions`.
- Names only in `<config>/agents/` and `<config>/skills/`: what is
  deployed, for reuse.
- User-scope servers, one key of the account's `.claude.json`:
  `jq -b -r '.mcpServers // {} | keys[]' <file>`. **Never Read the whole
  file**: it is Claude Code's runtime state, the OAuth account and every
  project's history beside that one key.
- Plugins, by the bundled script, never by hand:

  ```bash
  uv run --no-project ${CLAUDE_SKILL_DIR}/scripts/plugin-inventory.py
  ```

  It reads `enabledPlugins` from the user, project and local settings,
  and under the plugins root the install records, `cache/`, each
  `synced/<bucket>/` folder (the claude.ai account's, loaded as
  `<name>@synced` with no install record) and every marketplace clone's
  list. Per plugin it prints which settings file wins, the stage, the
  `<plugin>:<skill>` names, and each server's url or command with its
  header and env keys, never their values. Every run before it wrote
  that read by hand, and three got it wrong (2026-10-21): **a synced
  folder is named by its own `.claude-plugin/plugin.json`**, the `name`
  `enabledPlugins` uses, not by the bucket's `manifest.json`, whose
  `name` is the folder's, often a UUID. Exit 2 says a file's shape
  changed: read that one by hand and call the inventory partial.
  `--plugin <name>` looks a plugin up in the marketplaces, for step 4.
- **claude.ai connectors are in no file.** Read this session's own tool
  list for connector servers and report their tool families; their
  endpoints cannot be read from files. A desktop session's
  `mcp__ccd_connectors__session_connectors_status` lists each server's
  name, kind, status and tool count, and a connector's id, which is its
  tool prefix, and connects nothing (2.1.304, more than one session,
  2026-10-21). Its tool count is the server's own, which a
  `permissions.deny` leaves as it was: read a deny's effect from the
  session's tool list (2026-10-22). There they run in-process,
  `type: "sdk"` servers that no
  MCP setting reaches (MCP docs § "How connectors reach Claude Code",
  read 2026-10-21).
- **The desktop app's own config is a third user-scope source.** Its
  `%APPDATA%\Claude\claude_desktop_config.json` `mcpServers` load in
  every local Code-tab session beside `~/.claude.json` and `.mcp.json`,
  and the CLI reads none of them (Desktop docs, read 2026-11-14). The
  status tool above lists each as `kind: "desktop"`, and one named
  `github-mcp` was the only `github-mcp` a session listed in a repo
  whose `.mcp.json` enables its own (observed 2026-11-14, 2.1.321).
  Read each entry's key, `command` or `url`, and `env` key names by
  `jq -b`, never a value.

**Where Read refuses a path outside the working directory**, under
`permissions.blockReadsOutsideWorkingDirectories`, read the one key with
`jq -b`, which prompts rather than refuses (settings reference).

**Connect nothing.** No `claude mcp list` or `get`, `/mcp`,
`claude plugin list`, `az`, `headersHelper` run or call to a project
server's tool. `claude mcp list` health-checks every server it lists,
which runs each project helper, and an `az`-based helper takes its token
from whichever login the shared `~/.azure` holds: from a client repo,
that is a call into another tenant, the hazard of check 4. The files
answer every question here.

**The harness may have connected already.** In a repo whose `.mcp.json`
servers are approved, Claude Code connects them at session start, so
their helpers ran before step 0 (observed once, 2026-10-21). Nothing
here can stop that: where check 4 fires, say a cross-tenant call at
launch is the launch's, not this audit's.

## 3. Findings

### 3.1 Plugins declared off

For each `enabledPlugins` entry set `false` in user, project or local
settings (the highest source naming the id wins: managed, then
`--settings`, local, project, user), read from step 2's inventory, the
report carries one line, though none of it is a fault (step 6):

- **Its stage**: installed, cached and not installed, synced, or not
  fetched. **Then whether this session's own skill listing carries the
  plugin's `<name>:` skills**, which the inventory names: a `false` is
  what the CLI reads, not what a running session loaded. With
  `code-review@synced` set `false`, a desktop session three hours after
  the deploy still listed its `code-review:` skill, while
  `claude plugin list` on the same config directory printed it disabled
  (2.1.307, 2026-10-21).
- **Whose decision**: an id the payload's `claude/settings.json` sets
  `false` was switched off on purpose, for its listing cost (2026-08-31),
  since `skillOverrides` cannot reach a plugin's skills. **Never
  recommend installing a plugin that is installed and off.** If it earns
  its place in this repo, recommend enabling it here only, in
  `.claude/settings.local.json` or `.claude/settings.json`, which
  outrank the user `false`, against that reason.
- **A plugin suggestion that never appeared** has several documented
  causes: the plugin is installed; a relevance suggestion comes only
  from a marketplace an administrator lists in
  `pluginSuggestionMarketplaces`; a CLI hint comes once ever per plugin,
  and never with analytics off. Name the ones that fit; assert none.

### 3.2 `.mcp.json` hygiene

For each server:

- **A placeholder still in place**: a `<...>` segment in `url`, `args`
  or `headers`, as the project template ships them (`<WorkspaceId>`,
  `<GITHUB_PAT_VAR>`; the user's MCP README, `<config>/mcp/README.md`
  where their config holds one, lists them). It fails at
  every session start. An empty `url` is not this: Claude Code lists it
  `not configured` and never dials it.
- **A header holding a literal value** rather than a `${VAR}` or a
  `headersHelper`: a credential in a file. **Name the key, never the
  value.** Tracked and pushed, it is `recreate-repo`'s case; otherwise
  move it to a variable named per account, with no generic fallback.
- **A `${VAR}` this session lacks**: `printenv NAME >/dev/null && echo
  set || echo unset`, never printing the value. Unset with no
  `:-default`, Claude Code warns and sends the text unexpanded. A
  credential name such as `ANTHROPIC_API_KEY` or `NPM_TOKEN` reads as
  empty in a remote `url` or `headers` whether set or not (MCP docs).
  VS Code reads `.mcp.json` too and expands no `${VAR}` at all
  (1.140.0, 2026-10-03).
- **Tracked or not**: tracked, every clone gets the servers and is asked
  to approve each; untracked or ignored, clones get none. Either can be
  right: say which, and whether a server carries per-person values.
- **A `timeout` on the wrong transport.** A hosted Fabric `http`
  server with none fails any call past about 60 seconds with
  `The operation timed out.`; on a stdio server the value is a hard
  wall-clock cap on each call. The project template sets `120000` on the
  measured hosted entries and none on stdio, and the user's MCP README,
  where one exists, has why in § "Per-server timeout". One
  `.mcp.json` copied from another project had it the other way round
  (2026-10-21).
- **Overlap**: the same name at local or user scope with another
  endpoint (Claude Code warns; sign-ins are per endpoint), or the same
  endpoint as a plugin's server, a synced plugin's included, or a
  claude.ai connector. Plugins and connectors are matched by endpoint
  and the project server hides them (MCP docs, scope precedence).
  Recommend keeping one. A connector is hidden so only where Claude Code
  fetches connectors itself, in terminal, IDE and SDK sessions; a
  desktop session's run in-process (step 2).
- **Permission rules for a server's tools** go in `.claude/settings.json`,
  not beside the server.

### 3.3 Scope

User scope holds what is bound to nothing: on this machine, the two
docs servers `microsoft-learn-mcp` and `claude-code-docs`. A server
that needs a workspace, a database, a connection string, a desktop
app, a GitHub account or a tenant belongs in this repo's `.mcp.json`.
**A tool absent from user scope is not a gap**; a recommendation to put
one there is the finding.
The same test places a hook: one every repo needs is payload, one for
this repo's tools is the repo's. A claude.ai connector (step 2) reaches
every repo its account opens, as user scope does, so a tenant-bound one
meets the same test; its fix is on claude.ai, in no file. So does a
server in `claude_desktop_config.json` (step 2), whose fix is deleting
its entry by hand, since no deploy reconciles that file.

### 3.4 Tenant pins that MCP servers ignore

When the repo pins `az` to a tenant (a script or hook setting
`AZURE_CONFIG_DIR`, a guard reading `az account show`, a `CLAUDE.md`
line naming the tenant) and also declares a tenant-bound server
(`azure-mcp`, a Fabric or Power BI `headersHelper` server,
`microsoft-fabric-mcp`, `fabric-rti-mcp`), **the pin does not cover the
server**. Servers and their helpers are spawned by Claude Code and
inherit its environment, so an `az`-based one reads the shared
`~/.azure`: the user-scope `CLAUDE.md` says MCP servers ignore
`AZURE_CONFIG_DIR`, and the user's MCP README, where one exists,
§ "The helper's login is the harness's, not the folder's", holds the
one relayed measurement (2026-09-22). Report it with that section's
three candidate remedies, all unrun, the third a stdio server's own
`env`, or with no such file that one alone: measure one before relying
on it. Never confirm the finding by calling the server.

**The launch may already carry a pin**, so read the harness's own value
before wording the finding: `$env:AZURE_CONFIG_DIR` in the PowerShell
tool, which runs `-NoProfile`, or `printenv AZURE_CONFIG_DIR` in Bash
only when `/proc/$$/cmdline` shows a snapshot (`bash -c source …`). A
login-mode Bash reruns the profile, which sets it from the folder
whatever the harness has. Set, report the servers covered by the
launch, not by the repo, so a session started another way has nothing
pinning them; unset, report as above. Whether a project helper keeps
it past Claude Code's credential stripping is unprobed. The same README
section has the measurements (2026-10-21).

### 3.5 `CLAUDE.md` rules nothing enforces

For each line in the files read in step 1 that says something must or
must not happen, look for what enforces it in the settings, hooks,
pre-commit config and tests. `CLAUDE.md` is "context, not enforced
configuration", while "permission rules are enforced by Claude Code,
not by the model" (memory and permissions docs). Where nothing does:

| The line says | Enforce with | Say also |
| --- | --- | --- |
| ask before X | `permissions.ask` with X's rule | prompts even in `acceptEdits` and `bypassPermissions`; `dontAsk` denies instead |
| never read or edit F | `permissions.deny` with `Read(...)` or `Edit(...)` | covers the file tools and Bash file commands Claude Code recognizes, not `grep -r` or a script opening files; the sandbox is the OS-level answer |
| never run C, never print secrets | a `PreToolUse` hook that exits 2 | a failing hook lets the call through unless it sets `"onFailure": "block"` (2.1.295+); a Bash rule matches command text only |
| only the user starts X | `permissions.ask` naming X's script, a rule per shell | `disable-model-invocation: true` stops Claude loading a skill, not running its script or the command it wraps (skills docs) |
| run X before committing | a git hook in `.pre-commit-config.yaml` | binds every committer, not only Claude |
| change A with B and C, keep these in step | a test comparing them, run in CI | binds every change, not only Claude's; a value that may differ on purpose goes in the test's exception list, with its reason (2026-10-22) |

**A gate counts only once it passes.** The last two rows, and the
catalog's Hooks rows, count a gate step 1 found, or propose one, only
over a baseline that passes: failing, it blocks every commit touching a
failing file, or rewrites each whole by a `--write` or `--fix` step. One
client run recommended `npm install` to arm a husky gate configured and
not armed; once installed, its ESLint, Prettier and Jest steps failed
across most of the repo (2026-10-28). **This skill never runs a gate**,
which would run the repo's code and its formatters:

- **Unmeasured**, say so, and make running the gate in check mode the
  first Recommended action, ahead of any arm: `prettier --check`,
  `eslint` without `--fix`, the test script. Install by `npm ci`, not
  `npm install`, with `HUSKY=0` set: `npm ci` runs the `prepare` script
  too, which arms husky (npm scripts docs; `HUSKY=0` is husky's own
  switch for an install that must not, 2026-10-28).
- **Measured failing**, by the user or a CI log, report its counts; the
  fix is a baseline cleanup, or scoping the gate to changed files, never
  arming it as it is. So too a CI step proposed to run a script the repo
  already has.

**A rule on command text has twin routes.** Check a "never run" or
"never print" line against each, and answer each with a matcher or with
`permissions.ask` or `deny`:

- **Another command runner.** The desktop app's
  `mcp__terminal__run_in_terminal` runs commands no `Bash|PowerShell`
  matcher sees and no permission rule reaches: Claude Code skips an
  `mcp__` rule with parentheses, and a bare one asks on every command
  (permissions docs § "Match by input parameter", read 2026-11-14). So
  answer a `Bash(...)` or `PowerShell(...)` rule there with a
  `PreToolUse` hook on the tool that returns `permissionDecision` `ask`
  or `deny`; a matcher naming the tool fired in a live Desktop session
  (observed 2026-11-14, 2.1.321).
- **A declared server's tools.** Azure MCP's
  `appservice webapp settings get-appsettings` is annotated Secret, its
  values able to include connection strings (Learn, 2026-10-21): a rule
  on `mcp__<server>__<tool>`. In `azure-mcp`'s default namespace mode
  that is `mcp__azure-mcp__appservice`, one tool for every App Service
  operation, so the rule denies its writes too (read from a session's
  tool list 2026-10-21).
- **A second CLI for the same API.** Az PowerShell's
  `Get-AzStorageAccountKey` and `Get-AzFunctionAppSetting` pass a guard
  matching `az` as a word, and ignore `AZURE_CONFIG_DIR`, so a
  tenant-pin rule has the same hole (a guard fed synthetic payloads,
  2026-10-21): widen the pattern to the second CLI.
- **The same CLI's REST verb.** `az rest`, `gh api` and `fab api` take
  the operation as a URL, so its name arrives as a path segment:
  `az rest` against a site's `config/appsettings/list` or
  `config/connectionstrings/list`, or a storage account's `listKeys`,
  passes a guard matching `appsettings list` or `keys list` (a client
  guard fed synthetic payloads, 2026-10-21; its patterns re-run on the
  URLs 2026-10-22). Match the path segments too, or deny the REST verb
  where the repo has no use for it.

Whether the line then stays as the reason, moves or goes is
`scope-instructions`' question, as is a side-effecting workflow
written as prose: name it, do not answer it.

### 3.6 `.claude/launch.json`

**The desktop app's Browser pane config**: one entry in `configurations`
per dev server it starts, or per URL it opens (Desktop § "Configure
preview servers", read 2026-10-29). It takes JSON with comments, so
Read it rather than `jq` it. Each check here is from the docs' text,
and none has yet met a broken file. With no file, the line says so, and
the catalog's dev-server row weighs proposing one.

- **Tracked or ignored**, by step 1's two `git` lines. The docs treat
  the file as committed: `env` reads "Don't put secrets here since this
  file is committed to your repo". So ignored is the finding: a clone
  has no entries until the app detects a dev server on its first
  preview. An allowlisting `.gitignore` (`/.claude/*`, then a `!` line
  per file) ignores a new one silently, exit 0, as the config source's
  did until it gained a line (2026-10-29). Which copy a desktop-app
  worktree session reads is undocumented; one relayed note found a
  worktree's own copy unread (2026-10-20).
- **A literal value in an entry's `env`** that reads as a credential:
  name the key, never the value, as 3.2 does for a header. Tracked and
  pushed, it is `recreate-repo`'s case; otherwise it moves to a user
  environment variable on Windows, or the local environment editor,
  then a Desktop restart (§ "Set environment variables for dev
  servers"). A dev server gets neither `~/.claude/settings.json`'s `env`
  nor a saved environment's.
- **A `url` the app refuses.** One on `localhost`, a `*.localhost`
  subdomain, `127.0.0.1` or `::1` must be the server's origin alone, its
  port the entry's `port`, 3000 when unset: a path, a query or another
  port is reported as a configuration error. Any `url` must be `http`
  or `https`, with no username or password. An external one may carry a
  path, and asks permission the first time the preview opens it.
- **`autoVerify` and `autoPort` are no finding** on their own.

## 4. Recommendations

**Reuse first.** Before anything new, match the need against what step
2 found deployed: the user-scope agents and skills,
`microsoft-learn-mcp`, the payload's hooks, and the built-in skills. A
need one of them meets is a "use X" row, or no row.

Then Read [references/catalog.md](references/catalog.md) and match step
1's signals. Keep one or two per category, the strongest signal first,
or three to five in the category an argument names; skip a category
with nothing. Every item names the file or signal behind it.

**Name only what exists here**: a plugin the inventory's `--plugin`
lookup finds in a marketplace's list, a server from the project
template the MCP README describes, or one Learn documents through
`microsoft-learn-mcp`. Found nowhere, it is not recommended; say what
was looked for.

**A copied skill moves with its group, whole.** A skill listed in
`.claude/skills/.managed-skills.json` was copied from the payload's
`skills/` by a script retired once client repos took each group's plugin
from the organization's catalog (2026-11-17), so nothing refreshes it.
Recommend removing no one copied skill, whatever its description says,
but the move: the copy and its manifest deleted, and the group's plugin,
which brings the group whole as the copy did, enabled in
`.claude/settings.json`. Name that plugin only as **Name only what
exists here** allows; found nowhere, recommend no change and say what was looked for.

## 5. Place each item

| Lands in | When | How it gets there |
| --- | --- | --- |
| the repo | bound to its tools, files or tenant | `.claude/settings.json` or `.mcp.json` for everyone, `.claude/settings.local.json` for one person, `.claude/agents/`, `.claude/skills/`, `.pre-commit-config.yaml` |
| the payload | every repo needs it, or a payload file is wrong | in the config source, a proposed edit; elsewhere `capture-learning` where installed, which writes the inbox note and cites a client's estate by kind; with neither, named for the user |
| nowhere | reuse covers it, the code makes it derivable, or a payload decision rules it out | say which |

## 6. Report

Plain markdown, no emoji headings, about a screen:

```text
## Profile              the account read, the commit read (git rev-parse --short HEAD), the stack, the signals that drove the report
## Findings             3.1 to 3.6, a line each: the file, what is wrong, the fix, where it lands
## Recommendations      by category, one or two each: what, the signal, where it lands
## Next steps in other skills  what scope-instructions, /doctor or /fewer-permission-prompts owns here, for the user to run
## Recommended actions  numbered: each fix or recommendation above that calls for an edit, and where it lands
```

**Findings gives every check a line**, a clean one included, since a
missing line reads the same as a check not run: one run gave 3.4 none,
having read no `AZURE_CONFIG_DIR` (2026-10-21). **It also gives each
plugin set `false` its line from 3.1**: stage, whether the session
lists its skills, and whose decision. One run read every stage, then
reported only that the ids matched the payload (2026-10-21).

**Recommended actions ends the report**, numbered `1.`, `2.`, … across
Findings and Recommendations: one line per finding fix or
recommendation that calls for an edit, naming the finding or category
it comes from and where it lands, as `1. 3.5.1, the inbox-delete rule:
a PowerShell twin of its ask rule, in the payload's
claude/settings.json`. A clean check, a 3.1 line, a finding the report
says to leave, a category with nothing new and an item under Next steps
in other skills get none. With nothing to edit, it reads `_(none)_`. It is the list a
handoff transcribes: in the config source, `file-audit-findings`, where
it has one, briefs each item without choosing among the findings, and
elsewhere nothing reads it.

**A gate's check-mode run comes first**, where 3.5 calls for one: it is
`1.`, though it edits nothing, ahead of any fix that would arm the gate.

Leave out any other empty section. Then stop: applying a row is a
separate request.

## Constraints

- **Edits nothing and writes nothing**, an inbox note included: that is
  `capture-learning`'s, run by the user.
- **Connects nothing**: no `claude mcp`, `claude plugin` or `az`
  command, and no tool of a project server.
- **Runs no gate**: no test, linter or formatter of the repo's, in check
  mode or not, and no install that would arm one (3.5).
- **Prints no secret**: a literal header or a variable's value is named
  by its key, never shown.
- **Recommends nothing at user scope that is bound** to a workspace, an
  account or a tenant.
- **A plugin the payload switched off stays a decision**: weigh its
  reason; never recommend installing it again.
- **A client's evidence stays in its repo**: a payload row from a client
  repo reaches the config source only through `capture-learning` or the
  user, cited by kind.
- **Not this skill**: where guidance lives (`scope-instructions`),
  install health and context cost (`/doctor`), allowlists from past
  sessions (`/fewer-permission-prompts`).
