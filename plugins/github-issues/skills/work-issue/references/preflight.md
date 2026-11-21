# Preflight, the card and the ready order

The steps `work-issue` and `lead-sessions` take for each board issue,
in one home: the first works an issue by hand, the second's coordinator
claims one per headless worker and lands every branch, its workers' and
those the first hands it. Each skill's `SKILL.md` says when to run a
section; where a section differs for one of them, it says so. `<n>` is
the issue's number, `<slug>` its worktree's name, a brief file's stem
for a file, `<S>` the session's scratchpad, `<skills>` the folder
holding the calling skill's own folder, its base directory's parent,
and `<default>` the repo's default branch, which the preflight reads.
**`main` in these parts names that branch**: a repo whose default is
`dev` reads each as `dev`. The main checkout is the repo's first
working tree, and holds `<default>`: the preflight stops on any other
branch there. These files are Read, so
nothing in them is substituted: a sibling skill's script is spelled from `<skills>`, so that
`<skills>/triage-inbox/scripts/set-card.py` is the path a `SKILL.md`
spells `${CLAUDE_SKILL_DIR}/../triage-inbox/scripts/set-card.py`,
quoted in a command as `SKILL.md` quotes it. `<land-branch>` is
`land-branch`'s scripts folder, the first of these that `test -d`
finds: `<skills>/land-branch/scripts`, where a plugin carries it
beside the calling skill, or `$HOME/.claude/land-branch-scripts`, the
copy a setup deploys where `land-branch` sits in a plugin of its own,
quoted in a command as `<skills>` is: a Windows base directory holds
backslashes, and a profile path may hold a space.

**The procedure is split by phase, each part read at the step that runs
it and never before**: a file read early is re-read by every later call
of the session. Read whole at the start, the procedure was about 20k of
a `work-issue` session's first 87k tokens (2026-11-05). This
part comes first; the rest, in this folder:

| Part | Holds | Read |
| --- | --- | --- |
| [claim.md](claim.md) | the worktree's name, the shared-file check | before a claim or a worker's launch |
| [deferral.md](deferral.md) | a deferral's comment and the card's release | on a deferral |
| [prep.md](prep.md) | prep and its gate | once the work is committed |
| [retest.md](retest.md) | the retest of a skill the range edited | on the gate's retest option |
| [lead-hand-off.md](lead-hand-off.md) | finding a live lead, the mark, the message, the replies | at the gate, and to hand a branch over |
| [fast-forward-landing.md](fast-forward-landing.md) | this repo's landing | to land where the repo's rule names it |
| [pull-request-landing.md](pull-request-landing.md) | landing by pull request, and merging it | from the preflight on, where the landing bullet names one |

## Preflight, from the main checkout

**Run the section's blocks as one Bash call**, joined in their order
by newlines, never `&&`, since `printenv` exits 1 off the cloud, then
read each output against its stop below. Two outputs gate the rest: a
`true` from `printenv` ends this file, `cloud-session.md` taking over,
and the base check's `grep` is a fast-forward's alone, so a pull
request route ignores it for that section's own check. No other output
changes what a later command of the call runs, and each call re-reads
the whole session. Run as
five or six calls, preflight's stretches cost a `work-issue` session
$0.086 at the ceiling after 2026-11-06, 71 in 93 sessions, against
$0.021 before; this file's checks ran as one call, exit 0
(2026-11-11, 2.1.322). A fallback a stop names, such as reading the
rule, follows the call.

**In a cloud session, `CLAUDE_CODE_REMOTE=true`, follow
[cloud-session.md](cloud-session.md) instead of this file**: neither the
board nor a landing in the main checkout reaches a container.
Run the first line below to know: an arm with the variable set never
looked, and gave the Windows route (2026-11-02, 2.1.316).

```bash
printenv CLAUDE_CODE_REMOTE                                       # true: a cloud session
git rev-parse --path-format=absolute --git-dir --git-common-dir   # two equal paths: the main checkout
```

**Stop on anything else.** A worktree is not the main checkout: every
GitHub write and the landing run from the main checkout, a worktree
session's guard refuses git outside its own tree, and a coordinator's
workers hang their worktrees off the main checkout.

**Then read the default branch, `<default>`**, which every landing
integrates into: each part's commands spell it for the pull request's
base, the rebase, the range lint and each count against
`origin/<default>`, so a repo whose default moves from `main` to `dev`
lands into `dev`, with nothing here changed.

```bash
git ls-remote --symref origin HEAD                                # ref: refs/heads/<default>, then a SHA line
git branch --show-current                                         # must print <default>
```

**Stop where the main checkout holds another branch**, its fix
`git switch <default>` there, the user's: every landing merges into the
branch the main checkout holds, so after a change of default on GitHub,
which moves no local checkout, a main checkout left on `main` would take
`dev`'s unpromoted commits into `main`, or fail on a `dev` it lacks.

**It asks the remote, so it is current**, where `git symbolic-ref
refs/remotes/origin/HEAD` keeps the old name once the default moves: a
fetch creates `origin/HEAD` only where it is missing, and never moves it
(git-config's `remote.<name>.followRemoteHEAD`, default `create`, git
2.55's docs, read 2026-11-17). **No `ref:` line, or an error**: read
`gh repo view --json defaultBranchRef -q .defaultBranchRef.name` after
the call, and stop on that failing too.

**Then print the repo's landing**, since no issue loads it: its
instructions for landing a brief's worktree, the bullet of its rule for
briefs whose bold opening names the route, as `audit-repo`'s scaffold
writes it. In this repo it runs
[§ "This repo's landing"](fast-forward-landing.md#this-repos-landing).

```bash
awk -v re='worktree lands (from the main checkout|by pull request)' -v end='^(- |#|$)' '$0 ~ re {p=1; print; next} p && $0 ~ end {exit} p' .claude/rules/handoff-briefs.md   # the bullet; nothing, or no such file: find it below
```

**Print the bullet rather than Read the rule**: nothing else in it serves an
issue, whose re-measure and `needs:*` question `work-issue`'s own
steps carry, and a brief file's first Read loads the rule whole anyway.
A Read or a `head` of the rule loads three more by their globs,
`agent-instructions-scoping.md`, `coding-markdown.md` and this repo's
`editing-rules.md`, and the four added 11.35k tokens to each later call
of the sessions measured, where an `awk` loaded none (2026-11-05,
2.1.318). **With nothing printed**, Read the rule once if the file
exists, since its bullet may be worded by hand or its bold opening
wrapped across lines, then the repo's other instructions, its
`CLAUDE.md` first. A repo whose instructions say
nothing about it gets no worktree: say what is missing, name the fix,
and stop, since a branch would wait for a landing nobody
has written down. The fix is a landing bullet in the repo's rule for
briefs, which `audit-repo` offers a queue that lacks one, its default
a fast-forward from the main checkout with no push (its
`references/scaffolds.md` § "The handoff queue"), copied from the
template there for its route and never retyped. **A bullet that names
a pull request takes [§ "Landing by pull
request"](pull-request-landing.md#landing-by-pull-request)**, read
now, and every other a fast-forward.

**Then check the base the route needs.** A pull request's is that
section's own check. A fast-forward's:

```bash
grep -n -A1 '"worktree"' .claude/settings.json                     # must read "baseRef": "head"
```

**Stop on any other.** Under the default `worktree.baseRef`, `fresh`, a
worktree branches from the remote's default branch, missing every commit
landed here and not pushed, with nothing said. **A stop on the base
names its fix**, `"worktree": {"baseRef": "head"}` in the repo's
`.claude/settings.json`, a shared file the user writes or approves;
`audit-repo` offers it with its handoff-queue scaffold.

**Then check the range lint's config**, on either route: prep and the
landing each run `pre-commit run --from-ref`, which reads one.

```bash
test -f .pre-commit-config.yaml; echo "exit=$?"                    # must read exit=0
```

**Stop on `exit=1`, before any worktree.** With no config, `pre-commit
run` exits 1, `InvalidConfigError: =====> .pre-commit-config.yaml is not
a file`, which prep would read as a failure to fix (pre-commit 4.7.0,
2026-11-03). **The stop names its fix**: a `.pre-commit-config.yaml` of
`repo: local` hooks running the repo's own checks, its CI's among them,
for the repo to write or approve, as one on a hand-written
`core.hooksPath` hook did (2026-11-03). **`core.hooksPath` is no bar**: it
refuses `pre-commit install`, not `pre-commit run`, and a scratch repo
with it set ran a local hook over the range's files, exit 0
(2026-11-03). A hook under that path cannot stand in where it reads
`git diff --cached`, as `audit-repo`'s `githooks-lint-briefs.sh` does,
since a range has nothing staged. `audit-repo` offers its pre-commit
baseline with the handoff-queue scaffold.

**Then sweep the empty worktree folders earlier sessions left.** A
session that removes its own worktree, as a lone `work-issue` does at
its landing, leaves the folder whenever a child it started there still
holds it, a language server by inference, and that child lives as long
as the session: only a later session can remove it (2026-11-05).

```bash
[ ! -d .claude/worktrees ] || find .claude/worktrees -mindepth 1 -maxdepth 1 -type d -empty -mmin +10 -delete -print   # each folder removed; exit 1 naming one: still held
```

**It removes only debris**: a registered worktree holds its `.git`
file, so it is never empty, and a held folder is refused, `find: cannot
delete '<path>': Device or resource busy`, exit 1, which is no stop.
**The 10-minute floor spares a worktree being made**: `git worktree
add` creates the folder before it writes `.git`, and another session
may be adding one now. In a scratch repo it removed the old empty folder
alone, keeping a new empty one, a non-empty one, a registered worktree
and a held one (2026-11-05).

## Reading the card and the issue

```bash
uv run --no-project "<skills>/triage-inbox/scripts/set-card.py" . <n>
gh issue view <n>              # the title, labels, assignees and body
gh issue view <n> --comments   # the comments alone; nothing when there are none
```

**`--comments` replaces the body, never adds to it**: off a terminal, gh
2.102.0 printed one issue's comment with no body, and 0 bytes for
another with no comment (2026-10-29). So read both. **`update-issue` and
`file-issue` keep their own copies of these reads**, in `update-issue`'s
`SKILL.md` step 2, before stops that differ from these, and
`file-issue`'s step 3, so a change to any is made in all.

`set-card.py` prints `acting as <login>` and the card as JSON, checking
the board and the account once for the run. **Stop on any of these:**

- **Any `set-card.py` error**: no GitHub origin, no linked project
  carrying the contract, an issue off the board. Its
  `acting_as` must be the account `git config user.name` names; a `404`
  or `Could not resolve to a Repository` from `gh` is that check
  failing.
- **A card whose `state` reads `CLOSED`**: the read prints it at exit 0,
  and only a write refuses, `error: #<n> is closed` (2026-11-01). **On
  the pull request route, one with its branch still here is a merge to
  sweep**, by [§ "Landing by pull
  request"](pull-request-landing.md#landing-by-pull-request).
- **A mirror**: a body opening by naming a brief file that still
  exists, which `set-card.py` refuses. The file is the source until the
  queue's cutover: work it as a brief file, which its first Read loads
  the rule for, and `lead-sessions` by that file's stem.
- **A card In flight or assigned to someone else**: a session holds it,
  on this machine or another. Print its assignees. In flight and
  assigned to the acting account alone is `work-issue`'s resume, its
  step 1; `lead-sessions` stops on any card in flight.
- **A parent**: `gh issue view <n> --json subIssuesSummary` reads a
  `total` above 0. It holds no work of its own, so take its open
  sub-issues instead, as [§ "The ready order"](#the-ready-order) lists
  them. With every one closed, the queue view reads `all <total>
  sub-issues closed: close it`: one
  [§ "Closing a parent"](#closing-a-parent) leaves to the user.

## The ready order

**One order serves both skills**, from the queue view's JSON, which
already groups each issue by its card, labels and links:

```bash
uv run --no-project "<skills>/triage-inbox/scripts/handoff-status.py" . --no-inbox --json > "<S>/queue.json"
jq -b -r '.repos[0].briefs // [] | .[] | select(.group == "ready" and .in_flight == null and (.path | startswith("#"))) | [.path, "P" + .priority, .written, .parent // "-", .title] | @tsv' "<S>/queue.json"
```

**`ready` is open, unblocked and needing nothing.** The view puts a
Deferred card in `deferred`, a `needs:*` label in a needs group, and an
open blocker or an open sub-issue in `blocked`, so a parent waits on its
sub-issues. A card In flight stays `ready` with `in_flight` set, which
the filter drops. The JSON lists each group by Priority, then
`written`, then number, so the first line printed is the next issue.
Brief files take the same order from their frontmatter, `priority`,
then `written`, then the filename, which `lead-sessions` keeps within one
level of a chain.

**A parent's open sub-issues** are the entries whose `parent` is
`#<n>`; the view reads open issues alone, so no closed one is listed:

```bash
jq -b -r --arg p '#<n>' '.repos[0].briefs // [] | .[] | select(.parent == $p) | [.path, .group, (.in_flight // "-"), "P" + .priority, .title] | @tsv' "<S>/queue.json"
```

They print in the same order, `ready` first, each with its group, so a
blocked one names what it waits for in the view's table.

## Closing a parent

**No commit closes a parent**: a commit says `Closes #<n>` for its own
issue alone. A parent holds no work and closes with its last sub-issue
(`provision-board`'s `references/board-contract.md` § "Parents and
sub-issues"), but a commit cannot know it is the last while a sibling
lands beside it, so no commit of one parent's four sub-issues carried the
line, its last three landing within 25 minutes (2026-11-01).

- **Where the repo has `.github/workflows/close-parent.yml`**, as this
  one does, that workflow closes the parent when its last sub-issue
  closes, bar one labelled `standing` or in another repository, which
  it leaves open. The board's Item closed workflow moves the card to
  Done: a close by `GITHUB_TOKEN` still fires it, as one parent's did
  (2026-11-02) and another's (2026-11-04).
- **Elsewhere, and for those two, the close is the user's**: once the
  push or the merge
  closes the last sub-issue, the queue view reads `all <total>
  sub-issues closed: close it`.
