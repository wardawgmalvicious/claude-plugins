# The retest child's prompt

The text below is the whole prompt a retest child gets, from
[retest.md](retest.md) § "Retesting an edited skill" or from a
`lead-sessions` test run, by that skill's `references/test-mode.md`,
one file for both, with `<name>` the skill, `<verdict>` its row's verdict, `<group>` its
`dir`'s group, `<command>` `test-skill`'s slash command, a `/` and
its name, as the repo's `.claude/skills/` holds it, and `<dir>` the
child's own scratchpad, the folder made before the launch below, by its full
path in long form, and `<default>` the default branch
[preflight.md](preflight.md) read. Write the filled
text to `<scratchpad>/<name>.prompt` with Write and pass it **on
stdin**. It opens with the slash command so the typed-only `test-skill`
expands; the rest arrives with it as the command's arguments.

```text
<command> <name>

Another session started you from its worktree, the directory you
are in, to retest <name>, which skill-status.py
rates <verdict>. Nobody can answer a permission prompt or a question,
and the run ends when you stop.

Test the skill as it is in this worktree. Your scratchpad is <dir>,
an empty folder made for you, since your environment names none. Write
probe directories and arm output under it, and pass
test-activation.ps1 a -ProbeRoot under it, since other sessions run
beside you. Run each shell command as a plain one of its own, not
chained to another by && or ;, and give a command that needs a folder
its full path in place of cd or a variable set on an earlier line.
test-skill's plugin eval block is written chained: run its steps one
by one so. A claude
plugin eval run with --keep-temp leaves each run's folder in the temp
folder: once you have read them, delete those folders by the paths the
eval printed, never by a glob.

Where the skill would ask the user something by AskUserQuestion, put
the question on the DECIDE line instead and go on.

Only if the retest passed: stamp here, in this worktree, and commit the
stamp, with anything the test added under tests/skills/, by
commit-changes, on this worktree's branch. If it failed, commit
nothing.

Do not call EnterWorktree or ExitWorktree, mark the branch or message
any session. Never edit the skill, and delete no brief: name on the
NOTES line any brief test-skill step 10 would delete. Do not rebase,
merge or push.

If an action you need is denied, or the test needs a decision only the
user can make, stop at once without working around it. If what was
denied is a script you wrote to set up your probes, keep it, and on the
DECIDE line give its full path and ask whether the parent should run it.

End your reply with four labelled lines:
STATUS: passed, failed or stopped, and why.
COMMITS: each commit's hash and subject, or none.
DECIDE: a question for the user, or none.
NOTES: anything the user should know, or none, including every command
that was denied, and on this line the hand-run arms' total cost and
each eval invocation's total, as its summary prints it.
```

For a row whose `owed` reads `smoke`, add one paragraph after the one
beginning "Another session started you"; a row with no `owed`, as a
backlog retest's, takes none:

```text
skill-status.py --stale --base <default> rates this branch's change to
<name> rename-only, owed smoke: run test-skill's smoke test, step 8,
in place of the full retest.
```

For a skill in a standing group, one the repo deploys at user scope,
as root `CLAUDE.md` § "Branching and concurrent sessions" lists them
here, add one paragraph after the same one, and after the smoke
paragraph where there is one:

```text
<name> is in the standing group <group>, so ~/.claude/skills lists the
main checkout's copy: run every arm from a probe holding this
worktree's copy, on --setting-sources project,local, as test-skill
step 7 says.
```

For a child of `work-issue`'s retest, which runs beside the rest of its
batch in its parent's one worktree, put this paragraph in place of the
one beginning "Only if the retest passed"; a lead's tester, alone in a
worktree of its own, keeps that one:

```text
Other children may be retesting other skills in this worktree beside
you, and they share its index, so stage, stamp and commit nothing, whatever
test-skill's steps say: run neither skill-status.py --stamp nor
commit-changes. Write in this worktree only under tests/skills/<name>/
and leave it uncommitted. If the retest passed, give on the NOTES line
the exact skill-status.py --stamp command for <name>, naming only the
phases that ran, each path you wrote under tests/skills/<name>/, and
anything test-skill would have written elsewhere.
```

Before the launch, make the child's scratchpad, `<S>` this session's,
and fill `<dir>` with the path it made. Where `<S>` holds an 8.3
segment such as `USERNA~1`, expand it by `cygpath -lw` first:

```bash
mkdir "<S>/tester-<name>"   # "File exists": an earlier child's; take tester-<name>-2, then -3
```

Launch it from the worktree with the Bash tool's `run_in_background`,
adding the `--max-budget-usd` the gate or the offer named:

```bash
claude -p -n "test-skill: <name>" --permission-mode auto --permission-prompts none --output-format json < "<S>/<name>.prompt" > "<S>/<name>.json" 2> "<S>/<name>.err"
```

## Why each sentence is there

- **"<command> <name>" first, on stdin**: the skill is typed only, so
  its description is not listed and no prose request reaches it; only
  the slash path does. Git Bash rewrites a leading-slash argument to a
  path under the Git install (`test-skill` step 8, 2026-09-02), and
  stdin is no argument. The pilot's first user record was the
  `test-skill` expansion (the pilot skill's `tests/skills/<name>/README.md`,
  where the repo keeps one).
- **The smoke paragraph**: the child rates nothing itself, and
  `test-skill` runs its full matrix unless told the change is a rename;
  the parent read `owed` from `retest.md`'s `--base` row.
- **The `-n` name**: `landing-clear.sh` holds a lead's landing that
  touches a `test-skill: <name>` row's skill, and `editing-skills.md`
  § "A skill a peer is testing" reads the same rows.
- **"Nobody can answer"**: `--permission-prompts none` denies whatever
  would prompt and removes `AskUserQuestion`, as for `lead-sessions`'
  workers (`worker-prompt.md` there).
- **"as it is in this worktree"**: the child's cwd is the worktree, so
  `.claude/skills/` loads from it and step 7's probe copies come from
  it; only a standing group's junction points elsewhere, which the
  extra paragraph covers.
- **"Your scratchpad is <dir>"**: a headless `claude -p` gets no
  scratchpad in its environment, so "your scratchpad" named nothing. On
  one issue the `capture-learning` child looked for one by listing the temp
  folder in a chained command, which auto mode denied, and stopped;
  told to use the one its environment names, it replied it had none and
  stopped again: two runs, $2.65, no arm run. Given a new empty
  folder's full path under the parent's scratchpad, it ran and
  passed, as the `triage-inbox` child, given one up front, did first
  time (2026-11-11). That parent worded the path in its own words: this
  prompt's sentence is unmeasured. A relaunch takes a new folder: arms
  sharing one met each other's files (the pilot skill's
  `tests/skills/<name>/README.md`, "Confounds"), and a reused
  folder would hold the earlier child's, unmeasured.
- **"a plain one of its own"**: that child's denied read was a chained
  command; whether the chain or the temp folder drew the denial is
  unmeasured.
- **"a -ProbeRoot under it"**: the script's default probe is
  `$env:TEMP/claude-activation-probe-<set>`, one per set, and its
  `finally` tears the probe down, so two testers on one set would delete
  each other's (the repo's `test-activation.ps1`, `test-skill` step 6).
- **"delete those folders by the paths the eval printed"**: each kept
  run is a `claude-eval-<random>` folder that nothing else removes soon
  (`clean-temp.ps1` waits 14 days, and its weekly task was not
  registered on 2026-11-05), and 40 had piled up by 2026-11-05, while a
  glob would take a tester's beside it (`test-skill`'s guide to reading
  a failure, "Model and effort").
- **"on the DECIDE line"**: `test-skill` step 10 asks a pin change or a
  bundled script by `AskUserQuestion`; the parent asks it instead, with
  the user present.
- **"a script you wrote to set up your probes … its full path"**: the
  classifier denied a `provision-board` child its fixture script,
  giving no reason, and the parent can run one only once it has read it
  (`retest.md`, "A denied fixture setup", 2026-11-07). "Keep it" is a
  precaution, in case a cleanup on the stop removes it; no child has
  been seen to.
- **"stamp here"**: an issue's branch holds the edit, so the stamp
  lands with it (`test-skill`'s guide to reading a failure, "The
  exception is a branch holding the tested edit"). A backlog retest's
  worktree is cut from `main` and holds no edit, so its stamp, taken
  before the branch's first commit, names a commit on `main`, as
  `test-skill`'s own stamp in a lead's worktree does. A failed retest
  writes no stamp.
- **The batch paragraph**: a `work-issue` parent runs its children
  side by side in its one worktree, so its index is theirs, and every
  stamp rewrites the repo's `.tested.json`: two children committing
  at once meet on `index.lock` or sweep each other's stamp in. So the
  parent stamps and commits once the batch has exited
  ([retest.md](retest.md)), from the command and paths the `NOTES:`
  line gives. A lead's testers each have a worktree and branch of their
  own, their stamps meeting only at a rebase, so they keep the stamp
  paragraph. One branch's nine children ran so, none stamping, on their
  parent's own wording (2026-11-16): this paragraph is unmeasured.
- **"Do not call EnterWorktree … mark the branch or message"**: a typed
  tester with a lead live enters a worktree and hands it to the lead;
  this one is already in its parent's worktree, and the parent hands
  the branch over, or a lead lands it, once, after the retest.
- **"Never edit the skill"**: a stamp hashes the skill as it is on disk,
  so an edit in the same run records itself as tested. A fix is the
  parent's, with the user, before the next retest.
- **"delete no brief"**: `test-skill` step 10 deletes a brief still
  queued, and an open edit brief naming the skill would lose its edit
  unmade.
- **The four labelled lines**: the parent reads `STATUS:` for passed,
  failed or stopped, `COMMITS:` beside `git log`, and asks `DECIDE:` and
  reports `NOTES:`.
- **"on this line the hand-run arms' total cost and each eval
  invocation's total"**: each is a process of its own, outside the
  child's `total_cost_usd` and `--max-budget-usd`, so the reply is the
  read the parent is handed: file-issue's child read $3.22 beside $7.06
  of eval runs (`retest.md`, 2026-11-06). "On this line" because
  `retest.md` greps the labelled lines, so a NOTES carried onto a
  second line loses it.

## Resuming a dead child

A child whose JSON reads `is_error` true, or holds no `STATUS:` line,
is resumed once, from the worktree, with this text in
`<scratchpad>/<name>.resume`, `<stamp-file>` being the repo's
`.tested.json`, where it keeps its retest stamps:

```text
Your run ended on an error before your reply's labelled lines. Do not
run the test again. If the retest passed, commit the stamp, with
anything the test added under tests/skills/, by commit-changes, on
this worktree's branch. If it failed, or you cannot tell which, run
git checkout -- <stamp-file> and commit nothing. Then end
your reply with the four labelled lines your first prompt asked for.
```

A child given the batch paragraph takes this text instead, since its
siblings may still be running in the tree:

```text
Your run ended on an error before your reply's labelled lines. Do not
run the test again, and stage, stamp and commit nothing, as your first
prompt said. End your reply with the four labelled lines it asked for,
the NOTES line giving the stamp command and the paths it asked for if
the retest passed.
```

```bash
claude -p --resume <session_id> -n "test-skill: <name>" --permission-mode auto --permission-prompts none --output-format json --max-budget-usd <left> < "<S>/<name>.resume" > "<S>/<name>.resumed.json" 2> "<S>/<name>.resumed.err"
```

`<left>` is the budget less the first run's `total_cost_usd`, and the
parent reads `<name>.resumed.json` as it read the first. One issue's
resume, with this text and no `-n`, passed in 6 turns for $2.62
(2026-11-03). **A child stopped by its budget or turn cap is not
resumed**, nor one whose `<left>` is not above 0: it stops, as
`retest.md`'s "Anything else" says. The `-n` is given again
since a `-p` resume without it was listed under another name
(`fast-forward-landing.md` § "This repo's landing"), which
`landing-clear.sh` would not read as a tester's; that it restores the
name is unmeasured.

## Resuming after a denied setup

A child stopped on its own fixture script, which the parent then read
and ran on the user's yes, exit 0, as `retest.md`'s "A denied fixture
setup" says, is resumed once, from the worktree, with this text in
`<scratchpad>/<name>.resume`, by § "Resuming a dead child"'s command and
its `<left>`, and under its caps. `<path>` is the script's path from
the child's `DECIDE:` line:

```text
The parent session read <path> and, on the user's yes, ran it from this
worktree, exit 0. Do not run it again. Go on with the retest from where
you stopped, as your first prompt says, and end your reply with the
four labelled lines it asked for.
```

A `provision-board` child's resume, with a note to the same effect,
passed for $3.23 with no denial (2026-11-07); this text is unmeasured.

## Measured, and not

Measured 2026-11-03 (the pilot's `tests/skills/<name>/README.md`): the
worktree guard runs the launch, the stdin slash expands, the child's arms
run under `--permission-prompts none` with no denial, and it stamps and
commits on the branch. **The worktree guard does not reach the child**,
a plain `claude -p` whose cwd is the worktree: it ran chained git and
`git -C` into the main checkout, which the parent's guard refuses. A
probe child launched by that command, on Sonnet, ran `pwsh` from Bash,
the PowerShell tool and `test-skill`'s `claude plugin eval` block, at
one Haiku run, to results, each with no refusal, while the parent's
guard refused `claude plugin eval --help` (2.1.317).
**Unmeasured**: a failed retest's fix loop. A failure there is a stop:
report it with the child's `claude --resume <session_id>`, and correct
this file.
