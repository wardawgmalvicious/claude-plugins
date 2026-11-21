# Retesting an edited skill

Part of the per-issue procedure, read by `work-issue` after prep, to
find a retest owed before the gate, and to run it on the gate's yes.
Its placeholders are [preflight.md](preflight.md)'s.

**`work-issue` retests a skill its range edited before handing the
branch on**, so a failure comes back to this worktree while it is open,
and the stamp lands with the edit. A `lead-sessions` worker does not.
It runs after prep, from the worktree, **only where the repo holds both
the stamp script and the skill the child runs**, as this one does: the
script alone would offer a retest whose child stops on an unknown
`test-skill` command. Where either is missing, the gate offers no
retest and the report names none owed. `<stamp-script>` is
`skill-status.py` by the path the repo's instructions run it at, as
root `CLAUDE.md` § "Commands" does here; with none, no retest is owed.

```bash
test -f <stamp-script> && test -f .claude/skills/test-skill/SKILL.md   # exit 1: no retest here
uv run --with pyyaml <stamp-script> --stale --base <default> --json   # rows: skill, verdict, dir, owed
```

**Owed** is a row with a `retest-*` verdict whose `owed` reads `full`
or `smoke`. `--base` rates each row's own change from the merge base,
by the rules in the script's docstring: a row `main` left stale reads
`none` unless the branch really edited it, and one whose change only
swaps old skill names for new, by `skill-telemetry.py`'s `RENAMED`,
or old group names for the ones the range moved their skills into,
reads `smoke`, `test-skill`'s smoke test in place of a full retest.
**A rename lists its old names in `RENAMED` first**, or each renamed
skill reads `full`, found at the base by no name. One rename owed
twelve full retests by the old rule, a row whose folder the range
changed, and the eight run cost about $49; replayed on its range,
`--base` owes three full and seven smoke (2026-11-07).
**Skip**, naming why at the gate: `untested` and
`untested-behaviour`, a first test that asks the user about pins, typed
as `test-skill` on `<name>`; a self-test, `lead-sessions`, `test-skill` and
`work-issue`, whose arms would run the session they sit under; and a
skill a `test-skill: <name>` row in `ListAgents` holds.

**The gate's retest option names the batch size and the whole run's
cost.** Three children run at once unless the user asks for another
size at the gate, up to four, the cap a lead holds its own workers to,
since a live lead's workers run beside them. The cost is the
children's caps summed, the budget times their number, beside what no
cap counts: one branch's nine retests, three at a time, cost $30.34 in
children and $23.47 in arms and evals, about $6 a skill, in 80 minutes
of wall time against about 158 end to end (2026-11-16, 2.1.326).

**On the gate's yes, one batch at a time.** Fill
[tester-prompt.md](tester-prompt.md) for each of the batch's skills, in
the order the rows printed, with its batch paragraph, and launch each
as that file says, `--max-budget-usd 20` unless the user named another
(the pilot child's own $2.33, 2026-11-03); the gate says it caps each
child alone, not its hand-run arms, while each eval invocation has
`test-skill`'s own `--max-cost-usd`. Then end the turn and **edit,
stage and commit nothing in the worktree until every child of the
batch has exited**: they share its index, and a stamp hashes the skill
as it is on disk. Each exit arrives as a new turn. Read it, with
`<tip>` prep's, which holds for the whole batch:

```bash
jq -b -r '"\(.subtype) is_error=\(.is_error) \(.total_cost_usd) denials=\(.permission_denials | length) \(.session_id)"' "<S>/<name>.json"
jq -b -r '.result' "<S>/<name>.json" | grep -E '^(STATUS|COMMITS|DECIDE|NOTES):'
git log --oneline <tip>..HEAD                    # prints nothing: no child commits
git status --porcelain -uall -- tests/skills/<name>/   # passed: the paths its NOTES line names
```

- **Passed**: `is_error=false`, no denials, `STATUS: passed`, and the
  reads as their comments say; a batch child also gives `COMMITS: none`
  and a `--stamp` command on the `NOTES:` line, its stamp waiting for
  the batch's end, below. A lead's tester, alone in a worktree of its
  own, names its stamp commit on `COMMITS:` and gives no command; its
  reads are those of `lead-sessions`' test mode, a stamp commit of
  `tests/skills/` paths only and a clean worktree. A stamp needs
  nothing at landing: its hashes hold across the rebase. A `conflict`
  reply naming the repo's `.tested.json` means another stamp landed
  beside it: resolve it as `test-skill`'s guide to reading a failure says,
  `main`'s side, then `--stamp --at <tested commit> --date <run date>`.
- **A pass shows only what the arms can run.** Where they cannot run
  the code the range changed, the report says so beside the pass:
  `diagnose-machine`'s arms grant Read, Glob, Grep and Skill, so no arm
  ran `network-doctor`, and that retest's stamp showed the body reads right,
  not that the skill handles the new verdict lines on live output
  (2026-11-03).
- **Failed**: `STATUS: failed` and no new commit. Put the findings to
  the user: a fix is made here, by step 5's rules, once the batch is
  committed, then prepped, and the gate offers the retest again; or the
  branch goes on with the retest still owed, said in the report. What
  the child wrote under `tests/skills/<name>/` stays out of the batch's
  commit, for the user to keep with the fix or drop.
- **A dead child**: `is_error=true`, whatever `subtype` reads, or no
  `STATUS:` line. One child ended on `API Error: 500 Internal server
  error` after 52 turns, `subtype` `success`, its stamp written and
  uncommitted (2026-11-03). Resume that session once, by
  [tester-prompt.md](tester-prompt.md) § "Resuming a dead child", its
  batch text, where a lead's tester takes the first, rather than
  launch another, since its arms already ran, unless it stopped on its
  budget or turn cap; read the resumed run by this list. **Until every
  child of the batch has a `STATUS:` line and the batch's commit, or a
  lead's tester's own, leaves `git status --porcelain` printing
  nothing, mark no branch and land nothing**: the tree holds the
  children's uncommitted files.
- **A denied fixture setup**: `STATUS: stopped`, its
  `permission_denials` naming only a script it wrote to build its
  probes, and that script's path on its `DECIDE:` line. One
  `provision-board` child stopped so on `bash <its scratchpad>/setup.sh`,
  three scratch repos with an unused `origin` and no GitHub write, the
  classifier giving no reason, for $2.08 (2026-11-07). **Read the script
  whole, then ask** by `AskUserQuestion` whether to run it, naming each
  path it writes outside the child's scratchpad and each network call,
  or saying it makes none. On a yes, run from the worktree the command
  `permission_denials` records, as a plain command, and on exit 0
  resume the child once by [tester-prompt.md](tester-prompt.md)
  § "Resuming after a denied setup", reading that run by this list:
  that child's, resumed with a note to that effect, passed for $3.23 with no
  denial. A no, a script denied here or exiting non-zero,
  or a resumed child denied again stops it, as below.
- **Anything else stops it**, a resumed child that dies or is denied
  again among them: print its `result`, the denials and `claude --resume
  <session_id>`, and leave its retest owed. A child's commit, or a
  path it wrote outside `tests/skills/<name>/`, is the user's to keep
  or drop before the batch's commit.
- **Each other `DECIDE:` line is asked** by `AskUserQuestion`, and each
  `NOTES:` line that is not `none` goes in the report, with the cost.
- **`total_cost_usd` is the child's own spend, not its arms'**: each arm
  and each `claude plugin eval` case runs as a process of its own, which
  neither it nor `--max-budget-usd` counts. file-issue's child read
  $3.22 beside $7.06 of eval cases (2026-11-06, 2.1.319). Report the arm
  and eval costs its `NOTES:` line names beside its own.

**Once every child of the batch has exited**, a resumed one included,
stamp and commit the batch in the worktree, before the next launch:

```bash
git status --porcelain   # only the batch's tests/skills/<name>/ paths
```

Run each passed child's `--stamp` command, one after another, once it
reads `uv run --with pyyaml <stamp-script> --stamp <name>
--phase <phases>` for that child's own skill and nothing more; one that
reads otherwise stops that skill's stamp, as "Anything else" does. Then
commit the stamps and each passed child's paths as one commit, by
`commit-changes`, prep it as a critical fix's is, and take the new
`<tip>`. **The stamps' hashes are the tested ones**: `--stamp` hashes
the working tree and names `HEAD`, and nothing changed either while the
children ran. **One commit a batch, not a skill**: the stamps share
their `date` and `commit` lines, which left `stage-part.py` no block of
`.tested.json` to stage one skill's apart (2026-11-16).

**No commit while a child runs**: pre-commit stashes changes to tracked
files around a commit, so a child's edited file reverts for that
window, and a write the child makes to it meanwhile is rolled back when
the stash will not reapply. On one branch, which launched a child whenever
one ended, the stash around `4ec87d0a` took `init-user-instructions`'
README while its child was writing, and the restore was clean
(2026-11-16). A batch's end is the moment none runs; strict batches
are unmeasured.

Then the next batch, if any skill is owed; once none is left, commit
any record of the retest the issue lists, as prep's deliverables check
says, then the gate again, without the retest option.
