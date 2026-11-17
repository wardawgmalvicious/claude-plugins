# Choosing which findings to fix

**For the caller, not the review.** `review-code` runs as a fork and
reads none of this: the session that invoked it reads this file once the
findings are back and a critical finding is fixed, and runs it where its
own skill says. `work-issue`'s gate offers it
(`prep.md` § "Preparing to land"), and `land-branch` runs it
before its push (step 3). `commit-changes` does not: it would put a
question on every commit to the default branch.

**Why it exists**: a warning or a suggestion went only into the report,
so the user asked each worker what it had left, then had it file an
issue or reopened a worktree to fix it and hand it back (the user,
2026-11-04). Offering the fix while the worktree is open ends that loop.
**Filing the rest by default started another**: each follow-up issue
ran a reviewed session of its own, whose leftovers were filed in turn,
so § 5 files only what evidence backs (the user, 2026-11-05).

## 1. When it applies

**The review's count line shows a warning or a suggestion still
standing** once every critical is fixed. A count line of zeros, or
`no issues found`, skips it, and the count line of a fix review (§ 4)
does not start it again. **An `Unchecked:` line is not a finding**:
no fix is known for it, so it goes in the report, never in the picker.

## 2. Number and recommend

Number each 🟡 and 🟢 finding once, in the review's own order, and print
the list before asking: number, severity, `file:line`, its one-line
summary, and `(recommended)` where it is. **Recommended** is:

- a 🟡 whose fix stays in files the range already changes;
- a 🟢 whose fix is the finding's own `Fix:` snippet, in a file the
  range already changes.

**Never recommended**, whatever its severity: a fix that reaches a file
outside the range, or one that reverses a choice the issue or brief made
on purpose. Those are left, and filed only where § 5 allows, never
changes made under this branch's name.

## 3. The picker

**One `AskUserQuestion`, of up to two questions**, each standing alone,
the second asked only as its item says: the list
printed above may be off screen while the dialog is open. A session
with no `AskUserQuestion`, as `dontAsk` mode denies it, skips the picker
and reports every finding as left.

1. **Which findings to fix**, single-select. Each option's `preview`
   lists the findings it covers, number, severity, `file:line` and
   summary:
   - `Recommended: #1, #3, #4 (Recommended)`, first;
   - `All <N>`;
   - `Warnings only`, where it differs from both;
   - the caller's way out: `Back to the gate` in `work-issue`, `None,
     go on` in `land-branch`.

   Drop an option whose set repeats another's; with none recommended,
   `All <N>` comes first, unmarked. The question says numbers typed in
   Other pick any set by hand.
2. **The ones not picked**: `Report only (Recommended)`, first, and
   `File one follow-up issue`, offered only where an unpicked finding
   earns an issue by § 5, its preview naming which. With none that
   does, this question is not asked: they are left. Its answer is moot
   when every finding is picked, and the way out leaves every finding
   unpicked.

## 4. Fixing the picked ones

Make each fix in the worktree or branch under review, by its finding's
`Fix:` and the repo's editing rules: Read the file before changing it.
**A fix that turns out wider than its finding said is not made**: it
moves to the unpicked set, and the report says why. Commit through
`commit-changes`, then review the new commits: `work-issue` as its
prep reviews a critical fix's, `land-branch` by `review-code` on the
fix commits' own range. **Only a 🔴 from that review is acted on**: a
new critical is fixed as any critical is, and its 🟡 and 🟢 go straight
to the report as left, never offered, so the picker runs once per range. A
docs-only change offered its fix review's two wording findings, then
ran `review-code` a third time on their fixes, each round at 200k+ of
session context (2026-11-05).

**A Markdown-only range gets no fix review**: where the range and its
fixes change only `.md` files, the fix commits run `pre-commit`, as
`commit-changes` does at each commit where the repo's hook is
installed, and no `review-code`; where it is not, nothing runs, and
the report says so. The first review already read
the range's claims, and each fix is that review's own `Fix:` sentence.
**This spares the picked 🟡 and 🟢 alone**: a critical's own fix is
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
own**: its unpicked findings are left, whatever they hold. This caps
review findings alone: a failure the session saw in a real run is
`work-issue` step 9's open item, filed there.

On `File one follow-up issue`, Write one draft, of only the findings
that earn one, in `file-issue`'s brief
shape, its step 2's template, frontmatter first: its body check refuses
any other, `error: <file>: no frontmatter`, exit 1, after the user's yes.
Write it as `<scratchpad>/file-issue/drafts/<stem>.md`, the stem two to
four kebab words naming the area, no number, as `review-picker-followups`:
step 2 makes the stem the issue's identity. In the template:

- the heading `# Handoff: Follow-ups from the review of <branch>`;
- `Follow-up to #<n>.` first under the heading, where the branch works
  an issue;
- one section per finding: its `file:line` as `main` will hold it once
  the branch lands, what is wrong and why, and its `Fix:`.

Then invoke `file-issue` with the draft's path. **Its reconcile table is
the user's yes**, and its checks run: a repo with no board stops there,
by its own step, and the findings go in the report instead. Never a bare
`gh issue create`, which skips the card's fields and the denylist check.

## 6. The report

The caller's report names each finding as **fixed**, by the commit's
SHA; **filed**, by the issue's URL; or **left**, listed with its
`file:line` and summary. An `unchecked` count goes beside them, as
before, and so does a line saying no `pre-commit` ran, where § 4 finds
none to run.
