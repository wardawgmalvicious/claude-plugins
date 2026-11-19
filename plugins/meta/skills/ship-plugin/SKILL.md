---
name: ship-plugin
model: inherit  # inert anyway: a paths: skill has no cold slash route
effort: xhigh
disable-model-invocation: false
description: "Ships a Claude Code plugin so it installs and runs where its users are. A plugin gets no build step, so a .mcp.json pointing at a gitignored dist/ installs cleanly and its server never starts; chat, Cowork and Claude Code each load a different part of a plugin, and a top-level bin/ makes chat, Cowork and org sync refuse it; version means something different for a local-path marketplace, one added by source and one synced to a claude.ai organization; a synced marketplace is labelled with its repository's owner/repo and nothing renames it, and Delete source removes every plugin for every member. Ends with an install test in a throwaway CLAUDE_CONFIG_DIR (claude plugin validate, install --config, claude mcp list) and claude plugin eval for the plugin's own skills. Not for a mod, which plugin-authoring makes."
when_to_use: "Use when writing or changing a plugin.json or marketplace.json, turning an MCP server or a set of skills into a plugin, making one depend on another plugin, releasing or versioning one, syncing a marketplace to a claude.ai organization, or when a plugin's server never connects or shows no tools, an update changes nothing, a plugin stays disabled over a dependency, or chat ignores part of a plugin."
paths:
  - "**/.claude-plugin/*.json"
---

# Ship a plugin: from a repo to an install that runs

A plugin that validates can still fail every user it reaches: its server
never starts, chat skips half of it, an update never arrives, or an
organization's members see it under a name nobody chose. Each failure is
silent, and each depends on **the route the plugin travels**. This skill
names the route first, then checks what ships, what each surface loads,
what `version` does, what an org sync fixes for good, and how to test
the install and the plugin's own skills without the user's real config.

It does not teach plugin layout or components: the Claude Code docs'
`plugins/components` page and `claude plugin validate` own those. A mod,
a pane or a hook module that changes Claude Code's own interface, is
`plugin-authoring`'s. Submitting to Anthropic's directory is out of
scope.

This skill is path-scoped to `.claude-plugin/*.json`, so it is listed
only once a session reads or writes a `plugin.json` or
`marketplace.json` in its working directory. A plugin's own repository
holds both; anywhere else it costs nothing.

Every claim below was read in the Claude Code and claude.com docs on
2026-10-22 against Claude Code 2.1.308, unless it says otherwise.
Past it, its `references/`, then the live page: code.claude.com by the
`claude-code-docs` MCP server or
`curl -s https://code.claude.com/docs/en/<page>.md`, and claude.com,
which that server does not cover, by
`curl -s https://claude.com/docs/<path>.md`. A live page that
contradicts a line here wins: say so, act on the page, and route the
fix by `capture-learning`, bar a dated measured line that names the
page it overrules and the call that measured it, which a page changed
since its date sends back to re-measure. An observed claim is cited or
marked pending a doc check, and stands, marked observed, only where no
page covers it, as step 5's label claim does: silence is no
contradiction, and a page that later covers it wins.

## 1. Name the route

Ask which route the plugin travels, or read it from the repo: a
`marketplace.json` alone says little, since one repository can serve
every route at once.

| Route | Who gets it | What `version` does | How a change arrives |
| --- | --- | --- | --- |
| Local-path marketplace, `marketplace add ./path` | whoever reads the path: the author, or a team on a shared directory | nothing: current files load each session | the next session or `/reload-plugins`; no dependency install |
| Marketplace added by source: GitHub, git URL | anyone who can clone it with credentials already on their machine | `plugin.json`, then the entry, else the commit SHA | `claude plugin update`; auto-update is off until a user or admin turns it on; none past a `ref` pinned to a commit (below) |
| claude.ai organization sync | members in chat, in Cowork, and in Claude Code sessions signed in to that account | not read: claude.ai records its own | a push to the default branch with **Sync automatically** on, or **Re-sync**; tags are not read |
| Claude Code managed settings | every machine that receives them | as added by source | auto-update, when managed settings turn it on; none past a `ref` pinned to a commit (below) |
| A repo's committed settings: `extraKnownMarketplaces` and `enabledPlugins` in its `.claude/settings.json` | each contributor who trusts the folder and installs the plugin in that clone (below) | as for the marketplace's route | as for the marketplace's route |

**A local-path test proves the least.** The plugin loads in place from
the source directory, with no copy and no dependency install, so it sees
whatever the author's build left there. Every other route copies the
plugin into the cache and sees only what was committed.

**A repo's committed `enabledPlugins` installs nothing.** Each
contributor runs, once per clone, or at `--scope user` for every
project:

```bash
claude plugin install <name>@<marketplace> --scope project
```

Until then the plugin does not load at session start; with its
marketplace registered, `/plugin`'s **Errors** tab shows `not cached` or
`Plugin "<name>" is enabled in project settings but isn't installed here`,
and with neither message, the marketplace is missing: add it first.
The repo's
`extraKnownMarketplaces` registers nothing in a folder the contributor
has not trusted, without a message. Two kinds of plugin skip the
install: one in a seed directory (plugins/org § "Seed containers and
CI"), and a relative-path one: listed in a marketplace added from a
local path, it loads at session start; in a git marketplace,
`/reload-plugins` loads it for that session alone, and
`CLAUDE_CODE_SYNC_PLUGIN_INSTALL=1` for one `-p` run (plugins/loading,
plugins/org, read 2026-11-14).

**A `ref` set to the full lowercase SHA of a commit on a branch or tag
holds a marketplace there**: a
`github` or `git` source then moves on neither a refresh nor an
auto-update, so an admin can pin a reviewed commit. Update Claude Code
on every machine first, since a client before v2.1.324 cannot load a
marketplace pinned so. A reserved name such as
`claude-plugins-official` refuses a SHA, and a plugin entry with its
own remote source still updates: pin that entry too, by its `sha`
(plugins/marketplace-reference, read 2026-11-14).

## 2. Ship what runs

**Nothing builds a plugin.** Claude Code's only install step is a Node.js
dependency install into the cached copy, and it runs only when the
plugin root holds both a `package.json` and a supported lockfile. Its
limits, each checked against the `plugins/loading` page on 2026-11-07:

- the lockfile is `npm-shrinkwrap.json` or `package-lock.json` at
  `lockfileVersion` 2 or 3, or `bun.lock` at 2 or lower; `yarn.lock`,
  `pnpm-lock.yaml` and `bun.lockb` get no install
- every dependency is a registry package pinned exactly, fetched over
  `https` unless from the installing user's own default npm registry; a
  git, GitHub, folder, workspace or linked dependency gets no install
- frozen resolution: the lockfile's exact versions, and no install when
  `package.json` and the lockfile list different dependencies
- a separate install folder holding only a copy of the dependency list,
  so the plugin's `.npmrc`, `.env` and `bunfig.toml` are not read (so a
  registry or token set there cannot reach the install, an inference)
- `--ignore-scripts`, so nothing compiles, native modules included
- npm `overrides` or Bun `patchedDependencies` get no install
- 60 seconds, then it counts as failed
- "You can't turn the automatic install off"

So a `.mcp.json` pointing at a gitignored `dist/` installs cleanly and
its server never starts. A plugin whose install fails or is skipped
still loads; `/plugin` and `claude plugin list` note the missing
`node_modules`. An update the user starts can retry an install that
failed or timed out, even at an unchanged version; one skipped for its
lockfile or a missing package manager stays skipped.

Pick one way out:

1. **Commit a bundle.** A single-file bundle in a plugin folder that
   holds no `package.json`, so no install runs, with the repo's test
   script regenerating it so a stale bundle shows as a diff. One session
   reached `✔ Connected` from a fresh clone this way, with an esbuild
   CommonJS bundle (observed once, 2.1.308, 2026-10-22).
2. **Ship JavaScript and an exact npm lockfile**, registry dependencies
   only, and let the install run. An npm lockfile reaches the most users;
   Claude Code runs that lockfile's package manager from the user's
   `PATH` and tries no other.
3. **Install from a `SessionStart` hook into `${CLAUDE_PLUGIN_DATA}`**,
   for what the install cannot provide: lifecycle scripts, Python, Yarn
   or pnpm, git dependencies. The `plugins/components` page has the hook.

Then, whatever the way:

- **Durable files go in `${CLAUDE_PLUGIN_DATA}`.** `${CLAUDE_PLUGIN_ROOT}`
  names a per-version cache directory and moves on every update.
- **Nothing outside the plugin folder is copied**, so a script reading
  `../shared` finds nothing in the cache. A symlink inside the plugin is
  kept, one to elsewhere in the marketplace is copied in its place, and
  one leading outside the marketplace is skipped. Installed from a local
  path, or from a `command` source in its default `copy` mode, a plugin
  keeps only the symlinks that resolve inside itself and skips the rest
  (plugins/host-marketplace, read 2026-11-15).
- **A component path that escapes the plugin is rejected**, whether
  `plugin.json` or a marketplace entry declares it, loaded in place or
  from the cache: a path outside the plugin as written, such as
  `../shared-utils`, or a symlink leading outside it, bar one to another
  plugin in the same marketplace. On macOS and Linux a path holding a
  backslash anywhere is rejected even inside the plugin, so a component
  declared with backslashes loads on Windows only: write forward
  slashes, `./commands/deploy.md`. Each shows as a
  `path escapes plugin directory` error, and the plugin loads without
  that component (plugins/loading, read 2026-11-15). Since 2.1.325,
  loading skips and `claude plugin validate` reports some unsafe paths
  and links in the plugin's folder
  (Claude Code `CHANGELOG.md` 2.1.325, read 2026-11-15).
- **Git LFS files arrive as pointer files.** No clone fetches LFS.

**A plugin can depend on another**: a `dependencies` array in
`plugin.json`, or in the marketplace entry for a plugin with none
(plugins/dependencies, read 2026-11-18).

- **A bare name resolves only in the declaring plugin's own
  marketplace**, so the dependency ships in every marketplace that ships
  a dependent. One from another marketplace is named, `<dep>@<marketplace>`
  or the object's `marketplace`, and the root marketplace lists that
  marketplace in `allowCrossMarketplaceDependenciesOn`. Without that, and
  unless the user already has the dependency enabled at the same scope,
  an entry's dependency refuses the install, `... which is not in the
  allowlist`, while a `plugin.json` one installs without it and the
  plugin fails to load (plugins/dependencies, read 2026-11-18).
- **Name the marketplace in a plugin users may turn on from claude.ai**,
  `{ "name": "<dep>", "marketplace": "<marketplace>" }`, even its own: a
  synced copy loads as `<name>@synced`, with no marketplace, and counts
  only an entry naming one as met, by the dependency from that
  marketplace or a claude.ai plugin of its name (plugins/dependencies,
  read 2026-11-18). Tell those users to turn the dependency on there too.
- **Adding a dependency to an installed plugin disables it** at the
  next load, `Dependency "<dep>" is not installed`, until each user
  installs the dependency; a fresh install brings it,
  `(+ 1 dependency: <dep>)` (plugins/troubleshooting, read 2026-11-18)
  (observed 2026-11-18, 2.1.327). Uninstalling the dependent leaves it
  for `claude plugin prune` (plugins/install, read 2026-11-18).
- **A tool a dependency's `SessionStart` hook fetches**, way 3 above,
  reaches the Bash tool by a `PATH` line in `CLAUDE_ENV_FILE`. On
  Windows the PowerShell tool gets no value holding `/` or `\`, and no
  variable at all once any line reads `$PATH` (hooks, read 2026-11-18).
  Other plugins' hooks did not see that `PATH` (observed 2026-11-18, 2.1.327),
  so a dependent's hook looks in `${CLAUDE_PLUGIN_DATA}/../<dep>-*/bin/`.

## 3. Check each component against each surface

A surface skips what it does not load, so a plugin can look complete in
Claude Code and partial in chat. The rules that bite:

- **A local MCP server**, any command the app starts, `.mcpb` included,
  is ignored in chat, and loads in Cowork only when the session runs on
  the user's computer.
- **A remote `http` or `sse` server** is listed in chat on the plugin's
  **Connectors** tab and works once the user connects it there. Setting
  a plugin's availability adds no connector: an Owner also adds it in
  **Organization settings > Connectors**.
- **A server referencing `${user_config.*}`** is ignored in chat when the
  URL holds the reference, and in Cowork when a referenced option has no
  default, since Cowork never prompts. Only Claude Code prompts.
- **A top-level `bin/`** makes chat and Cowork refuse the whole plugin,
  and org sync reject it with `Plugin contains a top-level bin/
  directory` while syncing the rest. Keep executables in the plugin's
  scripts folder and call `${CLAUDE_PLUGIN_ROOT}/scripts/<name>`.
- **Agents and hooks** load in Cowork and Claude Code, not chat; LSP
  servers, output styles and themes load in Claude Code only.
- **A dependency that works by a hook does nothing in chat**, so a
  dependent's skill there finds only the sandbox's tools (an inference
  from the line above).
- **A plugin's `settings`**, a root `settings.json` or the manifest's
  `settings` key, loads in Claude Code only, and only its `agent` key
  still works: 2.1.323 deprecated it, warning at startup, in `claude
  plugin list` and in `claude plugin validate`, and removed the
  `subagentStatusLine` setting (Claude Code `CHANGELOG.md`, read 2026-11-14).
  Each form still ran the plugin's agent as the main thread, its prompt
  and model (observed 2026-11-14, 2.1.325). code.claude.com no longer
  documents the component, so a page that covers it later wins. Build
  no new plugin on it: point users to their own `agent` setting or
  `--agent`, as the warning does.

The full table is in
[references/surfaces-and-org-sync.md](references/surfaces-and-org-sync.md).

**Chat runs a skill's scripts in claude.ai's code execution sandbox**,
so a script tested only on the author's machine is untested there. A
probe of a personal chat read Ubuntu 24.04.5 x86_64, root in
`/home/claude`, Python 3.13.18, poppler's `pdftotext` 24.02.0, a POSIX
locale with UTF-8 stdout, and `pypi.org` answering 200 (observed
2026-11-15); an organization's network setting may differ. What a
Windows author's own run misses:

- **The host's tools are not the sandbox's.** Git Bash's `pdftotext` is
  xpdf 4.06 (observed 2026-11-15), whose `-v` exits 99 where poppler's
  exits 0, so `pdftotext -v || echo missing` calls it missing: probe
  with `command -v`, and the version with
  `pdftotext -v 2>&1 | head -n 1`. Python 3.14 and older write piped
  stdout on Windows in the ANSI code page, cp1252 here, unless
  `PYTHONUTF8=1` (observed 2026-11-15, Python 3.13); 3.15 made UTF-8
  the default (PEP 686).
- **Chat runs a script as `python3 -I`** (reported: an organization's
  plugin-repo session, 2026-10-27), and `-I` leaves the script's folder
  off `sys.path`: a script importing its sibling exited 1,
  `ModuleNotFoundError`, under `-I`, and ran without it (observed
  2026-11-15, Python 3.13).
- **Test it there**: zip the scripts, checks that build their own
  inputs and run each script by `sys.executable -I`, and a prompt asking
  for each tool's version, `locale` and `sys.stdout.encoding`, then
  every check against its stated result; upload it to a chat with code
  execution on. Read each result from the tool call's Response panel,
  not the reply, which dropped a line of one output before correcting
  itself (observed 2026-11-15). A probe stops first on a marker of the
  sandbox, which has `/mnt/user-data` where Git Bash has no `/mnt`, so
  pasted elsewhere it reports nothing as the sandbox's:
  `( test -d /mnt/user-data || { echo "not claude.ai's sandbox"; exit 1; }; echo "claude.ai's sandbox" )`.
  The user's Bash coding rule, where their config holds one, has the
  measurement; with none, this line is the whole of it.

A Linux container built to the probe's values stands in locally, but a
pass there is not a pass in chat, which still decides a release. Beyond
that probe, nothing here was run in chat or Cowork: say so before
promising a behaviour there.

## 4. Decide what `version` does

Choose per release line, after step 1's route:

- **Bump `version` on every release**: users stay on their cached copy
  until the string changes, and `claude plugin update` prints `<name> is
  already at the latest version (<version>).` for every push between.
- **Omit `version`** from both `plugin.json` and the marketplace entry:
  each commit is a new computed version, the commit SHA, which also
  names the cache directory (12 characters there, observed 2026-10-22).
  It still waits for an update or auto-update.
- **Never set it in both files.** `plugin.json` wins without warning at
  load, and `claude plugin validate` reports `Entry declares version
  "<a>" but <path>/plugin.json says "<b>"`.
- **A dependent's `version` range resolves only against
  `<name>--v<version>` tags** on the dependency's source repository,
  the marketplace's for a relative path, so a plugin that omits
  `version` can be depended on but not constrained. A relative-path
  dependency with no tag in range installs the current copy, and the
  dependent stays disabled, `Requires "<dep>" <range>, installed
  <version>` (plugins/dependencies, read 2026-11-18).

What follows from the choice:

- `claude plugin validate --strict` fails a missing `version`; drop
  `--strict` where `version` is omitted on purpose.
- `claude plugin tag` needs a `version`, and checks `plugin.json` and
  the entry agree before it creates `<name>--v<version>`.
- `engines["claude-code"]` in `plugin.json` states the Claude Code
  versions the plugin supports: a client outside that range does not
  install, update or load it, and install and update pick the newest
  plugin version that fits
  (Claude Code `CHANGELOG.md` 2.1.323, read 2026-11-15). So a release
  that raises the floor leaves an older client on the newest version
  still in its range, an inference. No plugin page documents the key or
  the range's form (plugins/manifest-reference, read 2026-11-15): leave
  the form unstated rather than guess it; a page that covers it wins.
- An org-synced member gets claude.ai's version whatever the file says,
  and a local-path user gets the current files.

## 5. Before an organization sync

The sync is stricter than `marketplace add`, and two of its steps cannot
be undone. Check with the user, before they open **Sync from GitHub**:

- **The repository is private or internal** on github.com and gitlab.com.
- **Each plugin source is `github`, `url`, `git-subdir`, or a path from
  `./`.** A bare name under `metadata.pluginRoot` is rejected as an
  unsupported source: write `./plugins/<name>`.
- **No plugin has a top-level `bin/`** (step 3).
- **Each dependency entry names its marketplace** (step 2), and the
  dependency is synced too: a claude.ai plugin meets a dependency only
  when the dependent also loads from claude.ai, and a marketplace
  dependent reads it `is not installed` until the dependency is
  installed from its marketplace (plugins/dependencies and
  plugins/troubleshooting, read 2026-11-18). Whether turning a plugin on
  turns its dependency on, no page says (claude.com org-sync, read
  2026-11-18).
- **The marketplace's label is its repository's `<owner>/<repo>`, and
  nothing changes it.** The dialog's "Marketplace name" field is a
  read-only echo of the repository picked above it, the Marketplaces
  tab's `⋯` menu offers no rename, and `marketplace.json` has no field
  for it: its `name` is the install id, not this label (user-observed on
  a Team plan, 2026-10-22 and 2026-11-02; no claude.com page covers it,
  `org-sync` and `admin` read in full on 2026-11-07; Enterprise is
  unseen). Name the repository with the label in
  mind; whether renaming it later relabels the marketplace, or breaks
  the sync, is untested.

After it syncs:

- **Never use Delete source to fix one plugin.** It "permanently deletes
  every plugin in that marketplace for every member".
- **A synced plugin cannot be reverted.** Fix it in the repository, push
  to the default branch, and **Re-sync**; meanwhile set its availability
  to **Not available**, and any Enterprise group's own setting too.
- **A plugin's `name` is permanent.** Change the label with `displayName`;
  a rename that cannot wait goes through `marketplace.json`'s `renames`.
- **A developer with both routes** gets the managed-settings copy; Claude
  Code reports the synced copy as not loaded.

## 6. Test the install in a throwaway config

Test what users get, not the working tree, and not in the user's own
config. Each Bash call is a fresh shell, so set `CLAUDE_CONFIG_DIR` on
every command, and use a scratch directory the session's tools can reach:

```bash
git clone --branch <branch> <repo-url> <scratch>/clone   # committed files only
mkdir <scratch>/config                                   # empty: no plugins, settings or sign-in
CLAUDE_CONFIG_DIR=<scratch>/config claude plugin validate <scratch>/clone
CLAUDE_CONFIG_DIR=<scratch>/config claude plugin validate <scratch>/clone/<plugin-dir>
CLAUDE_CONFIG_DIR=<scratch>/config claude plugin marketplace add <scratch>/clone
CLAUDE_CONFIG_DIR=<scratch>/config claude plugin install <plugin>@<marketplace> --config <key>=<value>
cd <scratch> && CLAUDE_CONFIG_DIR=<scratch>/config claude mcp list
CLAUDE_CONFIG_DIR=<scratch>/config claude plugin details <plugin>@<marketplace>
```

- **Validate each plugin directory too.** A marketplace run opens no
  skill, hook or MCP file of a plugin kept in another directory.
- **`validate`, `plugin list` and `details` do not check `.lsp.json`.**
  `claude plugin validate` doesn't read it, and an invalid entry skips
  the whole file at load. A copy of a plugin whose `.lsp.json` had
  `extensionToLanguage` emptied passed both validates, `claude plugin
  list` read it `✔ enabled`, and `details` still counted `LSP servers
  (1)` (2.1.319, 2026-11-07). `/plugin`'s **Errors** tab shows
  `Invalid LSP server config for ".lsp.json"`.
- **Pass `--config` for every required option.** The shell install never
  prompts for `userConfig`, and prints `userConfig options not yet set`
  when one is missing.
- **A plugin with `dependencies`**: the install prints
  `(+ 1 dependency: <dep>)`, and `claude plugin list` shows no
  `Dependency "<dep>" is not installed`. To develop the two together,
  load both: `claude --plugin-dir <dep> --plugin-dir <plugin>`
  (plugins/dependencies, read 2026-11-18).
- **Run `claude mcp list` from the scratch directory**, outside the repo,
  so a project `.mcp.json` cannot answer for the plugin's server, which
  is listed as `plugin:<plugin>:<server>`.
- **`claude plugin details`** shows the component inventory and the
  always-on token cost the plugin adds to every session.

That recipe ran twice with no sign-in (2.1.308, 2026-10-22). Added from a
local path, the clone loads in place with no dependency install, which
fits a committed bundle. **A plugin relying on step 2's dependency
install needs the copied route**: add the pushed branch as
`<owner>/<repo>#<branch>` instead, so the install runs in the cache.
That variant follows from the loading reference and was not run here.

It is the plugin counterpart of the fresh-session `claude mcp list`
check in `claude-config-scoping.md`.

## 7. Test the plugin's own skills

Step 6 proves the plugin installs and its server connects, not that its
skills change what Claude does. `claude plugin eval`, Claude Code
2.1.269 or later, runs that:

- **Cases live in the plugin's `evals/`**: a directory per case with a
  `prompt.md` or `case.yaml` and at least one grader. `claude plugin eval
  init` from the plugin root interviews the user and writes them.
- **Each case runs three times with the plugin and three without**, so
  the report's `Δ` is what the plugin added. Every run is a full
  `claude -p` child on the user's plan or bill: pass `--max-cost-usd`.
- **No real MCP server starts** unless asked. A tool answers from
  `evals/mocks/<server>/<tool>.md`, and a tool without one is not
  available; `--allow-real-servers` runs the real process, as the user,
  outside the run's sandbox.
- **The report stays local when Claude starts the run**; from the user's
  own shell, signed in to a claude.ai plan with artifacts, it publishes
  as a private artifact unless `--no-publish`. Never add
  `--publish-report` unasked.
- **A non-interactive run cannot answer the trust prompt** and exits 1:
  pass `--trust-plugin` only for a plugin the user would run.
- **A case granted Bash or PowerShell fails on native Windows**, which
  has no sandbox backend: each run is refused and scores 0, so run those
  suites under WSL2.
- **Gitignore each suite's `results/`**: `evals/results/` in the
  plugin's own `.gitignore`, or `/<plugins dir>/*/evals/results/`, such
  as `/plugins/*/evals/results/`, in a marketplace's root one, where a
  bare `evals/results/` matches only a root `evals/`, as a pattern with
  a slash before its end is relative to its `.gitignore` (git-scm.com
  `gitignore`, read 2026-11-14).

The case format, graders, mocks and options are in
[references/plugin-eval.md](references/plugin-eval.md).

## 8. Constraints

- **Name the route before advising on `version` or updates.** The same
  advice is right on one route and a trap on the next.
- **Never test in the user's real config.** Install into a throwaway
  `CLAUDE_CONFIG_DIR`, from committed files.
- **Never promise chat or Cowork behaviour** from a Claude Code test.
- **Never recommend Delete source** to fix a synced plugin or its name.
- **The repository's name, which the org sync shows as the marketplace's
  label, and the plugin `name` are the user's to choose**,
  before the sync; ask rather than default.
- **Bound every eval run** with `--max-cost-usd`, and publish no report
  the user did not ask to publish.
