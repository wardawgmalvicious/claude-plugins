# Landing by pull request

Part of the per-issue procedure, read from the preflight on wherever
the repo's landing bullet names a pull request: its base check before
the worktree, then `work-issue`'s step 8 and `lead-sessions`' step 6.
Its placeholders are [preflight.md](preflight.md)'s.

**A repo's landing bullet names this route, and only then does a session
push.** It pushes the branch and opens a pull request saying
`Closes #<n>`, by `land-branch`'s account checks, and stops short of
the merge, which is a reviewer's, bar where `main` requires no approving
review: the user is the reviewer there, and `work-issue` merges on its
gate's yes ([§ "Merging where no approval is
required"](#merging-where-no-approval-is-required)), or a live lead on
the user's yes per merge ([§ "A lead's
landing"](#a-leads-landing)). Every other repo, this one among them,
lands by a fast-forward.

**Written 2026-10-30 from reading. `work-issue` ran it end to end in
client repos on 2026-11-04 and 2026-11-11**, the second by open
and merge. **A lead first landed by it on 2026-11-17**, in a client
repo requiring a pull request and one check but no approval: § "A
lead's landing" ran in order for a `work-issue` deferral's hand-off,
from the rebase to the merge on one `AskUserQuestion` yes, the verify
and the `landed` reply, each step as worded. Not yet run: a bounce, the
`opened` fallback, a required approval, a failing check, a lead's own
worker, and a compaction between the rename and the merge.

**Before the worktree**, in the preflight and again before each worker's
launch, from the main checkout:

```bash
git fetch origin
git rev-list --left-right --count <default>...origin/<default>   # <ahead> <behind>
grep -n -A1 '"worktree"' .claude/settings.json                    # no match, a missing file or "fresh": the default
```

- **The base is `fresh`, or no key at all.** A worktree then branches
  from `origin/<default>`, which holds what a reviewer merged, where
  local `main` lags. **`fresh` alone is not current**: Claude Code
  fetches only when the repo has gone 24 hours unfetched, capped at five
  seconds, and falls back to the cached ref (worktrees page, read
  2026-10-30). So the `git fetch` above is what makes it so. `head` works
  only with `main` level with `origin/<default>`: stop on it otherwise,
  its fix the key's removal.
- **`<ahead>` above 0 stops**: `main` holds commits no route here lands.
  Print them for the user.
- **`<behind>` above 0 reads a stale tree**, which the re-measure would
  trust. With the tree clean and the placement line of [§ "This repo's
  landing"](fast-forward-landing.md#this-repos-landing) at `exit=0`, run
  `git merge --ff-only origin/<default>`. Otherwise leave it, and read
  the evidence by `git show origin/<default>:<path>`.

**The landing.** `work-issue` runs it in its worktree after prep's
gate, dropping the `-C` and the subshell; `lead-sessions`' coordinator
from the main checkout, in its order, for its own workers' branches and
a `work-issue` hand-off's alike, going on to [§ "A lead's
landing"](#a-leads-landing). `<type>/<slug>` is `<branch>`:

```bash
git fetch origin
git -C .claude/worktrees/<slug> rebase origin/<default>          # the first push only; never once a pull request is open
(cd .claude/worktrees/<slug> && pre-commit run --from-ref origin/<default> --to-ref HEAD)
git range-diff <base>..<tip> origin/<default>..worktree-<slug>   # a prepped branch: = was reviewed; review-code reads each ! patch and any new one, intent: #<n>
git diff --stat origin/<default>...worktree-<slug>               # no prep: a language review-code's description names, Markdown among them: invoke it on this range, intent: #<n>
git branch -m worktree-<slug> <branch>                           # a commit type, as user-scope CLAUDE.md § "Branch naming" has it
git log --oneline origin/<default>..<branch>                     # this issue's commits alone, or stop
git push -u origin <branch>
gh pr create -R <owner>/<repo> --base <default> --head <branch> --title "<title>" --body-file "<S>/<slug>.pr.md"
gh pr view <branch> -R <owner>/<repo> --json number,url,headRefOid
```

Where `review-code` is not installed, [§ "Preparing to
land"](prep.md#preparing-to-land)'s `/code-review` fallback reviews the
range instead, each finding a critical one.

- **`land-branch` owns the account and the body**: load it by the Skill
  tool, `git:land-branch` where the `git` plugin serves it, its args
  naming the steps this file runs, and run its step 2 before the push
  and its step 5 for the pull request, by whichever tool step 2
  confirms. Its step 7 on runs only
  for a merge by [§ "Merging where no approval is
  required"](#merging-where-no-approval-is-required).
  **Its files are under the result's `Base directory for this skill:`
  line**, and nowhere else: the skill's folder under `~/.claude/skills/`
  went with the plugin, `installed_plugins.json`'s `installPath` named a
  cache folder that did not exist while that line named the checkout
  the plugin loads in place (2.1.326, 2026-11-17), and a search finds
  other copies, the catalog's among them.
  The rename follows its `references/linked-worktree.md`; `git branch -m`
  moves a branch's config with it, so the `#<n>` description follows,
  and the worktree's directory keeps its name.
- **The body says `Closes #<n>` on a line of its own, as the finishing
  commit does.** A squash may replace a commit's body with its default
  (`land-branch`'s `references/integration-routes.md`), and the body
  survives it. A deferral's body and commits omit the line, and nothing
  else does: **open items never keep the issue open**, since
  `work-issue`'s step 9 files each as an issue of its own. A pull
  request saying `Refs #<n>` for them left a client repo's issue open
  (2026-11-11), and `work-issue`'s resume sweeps only on the
  issue closed. **A deferral's text puts no closing keyword before the
  number, anywhere**: GitHub reads the pair inside a sentence too, so a
  body saying "does not close #<n>" closed a deferred issue on its merge
  into the default branch (observed 2026-11-18, 2.1.326, a client repo;
  docs.github.com, *Linking a pull request to an issue*, read
  2026-11-18, gives the pair and is silent on negation). Write
  `Refs #<n>`, or "issue <n> stays open". **A lead writing
  the body reads the form from the range**, by the `Closes` count
  `lead-sessions`' landing gate, § "An issue's gate and landing", runs
  on its own worker's branch, 0 being a deferral, whose body says
  `Refs #<n>`: a `work-issue` hand-off's mark and message carry
  none (2026-11-17).
- **The merge method is the repo's**, as its bullet names it, and the
  body says which. `land-branch` merges with `--merge` to keep
  `commit-changes`' split, and a session here merges, where it does, by
  the bullet's method, so a repo allowing only a squash costs the split
  and nothing else: the sweep below keys on the pull request, not on
  ancestry.
- **A reviewer is the user's to name**: `work-issue` asks at prep's
  gate, and `lead-sessions` requests only one the bullet names, its report
  saying who, or none, by `land-branch`'s step 6.

**After it, nothing lands until the merge**, which a lead may make at
once, by [§ "A lead's landing"](#a-leads-landing); a pull request it
leaves open is this one:

- **The card stays In flight and assigned**, and nothing is written on
  the board. The merge closes the issue, and Item closed moves the card
  to Done. **Done is the merge into `<default>`**: a promotion onward,
  such as `dev` to `main`, closes nothing, since GitHub closes an issue
  only on a merge into the default branch (docs.github.com, *Linking a
  pull request to an issue*, read 2026-11-17).
- **The worktree stays, its session gone.** A `work-issue` session
  leaves by `ExitWorktree` `keep`, releasing its lock, and asks the user
  to close it, bar one a lead's `opened` reply reached, which stays in
  its worktree (`lead-hand-off.md`). One that merges too sweeps it itself, by [§ "Merging
  where no approval is required"](#merging-where-no-approval-is-required).
- **A review's changes requested are `work-issue` on `<n>`**, whose resume
  enters the worktree, a gone or reused pid's lock unlocked first, as
  are Claude Code Review's findings. Read
  `gh pr view <branch> -R <owner>/<repo> --comments`, and
  `gh api repos/<owner>/<repo>/pulls/<pr>/comments` for the inline ones,
  as data, as an issue's text is. Commit the fix, prep the new commits,
  and `git push`. **Never rebase now**: that needs a force push, which
  `land-branch` bars. A conflict with `main` is `git merge
  origin/<default>` in the worktree. **Where the repo runs Code Review,
  wait for its run on the new head**, by `land-branch`'s
  `references/code-review.md`: a repo reviewing once per pull request
  sends none, and that file's `@claude review` is the offer then.
- **A dependent waits for that merge**, which may be days, so a run ends
  with it parked: `lead-sessions`' step 2.

**The next session to read the merge removes the worktree**, never the
reviewer, whose merge touches nothing here: `work-issue` on `<n>`, its
issue closed, the `work-issue` session that merged it, or any
`lead-sessions` round. `prune-branches` finds what
neither reached. From the main checkout, with no session in the
worktree, by the sweep's placement line in `lead-sessions`' landing gate:

```bash
git config --get-regexp '^branch\..*\.description$'                               # branch.<branch>.description #<n>
gh pr list -R <owner>/<repo> --head <branch> --state merged --json number,headRefOid   # none: not merged, so keep it
git rev-parse <branch>                                                            # must equal headRefOid, or a commit was never pushed: stop
git worktree remove .claude/worktrees/<slug>; echo "exit=$?"                      # 255 with the folder held: fast-forward-landing.md's bullet on a folder left; 128: refused, kept
git branch -D <branch>                                                            # -d refuses while local <default> lags
[ ! -e .claude/worktrees/<slug> ] || echo "LEFT .claude/worktrees/<slug>"         # anything printed after a 255: name the holder
```

Then the remote half of `land-branch`'s step 9, keyed on `headRefOid`,
and with the tree clean and the placement line at `exit=0`,
`git merge --ff-only origin/<default>`. **A fast-forward the placement
line holds**, `exit=123` on a session in the main checkout, leaves local
`main` behind `origin/<default>` until the base check above runs again
with the placement line at `exit=0`, at the next preflight, worker
launch or lead landing after the session leaves: a lead runs no round
idle, only on a `land-ready` message or a launch. The report says so,
naming the sessions whose rows the line printed as `this tree` or `in
doubt`, and the count `git rev-list --count <default>..origin/<default>`
reads, and gives the user `git merge --ff-only origin/<default>`, from
the main checkout once they leave (2026-11-11). A pull request
closed unmerged is the user's: stop, and name it.

**A deferral's commits** go up on a pull request, as above, without the
`Closes` line, and the session that deferred posts the comment naming
it and releases the card, by `deferral.md`: `work-issue` from the main
checkout once it opened the pull request itself, or from its worktree
on a lead's `landed` or `opened` (`lead-hand-off.md`), and a lead for
its own worker. The worktree stays until that merge, and the sweep
takes it the same way, a lead round on the pull request merged, since
the issue never closes.

## Merging where no approval is required

**Where `main` requires no approving review, the reviewer is the
user**, since an author cannot approve their own pull request (GitHub
docs, "Approving a pull request with required reviews", read
2026-11-05). With no merge here, a client repo's user finished a pull
request this route had opened by hand, `land-branch` on `<pr>` and then
`work-issue` on `<n>` to sweep, which neither skill pointed to
(2026-11-04). So `work-issue`'s gate offers to open and merge, and on
its yes runs both in this session; a pull request opened alone still
finishes that way. **Written 2026-11-05 from reading; open and merge
ran end to end on 2026-11-11.**

**Read the requirement live, before the gate**, from both of GitHub's
systems, as `land-branch`'s step 7 does, since neither read covers the
other, and never from a committed settings snapshot:

```bash
gh api repos/<owner>/<repo>/rules/branches/<default> --jq '.[] | select(.type == "pull_request") | "\(.parameters.required_approving_review_count) \(.parameters.require_code_owner_review) \([.parameters.required_reviewers[]?.minimum_approvals] | add // 0)"'   # rulesets, any level: a line per rule
gh api repos/<owner>/<repo>/branches/<default>/protection --jq '.required_pull_request_reviews | "\(.required_approving_review_count) \(.require_code_owner_reviews)"'   # classic: one line
```

**The gate offers the merge only when every ruleset line reads
`0 false 0` and the classic line `0 false`**, or `null null` from a
classic rule with no review set, and nothing else: a code owner's
review and a required team's (`required_reviewers`, rulesets only)
count as approvals, since the author cannot give either. The rules
read lists every active ruleset's rule, so a repo with several prints
a line for each, and none for no rule. The
classic read's exit 1, its JSON error body unfiltered on stdout and
`gh: Branch not protected (HTTP 404)` on stderr, is no classic rule
(measured here, 2026-11-05); any other error leaves the requirement
unread, and no merge is offered.

**The gate's one yes covers opening and merging**, which
`land-branch`'s Absolute rule, "Opening a PR and pushing `main` are
two decisions", would split: the user chose one for an issue (2026-11-05).
Where the pull request opened differs from what the gate disclosed, a
method the repo bars or a commit not in the reviewed range, stop and
ask again.

**On the yes, from the main checkout**, after `ExitWorktree` `keep`,
the pull request open:

1. Load `git:land-branch`, as above, and run its step 7 by the pull
   request row, whatever `main` requires, since the landing bullet
   names the route, with the gate's yes as its step 6. Its required
   checks first, waited out by its step 8's `gh pr checks <n> -R
   <owner>/<repo> --watch --required` under the Bash tool's `timeout`
   or `run_in_background`, so a job no rule requires stops nothing. It
   exits non-zero by design: read stderr, where `no checks reported`
   is no CI, or none registered yet, and no stop, while a failing
   check is. **Then Claude Code Review, where the repo runs it**,
   waited out and read by `land-branch`'s `references/code-review.md`,
   though its run concludes `neutral`: four merges on the required
   check alone each met real findings afterwards (2026-11-18). A result its
   table makes a stop goes to the user, since the gate's yes covers no
   merge past it: merge anyway, or leave the pull request open, as for
   a failed check below. Then `<sha>`, which must be the `headRefOid`
   the landing's last line printed, or a push this session did not
   make has moved it: stop. The merge takes the bullet's method,
   `--merge` where it names none. **Never `--admin`**: a rule left
   unmet, a review, a check, an unresolved thread or a barred merge
   method, is the user's to name, not this session's to bypass.
2. Its step 8, to verify.
3. The sweep above, at once, as the next session to read the merge:
   the worktree's removal, the remote half of `land-branch`'s step 9
   and the fast-forward of local `main`, which is why the session
   leaves the worktree before the merge.

**A failed check, a review's stop left open, a moved head or a refused
merge leaves the pull request open**, as opening it alone does: stop
and report it, the claim kept, and ask the user to close this
session. It then finishes as one opened alone: a fix by
`work-issue`'s resume on `<n>`, the merge by `land-branch` on `<pr>`,
whose checkpoint is the user's word, and the sweep by `work-issue` on
`<n>` once the issue reads closed.

## A lead's landing

**A live lead lands each marked branch in one pass, one at a time**, a
`work-issue` hand-off's and its own workers' alike, and **pushes only
then**: the branch goes up rebased on current `origin/<default>` and merges
in the same pass, so no pull request sits open and stale, no force push
is needed, and a conflict bounces before anything is pushed, as on the
fast-forward route. It is one issue's option 2, extended: the user chose
one lead to land and to field the conflicts in a pull request repo, as in
any other (2026-11-16).

**The pass**, from the main checkout, in `lead-sessions`' step 6 order:

1. **The landing above**, `git fetch origin` to `gh pr view`: the
   rebase onto `origin/<default>`, the range lint and `review-code`, the
   rename, the push and the pull request. A conflict, a failed hook or a
   critical finding bounces by `lead-sessions`' step 6, unpushed.
2. **The requirement, read live** by [§ "Merging where no approval is
   required"](#merging-where-no-approval-is-required)'s two reads, and
   held to its `0 false 0` test. An approval required, or a read that
   fails, takes the fallback below.
3. **The required checks**, waited out as that section's step 1 waits
   them. A failing one takes the fallback. Then Claude Code Review,
   where the repo runs it, waited out and read as that step says.
4. **The user's yes, per merge**: one `AskUserQuestion` naming the pull
   request's URL, the issue, `<first>..<last>`, the checks' result,
   Claude Code Review's, any stop of its table named as one, the
   merge method and the branch's deletion on `origin`, and asking
   whether anything outside git is bound to the branch. **A permission
   prompt is no such yes**, since none shows in auto mode without an
   `ask` rule on `gh pr merge`, nor under an allow rule; nor is the lead's
   invocation or a worker's message (the user's call, 2026-11-16). A no
   takes the fallback.
5. **The merge and its check**, by that section's steps 1 and 2, the
   yes above as `land-branch`'s step 6: the head held to `headRefOid`,
   the bullet's method, `--merge` where it names none, never `--admin`.
6. **The sweep above**, at once: the remote half of `land-branch`'s
   step 9 and the fast-forward of local `main` behind the placement
   line, with the lead's own id. A worker of the lead's has its
   worktree removed now; a `work-issue` session gets
   `landed #<n> <first>..<last> <url>`, and its worktree goes by the
   background wait `lead-sessions`' step 6 starts with that reply, run
   with `B=<branch>`, since the rename moved it, and, in place of its
   `git branch -d "$B"`, this file's sweep's `git rev-parse <branch>`
   check against `headRefOid` and `git branch -D <branch>`. **For every
   branch a session handed off, once the reply is sent**, `git config
   --unset branch.<branch>.landReady`, as the fallback does, since the
   wait keys on `B` and `W`, not the mark: left set, a later round's
   queue read takes the merged branch again, since a squash leaves it
   no ancestor of `main`, and sends a second `landed` (2026-11-17). A
   deferral's `landed` is the same, its range carrying no `Closes
   #<n>`: the lead writes nothing on its card, which its session
   releases from its worktree (`lead-hand-off.md`).

**A marked branch not named `worktree-<slug>`** may be a pass a
compaction or a restart cut short after its rename, which the queue
read finds by its mark on any branch (`landing-gate.md` § "The landing
queue"). Read its pull request first, `gh pr view <branch> -R
<owner>/<repo> --json state,url,headRefOid`: open, the pass from its
step 2 once the two checks below hold, never rebased again; merged, its
step 6; closed unmerged, the user's: stop, and name it; none, the whole
pass, its `git branch -m` from the branch's current name, as for the
desktop app's `claude/…`. Written from reading; a probe's `renamed` arm
resumed an open one on 2026-11-17 and reasoned out both checks, which this
paragraph did not yet name (`lead-sessions`' test README, § "The lead's
merge on the user's yes", at `tests/skills/<name>/README.md` where the
repo keeps its skill tests).

**At an open pull request, the mark and any review on record are the
pre-rebase branch's**: the mark's `<tip>` and a `landReviewed` range
end where the sender marked, before the rebase, so the `git rev-parse`
match `landing-gate.md` runs before a landing, and `lead-sessions`'
step 6 item 1 with it, fails on a branch that is right. Match its
commits instead, `<tip>` the mark's:

```bash
git range-diff origin/<default>..<tip> origin/<default>..<branch>   # each line = or !; exit 0 on a < or > line too, so read the lines
git rev-parse <branch>                                               # must equal headRefOid
```

- **A `<` or `>` line, `fatal: Invalid revision range` and exit 128
  for a tip git no longer holds, or a head unlike `headRefOid`** is a
  branch the mark does not describe: stop, and name it (a scratch repo,
  git 2.56.0, 2026-11-17).
- **The review the pass ran before the rename left no record**: the
  context that held it is the one lost. A `landReviewed` range ending
  at the mark's `<tip>` stands for each `=` line, and `review-code`
  reads each `!` patch, as the landing's own `git range-diff` line has
  it; with none on record, or on a worker of the lead's, `review-code`
  reads the whole `origin/<default>..<branch>`, `intent: #<n>`, before the
  pass's step 2. A critical finding takes the fallback, not a bounce:
  the branch is pushed, so its fix is `work-issue` on `<n>`.

**The fallback is the open and park this route had before**: the pull
request stays open and the mark is unset, since the branch is no longer
the queue's, by its renamed key, `git config --unset
branch.<branch>.landReady`: `git branch -m` moved the mark with the
description, and an unset by `worktree-<slug>` exits 5 and leaves it
(a scratch repo, git 2.55.0, 2026-11-17). A `work-issue` session gets
`opened #<n> <url>: <why>`. It finishes as [§ "Merging where no approval is
required"](#merging-where-no-approval-is-required)'s last paragraph
says of one opened alone. **A `work-issue` session hands off here only
where its gate read no approval required** (`prep.md`'s gate), so the
requirement's arm serves a lead's own workers and a rule changed since
that read.

**Against `lead-sessions`' step 6 items**: item 1, the lock and the
bounce stand, each before the push; item 2 drops, since `main` moves
only by the lead's own merge, whose fast-forward the placement line
gates; item 4 is the pass's step 1, on `origin/<default>`; item 5 is the
merge and the sweep's fast-forward, then any deploy the repo names;
item 6 is the reply above; item 7 sweeps a merge at once, and each
round runs the sweep above on every parked branch whose pull request
its `gh pr list` line reads merged, a deferral's too, whose issue
never closes (2026-11-17); item 8's card stays In flight until the merge,
the lead's or a reviewer's, bar a deferral's, released by the session that
deferred. A review's changes go to `work-issue` on `<n>`, never back
to a worker of the lead's.
