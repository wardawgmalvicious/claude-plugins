# This repo's landing

Part of the per-issue procedure, read to land where the repo's rule for
briefs names this section, as `.claude/rules/handoff-briefs.md` does
here: `work-issue`'s step 8 on the gate's land, and `lead-sessions`'
step 6. Its placeholders are [preflight.md](preflight.md)'s.

**From the main checkout, with no push.** `work-issue` asks first, at
prep's gate ([§ "Preparing to land"](prep.md#preparing-to-land)), then
leaves by `ExitWorktree` `keep`; `lead-sessions`' coordinator never
entered the worktree. `<before>` is `main`'s `HEAD` before the
fast-forward. **The landing is two runs with the review between them**,
each run handed to the `command-runner` agent as the paragraphs after
the commands say. The head, before the review:

```bash
claude agents --json | bash "<land-branch>/landing-clear.sh" '<session-id>' worktree-<slug>; echo "exit=$?"   # 0 or 3: go on; anything else: stop; a lead waits out 1
git -C .claude/worktrees/<slug> rebase <default>                # auto mode may refuse it as [Git Destructive]: the user's word lets it run
(cd .claude/worktrees/<slug> && pre-commit run --from-ref <default> --to-ref HEAD)     # no hook runs on a rebase or a fast-forward; keep the subshell
```

The review, the caller's own `review-code` call, however small the range:

```bash
git range-diff <base>..<tip> <default>..worktree-<slug>         # a prepped branch: = was reviewed; review-code reads each ! patch and any new one
git diff --stat <default>...worktree-<slug>                     # no prep: a language review-code's description names, Markdown among them: invoke it on this range
```

Either target ends `intent: #<n>`, or `intent: <path>` for a brief
file, as [§ "Preparing to land"](prep.md#preparing-to-land) passes it.
Where `review-code` is not installed, that section's `/code-review`
fallback reviews the range instead, each finding a critical one.

The tail, after it:

```bash
claude agents --json | bash "<land-branch>/landing-clear.sh" '<session-id>' worktree-<slug>; rc=$?; { [ "$rc" -eq 0 ] || [ "$rc" -eq 3 ]; } && git merge --ff-only worktree-<slug>; echo "exit=$?"   # checked again: a session may have started since the first line
git log --oneline <before>..HEAD                                # the landed commits, post-rebase SHAs
<deploy>                                                        # the repo's deploy line, only where the range changed what it deploys: the bullets below
<deploy-check>                                                  # the repo's check of the deployed payload, only after <deploy>: the bullets below
git worktree remove .claude/worktrees/<slug>; echo "exit=$?"   # once any deployed-payload check passes; 255: the folder is held
git branch -d worktree-<slug>                                   # refused while git still lists the worktree, so safe after a 255
[ ! -e .claude/worktrees/<slug> ] || echo "LEFT .claude/worktrees/<slug>"   # anything printed: not removed; exit 0 when clean
<stale-check>                                                   # the repo's stale-skill check, from its instructions, only where the range changed the repo's retest stamps: the deploy bullet below reads it; `skill-status.py --stale`'s exit 1 is an orphan row alone
```

**Each run goes to the `command-runner` agent**, by the Agent tool,
`subagent_type: command-runner`, or `github-issues:command-runner` where
that plugin carries the agent, and no `model`, since the agent pins
Haiku: one call for the head, one for the tail. Its prompt is the run's
commands in order, every placeholder and shell variable spelled out,
since each of the agent's calls starts a fresh shell, with the main
checkout's path to run them from and the scratchpad's. The caller
reads the report's exit codes and output and makes each call the
bullets below make; the agent makes none. **Each command a session
runs is a request that re-reads its whole context**, and the landing's
runs were the largest share these two skills could hand to a cheaper
model: at most $27.49 for the tail and $23.39 for the head, of a
$110.75 ceiling over one machine's personal-account sessions,
transcripts modified 2026-10-29 to 11-06 UTC, measured 2026-11-05 by
`find-delegable-stretches.py` with a scratch split by step (an issue's
deferral comment of that day). A single command gains nothing, the call and the read costing
what it saves, so the review's reads stay the caller's.

- **Drop each closing `; echo "exit=$?"`**, as the agent's body asks:
  the echo makes every line exit 0 and the agent stops on the tool's
  exit code, so a held clear would go on to the rebase.
- **The prompt says where to stop**: at the first command that exits
  non-zero, but for the head's clear, whose 3 still runs the rebase and
  `pre-commit`, and the tail's deploy and removal, whose 1 and 255
  still run the commands after each. Without the head's
  exception the agent stops on a 3 before the rebase, as a walkthrough
  found (2026-11-07); the tail's clear tests its own. The agent fixes,
  aborts and retries nothing: a rebase stopped on a conflict stays
  stopped, for `work-issue` to mend or a lead to bounce.
- **The tail carries the deploy only where the range changed what the
  repo deploys**: `<deploy>` is the deploy line its instructions give,
  here root `CLAUDE.md` § "Commands"'s `link-claude.ps1` line, where
  the range changed `claude/` or a deployed group, with `-Force` for
  `claude/CLAUDE.md` or `claude/settings.json`, and the agent runs it
  by the PowerShell tool. **A 1 from the deploy still runs the rest**:
  `link-claude.ps1` exits 1 on drift it only warns of, a
  `settings.json` differing without `-Force` or another account's MCP
  servers off the template, and that stopped 3 of 12 deploying tails
  before the `grep` and the removal, which their callers then ran
  themselves (transcripts of 2026-11-06 to 11-11 UTC). The caller
  reads the deploy's `WARNING` lines in the report, a real failure among
  them, and reruns it from the main checkout, which the removal leaves
  alone.
- **`<deploy-check>` follows only a deploy**, and only where the repo's
  instructions give one, as they give `<deploy>`: here root `CLAUDE.md`
  § "Commands"'s `grep` for a platform or git skill deployed, kept equal
  to it but inverted, so that it exits 1 with a name printed, and with
  none outside the repo's root, which stops the run before the removal:

  ```bash
  [ -d skills/fabric ] && ! command ls ~/.claude/skills | grep -xF -f <(command ls -d skills/*/*/ | grep -vE '^skills/(github-admin|github-issues|intake|social|meta|handoff-inbox|machine)/' | cut -d/ -f3)
  ```

  Any other check the deployed payload needs follows it, by its own
  command. A repo with no deploy line runs neither, so the tail goes
  from the landed commits to the removal.
- **A refusal by auto mode comes back in the agent's report**: the
  agent's transcript holds the delegation, not the user's yes at the
  gate. The caller runs that command itself, on that yes, then the
  rest of the run. None has come back yet: 139 runs under 35 auto-mode
  sessions held 212 rebase and 68 fast-forward calls, and their only
  errors were 6 conflicts and a fast-forward its own clear held
  (transcripts modified 2026-11-06 to 11-12 UTC).
- **A run past 180 s comes back twice**: since 2.1.318 a background
  subagent moves a shell command to the background after 3 minutes,
  whatever its `timeout`, "so the prompt cache doesn't expire while it
  runs" (the CLI's changelog; the tools reference still says a command
  moves at its own timeout, 2026-11-07). If the caller is first told
  the agent "is waiting on its own background work", with no report,
  that is not the result: wait for the agent's report. The head's
  `pre-commit` is the likeliest to pass 180 s.

The prompt, its first bracket the head's alone and its second the
tail's:

```text
Run these commands in order from <main checkout>, each by the tool named, and report each command, its exit code and its output. Stop at the first that exits non-zero[, except that a 3 from the first command still runs the rest][, except that a 1 from the deploy and a 255 from the worktree removal each still run the commands after it]. The scratchpad is <S>.
1. (Bash) <command>
2. (PowerShell) <command>
```

**The caller reads each report as it read its own runs**, by these:

- **A session in the main checkout stops the landing only if the move
  can cost it something**, which `landing-clear.sh` decides per row, in
  any directory of the checkout: idle clears, since the fast-forward
  costs it only its memory of the changed files and git refuses one
  that would overwrite an uncommitted file; a `test-skill: <name>` row
  holds, whatever its status, only a range touching its skill's group,
  its fixtures or `claude/`; a background row with no process clears;
  a busy or waiting session reads `notice` where the tree is clean,
  else holds; a lead and a row it cannot place hold. The script's
  header has each case.
  **A clear row needs no question**: the user's yes at prep's gate
  covers it, so land and name it in the report. An idle read-only
  session held landings until closed, one issue's on 2026-10-29 and a
  `report-backlog` run on 2026-10-30.
- **On `exit=1`, ask the user, naming each held row from the script's
  lines**, and recommend waiting. A lead waits instead (`lead-sessions`'
  landing gate, § "The landing queue"). `exit=2` means it could not
  tell: stop, and print why.
- **On `exit=3`, land**: each `notice` row loses only its view of the
  changed files, so tell each by `SendMessage` the range and those
  files, and name them in the report. The user chose that over a wait
  on 2026-11-07, after a busy, then waiting, session held four landings
  that touched none of its files.
- **The review runs because no pull request reviews a brief**, in any
  repo. **A critical finding stops the landing**: list the findings,
  and fix them in the worktree, then land from the rebase again, or
  land as is on the user's word (the user, 2026-10-27). A lead fixes
  nothing: it bounces the finding to the worker, by the table in
  [§ "Handing a branch to a
  lead"](lead-hand-off.md#handing-a-branch-to-a-lead).
  Lower ones go in the report. **A prepped branch was reviewed at prep**, so the rebase
  is what needs reading: `git range-diff` marks a patch it left
  unchanged `=`, as it did for each of the pilot's three on 2026-10-29.
- **Cite SHAs only after the rebase**, which rewrites them, each checked
  with `git merge-base --is-ancestor <sha> <default>`, since `git cat-file
  -e` passes on a stale one.
- **Deploy after the merge**, as root `CLAUDE.md` § "Commands" says,
  then any check that needs the deployed payload and any `test-skill`
  stamp, fixing forward on `main`. **A stamp the branch carried**, from
  [§ "Retesting an edited skill"](retest.md#retesting-an-edited-skill),
  still holds if `skill-status.py --stale` no longer names its skill; one it
  names again means `main` changed the skill since the retest, so the
  retest is owed again: say so in the report. The tail's last line
  runs that check, so the caller only reads it: leads ran it themselves
  in 35 landing requests from 2026-11-06 to 11-11 UTC.
- **The worktree goes once landed**, and `git branch -d` drops the
  branch's `#<n>` description with it. A remove refused as locked,
  exit 128, names the pid that took the lock, if any: alive as
  `claude.exe`, a session holds it, so stop; gone, or reused by another
  image, `git worktree unlock` it, whoever's session took
  it, this one's own by a refused `EnterWorktree` by name among them;
  no pid, a lock set by hand, stop and name it
  (`lead-sessions`' landing gate, § "The lock").
- **A folder left after exit 255 means a process holds it**, and
  the worktree is not removed, whatever git dropped:
  `error: failed to delete '<path>': Permission denied`, the admin
  entry and the files up to the held one gone, the folder kept with
  the rest, and still there once the holder exits (2026-11-04). Name
  its likely holder by `landing-gate.md` § "The landing queue", in the
  report, and leave the folder while it holds. **The next preflight
  removes it once empty**, `work-issue`'s or `lead-sessions`', by
  [§ "Preflight, from the main
  checkout"](preflight.md#preflight-from-the-main-checkout):
  a holder this session started lives as long as the session does. One
  left holding files is not empty, and stays for the user's
  `Remove-Item -Recurse`, by `landing-gate.md` § "The landing queue".
  A folder left after
  exit 128 is a refused removal, a lock or a dirty tree, with the
  worktree still listed: its error says which.
  One left after exit 0 holding only a junction or symlink, as a
  `worktree.symlinkDirectories` entry leaves, is debris: remove it, by
  `landing-gate.md` § "The landing queue".
- **A landed issue's card stays In flight and assigned**, and nothing is
  written on GitHub: the user's push carrying `Closes #<n>` to the
  default branch closes the issue, and the board's Item closed workflow
  moves the card to Done, as one issue's push did (2026-10-27).

**The placement line**, which `landing-clear.sh` narrows, still gates
what has no range to weigh, a sweep's removal and a `git merge --ff-only
origin/<default>`. It places every session but this one, and anything but
`exit=0` stops:

```bash
set -o pipefail; claude agents --json \
  | jq -b -n --raw-output0 --arg me '<session-id>' 'def mine: .sessionId == $me or (.pid | tostring) == $me; (input? // []) | if any(.[]; mine) then .[] | select(mine | not) | .name else error("no row is this session") end' \
  | xargs -0 -r bash "<land-branch>/placed-elsewhere.sh"; echo "exit=$?"
```

**Both scripts run from `<land-branch>`**, as
[preflight.md](preflight.md) resolves it, never from `land-branch`'s own
skill folder in another plugin, which an installed plugin cannot reach
(2026-11-17). `land-branch`'s
`placed-elsewhere.sh` places each by git's top level for its `cwd`: a
session in any directory of the
main checkout shares its HEAD, and one in a linked worktree has its own
(`land-branch`'s `references/never-prompted-sessions.md` § "Where a
listed session sits"). It keeps in this tree a row it cannot place, a
name two sessions share among them, and exits 1, which `xargs` returns
as 123. `-0` hands it each name as one argument, since a hook's
`brief: <slug>` holds a space, and `-r` runs nothing when no other
session is listed, where the script, given no name, exits 2. No match on
the `cwd` string places a session: on 2026-10-16 (2.1.293) the suffix
this line held, an `endswith` on the repo's former name, missed an idle
session started in `skills\`, which this line placed in this tree.

**`<session-id>` is this session's own id**, the directory above
`scratchpad` in its scratchpad path. Both checked on 2026-10-12 matched:
an interactive session's row and a `-p` coordinator's. Never leave this
session's row out by name: a `claude --resume <id> -p` dropped its `-n`
name, and the resumed coordinator was listed as the repo's former name
suffixed `-15`.
Whether a resumed row keeps its `sessionId` is unmeasured; both
coordinators that day found themselves by walking their process ancestry
instead (`Get-Process -Id $PID`, then `.Parent`, up to the `claude`
process), and that pid, passed as `<session-id>`, leaves out the same
row. A list without that row stops the landing, with jq's `no row is
this session` and exit 5, as an empty read, output that is not JSON,
`[]` and a wrong id each did on 2026-10-16; without the check, a list
that read as nothing would show no one, and pass.

`git worktree remove` refuses a dirty worktree, `fatal: '<path>'
contains modified or untracked files, use --force to delete it`, and
`git branch -d` refuses an unmerged branch, `error: the branch '<b>' is
not fully merged`; after a fast-forward neither applies. All of these
ran unprompted in an auto-mode session on 2026-10-12, on worktrees the
session's own workers had created.

**The subshell keeps this session in the main checkout.** The Bash
tool's working directory persists between calls, and on 2026-10-12
(2.1.296) a bare `cd .claude/worktrees/<stem> && pre-commit run
--all-files` left the coordinator there: the harness then named the
worktree the session's primary working directory, with the note "Do NOT
cd to the original repository root". From there, `git merge --ff-only
worktree-<stem>` merges the branch into itself: `Already up to date.`,
exit 0, `main` unmoved (a scratch repo, same day). No `EnterWorktree`
was behind the move, so no guard held: a `git -C` read of the main
checkout ran, and so did the `cd` back.

**The rebase and the classifier.** On 2026-10-06 (2.1.289) auto mode
refused `git rebase main` in a brief's worktree as `[Git Destructive]`
until the user said to run it. On 2026-10-12 (2.1.293)
`claude auto-mode defaults --label 'Git Destructive'` read that
"Reshaping the agent's own work — `--amend`, rebase, force-pushing a
personal branch containing only their commits — is the normal iteration
loop, not this rule", and a worker's `git rebase main` ran. Handle both:
a refusal goes to the user; an allowed rebase proceeds.
