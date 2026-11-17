# claude-plugins

A [Claude Code plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces)
of skills for Microsoft Fabric, Power BI, git and GitHub work. The
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

No plugins are published yet.

| Plugin | What it covers | Platforms | Install |
| --- | --- | --- | --- |
| *none yet* | | | |

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
