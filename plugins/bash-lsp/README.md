# bash-lsp

Starts the Bash language server for `.sh` files in Claude Code, so
shellcheck's diagnostics reach Claude after an edit (none for the
first edit, made while the server starts) and it can look up a
function's definition and references.

## Install the server first

**The plugin ships no server.** Its `.lsp.json` starts
`bash-language-server` from your `PATH`, and the server runs
`shellcheck` from your `PATH` for its diagnostics:

```bash
npm install --global bash-language-server
```

Then install `shellcheck`, for example `winget install koalaman.shellcheck`
on Windows, `brew install shellcheck` on macOS, or your distribution's
`shellcheck` package. Without it the server starts with no shellcheck
diagnostics.

## Install the plugin

```text
/plugin install bash-lsp --marketplace wardawgmalvicious/claude-plugins
```

That one step adds the marketplace too, on Claude Code 2.1.275 or
later.

**`claude plugin validate` passes a plugin whose `.lsp.json` is
invalid** (2.1.326): its only sign is `Provides: not listed, as a file
could not be read` in place of the server's line, and it never checks
that the server is on your `PATH`, so a pass says nothing about whether
the server starts.
