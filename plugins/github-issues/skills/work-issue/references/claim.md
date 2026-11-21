# Before the claim: the worktree's name and a shared file

Part of the per-issue procedure, read before a claim:
`work-issue`'s steps 3 and 4, and `lead-sessions`' step 2 and each
launch. Its placeholders are [preflight.md](preflight.md)'s.

## Naming the worktree

**The worktree takes the issue's subject, never its number**, as a
branch name does (the user-scope `CLAUDE.md` § "Branch naming"): the
2–4-word kebab slug the body names for its worktree, where it names
one, as an issue's names `audit-repo-board-check`, else one made from the
title. Its branch is `worktree-<slug>`.

```bash
find docs/handoffs -name '<slug>.md'   # nothing: no brief file has the stem
git worktree list                      # no .claude/worktrees/<slug>
```

Print the slug before the claim.

## Checking for a shared file

**Before a claim, compare the issue's files with every branch in
flight**: `work-issue` at its step 4, `lead-sessions` before each
launch, both from the main checkout. Neither the ready order nor the
lead's same-file rule sees the other side: the ready order drops an
issue someone holds, and the lead's rule orders its own chain alone. So
one issue, worked by hand beside a lead's two issues, met them first at
the lead's rebase, on two shared files (2026-11-04).

**An issue's files** are those its `## Where it lands` section names,
else the repo paths its body names, as `lead-sessions`' step 2 reads
them, and an evidence ledger such as `docs/evidence/` counts on neither
side, as there; this check adds that a folder covers the files beneath
it. **A branch's files** are its changes so far and its issue's, since
one claimed a minute ago has changed nothing yet. The view is read
afresh, since In flight is what changes between steps:

```bash
uv run --no-project "<skills>/triage-inbox/scripts/handoff-status.py" . --no-inbox --json > "<S>/queue.json"
jq -b -r '.repos[0].briefs // [] | .[] | select(.in_flight != null) | [.path, .in_flight, .title] | @tsv' "<S>/queue.json"   # the board's In flight, and brief files by worktree
git log origin/<default>..<default> --format=%B | grep -E '^Closes #[0-9]+$'   # landed, waiting for the push: not in flight
git config --get-regexp '^branch\..*\.description$'                             # branch.worktree-<slug>.description #<m>
git worktree list                                                               # every worktree-<slug> branch
git diff --name-only <default>...worktree-<slug>                                # per branch: its changes so far
gh issue view <m> --json body -q .body                                          # per issue: the paths it names
```

**The board lists the issues and git the branches**, since neither
holds both: a lead's worker carries no `#<m>` description until its
gate marks it (`lead-sessions`' landing gate, § "The landing queue"), and a
claim from another machine has no branch here. Name a branch by its
description, else by its worktree. A landed card stays In flight until
the push, so one whose `Closes` line `main` holds is out, and a merged
branch's diff prints nothing. `lead-sessions` leaves out its own
chain, which its step 2 already orders.

**Under `work-issue` a match warns, and never blocks**: a shared file
is no conflict, as two changes to one file often sit apart. It names each
in-flight issue or branch with the paths it shares, and asks by
`AskUserQuestion`, its pick first and marked "(Recommended)", from what
`git diff <default>...worktree-<slug> -- <path>` shows of the other's edit:

- **Proceed**, accepting a rebase at landing: claim as before.
- **Take the next ready issue**: the ready order's next line, its card
  read and checked as step 1 reads one.
- **Wait for it to land**: stop here, unclaimed, for `work-issue` on
  `<n>` once it has.

**Under `lead-sessions` a match holds the launch**, as a shared file in
its own chain does, until that branch lands, which the lead does from
its mark, or its card leaves In flight; the launch table names it as
what the brief waits for, and its step 2 says how a run ends on one.

**A shared file is never a `blocked-by`.** Filing knows only the paths
an issue names, and a link set then serializes the two for good, where
this check sees only what is in flight now: `blocked-by` stays for a
real code dependency.

**The landing still catches what this misses**: the lead bounces a
conflict to its worker, and the review of each range, run again on
what a rebase changed, guards a conflict that rebases cleanly.
