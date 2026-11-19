---
name: land-branch
model: inherit
effort: xhigh
disable-model-invocation: false
description: "Takes a committed branch from local to merged — pushes it, confirms which GitHub account each tool actually acts as in this repo, opens the PR through the one that matches (gh where its login is confirmed, else github-mcp where loaded), then integrates it into the default branch, reports CI, and deletes the merged branch locally and on origin. Guards two silent failures: gh and github-mcp can authenticate as different accounts, so a PR lands under the wrong identity with no error, and integration preserves every SHA — a local --ff-only merge by default, a no-checkout refspec push where another session holds the tree, or a server-side merge commit where main requires a pull request — because a squash would collapse the logical split commit-changes just made. Stops for confirmation before the write to main. To make the commits first use commit-changes; to review before landing, review-code, or the bundled /code-review where review-code is absent."
when_to_use: "Use when asked to land, ship or publish a branch, open a pull request, merge to main, or get a branch in — the step after commit-changes. Use it even when the request already names the mechanism — 'squash these and merge', 'just merge it into main', 'force push it' — a named mechanism is the case these guards exist for, not a reason to skip them."
---

# Landing a branch

Take a branch that is **already committed**, as `commit-changes` leaves
it, unpushed, and merge it into the default branch: **`main` in this
skill's prose, `<default>` in its commands**, which step 1 reads.

Two things here are irreversible or outward-facing — opening the PR and
writing to `main` — so the procedure gates each one. A third, deleting the
branch from `origin`, is outward-facing and deliberately **not** gated;
step 9 and [references/branch-deletion.md](references/branch-deletion.md)
say why, and why that reasoning does not generalise. Past `references/`,
read docs.github.com by `curl -s` of its search,
`https://docs.github.com/api/search/v1?query=<q>&language=en&client_name=x`,
then of `/api/article/body?pathname=<hit's url>`, and code.claude.com by
`curl -s` of a page's `.md`. A contradicting page wins: say so, act on it,
route the fix by `capture-learning` where installed, else tell the user,
bar a dated measured line naming it and its call, re-measured once the
page changes. An observed claim is cited or marked pending a doc check,
and stands, marked observed, only where no page covers it.

## 1. Preflight

```bash
git fetch origin                # origin/<default> current before anything reads it; no origin at all: references/new-repository.md, before step 2
git ls-remote --symref origin HEAD   # ref: refs/heads/<default>, asked of the remote, as a local origin/HEAD keeps an old default (git-config's followRemoteHEAD, read 2026-11-17); no ref: line, gh repo view --json defaultBranchRef
git status --short              # see below — clean, or knowingly left
git branch --show-current       # must not be <default>
git log --oneline origin/<default>..HEAD
git rev-parse origin/<default>  # <base>, kept like step 7's <sha>: after the merge, nothing else says where main stood
git log --merges --oneline origin/<default> | wc -l   # the history's merges so far, for step 6
git worktree list               # separate trees — not who shares this one
git branch -vv                  # where HEAD is, and each branch's tip
git rev-parse --path-format=absolute --git-dir --git-common-dir   # two paths: a linked worktree
```

**A dirty tree is not automatically unfinished work.** `commit-changes` ends
on a clean tree *or* on lines it names as intentionally left, so a leftover
is a question rather than a stop: ask whether it belongs in this branch.
Uncommitted work does not travel into the PR either way — what matters is
that nothing which *should* have been committed is sitting unstaged.
Anything you cannot account for, stop and ask.

Nothing to land means there is nothing to do — say so rather than
opening an empty PR.

**Where the repo's instructions land this branch without a push, follow
them instead**, unless a push or a PR was asked for: step 3 publishes
every unpushed commit beneath the branch. A bare run of this skill there
asks for neither: ask which was meant, the repo's own landing first (a
brief's worktree, 2026-10-28).

**Two different paths from the last command mean a linked worktree**:
steps 6 to 9 change there, and a generated branch name is renamed first.
Read [references/linked-worktree.md](references/linked-worktree.md)
before step 3.

**Check whether another session is live in this working tree, then
ask.** Step 7's default runs `git switch`, and one working tree has one
HEAD, so the switch is not scoped to you — it moves the branch under
anyone else working here. **`ListAgents` answers this; the two git
commands above cannot.** They report worktrees and refs, and print the
same thing whether one session shares this HEAD or five — measured
2026-09-22, when both came back clean while `ListAgents` named two live
sessions in the tree. Read every row, and place none by its name, which
names a directory at best, and not which one: the script below places
each. What the git commands do show is a branch tip equal to your own —
the tell that someone cut their branch from yours, which is what makes
the merge method at step 7 load-bearing. Asked directly, a user answers
about *subject matter* — "working on something else that won't touch
your edits" is truthful and entirely compatible with sharing this HEAD,
which is what it turned out to mean on 2026-09-15.

**The answer expires.** Re-run `ListAgents` immediately before each
command that moves HEAD — step 7's `git switch`, and step 9's when it
has one — and read HEAD in the same command as the move, because a
session that has *ended* is invisible to `ListAgents` while its moves of
HEAD are not, and one that starts after the check is not in it: a
switch made then puts that session's next commit on `main`, silently. The
reflog records every move and never the mover, so the check comes before
the move. **A row `${CLAUDE_SKILL_DIR}/scripts/placed-elsewhere.sh` places
elsewhere is no peer, nor one it keeps that
`${CLAUDE_SKILL_DIR}/scripts/never-prompted.sh` passes**
([why](references/never-prompted-sessions.md)): run each on its rows, names
whole, and, ahead of each move in its command, on those it passed. Name at
step 6 what each passed; a failed read keeps a row in this tree, or live.

Someone being live is **not** a reason to abandon the landing — step 7
has a no-checkout route for this case. Disclose it at step 6 and take it.

## 2. Establish the identity before anything outward

**This gates every outward action, and it is the step most likely to
fail silently.**

```bash
git config user.name            # the includeIf identity for this root
gh api user -q .login           # the account gh will actually act as
git remote -v                   # who owns the repo; beside an upstream remote a bare gh pr targets upstream, so pass -R <owner>/<repo>
```

Then `github-mcp` → `get_me` when that server is loaded, and compare
every login against the repo owner. Use the tool whose account matches.

`gh` may be **folder-scoped**, wrapped to act as the account the repo's
`user.name` names, as on the machine this skill was written for (since
2026-09-04), and whether it is changes what the probe means. Four
consequences.

- `gh auth status` reports the keyring's *active* account, not the one
  the wrapper will use. **`gh api user -q .login` is the honest probe**
  either way, which is why it is the command above.
- The probe vouches only for a `gh` that reaches the wrapper, and what
  reaches it depends on how the wrapper is built
  ([what misses it](references/gh-wrapper-reach.md)). No native program
  does, the Claude desktop app's PR tools among them: they failed once as
  a missing PR (2026-10-25, cause inferred). What misses the wrapper
  acts as the keyring's active account, so the probe passes while the
  action runs as someone else. **Probe through the invocation it uses.**
- **A wrapper that resolves nothing falls through to the active account
  as well.** It has nothing to go on where `user.name` is unset — any
  clone outside every identity root — or names no keyring login, and it
  can do so without a word (measured 2026-09-23). The probe reports the
  fallback honestly, so compare its answer with the owner in
  `git remote -v`, never with `user.name`: that is empty there, or is
  the very name that failed to resolve.
- **Where no such wrapper exists, `gh` simply acts as whichever account
  is active** — which makes the probe more necessary, not less. Do not
  read the absence of folder-scoping as safety.

**Prefer a `gh` whose *confirmed* login matches the repo owner**: one
route on every repo, and step 8's CI read needs no fallback; a client
repo has no `github-mcp` (2026-09-04: `gh` confirmed as the client
account, PR opened cleanly). `github-mcp`, project scope (`.mcp.json`)
and bound to one token, is the fallback where loaded and matching, and
the route where `gh` matches no one. A cloud session,
`CLAUDE_CODE_REMOTE=true`, runs neither (observed 2026-11-15): its own
GitHub tools open the PR. A `CLAUDE.md` can state the rule, not run the
comparison.

**A confirmed identity is not a confirmed capability.** `get_me` proves
which account a token acts as, not what it may do, and the gap is
**per-resource, not read-versus-write**: a write that worked says
nothing about the next read. A 403 *"Resource not accessible by
personal access token"* at step 5 or 8, or a 404 on a private repo, is
then a scope answer, since step 2 matched: do not re-debug step 2. Fall
back to the `gh` whose login step 2 already confirmed — sanctioned here
for an under-scoped MCP exactly as for an absent one
([evidence](references/token-scope.md)).

**Nothing warns you**: the PR simply appears under the other account.
If no identity matches the repo owner, stop and ask.

## 3. Review, then push the branch

When `git diff --stat <base>...<branch>` touches a language `review-code`'s
description names, Markdown among them, invoke it on that range, its paths
and an `intent: #<n>` per issue a closing keyword (any casing) names in its
commits or an open PR's body (docs.github.com, read 2026-11-16):
`commit-changes` reviews only the default branch, never Markdown. **A
critical finding stops here**: list them and ask whether to fix them first.
**Lower ones go to its `references/choosing-fixes.md` before the push**,
which fixes the set it recommends unasked, then push; each as fixed or left,
and an `unchecked` count, go in step 6's report. **Without it, run the bundled
`/code-review`** on the range: it runs in the background, so push only once
its findings arrive and the user says whether to fix them first.
**Code neither reviews is unreviewed, not clean**: step 6 names it.

```bash
git push -u origin <branch>
```

## 4. Survey what is actually landing

Read every commit `git log --oneline origin/<default>..HEAD` prints, not
just yours. **A commit another session made while you were on this
branch landed on this branch**, and ships inside your PR: not a problem
to fix, but name it in the body (step 5).

Anything that should not ship yet is a stop: say so rather than landing it.

## 5. Open the PR — through the identity step 2 confirmed

`gh pr create -R <owner>/<repo> --title … --body-file …` from the probed
shell; or, when `github-mcp` is the confirmed tool, `create_pull_request`
with `owner`, `repo`, `title`, `head`, `base`, `body`. **A form shown is
no PR** ([why](references/form-deferral.md)).

**The body is the deliverable, and it is the only judgement step in
this skill.** The diff is already visible; do not restate it. What it
owes a reader:

- **Why the change exists**, and what it decided.
- **What was verified, and what was not** — including anything believed
  but unmeasured. A claim's provenance is the part that rots first.
- **Reasoning behind any reversal** of a previous decision, quoted, so
  the reversal is auditable rather than silent.
- **Disclosure of concurrent-session commits** from step 4.
- **How it is to be integrated**, where the repo has a convention.

**A repo's pull request template shapes the body**: both routes skip its
prefill, so [look for one and fill it](references/pr-template.md).

**No GitHub remote, or no confirmed identity? Stop.** An `origin` that
is not GitHub — a `file://` path, another host — means there is no PR
to open; no `github-mcp` *and* no `gh` login that matches the repo
means the same thing for a different reason. Neither is permission to
skip ahead and merge locally. A local merge satisfies the literal words
"merged into main" while discarding review, CI and the PR body, and it
makes any later PR empty because `main` already contains the commits.
Report what is missing and let the user choose. Reaching for an
*unconfirmed* `gh` is never the answer — step 2.

## 6. Checkpoint — stop here

**The gate is the next command that writes to `main`, not the PR.** Stop
before that command whether or not a PR exists: a PR that could not be
opened is a reason to stop sooner, never a reason to carry on. **Where
Claude Code Review runs, wait for its run on the head and report its
result here** ([references/code-review.md](references/code-review.md)).

Report where things stand — the PR URL, or what blocked it — and state
exactly what happens next: which route step 7 will take and what chose
it (a repo document, by name, or the default), its write to `main`, and
**then deleting the branch locally and on `origin`** (step 9). The
deletion is disclosed here rather than prompted for afterwards — one
decision taken before the work, not a third gate on an action this
recoverable. Ask in the same breath whether anything outside git is
bound to the branch — a preview environment, a deploy target pinned to
the ref; a synced Fabric workspace is no bar (step 9), whose other
exceptions are git-internal and cannot see one. A linked worktree you are
in: name its removal, the yes `ExitWorktree` needs. Ask it with the go-ahead
in one `AskUserQuestion` call where the session has it. **Then wait.**

**Leaving the PR open for review is an answer too.** A reviewer is the
user's to name, never inferred, since the request notifies them: ask
whom, with none an option, and request it through step 2's tool,
`update_pull_request` with `reviewers` or `gh pr edit <n> -R
<owner>/<repo> --add-reviewer <login>`, then read it back with
`gh pr view <n> -R <owner>/<repo> --json reviewRequests` (gh 2.101.0
and github-mcp's schema, 2026-10-28). Then stop: the merge waits for a
later go-ahead.

Everything past this point writes to `main`. Do not continue on your own
initiative, even when the merge looks routine, and even when the local
half would plainly succeed on its own — this checkpoint is the skill's
whole reason for not being one command.

## 7. Integrate — preserving every SHA

**Pin the write to one SHA first.** Read the PR's head immediately
before integrating — after required checks pass, where `main` has any —
and call it `<sha>`:

```bash
gh pr view <n> -R <owner>/<repo> --json headRefOid -q .headRefOid   # pull_request_read method get: head.sha
```

Every route then refuses any other head — the local ones by comparing
in the same command as the write, the PR merge by
`--match-head-commit <sha>` (gh) or `expectedHeadSha`
(`merge_pull_request`) — and step 9 keys the deletion on it. A mismatch
is the answer, not an error to retry; the reference below says why
heads move and how to find which side did.

```bash
[[ "$(git branch --show-current)" == "<branch>" && "$(git rev-parse <branch>)" == "<sha>" ]] \
  && git switch <default> && git merge --ff-only <branch> && git push origin <default>
```

Re-run `ListAgents` just before (step 1); HEAD off `<branch>` catches a
mover it cannot see. A peer who appeared after step 6 moves you to the
table's second row — the same write, without the checkout. These guards
are Bash: PowerShell's `&&` runs its right side whenever the left side
*ran*, true or false, so a literal port never refuses — use
`if (…) { … }` (measured 2026-09-23, pwsh 7.6).

This preserves the exact SHAs, keeps `main` linear, and adds no merge
commit. GitHub marks the PR merged once its commits are reachable, so
the merge button is never needed.

**`--ff-only` fails loudly rather than inventing a merge commit.** If it
fails, `main` has moved: stop, reconcile deliberately, and never reach
for `--force`.

Any other state routes elsewhere. Read what `main` requires — from both
of GitHub's systems, since neither read covers the other — and the
repo's merge settings with `delete_branch_on_merge` beside them, which
step 6's disclosure needs:

```bash
gh api repos/<owner>/<repo>/rules/branches/<default> --jq '[.[].type]'   # rulesets, any level
gh api repos/<owner>/<repo>/branches/<default>/protection --jq '.required_pull_request_reviews != null'   # classic; 404 "Branch not protected" is none
```

| State | Route |
| --- | --- |
| `main` requires no pull request, and you hold the tree | the default above |
| `main` requires no pull request, and another session holds the tree (step 1) | `git push origin <branch>:<default>`, behind the same `<sha>` check |
| `main` requires no pull request, and the branch is in a linked worktree (step 1) | that push, or the main checkout's route: [references/linked-worktree.md](references/linked-worktree.md) |
| `main` requires a pull request — **whether or not you could bypass it** | `gh pr merge <n> -R <owner>/<repo> --merge --match-head-commit <sha> --subject … --body …`, with `--admin` only where a rule stays unmet, on the user's yes for that PR, step 6 naming what it skips ([`--admin`](references/integration-routes.md#--admin-a-merge-past-an-unmet-rule)) |
| `main` also requires linear history | stop — every route inside the gate rewrites SHAs; name which, then wait |
| The repo's documents name a mechanism — `CONTRIBUTING.md`, agent instructions, read before step 6 | treat it as asked for (the rows below), naming the document |
| A squash was asked for | name what it collapses, then wait |
| A merge commit was asked for | one clause of disclosure, then proceed |

**Route on the requirement, never on a refused push**: an account that
can bypass is never refused, so its push lands outside every required
check and reports success. A `pull_request` type from the first read
is the third row; `true` from the second needs the reference.

**Anything but the first row — read
[references/integration-routes.md](references/integration-routes.md)
before the step 6 disclosure**, not after it. Step 6 states which route
step 7 will take, so the mechanics have to be in hand while that
disclosure is being written.

Whichever line writes `main` — the local merge, the refspec push, or the
PR merge — is the write step 6 gates, whoever performs it.

## 8. Verify

Through the same tool step 2 confirmed — **both routes verify, and the
`gh` one is not optional.**

| Check | `gh` | `github-mcp` |
| --- | --- | --- |
| Merged, and by whom | `gh pr view <n> -R <owner>/<repo> --json state,mergedBy` | `pull_request_read` method `get` |
| CI conclusions | `gh pr checks <n> -R <owner>/<repo>` | `pull_request_read` method `get_check_runs` |

- Expect the PR to read as merged, and a merging identity that matches
  step 2. **The two routes do not share a field name**: `merged: true`
  is the MCP's, and `gh pr view <n> --json merged` answers *"Unknown
  JSON field: merged"*. `state` (`MERGED`), `mergedAt` and `mergedBy`
  are `gh`'s (confirmed against `gh pr view --json`, 2026-09-16).
- **`get_check_runs` can refuse a token that opened the PR** (step 2):
  the `github-mcp` route's caveat: `gh pr checks <n>` then reads CI.
- Read the check conclusions rather than the summary. A review bot,
  such as `copilot-pull-request-reviewer`, is **not** a gate, Claude
  Code Review's result being step 6's; a `pre-commit` style job is.
- **`gh pr checks` exits non-zero by design** — exit code 8 is *checks
  pending*, a failure is likewise non-zero, and a repo with **no CI at
  all** exits **1**, printing `no checks reported on the '<branch>'
  branch` to **stderr** with stdout empty (gh 2.101.0, measured
  2026-09-17). That is the answer, not a broken command; do not retry
  it. "No CI configured" and "checks passed" are different states the
  exit code does **not** separate — only that stderr line does, so a
  run that discarded stderr must report neither.
- **To wait for CI, give `gh pr checks <n> --watch` the Bash tool's
  `timeout` parameter or `run_in_background` rather than coreutils
  `timeout`.** Those keep `gh` bare, on the path step 2's probe vouched
  for, while `timeout gh` reaches a wrapper only where a wrapper file
  sits on `PATH` ahead of `gh.exe`. Where none did, in a client repo,
  the keyring's active account answered
  `Could not resolve to a Repository`, which reads as a bad slug
  (2026-09-23).
- **Read `origin/main` against the pins, never HEAD**, which the refspec
  push and the PR merge leave on the branch:

  ```bash
  git fetch origin
  git merge-base --is-ancestor <sha> origin/<default>          # exit 0: the pinned head landed as-is
  git log --merges --oneline <base>..origin/<default> | wc -l   # the branch's own merges, +1 for a merge commit
  ```

  A failed ancestor check is a squash or rebase merge, which no count
  sees; a higher count is `main` moving under the PR merge, and step 7's
  subject names yours ([measured](references/integration-routes.md#verifying-what-landed)).
- `main` and `origin/main` at one SHA: `git rev-parse <default>
  origin/<default>` prints two identical lines, after `git fetch origin
  <default>:<default>` with HEAD off `main`, since a plain fetch moves
  `origin/main` alone. Never `--short`, exit 128; the reference has both.

Report the PR number, the merged state, and the CI conclusions. If CI is
still running, say so rather than implying it passed.

## 9. Delete the branch

Step 8 has just proven the merge — the PR reads as merged, the pinned
head is in `origin/main`, `main` and `origin/main` at one SHA — so it
holds nothing that is not in `main`: cleanup rather than a judgement
call, disclosed at step 6 instead of gated here, in a shared repo too
([why](references/branch-deletion.md)).

```bash
# Local — move off <branch> first if HEAD is on it; alone by a ListAgents run now
[[ "$(git branch --show-current)" == "<branch>" ]] && git switch <default>
git merge-base --is-ancestor <branch> <sha> && git branch -D <branch>   # keyed on <sha>, step 7's pin

# Remote — probe, don't infer. GitHub may have done it already.
git ls-remote --heads origin <branch>        # empty = already gone
# Only when that came back non-empty; deletes only while origin holds <sha>:
git push --force-with-lease=<branch>:<sha> origin --delete <branch>

git fetch origin --prune                     # both paths
```

**Both halves key on `<sha>`, never on reachability from `main`**, which
a squash or rebase merge defeats while every change is in `main`. The
reference has the measurements, including why `-d` and `git cherry`
both misfire there.

- **Local.** `--is-ancestor <branch> <sha>` exits 0 when every local
  commit is in what merged; non-zero means one reached the branch after
  the pin — keep it and report. Behind that check `-D` is safe.
- **Remote.** The lease deletes only while `origin` still holds `<sha>`.
  A refusal — `! [rejected] (delete) -> <branch> (stale info)`, exit 1
  — means someone pushed after the merge, and that work is not in
  `main`: stop and report, don't retry. A delete needs no force; the
  lease adds only the condition.

**Run each command separately** — chained, one refusal silently skips
the rest. A `<sha>` this clone lacks fails
`--is-ancestor` with `fatal: Not a valid commit name`;
`git fetch origin pull/<n>/head` brings it in, and outlives the branch.

**HEAD on `<branch>` is the one local case that needs the move**: `-D`
refuses it, and the PR merge leaves you there when you hold the tree.
With anyone else live (step 1), keep the local branch and say so. A refusing
guard is an answer: HEAD on `main` needs no move, and on any other branch
someone moved it — stop and report. Step 8 left local `main` current.
Never switch just to make the delete succeed: step 1 says why.

**Empty from `ls-remote` means GitHub already deleted the branch**: say
so rather than claiming the delete, and never infer it from
`delete_branch_on_merge`, which changed mid-run once (2026-09-16). **The
prune runs on both paths**: an auto-deleted branch leaves this clone's
remote-tracking ref behind. The reference has the evidence for both.

Do not delete, and say why, when:

- The PR is not merged, or `--ff-only` failed. The branch is the
  recovery path.
- The user asked to keep it. Honour that with no round — it costs
  nothing, and the reference says why.
- Another session is live in the tree, or is on this branch — by a
  `ListAgents` run now and step 1's scripts, since step 1's answer has
  expired. Note this blocks the *deletion*, not the landing — step 7's
  variant covers that.
- **The branch is checked out in a linked worktree**: git refuses the
  delete until it goes, and only your own goes, given step 6's yes
  ([references/linked-worktree.md](references/linked-worktree.md)).
- **Something outside git is bound to the branch** — the question step
  6 asked — but not a Fabric workspace, which only needs re-pointing
  ([references/branch-deletion.md](references/branch-deletion.md)). What
  breaks when such a branch is deleted has never been tested; asking it
  only after the merge cost a round trip once (2026-09-22).
- **The branch is the base of another open PR.** Deleting it retargets
  that PR or closes it. This is the only exception steps 6 to 8 do not
  already establish — merge state does not show it — so it is the one
  that needs its own call, through the tool step 2 confirmed:

```bash
gh pr list -R <owner>/<repo> --base <branch> --state open
```

or `list_pull_requests` with `base`.

## Constraints

**Two kinds, and the difference is the point.** The first are
correctness and identity — an instruction does not lift them. The second
are convention — the repo's written one, else this skill's default —
yours to override; make the override informed rather than refusing it.

### Absolute — an instruction to do these is a stop, not an override

- **Never file the PR through an identity step 2 did not confirm.**
  Identity, not preference. "Just use `gh`" is not a licence on its
  own, because it files under whichever account `gh` resolves to here,
  and that is not something anyone can consent to without first being
  told which one. Until its login is confirmed, report the mismatch.
- **Never `--force`, never `--no-verify`** — including to get past a
  failed `--ff-only`. Step 9's `--force-with-lease` is on a *delete*,
  which needs no force; there it only adds a condition, and it licenses
  nothing anywhere else.
- **Never write to `main` before step 6**, bar a new repo's base push,
  asked first. Opening a PR and pushing `main` are two decisions.
- **Never `git switch` while another session is live in the tree** —
  live by a `ListAgents` run immediately before the switch and step 1's
  scripts inside its command, never by step 1's run or by an instruction.
- If the repo is not one the authenticated identity owns, stop and
  report rather than working around it. **A protected `main` is not
  that case** — a ruleset requiring pull requests is the repo working
  as intended, and step 7's PR merge lands inside it rather than
  around it. What stays banned is the workaround, and the silent form
  is the one to watch for: an account that can bypass has its direct
  push *accepted*, skipping every required status check with no
  rejection to evade. That is why step 7 routes on the requirement.

### Repo convention — overridable, but never silently

A squash and a merge commit are **defaults, not laws**, gated by what
they cost. **A squash keeps the full round**: name the commits it would
collapse, then wait, since a request that named it up front has not
heard the cost, and record it in the PR body. A merge commit, or a
squash of one commit, gets one clause and proceeds. Once reaffirmed, do
it: pressing the point twice is worse than the squash.
[references/integration-routes.md](references/integration-routes.md)
§ "Overriding the default" has each in full; step 9, the kept branch.
