# Preparing to land

Part of the per-issue procedure, read once every commit is in:
`work-issue`'s step 8, and any other sender before a hand-off to a
lead. Its placeholders are [preflight.md](preflight.md)'s.

**Every session preps its branch in its worktree before handing it to a
lead**, and `work-issue` before any landing, so a lead takes a tip
already checked and reviewed, and a self-landing starts from one. A
`lead-sessions` worker does not: its coordinator marks it and reviews
the whole range at landing. **Another sender runs prep's commands and
its fix, not its gate**: `triage-inbox`, `capture-learning`,
`author-skill` and `test-skill` hand over behind a gate of their own,
whose yes covers a critical finding's fix, and the deliverables check
and the retest are `work-issue`'s. A plain
session handed a branch over unreviewed on 2026-11-03, and the lead's
review bounced it for findings its own would have caught. Every commit
is in, by `commit-changes`, and **the block below runs as one Bash
call**, `<default>...HEAD` standing for `<base>..<tip>`, the same range, and
`; echo "exit=$?"` after `pre-commit`: a dirty tree or a failure makes
the rest stale, so fix, commit and run it again. In the worktree its
guard ran it chained, exit 0 (2026-11-11, 2.1.322), where five calls
each re-read the session:

```bash
git status --porcelain          # must print nothing
pre-commit run --from-ref <default> --to-ref HEAD   # a fixer's edit or a failure: fix, commit, run again
git merge-base <default> HEAD   # <base>
git rev-parse HEAD              # <tip>
git diff --stat <base>..<tip>   # a language review-code's description names, Markdown among them: invoke it on this range, with the intent
```

**The target carries the intent**: `git diff <base>..<tip> intent:
#<n>`, the issue being worked, or `intent: <path>` for a brief file, so
the review weighs a choice the issue made on purpose instead of
flagging it for the fixes to filter (2026-11-11). A sender with neither
passes the range alone, and `choosing-fixes.md` § 2 still screens what
it flags.

**Where `review-code` is not installed**, as in a repo that takes the
`git` plugin from a catalog without it, invoke the bundled
`/code-review` on the same range and its paths instead, as
`commit-changes` does (Claude Code's skills docs, read 2026-11-16). In
an interactive session it runs in the background, so end the turn and
go on only once its findings arrive; under `-p` it returns them inline
(code-review-local docs, § "Run in the foreground", read 2026-11-17).
**Treat each finding as a critical one**: there is no
`choosing-fixes.md` to sort the rest. With neither, the gate says no
review ran, and the range is unreviewed, never clean. **This is the
fallback every review in this procedure takes**, at the landing and a
lead's alike.

**Lint the branch, never the whole tree, here and at landing.**
`--from-ref` checks the files `<default>...HEAD` changed, and a check over a
whole set still runs when one of its files did. Sessions in parallel each
running `--all-files` overlapped, four at once, and drove 5 CPU cores of
PSScriptAnalyzer (measured 2026-10-31). CI still runs the whole tree on
push and pull request.

**A critical finding is fixed here**: commit the fix, run prep again,
reviewing only the new commits, and take the new `<tip>`. **Then
`work-issue` fixes the lower findings, with no question**, where a
warning or a suggestion stands, by `review-code`'s
`references/choosing-fixes.md`: the set its § 2 recommends, each fix
committed here, its § 4 scope check and fix review run, the rest left
for the report. The fixes' new `<tip>` ends the reviewed range, so a
lead's `git range-diff` passes over them. Another sender puts its lower
findings in its report. `<base>..<tip>` is the reviewed range.
**The range is always the whole branch**, `<base>` the merge base,
since each pass reviews what no earlier one read: a fix's new commits,
or each patch a rebase changed, by `git range-diff` as the landing
reads one. All but the last commit is no range a lead reads: review the
rest first. **On the pull request route**, `git fetch origin` first,
and `origin/<default>` stands for `<default>`, which lags the server's
merges.

**Every deliverable the issue lists is committed before the gate**:
read the body's list again, a test record or a README line as much as
the edit, and commit what is missing, prepped as a fix is. A record of
a retest comes after the retest, before the gate is asked again. One issue
listed a retest record and wrote it after the hand-off, which cost a
second landing round (2026-11-03).

**Prep ends at the user's gate**, one `AskUserQuestion`, its question
naming how many lower findings were fixed and how many left, where the
review found any, each listed above it, a fix by its SHA: its yes is
the user's word on the fixes, and one `git revert` takes back a fix the
user rejects.

- **With a retest owed**, as [§ "Retesting an edited
  skill"](retest.md#retesting-an-edited-skill) finds one, its first
  option, recommended: retest first, naming each skill, whether it owes
  a full retest or a smoke test, the batch size and the whole run's
  cost, as that section gives them, not one child's, and the budget,
  which caps each child alone, not its hand-run arms; each eval
  invocation has `test-skill`'s own `--max-cost-usd`. The
  route's own options follow, so a no hands the branch on untested.
- **On the pull request route**: open it, naming the reviewer to request
  with none an option, or park. **Where `main` requires no approving
  review**, read live by [§ "Merging where no approval is
  required"](pull-request-landing.md#merging-where-no-approval-is-required),
  **open and merge** is the route's first option, recommended where no
  retest is, and takes the named reviewer's place, since no merge waits on
  one: open alone stays, requesting none, and a reviewer comes by the
  gate's Other. It discloses what `land-branch`'s step 6 would, the
  merge and its method, a wait of up to 25 minutes for Claude Code
  Review where the repo runs it, the branch's deletion on `origin` and
  here, and the worktree's removal, and the question asks whether
  anything outside git is bound to the branch. Its yes is the user's
  word for the merge.
  **With a lead live there too**, hand off to it, by name, takes open
  and merge's place, since this session's merge would leave it in the
  main checkout, holding the lead's landings: the lead pushes, opens and
  merges, asking the user before the merge
  ([§ "A lead's landing"](pull-request-landing.md#a-leads-landing)).
  Where an approval is required, no lead is asked, live or not: it
  could only open the pull request this session opens itself.
- **With a lead live**, as [§ "Handing a branch to a
  lead"](lead-hand-off.md#handing-a-branch-to-a-lead) finds one: hand
  off to it, by name, or park. Landing here is no option: the landing
  check stops on the lead, which sits in the main checkout.
- **With none**: land, naming the exit, the landing and the worktree's
  removal with its branch, or park.
- **A park keeps the worktree and asks nothing more**, as one issue's
  session did on 2026-10-29: the branch carries no mark, the claim
  holds, and `work-issue` on `<n>` resumes it.
