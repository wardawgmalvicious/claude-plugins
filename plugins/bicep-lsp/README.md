# bicep-lsp

Starts the Bicep language server for `.bicep` files in Claude Code, so
compiler diagnostics and linter findings reach Claude after an edit
(none for the first edit, made while the server starts), and it can look
up symbols.

## Install the server first

**The plugin ships no server.** Its `.lsp.json` starts `bicep-ls` from
your `PATH`, the command the `Azure.Bicep.LangServer` .NET tool
installs:

```bash
dotnet tool install --global Azure.Bicep.LangServer
```

The tool needs the .NET SDK, and its 0.49.2 release targets .NET 10
(read from its NuGet package, 2026-11-17). Make sure the .NET global
tools folder, `~/.dotnet/tools`, is on your `PATH`.

## Install the plugin

```text
/plugin install bicep-lsp --marketplace wardawgmalvicious/claude-plugins
```

That one step adds the marketplace too, on Claude Code 2.1.275 or
later.

**`claude plugin validate` passes a plugin whose `.lsp.json` is
invalid** (2.1.326): its only sign is `Provides: not listed, as a file
could not be read` in place of the server's line, and it never checks
that the server is on your `PATH`, so a pass says nothing about whether
the server starts.
