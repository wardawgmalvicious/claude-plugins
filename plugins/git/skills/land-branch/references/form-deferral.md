# A form in place of a PR

Behind step 5's line: what `github-mcp` answers instead of opening a PR,
why, and what to do with that answer.

## What it is

**"An interactive form has been shown to the user" is no PR.** The
GitHub MCP server hands `create_pull_request`, `update_pull_request` and
`issue_write` to a form in any client that advertises MCP Apps, and runs
none of them, unless the server entry sends
`X-MCP-Features: mcp_apps_disable_form_deferral`. MCP Apps is on by
default, and the flag keeps its result views while making the writes run
directly (`github/github-mcp-server` `docs/server-configuration.md`
§ "MCP Apps", read 2026-10-22). The server drops an unknown flag in
silence, so a misspelt value reads as a header with no effect.

In two desktop-app sessions it answered so three times; the form the
user tried failed to submit, and no PR existed after (2.1.304,
2026-10-22).

## What to do

Check with `gh pr list --head <branch>`, then take the `gh` step 2
confirmed, as for a 403. Name the form at step 6, so the user knows why
`gh` opened the PR. A reviewer request through `update_pull_request` at
step 6 can meet the same form, since § "What it is" names that tool:
take `gh pr edit` then. That its read-back of `reviewRequests` shows
none after a form is reasoned, not run (2026-10-28).

**The header is read at connect.** Two calls made after it was saved, in
the session that saved it, still got the form: it takes a new session or
a reconnect. A repo whose `.mcp.json` was copied from the template
before the header was added keeps deferring until its own entry gains
it; the MCP README in the user's config, where it holds one, has the
entry under § "Source control and work tracking".

## Not established

- A session that loaded the header calling `create_pull_request` and
  getting a PR URL with no form.
- Whether a CLI or VS Code session advertises MCP Apps and gets the form
  at all; upstream tests MCP Apps with VS Code.
