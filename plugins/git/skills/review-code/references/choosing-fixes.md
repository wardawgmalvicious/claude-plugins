# Choosing which findings to fix

**For the caller, not the review.** `review-code` runs as a fork and
reads none of this: the session that invoked it reads this file once the
findings are back and a critical finding is fixed, and runs it where its
own skill says. `work-issue`'s prep runs it before the gate
(`prep.md` § "Preparing to land"), and `land-branch` runs it
before its push (step 3). `commit-changes` does not: it would put
fix commits behind every commit to the default branch.

**Why it exists**: a warning or a suggestion went only into the report,
so the user asked each worker what it had left, then had it file an
issue or reopened a worktree to fix it and hand it back (the user,
2026-11-04). Making the fix while the worktree is open ends that loop.
**Filing the rest by default started another**: each follow-up issue
ran a reviewed session of its own, whose leftovers were filed in turn,
so § 5 files only what evidence backs (the user, 2026-11-05).
**Asking which to fix added nothing**: every answer to the question
this file once asked took the recommended set, so § 3 fixes that set
unasked (the user, 2026-11-17).

## 1. When it applies

**The review's count line shows a warning or a suggestion still
standing** once every critical is fixed. A count line of zeros, or
`no issues found`, skips it, and the count line of a fix review (§ 4)
does not start it again. **An `Unchecked:` line is not a finding**:
no fix is known for it, so it goes in the report, never in a fix.

## 2. Number and recommend

Number each 🟡 and 🟢 finding once, in the review's own order, and print
the list before fixing: number, severity, `file:line`, its one-line
summary, and `(recommended)` where it is. **Recommended**, and so
fixed, is:

- a 🟡 whose fix stays in files the range already changes;
- a 🟢 whose fix is the finding's own `Fix:` snippet, in a file the
  range already changes.

**Never recommended**, whatever its severity: a fix that reaches a file
outside the range, or one that reverses a choice the issue or brief made
on purpose. Those are left, and filed only where § 5 allows, never
changes made under this branch's name.

## 3. The recommended set, fixed unasked

**No question is asked**: the recommended set is fixed, by § 4, and
every other finding is left. With none recommended, nothing is fixed.
**The user's word on the fixes comes at the caller's next checkpoint**:
`work-issue`'s gate, or `land-branch`'s confirmation before the write
to `main`, the fixes on the pushed branch by then. Each fix is its own
commit, so one `git revert` takes any of them back. **A headless run
fixes the same set**: in `-p`, or `dontAsk`, which denies
`AskUserQuestion`, the question's absence had left every finding. A
session that cannot change the files leaves every finding and says so.

## 4. Fixing them

Make each fix in the worktree or branch under review, by its finding's
`Fix:` and the repo's editing rules: Read the file before changing it.
**A fix that turns out wider than its finding said is not made**: it
is left, and the report says why. Commit each fix on its own through
`commit-changes`.

**Then check that every fix stayed in the range**, `<pre-fix tip>`
being the branch's tip before the first fix and `<base>` the caller's:

```bash
git diff --name-only <base>...<pre-fix tip> > <scratchpad>/range-files.txt
git diff --name-only <pre-fix tip>..HEAD | grep -vxF -f <scratchpad>/range-files.txt   # anything printed: a fix outside the range
```

**A file printed is a fix § 2 never recommends**: revert its commit,
`git revert --no-edit <sha>`, and leave its finding, the report saying
why. The check does what the list printed at a question once did: a
caller's guessed count marked a fix outside the range, and that list
took it back (2026-11-10).

Then review the new commits: `work-issue` as its
prep reviews a critical fix's, `land-branch` by `review-code` on the
fix commits' own range. **Only a 🔴 from that review is acted on**: a
new critical is fixed as any critical is, and its 🟡 and 🟢 go straight
to the report as left, never fixed, so this file runs once per range. A
docs-only change offered its fix review's two wording findings, then
ran `review-code` a third time on their fixes, each round at 200k+ of
session context (2026-11-05).

**A Markdown-only range gets no fix review**: where the range and its
fixes change only `.md` files, the fix commits run `pre-commit`, as
`commit-changes` does at each commit where the repo's hook is
installed, and no `review-code`; where it is not, nothing runs, and
the report says so. The first review already read
the range's claims, and each fix is that review's own `Fix:` sentence.
**This spares the fixed 🟡 and 🟢 alone**: a critical's own fix is
still reviewed, as `work-issue`'s prep reviews one. A fix that changes
any other file is reviewed as above.

```bash
git diff --name-only <base>...HEAD | grep -v '\.md$'   # the caller's <base>; anything printed: review the fixes
```

## 5. Filing the rest

**A finding earns an issue only on evidence**: a failure seen in a real
run, a log or a user's report, or a guard that fails open on input a
real command would produce. A finding the review reasoned out that no
run showed, a rare shape, an untested path or a missing test is left,
in the report, and never filed; where the code keeps a known-limits
list, as the comment above `open_quote` in
`claude/hooks/identity-guard.sh` does ("The misreads known, each
failing open and accepted as rare"), it may take a line there instead.
Real use finds what matters, and `capture-learning` routes it then.
**A branch that works a follow-up issue files no follow-up of its
own**: its left findings stay in the report, whatever they hold. This
caps review findings alone: a failure the session saw in a real run is
`work-issue` step 9's open item, filed there.

**A left finding that earns an issue is the caller's to file**, never
this file's: `work-issue` step 9 drafts it as an open item, for its one
`file-issue` call, and `land-branch`'s report names it, for the user
to file by `file-issue`. Its draft gives the finding's `file:line` as
`main` will hold it once the branch lands, what is wrong and why, and
its `Fix:`. **`file-issue`'s reconcile table is the user's yes**, and
its checks run: a repo with no board stops there, by its own step, and
the finding stays in the report. Never a bare `gh issue create`, which
skips the card's fields and the denylist check.

## 6. The report

The caller's report names each finding as **fixed**, by the commit's
SHA; **filed**, by the issue's URL; or **left**, listed with its
`file:line` and summary, and with its reason where § 4 left or reverted
its fix. An `unchecked` count goes beside them, as
before, and so does a line saying no `pre-commit` ran, where § 4 finds
none to run.
