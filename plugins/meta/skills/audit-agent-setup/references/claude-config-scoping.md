# Claude Code configuration: what belongs where

## The scope table

| File | Committed? | Reaches | Put here |
| --- | --- | --- | --- |
| `~/.claude/settings.json` | no — machine-local | every session on the machine | model and effort defaults, `permissions.defaultMode`, hooks that must run everywhere |
| `~/.claude.json` → top-level `mcpServers` | no | every session on the machine | **user-scope** MCP servers only |
| `%APPDATA%\Claude\claude_desktop_config.json` → `mcpServers` | no | the desktop app's chat and every local Code-tab session, never the CLI | only what every Code-tab session may get (Desktop docs, read 2026-11-14) |
| `~/.claude.json` → `projects.<path>.mcpServers` | no | one repo, this machine | **local-scope** servers: private, unshared |
| `<repo>/.mcp.json` | yes | everyone who clones | servers bound to this repo's workload |
| `<repo>/.claude/settings.json` | yes | everyone who clones | permissions for this repo's tools, repo-scoped hooks |
| `<repo>/.claude/settings.local.json` | no — gitignore it | you, in this repo | personal overrides and approvals |

Two of those are easy to conflate and the mistake is not reported.
Putting a user-scope server under `projects.<path>.mcpServers` makes it
local scope — present in one repo instead of all of them.

**`permissions.defaultMode` set to `auto` or `bypassPermissions` counts
only in user or managed settings.** Either value in a project's
`.claude/settings.json` or `.claude/settings.local.json` is ignored: set
it in `~/.claude/settings.json`, or pass `--permission-mode` for one
session. Before 2.1.257 `bypassPermissions` took effect from any file
(settings docs, read 2026-10-07).

## The MCP scope test

How often a server is used never lifts a bound one to user scope. The
test is whether a session unrelated to its workload should still pay for
it: every user-scope server is in every session on the machine,
including ones where it cannot fire. With tool search on, the default,
that is its tool names and instructions; `alwaysLoad: true` loads its
whole tool surface at session start (MCP docs, 2026-10-07). Deferral
cuts the cost, not the binding, so it moves no server to user scope.

- **User scope** — answers questions about your work in general and is
  bound to nothing: docs lookup. Useful in any repo and in a scratch
  directory, and **already in demand**: sessions reach for what it
  serves, as counting the transcripts by the host it would replace shows
  (one machine, 2026-10-27: `code.claude.com/docs` in 222 of 557, Claude
  Academy's site in 2). A server bound to nothing that serves none of
  your work stays out.
- **Project scope** — anything needing a workspace ID, a database, a
  connection string, a running desktop application, or a **tenant**. It
  belongs in the repo that has those things, as does a server bound to
  nothing that one kind of repo uses: docs for that repo's subject.

**A server bound to no workspace is still bound to a tenant.** A cloud
control-plane server — `azure-mcp`, `fabric-core` — answers from
whichever login the shared `~/.azure` holds, the one store no folder
pin reaches, so at user scope it gives every repo on the machine a
client pointed at whichever tenant last logged in. At project scope a
repo that does not declare it **fails closed**: no server, no tools,
nothing to point at the wrong tenant.

`.mcp.json` declares which servers *exist*; `settings.json` says which of
their tools may run **unattended**. Keep that split — a permission entry
in the file that declares the server reads as a scope the server does not
have.
