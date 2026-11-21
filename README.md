# claude-plugins

A [Claude Code plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces)
of skills for Microsoft Fabric, Power BI, git and GitHub work, and
Godot games. The
marketplace is named `wardawgmalvicious`, so each plugin installs as
`<plugin>@wardawgmalvicious`. Most of these skills were written on
Windows and say so where a step is Windows-only.

## Install

Add the marketplace once, in Claude Code:

```text
/plugin marketplace add wardawgmalvicious/claude-plugins
```

Then install a plugin by its name in the table below:

```text
/plugin install <plugin>@wardawgmalvicious
```

The same commands run from a shell as `claude plugin marketplace add …`
and `claude plugin install …`. Plugins carry no version, so an install
tracks this repo's commits, and `/plugin marketplace update wardawgmalvicious`
fetches the latest.

## Plugins

| Plugin | What it covers | Platforms | Install |
| --- | --- | --- | --- |
| `fabric` | Microsoft Fabric and Power BI items, the REST API and `fab` CLI, deployment, security and governance; an agent and a hook load an item's skill before it is edited | Claude Code | `/plugin install fabric@wardawgmalvicious` |
| `git` | Logical commits, code review, landing a branch through a pull request, pruning branches | Claude Code | `/plugin install git@wardawgmalvicious` |
| `github` | Auditing a repo's settings and community files, a Projects board for issues, recreating a repo after a pushed leak | Claude Code | `/plugin install github@wardawgmalvicious` |
| `github-issues` | A repository's backlog as issues on a GitHub Projects board: filing an issue as a brief, moving its card, working it from the claim to the branch landed; it needs a board from `github`'s `provision-board` | Claude Code | `/plugin install github-issues@wardawgmalvicious` |
| `meta` | Claude Code itself: agent setup audits, finding past sessions, user-scope `CLAUDE.md`, session cost, instruction placement, shipping plugins | Claude Code | `/plugin install meta@wardawgmalvicious` |
| `essentials` | Your claude.ai Instructions for Claude block and a Project's instructions | claude.ai chat, Cowork, Claude Code | `/plugin install essentials@wardawgmalvicious` |
| `admin` | A claude.ai organization's Organization instructions, for its Owners | claude.ai chat, Cowork, Claude Code | `/plugin install admin@wardawgmalvicious` |
| `game-dev` | Godot 4 games from files and the command line on Windows: a pinned editor, static typing, hand-edited scenes, pixel art, headless runs and export, Steam through GodotSteam | Claude Code | `/plugin install game-dev@wardawgmalvicious` |
| `toolchain` | The `jq` and `uv` other plugins run, fetched pinned and checksum-checked into its own data folder when missing, and a check that `gh` is signed in; `fabric`, `git` and `github-issues` install it as a dependency, [see its README](plugins/toolchain/README.md) | Claude Code | `/plugin install toolchain@wardawgmalvicious` |
| `bash-lsp` | Bash language server for `.sh` files; [install the server first](plugins/bash-lsp/README.md) | Claude Code | `/plugin install bash-lsp@wardawgmalvicious` |
| `yaml-lsp` | YAML language server for `.yml` and `.yaml` files; [install the server first](plugins/yaml-lsp/README.md) | Claude Code | `/plugin install yaml-lsp@wardawgmalvicious` |
| `bicep-lsp` | Bicep language server for `.bicep` files; [install the server first](plugins/bicep-lsp/README.md) | Claude Code | `/plugin install bicep-lsp@wardawgmalvicious` |

**The language-server plugins ship no server**: each starts a binary
from your `PATH`, which its README names.

## Other agents: the `skills` CLI

For an agent other than Claude Code, such as Codex or Cursor, the
[`skills` CLI](https://www.npmjs.com/package/skills) reads the same
marketplace file and installs the skills each plugin lists:

```bash
npx skills add wardawgmalvicious/claude-plugins
```

**This route is untested outside Claude Code.** A skill that relies on
something only Claude Code provides, such as `${CLAUDE_SKILL_DIR}` or
the `AskUserQuestion` tool, may not run in another agent.

## Contributing, security and licence

- [CONTRIBUTING.md](CONTRIBUTING.md): how a change here reaches the
  plugins.
- [SECURITY.md](SECURITY.md): report a security hole privately.
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
- [MIT](LICENSE).
