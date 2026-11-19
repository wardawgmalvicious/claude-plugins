# Signals and what they lead to

Step 4 of `audit-agent-setup` reads this after reuse has been checked.
Each row is a signal found in step 1, what it may justify, and what is
already deployed that makes a new item unnecessary. Keep one or two per
category in the report; a signal is a reason to look, not a verdict.

Built on 2026-10-21 from the categories and signal tables of Anthropic's
`claude-code-setup` plugin (1.0.0, Apache-2.0), rewritten for this
machine's stacks and payload; no table is copied. Its context7 and
Playwright defaults, web search and emoji report are left out on
purpose.

## Hooks

A command hook spends a Git Bash spawn per event on this machine, about
60 ms healthy and 0.5 to 3.2 s while `bash.exe` is degraded
(2026-10-17), so prefer a mechanism that runs once: a permission rule,
or a git hook at commit. **An existing gate counts only once it passes**,
armed or not, and this skill never runs one: SKILL.md § 3.5.

| Signal | May justify | Reuse or note |
| --- | --- | --- |
| a formatter or linter config: `ruff.toml` or `[tool.ruff]`, `.prettierrc*`, `eslint.config.*`, `PSScriptAnalyzerSettings.psd1` | a `PostToolUse` hook on `Edit\|Write` formatting the edited file | none if a git hook already runs it and passes: that binds every committer, the hook only Claude |
| `.pre-commit-config.yaml` present | the payload's `identity-guard.sh` as a git hook, its `--git-hook` modes, so a commit from any harness is scanned for denied names | the user's `identity-guard.sh` hook, where their config holds one, already gates Claude's own commits |
| `.husky/`, or a `lint-staged` key in `package.json` | nothing new: the gate run in check mode first | armed only with a `pre-commit` in the folder `git rev-parse --git-path hooks` prints; never `npm install` to arm it |
| no `.pre-commit-config.yaml` or `.husky/`, and a "run X before committing" line | adding one (check 3.5) | |
| a command that must never run | a `PreToolUse` hook exiting 2, with `"onFailure": "block"` | a `permissions.deny` Bash rule first, where matching the command text is enough |

## Permissions

| Signal | May justify | Reuse or note |
| --- | --- | --- |
| `.env*`, `secrets/`, a credentials file, a credential-shaped `.gitignore` pattern | `permissions.deny` with `Read(./.env)` and the like: repo-relative in `.claude/settings.json`, a per-person absolute path in `.claude/settings.local.json` | deny also hides the files from search; it does not reach `grep -r` or a script |
| a lock file | `permissions.deny` with `Edit(./<lockfile>)` | the package manager changes it, not an edit |
| a deploy, release or push script | `permissions.ask` naming it | |
| a Salesforce DX project (`sfdx-project.json`) | `permissions.ask` with `Bash(sf project deploy *)`, and the same for the PowerShell tool: a write to an org | `salesforce-development`'s `prod-check` hook blocks a production target only, and lets an unknown org through (Plugins, below); `sf` is not installed here, so its behaviour is unverified |
| a plugin in a Git-hosted marketplace with no `version` in its `plugin.json` | `permissions.ask` with `Bash(git push *)` | unversioned, each commit is the version, so a push to the default branch is the next update for every user who added the repo directly (plugins loading docs § "Versions and updates"), taken at their `/plugin marketplace update` or `claude plugin update`, since background auto-update is off by default for a marketplace added by source (`host-marketplace`, both 2026-10-22); `land-branch` asks before its write to main, a bare push does not |
| a `.mcp.json` server with read-only tools | `permissions.allow` with `mcp__<server>__<tool>` in `.claude/settings.json` | project allow rules apply only once the folder is trusted |
| commands the repo's docs run often | `permissions.allow` for them | `/fewer-permission-prompts` derives this list from past sessions: name it instead |
| `defaultMode` `auto` or `bypassPermissions` in a project file | a finding: ignored there | user settings, or `--permission-mode` for one session |

## Subagents

User scope deploys `security-reviewer`, whose edits a hook confines to
its own memory folder, and `command-runner`, which runs a decided
operation on Haiku and reports its exact output, its Writes held to the
session's scratchpad by a hook in its own frontmatter.

| Signal | May justify | Reuse or note |
| --- | --- | --- |
| auth, secrets handling, IaC, pipelines | a security review | `security-reviewer`; never a project copy |
| review of changes in general | a code review | the `review-code` skill |
| mechanical operations run on the main thread: a sync, a run, a poll, a check | delegating them off the main model | `command-runner`; never a project copy |
| a review only this repo needs, against its own checklist | `.claude/agents/<name>.md`, read-only tools | a project agent outranks a user one of the same name; the first file in a new `agents` folder needs a restart |

## Skills

A skill with side effects is user-only, `disable-model-invocation:
true` (skills docs). The field stops Claude loading the skill, not
running its script or the command the script wraps, so pair it with
`permissions.ask` naming the script (check 3.5). A signal from code
belongs here; one from `CLAUDE.md` prose is `scope-instructions`'.

| Signal | May justify | Reuse or note |
| --- | --- | --- |
| a deploy or release script with no skill around it | a project skill, user-only, that runs it and checks the result | |
| a plugin the repo ships with skills of its own, as a marketplace's `plugins/<name>/skills/` | an eval suite in the plugin's `evals/`, run by `claude plugin eval`: a no-plugin baseline arm by default, MCP stand-ins from `evals/mocks/` | `ship-plugin` § 7 has the run, listed once a Read opens the plugin's `.claude-plugin/plugin.json`; pass `--max-cost-usd`, and `--no-publish` in the user's own shell, where a claude.ai sign-in with artifacts publishes the report, while a run a Claude session starts stays local unless `--publish-report` (2.1.308 `--help` and `plugin-evals` docs, 2026-10-22); `test-skill` is the config source's own and tests only its skills |
| launching or driving the app | nothing new | `/run`, `/verify` and `/run-skill-generator`, built-ins to type (below) |
| a `dev` or `start` script in `package.json`, and no `.claude/launch.json` | nothing new | the desktop app detects the server and writes the file on its first preview; propose one in the repo only where detection misses, as a custom dev command, or a subfolder's server in a session started at the root (Desktop § "Configure preview servers", read 2026-10-29); its checks are SKILL.md § 3.6 |
| commits, pull requests, landing, branch cleanup | nothing new | `commit-changes`, `land-branch`, `prune-branches` |
| a leak pushed to GitHub | nothing new | `recreate-repo` |
| guidance in the wrong home | nothing new | `scope-instructions` |
| a learning another repo's guidance should hold | nothing new | `capture-learning` |

## Instruction files

**A `CLAUDE.local.md` holds one person's facts about a repo** that no
tracked file may carry: which login and identity it runs under, a
personal repo it exchanges files with, a sandbox. The template is this
skill's `assets/CLAUDE.local.template.md`, under the base directory
the skill's launch names, named so no ignore rule hides it and no
session loads it as instructions; filling it and copying it to the repo root as
`CLAUDE.local.md` is a separate request. Step 1's Read of
`CLAUDE.local.md` and its two `git` lines decide the first three rows;
the fourth needs a Glob for `AGENTS.md` at the root, which no step 1
line runs, and a session launched there has it switched off.

| Signal | May justify | Reuse or note |
| --- | --- | --- |
| no `CLAUDE.local.md`, and a fact of that kind turns up in the session or the report | the template, filled and copied to the repo root | Claude Code adds `.claude/settings.local.json` to the global excludes the first time it writes it (settings docs, read 2026-11-17); this file only by `/init`'s personal option under `CLAUDE_CODE_NEW_INIT=1`, into the repo's own `.gitignore` (memory docs, read 2026-11-17) |
| a `CLAUDE.local.md` no ignore rule matches | a finding: one `git add .` from a commit | the global excludes file, `git config core.excludesFile`, else `~/.config/git/ignore`, where the user's machine bootstrap may list it already; never the repo's `.gitignore` in a client repo, which is a commit there |
| a tracked `CLAUDE.local.md` | a finding: one person's notes shared with every clone | `git rm --cached`, then the row above; pushed with an identity string, `recreate-repo` |
| a `CLAUDE.local.md`, an `AGENTS.md`, and no `CLAUDE.md` or `.claude/CLAUDE.md` | a finding: the local file switches the `AGENTS.md` off for its owner | an `@AGENTS.md` line in the local file, as the template carries; `agent-instructions-scoping.md`, the user-scope rule or its copy beside this file, has why |

Of the three launch built-ins only `run` is in Claude's listing by
default: `/verify` runs only when the user types it (skills docs, read
2026-10-21), and `/run-skill-generator` likely the same (inferred).
**The payload's `skillOverrides` sets `run` to `user-invocable-only`**
(`claude/settings.json`, 2026-10-22), which hides it from Claude and
keeps `/run` for the user to type (settings reference, read 2026-11-03),
so on every account the payload deploys to the report names all three
as commands to type. Where a launch needs
more than a standard start, an env or credentials file or a mock
service, name `/run-skill-generator`, which records the recipe as a
project skill in `.claude/skills/run-<name>/`.

## Plugins

Look a name up with step 2's inventory, `--plugin <name>`, which reads
each marketplace clone's list, not only its `plugins/` folder: the
official list held 315 on 2026-10-21, among them the language-server
plugins below. **A language-server plugin spawns a binary it does not
install**, and the lookup says whether this shell's `PATH` has a file of
that name, which it never runs, and of a rustup proxy, which is there
either way, whether its component is installed:

| Plugin | Spawns |
| --- | --- |
| `pyright-lsp` | `pyright-langserver --stdio` |
| `csharp-lsp` | `csharp-ls` |
| `typescript-lsp` | `typescript-language-server --stdio` |
| `rust-analyzer-lsp` | `rust-analyzer`, rustup's proxy: the component of the toolchain the repo pins |

Measured 2026-10-21 from the marketplace entries, when none of the first
three was on Git Bash's `PATH` here; `rust-analyzer-lsp`'s row
2026-11-04, where `rust-analyzer` was on it, as rustup's proxy.
A missing binary's install is the payload's, in the config source's
machine bootstrap where it has one, by `capture-learning` from another
repo, bar a rustup component, which the register's row adds per machine.
**Each plugin's decision is the register's**, where the user's config
holds one, `<config>/plugin-register/README.md`, with refusals in its
`DECLINED.md`: which binaries the bootstrap installs, which plugins the
payload turns off and why, where each is enabled, its install command,
and the servers weighed for languages no official plugin covers. Read
both before recommending a plugin, and point there rather than restate
a row; with no register, check 3.1 and the table below are the whole of
it. `typescript-lsp`, for one, fits a TypeScript 5 or 6 repo and
never a TypeScript 7 one; Bash, YAML and Bicep servers were picked, and
KQL, T-SQL, TMDL and PowerShell ones declined (2026-11-03).

| Signal | May justify | Reuse or note |
| --- | --- | --- |
| Python, C#, TypeScript or Rust as the main language | its language-server plugin, in the repo's `.claude/settings.json` when only this repo wants it | check 3.1 first: installed and off is enable, not install; and its binary, above, Rust's a component on the pinned toolchain |
| a plugin the payload sets `false` | a per-repo enable, only against the payload's reason, which the register gives | check 3.1 |
| a synced plugin whose server matches a project server | a finding: one hides the other | check 3.2 |
| an `@modelcontextprotocol/sdk` dependency, or an MCPB `manifest.json` | `mcp-server-dev@claude-plugins-official`: `build-mcp-server`, `build-mcpb`, `build-mcp-app` | unexercised; the repo's own server is the MCP table's |
| a plan to ship the repo's server or skills as a plugin | nothing new | `ship-plugin`, a `paths:` skill listed from the first Read or Write of a `.claude-plugin/plugin.json` or `marketplace.json`; until then name that file, since typing the skill's name as a command answers `Unknown command` |
| a Salesforce DX project: `sfdx-project.json` at the root, `.forceignore`, a `force-app/` tree | `salesforce-development@claude-plugins-official`, enabled in this repo only | the user's choice per repo, with its costs below; never report it as refused |

**`salesforce-development`'s costs**, at the marketplace's pinned
`d3088edf` (read on GitHub, 2026-10-28; its `source.sha` in the
marketplace clone's `.claude-plugin/marketplace.json` says whether the
pin has moved). 39 hooks on 9 events, among them a `PreToolUse` hook on
every `Bash`, `Edit|Write|MultiEdit`, `Skill` and `Task|Agent` call and
one on each prompt, each a Git Bash spawn at the Hooks section's cost;
telemetry hooks, with a `:telemetry` command; advisories proposing
plugins not installed; three stdio servers, `salesforce-api-context`,
`salesforce-metadata-experts` and `salesforce-lsp`; and hooks that run
`python3`, a Store stub on this machine, where its README says a failed
hook denies a shell command that could deploy or delete (inferred, not
run). Its `PostToolUse` deploy of each edited file,
`sf-deploy-gate auto-deploy`, does nothing unless `SFDX_AUTO_DEPLOY=1`,
and never targets production. The signal is the plugin's own: its
skills read `sfdx-project.json` at the project root and default to
`force-app/main/default` (Salesforce's DX docs refused a fetch,
2026-10-28).

## MCP servers

The project template and its README, `<config>/mcp/README.md` §
"Servers (project scope)" where the user's config holds one, hold each
entry, its runtime and its placeholders: point there, never restate
them; with none, name a server by its own docs. Every row here is
project scope.

| Signal | May justify | Reuse or note |
| --- | --- | --- |
| Microsoft or Azure docs lookups | nothing new | `microsoft-learn-mcp`, at user scope |
| Claude Code or Agent SDK docs lookups | nothing new | `claude-code-docs`, at user scope |
| a GitHub remote | nothing new where `gh api user -q .login` returns the repo owner, `land-branch`'s first route since 2026-11-15: name that probe for the user to run in the repo, since this skill connects nothing and `gh` answers there by the repo's `user.name` | `github-mcp`, its token in a per-account variable, only where no `gh` login matches the owner; none at user scope, on purpose |
| an Azure DevOps remote | `azure-devops-mcp` | |
| `**/*.bicep`, `azure.yaml`, Azure SDK dependencies | `azure-mcp` | check 3.4 when the repo pins a tenant; its tools read secrets too, so a "never print secrets" line meets check 3.5 |
| the repo builds an MCP server | its own server, at local scope when it takes per-person credentials or reaches production data; in `.mcp.json` only against a mock | say what its data puts in the transcript; unexercised |
| Fabric items (`**/.platform`) | `microsoft-fabric-mcp`, `fabric-core` | both tenant-bound: check 3.4 |
| PBIP or TMDL files | `powerbi-modeling-mcp` | it writes to the model: say so |
| Eventhouse or KQL queries | `fabric-kqlendpoint` or `fabric-rti-mcp`, never both | |
| an Azure SQL database with a Data API Builder config | `sql-mcp` | |
| other libraries' documentation | nothing by default | say none is deployed; propose one only when asked |
