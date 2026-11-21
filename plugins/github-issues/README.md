# github-issues

Works a repository's backlog as issues on a GitHub Projects board, each
issue a brief for one session: file it, move its card, or work it from
the claim to the branch landed.

| Skill | Run it as | Does |
| --- | --- | --- |
| `file-issue` | `/github-issues:file-issue`, or ask to file an issue | drafts each item as a brief, searches open and closed issues for its subject, and files it with its card's fields, labels and links on one yes |
| `update-issue` | `/github-issues:update-issue <n> defer`, typed only | defers, reopens, drops or reprioritizes a card without working it, commenting the why first |
| `work-issue` | `/github-issues:work-issue [<n>]`, typed only | claims the card, works the issue in a worktree, commits with `Closes #<n>`, reviews the range, then lands it as the repo's instructions say |

To install it:

```bash
claude plugin install github-issues@<marketplace>
```

It brings the `toolchain` plugin with it, for `jq` and `uv`, and to
check that `gh` is installed and signed in.

## What the repository needs

- **A board carrying the contract the skills read**: its Status,
  Priority, Work model, Work effort and Reopen-when fields, and its
  `needs:*` labels. The `provision-board` skill, in the `github` plugin,
  makes one and links it to the repository. Every skill stops on a
  repository with no such board.
- **For `work-issue`, a written landing**: a line in the repository's
  instructions saying how a worktree's branch lands, by a fast-forward
  from the main checkout or by a pull request. With none, it says what
  is missing and stops before any worktree. `audit-repo`, in the
  `github` plugin, offers it with a handoff-queue scaffold, along with a
  `.pre-commit-config.yaml`, which `work-issue` runs over the range, and
  `"worktree": {"baseRef": "head"}` in `.claude/settings.json`, which a
  fast-forward needs so a worktree starts from local commits not yet
  pushed.
- **`git config user.name` set to your GitHub login, and `gh` signed in
  as that account with the `project` scope, active** (`gh auth switch
  --user <login>`): the scripts take that account's token by `gh auth
  token --user` whatever is active, but each skill's own `gh` calls act
  as the active account, and `file-issue` stops where it is not the one
  `user.name` names. `work-issue` and `update-issue` refuse a card
  someone else holds.

`work-issue` commits through `commit-changes` and reviews through
`review-code`, both in the `git` plugin, falling back to the built-in
`/code-review` where `review-code` is missing. It hands a branch to a
running lead session only where one is found; without one, it lands
the branch itself. It pushes only the branch, and only where the
repository's landing names a pull request; there the pull request's
merge closes the issue: a reviewer's, or `work-issue`'s own on your yes
where `main` requires no approving review. On a fast-forward landing it
never pushes: the push that carries `Closes #<n>` to the default branch
is yours, and closes the issue.

## The command-runner agent

A fast-forward landing is two runs of commands with the range's review
between them, and `work-issue` hands each run to the
`github-issues:command-runner` agent: it runs the commands it is given
on a cheaper model and reports their output verbatim, deciding nothing
and editing no tracked file.

A `PreToolUse` hook,
[hooks/command-runner-write-scope.sh](hooks/command-runner-write-scope.sh),
holds that agent's Write to the session's scratchpad. It is registered
on every Write and checks only the agent's, passing every other Write
first. It needs `bash` 4.4 or later, which Git for Windows provides, and
`jq`, from your `PATH` or the copy `toolchain` fetched; without either
it lets the agent's Write through with a `hook error` notice. It refuses
every Write of the agent's in a session with no scratchpad, such as
a `claude -p` started outside the Claude desktop app or VS Code, or
one on an API key or another provider, and on macOS and BSD, which lack
the GNU `realpath -m` it resolves paths with; the agent then reports
what it would have written,
for the caller to write.

## The session hooks

Two more hooks run in every session with the plugin on. Each needs
`bash` 4.4 or later, handing over to the one on your `PATH` where `sh`
is older or dash, and does nothing where none is found; neither ever
blocks. Where your Claude config folder, `~/.claude` unless
`CLAUDE_CONFIG_DIR` names another, already holds a copy of one under
`hooks/`, the plugin's copy does nothing and leaves the work to that
one, taking it as registered in your settings: a hook in both places
would run twice.

- [hooks/name-session.sh](hooks/name-session.sh), on `UserPromptSubmit`
  and on `SessionStart` after `/clear`, names a session once, from its
  first prompt, so the `/resume` picker and other sessions show what it
  is for: `/github-issues:work-issue 12` names it
  `github-issues:work-issue: 12`, a prompt naming an issue as
  `issue #7` names it `issue: #7`, and a session in a worktree takes
  the worktree's name. Each name ends in the first prompt's local date
  and time. A session already named, by `--name` or `/rename`, keeps
  its name.
- [hooks/offer-handoff.sh](hooks/offer-handoff.sh), on `SessionStart`
  after a compaction, tells Claude in every repository that a new
  request a skill covers is a new invocation of that skill, not a run
  of the copy re-attached after the summary. In a repository that has
  a `.claude/rules/handoff-briefs.md` or a `docs/handoffs/` folder, as
  `audit-repo`'s handoff-queue scaffold writes, it also says Claude may
  offer, once, to file a brief while the summary still holds the
  thread. Where `docs/handoffs/` holds brief files it lists them, so
  the offer can name the brief a thread belongs to. Where the folder
  holds none, or the repository has the rule and no such folder, it
  gives the command that lists the board's open issues instead, so the
  offer can name the issue. It never reads the board itself.

## The side-session guard

A `PreToolUse` hook,
[hooks/side-session-guard.sh](hooks/side-session-guard.sh), checks each
side session a Claude desktop session starts by the
`mcp__ccd_session__start_session` tool, which the desktop app alone
offers. It refuses a start that names neither a `source_branch` nor
`use_worktree` `false`, since the app then picks the worktree's base,
and a worktree start whose brief says nothing of how its branch lands:
no `landReady`, the mark `work-issue`'s hand-back block sets, no
`audit-session.md`, and no `no hand-back`. Each refusal names
`work-issue`'s `references/hand-back.md` in the plugin's folder, for
Claude to Read and start again with its block in the prompt. A start
with `use_worktree` `false` passes in silence. It needs only `bash`,
starting nothing else, and fails open: on empty input the start goes
ahead under a `hook error` notice. Whether Claude Code runs a hook on
that tool is not yet seen in a desktop session. As with the session
hooks, a copy under your config folder's `hooks/` leaves the work to
that one.
