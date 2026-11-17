# Security

**Report a security hole privately**, by the **Report a vulnerability**
button on this repo's
[Security tab](https://github.com/wardawgmalvicious/claude-plugins/security).
Please do not report one in an issue, a pull request or anywhere else
public, where it is disclosed before it is fixed.

## In scope

- Every plugin under `plugins/`: its skills, and any script, hook or
  MCP server configuration it ships.
- The marketplace file, `.claude-plugin/marketplace.json`.

A plugin runs with your Claude Code permissions, and a skill's script
runs on your machine. Read what a plugin ships before you install it.

## Supported versions

Plugins here carry no version, so an install tracks this repo's commits:
only the latest commit on `main` gets fixes. A fix arrives when you run
`/plugin marketplace update wardawgmalvicious`, or by itself where you
turned on auto-update for this marketplace in `/plugin`.
