# yaml-lsp

Starts the YAML language server for `.yml` and `.yaml` files in Claude
Code, so syntax and schema errors, such as a GitHub Actions workflow
that breaks its schema, reach Claude after an edit (none for the first
edit, made while the server starts), and it can look up symbols.

## Install the server first

**The plugin ships no server.** Its `.lsp.json` starts
`yaml-language-server --stdio` from your `PATH`, the npm package of that
name:

```bash
npm install --global yaml-language-server
```

## Install the plugin

```text
/plugin install yaml-lsp --marketplace wardawgmalvicious/claude-plugins
```

That one step adds the marketplace too, on Claude Code 2.1.275 or
later.

**`claude plugin validate` passes a plugin whose `.lsp.json` is
invalid** (2.1.326): its only sign is `Provides: not listed, as a file
could not be read` in place of the server's line, and it never checks
that the server is on your `PATH`, so a pass says nothing about whether
the server starts.
