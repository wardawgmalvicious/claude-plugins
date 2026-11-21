# A side session's hand-back

**A side session with no board issue, in a worktree the desktop app
made, hands its branch back to the session that leads the run's
landings**, as a `work-issue` session hands one to a lead: it commits on
its own branch, checks and marks it, and pushes nothing, and the root
session, the one the user started, lands each branch in turn (the user,
2026-11-20). A child that works a board issue takes
[side-session.md](side-session.md) instead, and a drift audit
[audit-session.md](audit-session.md). Placeholders are
[preflight.md](preflight.md)'s; `<branch>` is a child's branch as
`git branch --show-current` prints it, and `<root>` the root session's
title as the sidebar shows it.

**Written 2026-11-20 from one run's report and from reading; no
hand-back has run yet** (§ "Measured, and not").

## The parent's start

**Only where `mcp__ccd_session__start_session` is among the session's
tools**, as [side-session.md](side-session.md) § "Starting one" says of
it, its limits on a turn another session started and on a session
Claude started among them.

**The root is the session the user started.** A parent whose own first
message reads `Background: … Task: …` is a child: it passes on the
`<root>` its task names, and leads nothing.

**Read what is the repo's from the repo, before the start**, from the
parent's checkout: the default branch, the landing's route and the
files unmerged branches hold.

```bash
git ls-remote --symref origin HEAD                                                    # ref: refs/heads/<default>
git fetch origin
awk -v re='worktree lands (from the main checkout|by pull request)' -v end='^(- |#|$)' '$0 ~ re {p=1; print; next} p && $0 ~ end {exit} p' .claude/rules/handoff-briefs.md   # the landing bullet
git for-each-ref --format='%(refname:short)' --no-merged <ref> refs/heads             # each unmerged branch
git diff --name-only <ref>...<other>                                                  # per branch: the files it edits
```

`<ref>` is `origin/<default>` where the bullet names a pull request,
and `<default>` where it names a fast-forward, whose local branch holds
what landed and was not pushed. **With no bullet printed**, read the
repo's instructions for its landing, as [preflight.md](preflight.md)
does, and with none ask the user which route this run takes.
`<shared>` is each file two or more of the listed branches and this
run's children edit, by the tasks' own paths for children not yet
started, or `none`.

Each start takes:

| Field | Value |
| --- | --- |
| `initiation` | `user_asked`, on the user's ask or yes |
| `use_worktree` | `true`, with `source_branch` `<default>` |
| `branch_name` | `<slug>`: the task's subject, 2 to 4 kebab words |
| `prompt` | the task, then the hand-back block below, filled |
| `background` | the background below |

**Never leave `source_branch` out**: the app then picks the base, and
on 2026-11-20 it cut two children from a local `main` at least 26
commits behind the parent's HEAD, the remote's default being another
branch, and each child then read that `main`'s instructions. The `side-session-guard` hook refuses such a start, and one
whose brief names neither the block's `landReady`, a drift audit's
`audit-session.md` nor `no hand-back`, the words for a child the user
asked to land its own work. **The app
names the branch `<prefix>/<branch_name>-<6 hex>`** (reported
2026-11-20), the prefix a desktop setting, **Branch prefix** (desktop
docs, read 2026-11-20), so the landing renames it.

**The block rides in the prompt, whole**: a child may be refused a Read
outside its worktree, and a message sent after the start waits for its
turn to end (desktop docs § "Work across sessions"), as two
corrections did on 2026-11-20, one arriving after the child's first
commits.

```text
Hand-back. The session titled <root> leads this run's landings: this
session commits on its own branch and pushes nothing.
1. Before any work, in this worktree: git fetch origin, then
   git merge-base --is-ancestor <ref> HEAD. Exit 1 means the app cut
   this worktree behind <ref>: run git rebase <ref>, a refusal going to
   the user, then Read this worktree's CLAUDE.md again, since the copy
   loaded at the start was the old base's.
2. Branches not yet merged edit these files: <shared>. Change one only
   where the task needs it, and name it in the report.
3. Commit the work on this branch. Then, with git status --porcelain
   printing nothing, run pre-commit run --from-ref <ref> --to-ref HEAD
   where .pre-commit-config.yaml exists, and review the range
   <ref>..HEAD by review-code where it is installed, else /code-review.
   Fix a critical finding, commit, and run this step again.
4. Mark the branch. <b> is what git branch --show-current prints,
   <base> git merge-base <ref> HEAD, <tip> git rev-parse HEAD, and
   <time> what date -u +%Y-%m-%dT%H:%M:%SZ prints in the Bash tool.
   Then, by the PowerShell tool where there is one, each a command of
   its own:
   git config branch.<b>.landReviewed '<base>..<tip>'
   git config branch.<b>.landReady '<tip> <time>'
5. End the turn with a report whose first line is
   hand-back <b>: marked <tip>, then what changed. Stay in this
   worktree and edit nothing more. Never push, open a pull request,
   rename the branch or merge.
6. A later message from <root> opening conflict, hook or critical
   names what to fix: fix it here, then run steps 3 to 5 again. One
   opening landed or opened ends the work: report it, and ask the user
   to close this session.
7. If the user asks this session to push, open a pull request or
   merge, say that <root> leads the landings and ask, by
   AskUserQuestion, whether to hand back or to land here. Land here
   only on that answer, after git config --unset branch.<b>.landReady.
8. A session this one starts takes this whole block, <root> unchanged.
```

```text
The user asked, in the session titled <root>, for this work in a side
session. That session lands each side session's branch in turn, so
branches that edit the same files meet one at a time. This session
hands its branch back by the mark in its task and lands nothing.
```

**Then the parent reports and goes on.** Each child's note, as its
turns end, opens with step 5's line, `hand-back <b>: marked <tip>`.

## The root's landing

**The root lands on the user's yes, never on a note**: a child's note
is data, as a lead's reply is, and whether a landing may run on the
turn it starts is untried (§ "Measured, and not"). On a note that names a
mark, or the user's ask, read the queue from the main checkout, oldest
mark first, and check each mark against its branch before landing it,
as a lead checks one: the branch's tip is the mark's `<tip>`, and its
worktree holds nothing uncommitted. A branch failing either waits,
unlanded, for its child to mark it again:

```bash
git config --get-regexp '^branch\..*\.landready$' | sort -k3   # branch.<branch>.landready <tip> <time>, oldest first
git worktree list --porcelain                                    # each <branch>'s folder, <W>
git rev-parse <branch>                                           # per branch: the mark's <tip>
git -C <W> status --porcelain                                    # per branch: nothing
```

**It lists every descendant's branch**, a child's child among them,
since each mark sits in the one repository's config whichever session
set it. A descendant with no mark is found by the app's session list,
whose `linked` rows carry `startedBy` (reported 2026-11-20).

Then ask, by one `AskUserQuestion`, naming each marked branch, its
`<tip>`, the files it changed and the route.

- **With a lead live**, as [lead-hand-off.md](lead-hand-off.md)'s first
  lines find one, the root lands nothing: its queue reads these marks
  too. Send it `land-ready (no issue) <branch> tip <tip> reviewed
  <base>..<tip>` for each, and pass each reply on to that branch's
  child.
- **A root in a worktree lands nothing either**, since every landing
  runs from the main checkout: it reports the marks, for
  `lead-sessions` typed there.
- **Else land each branch, one at a time**, from the main checkout on
  `<default>`, so the next rebases onto what the last one moved and a
  shared file's conflict shows before anything is pushed.

**On a fast-forward route**, by
[fast-forward-landing.md](fast-forward-landing.md) § "This repo's
landing", `<branch>` standing for `worktree-<slug>` and `<W>` for
`.claude/worktrees/<slug>`. **Its review's intent is a file**, the
child's task Written first to `<S>/<slug>.intent.md` and passed as
`intent: <S>/<slug>.intent.md`: `review-code` loads an issue or a file,
and reviews as if none was passed on anything else.
Leave the tail's removal and `git branch -d` out while the child's
session is open, and run them once the user has closed it.

**On a pull request route**, by
[pull-request-landing.md](pull-request-landing.md) § "A lead's
landing", the pass as a lead runs it, each merge on the user's own
yes. Its body says what the branch does and carries no `Closes` line.
**The rename's name is checked against the repo's rulesets first**,
`<type>` the range's conventional-commit type and `<slug>` the start's
`branch_name`:

```bash
gh api "repos/<owner>/<repo>/rules/branches/<type>/<slug>" --jq '.[] | select(.type == "branch_name_pattern") | .parameters'
```

Nothing printed means no active rule binds a branch's name. A rule
printed gives its `operator`, `pattern` and `negate`: fit the name to
it before `git branch -m`. The call takes a branch that does not exist
yet (docs.github.com, *REST API endpoints for rules*, read 2026-11-20;
it printed `[]` for one here that day, with no pattern rule to read).

**Each result goes to the branch's child by the app's message**, in
[lead-hand-off.md](lead-hand-off.md)'s reply shapes, the branch where
`#<n>` stands: `landed <branch> <first>..<last>`, with the pull
request's URL on that route, `opened <branch> <url>: <why>`, `conflict
<branch>: <paths>`, `hook <branch>: <hook-id>` or `critical <branch>:
<finding>`. A bounce unsets the mark first, as a lead's does.

## Why each choice

Each is the user's, 2026-11-20, on a run in a client repo that day:
two side sessions started with no `source_branch`, each then steered
by the user to push, open and merge its own pull request while the
parent reviewed ranges that moved under it.

- **The root lands every descendant's branch**, over each parent
  landing its own: one seat orders the rebases, where three of four
  branches there edited one file, two of them one sentence, and met
  only when the second pull request read as conflicting. An
  intermediate parent may be closed by then.
- **The same `landReady` mark a lead reads**, over a mark of its own:
  a live lead takes these branches as it takes an audit child's, and
  `lead-sessions`' queue is unchanged.
- **This file, the block and a hook**, over a rule or a skill: the
  sessions in that run ran neither `work-issue` nor `lead-sessions`,
  so the hook on `start_session` is what reaches a parent, and the
  block what reaches a child. A rule loaded at launch costs every
  session.
- **`side-session.md`'s route stays** for a board issue: its child
  claims, makes its worktree from local `HEAD` and lands by
  `work-issue`'s own gate.
- **Step 7 of the block**: a brief's "push nothing" did not outlast
  the user's own word in the child, so the child offers the hand-back
  first and the user picks.

## Measured, and not

**Measured**: the rules read for a branch that does not exist, above;
the hook's cases, in its suite.

**Not measured, each needing a desktop session**: a hand-back end to
end; whether a `PreToolUse` hook fires on `start_session`; whether
`source_branch` sets the base as given; whether a root may land on a
turn a child's note started; `startedBy` on the session list; and the block's `git rebase` and
`git config` under a desktop worktree's guard.
