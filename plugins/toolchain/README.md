# toolchain

Makes `jq` and `uv` available to the skills and hooks of the plugins
that list this one as a dependency, and checks that `gh` is installed
and signed in. **A copy you installed yourself always wins**: the
plugin fetches a tool only when it is missing from your `PATH`, and a
machine that already has both, with `gh` installed and signed in,
fetches and prints nothing.

You rarely install it by name. A plugin that needs it, such as `git` or
`fabric`, lists it in `dependencies`, and Claude Code installs it with
that plugin from the marketplace. **A plugin you turn on from claude.ai
needs `toolchain` turned on there too**, or installed from the
marketplace (Claude Code docs, plugins/dependencies, read 2026-11-18).
To install it alone:

```bash
claude plugin install toolchain@<marketplace>
```

## What it fetches, and from where

At each session start, a `SessionStart` hook checks each tool:

| Tool | Version | Source |
| --- | --- | --- |
| `jq` | 1.8.2 | `https://github.com/jqlang/jq/releases/download/jq-1.8.2/` |
| `uv` and `uvx` | 0.13.7 | `https://github.com/astral-sh/uv/releases/download/0.13.7/` |

[hooks/tools.lock](hooks/tools.lock) pins each platform's file, from
the release itself, with its SHA-256 taken from the release's published
sums. A download whose SHA-256 differs is deleted, as is one that will
not run `--version`, and you see the install line instead. Builds exist
for Linux, macOS and Windows on x86_64 and arm64.

`gh` is never fetched: it needs you to sign in, so the plugin only
names its install line, or `gh auth login`. `pwsh` is not checked.
Nor is `az` here: plugins that never call it depend on this one too,
`git` among them, so the `fabric` plugin, whose skills do, checks it
with a session-start hook of its own (2026-11-20).

## Where it saves them

In the plugin's own data folder, `${CLAUDE_PLUGIN_DATA}/bin/`: under
`~/.claude`, `plugins/data/toolchain-<marketplace>/bin/`, which Claude Code
keeps across plugin updates and **deletes when you uninstall the
plugin**. Nothing is written anywhere else, and nothing is added to your
shell's `PATH` outside Claude Code. Uninstalling a plugin that pulled
this one in leaves it installed: `claude plugin prune` removes it then.

## Where the tools reach

- **The Bash tool**: the hook appends the folder to `PATH` through
  `CLAUDE_ENV_FILE`, for every Bash command in the session.
- **Not the PowerShell tool on Windows**: Claude Code passes it no
  variable holding a `/` or `\`, so the session message names the
  `winget` line for a copy that works everywhere.
- **Not other plugins' hooks, nor hooks in your settings**, which do
  not see that `PATH` (observed on Claude Code 2.1.327, 2026-11-18). A
  dependent's hook looks in the folder itself, as the next section says.

## When something is missing

The hook stays silent while every tool is present. Otherwise it shows
one message at session start, saying what it fetched or what is missing
and how to install it, and tells Claude the same, so a skill whose
script fails says why:

| Tool | Windows | macOS | Linux |
| --- | --- | --- | --- |
| `jq` | `winget install jqlang.jq` | `brew install jq` | `sudo apt install jq`, or your package manager's |
| `uv` | `winget install astral-sh.uv` | `brew install uv` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| `gh` | `winget install GitHub.cli` | `brew install gh` | [cli/cli's install page](https://github.com/cli/cli#installation) |

The hook never blocks a session, and every failure, a download blocked
by a proxy included, ends at that message. It needs `bash`, `curl` or
`wget`, and `sha256sum` or `shasum`, plus `tar` to unpack `uv` on Linux
and macOS and `unzip` on Windows: Git for Windows ships all of them. On
Windows without Git for Windows the hook cannot start, and Claude Code
shows a `hook error` notice each session.

## Turning the downloads off

Set **Fetch missing tools** off in `/config`, or from your shell:

```bash
printf '{"fetch":"false"}' | claude plugin configure toolchain@<marketplace> --values-stdin
```

The hook then fetches nothing and names each missing tool's install
line. An unset option counts as on.

## For a plugin that needs these tools

List it in `dependencies`, in `plugin.json` or the marketplace entry,
naming its marketplace, the `name` in the `marketplace.json` this
plugin is installed from:

```json
"dependencies": [
  { "name": "toolchain", "marketplace": "<marketplace>" }
]
```

**Name the marketplace even when it is your plugin's own.** A plugin
turned on from claude.ai loads as `<name>@synced`, with no marketplace,
and Claude Code counts its dependency as met by a claude.ai plugin of
the same name only when the entry names a marketplace. A bare
`"toolchain"` names none: it resolves in the declaring plugin's own
marketplace, which a synced plugin lacks (Claude Code docs,
plugins/dependencies, read 2026-11-18). From a marketplace install, the
bare name, `"toolchain@<marketplace>"` and the form above each
installed `toolchain` with `fabric` (a throwaway config, 2.1.327,
2026-11-18). A plugin in another marketplace also needs that
marketplace's `marketplace.json` to list `<marketplace>` in
`allowCrossMarketplaceDependenciesOn`, unless `toolchain` is already
installed and enabled at the same scope.

A skill's commands then find the tools on `PATH`. A hook does not: look
for the tool on `PATH`, then
in `<your data folder>/../toolchain-*/bin/`, and run it there by its
full path, as the `fabric` plugin's
[edit gate](../fabric/hooks/fabric-edit-gate.sh) does. A `C:/` path
globs as it is, but its colon splits a `PATH` entry.

**Adding the dependency to an installed plugin disables it** until
toolchain is installed beside it: `claude plugin list` reads
`Dependency "toolchain@<marketplace>" is not installed`, and
`claude plugin install toolchain@<marketplace>` clears it. A fresh
install of the dependent installs toolchain with it, `(+ 1 dependency:
toolchain)` (both seen in a throwaway config, 2.1.327, 2026-11-18).
