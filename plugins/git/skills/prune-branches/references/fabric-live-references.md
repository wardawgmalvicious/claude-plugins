# Fabric: a workspace's Git connection

Read before rung 1's verdict in a Fabric Git-sync repo, one with a
`workspaces/` folder or `.platform` files. A Fabric workspace connected
to Git tracks one branch, and only the service records which: nothing
in git names it, so § 3's grep finds it only where the repo's docs
happen to say so.

## What deleting a tracked branch costs

With its tracked branch deleted on the remote, one client repo's
workspace failed `git/status` with `GitProviderResourceNotFound`, and
the portal's **Checkout branch** returned only once the branch was
pushed back (a live read, 2026-10-20). Learn does not say so;
`rest-api`'s gotchas hold the row (2026-10-27). On 2026-10-26
rung 1 cleared such a branch, 0 ahead and 17 behind `main`.

## Find the workspaces the repo syncs

Where a repo records which workspaces sync from it is that repo's own:
its instructions, a README or a page under `docs/`, a deployment
parameter file. Read those for workspace IDs, or names to resolve to
IDs. **An empty map clears nothing**: when the repo names no workspace,
say so in the report and ask the user which ones sync from it. A
workspace the repo does not map, connected by someone else, is invisible
to this check, so name that limit in the report.

## Read each connection

[Get Connection](https://learn.microsoft.com/rest/api/fabric/core/git/get-connection),
`GET /v1/workspaces/{workspaceId}/git/connection`, takes a Contributor
or higher workspace role and `Workspace.Read.All`, and a user, a
service principal or a managed identity may call it (Learn, read
2026-10-27):

```bash
fab api "workspaces/<workspaceId>/git/connection"
git ls-remote --get-url origin   # this repo, to compare with the answer
```

A connected workspace answers `gitProviderDetails` with `branchName`,
`repositoryName` and the owner: `ownerName` on GitHub,
`organizationName` and `projectName` on Azure DevOps. One whose
`gitConnectionState` is `NotConnected` answers `gitProviderDetails:
null` and names no branch. **A workspace names a branch when its
`branchName` matches and its repository is this one**: a workspace in
the map can track a same-named branch of another repo, which keeps
nothing here. An error, `InsufficientPrivileges` among them, leaves
that workspace unchecked rather than clear: name it beside the deletion
command, for the user to check before running it.

**The call prompts, by design.** No allow rule keeps `fab api` or
`az rest` to a GET, as `rest-api`'s auth reference says, so
neither joins `allowed-tools`. Get Connection is the only call this
check makes. Auth, the other Git integration calls and moving a
workspace onto another branch, which is a reconnect, are
`rest-api`'s, § *Git Integration APIs*: a tracked branch the
user wants gone is reported KEEP, with that reconnect named as what has
to happen first.
