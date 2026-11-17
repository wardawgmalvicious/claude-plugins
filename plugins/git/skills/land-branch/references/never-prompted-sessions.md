# A listed session: never prompted, or placed elsewhere

Everything behind step 1's two exemptions: what a never-prompted session
is, what [scripts/never-prompted.sh](../scripts/never-prompted.sh) reads
to find one, how
[scripts/placed-elsewhere.sh](../scripts/placed-elsewhere.sh) finds
where a session sits, why any doubt reads as live and in this tree, and
what a switch under one costs. Step 1 and the Absolute bullet carry the
rules; `commit-changes` asks the same scripts before it messages a peer
or counts one.

## What it is

On 2026-09-30 a landing in a client repo, from VS Code on 2.1.284, kept
its local branch because `ListAgents` listed a second session in the
tree. The user knew of none, and when shown the row said they had closed
it; thirty seconds later the process was still running and still
listed, so the switch and the delete went back to the user as two
commands, and the tree stayed on a branch whose upstream was gone. One
landing put the question to the user three times.

The listed process was one of two `claude.exe` started two seconds apart
under one `Code.exe`, with identical command lines. Its registry entry
read `idle`, its `updatedAt` 355 ms after its `startedAt` and unchanged
since, and no transcript existed for its `sessionId`. `ListAgents`
printed it as `interactive · idle`, the row a working peer gets.

The same afternoon another repo's window held one more: `idle` 277 ms
after its start, no transcript, and listed eleven minutes on, with
nothing started near it. Why the extension starts such a process is not
established, and a panel opened and not yet typed in reads the same.

A headless process carries it too. Four `claude -p --input-format
stream-json` processes, nothing yet on their open stdin, read `idle`
727 to 774 ms after their start with no transcript, and `ListAgents`
listed each `interactive · idle`; the script passed all four, and one
left alone kept the signature for its whole hour, until its stdin
closed. Two sent one message each read live at the registry check,
`updatedAt` 2003 and 2030 ms after start. Measured 2026-10-01 on
2.1.282, by two sessions.

**A slow start reads as prompted.** An entry turns `idle` once startup
ends, `SessionStart` hooks included, so a slow one breaks the signature.
With this machine's three bash `SessionStart` hooks and `bash.exe` in
its slow state (`bash-doctor.ps1`, 772 ms a spawn), two never-prompted
`-p` processes read `idle` 3,723 and 5,107 ms after start,
`statusUpdatedAt` equal to `updatedAt`, and the script read both live;
the same process under `--safe-mode`, no hooks, read 895 ms and passed
(2026-10-22, 2.1.308). The doubt falls on the safe side.

## The two reads

| Read | Where | Never prompted when |
| --- | --- | --- |
| Registry entry | `<config>/sessions/<pid>.json`, the one whose `name` is the row's | `status` is `idle`, and `updatedAt` is under 1000 ms after `startedAt` |
| Transcript | `<config>/projects/**/<sessionId>.jsonl` | there is none |

`<config>` is `$CLAUDE_CONFIG_DIR`, else `~/.claude`. Claude Code
documents neither read, and its times are milliseconds since the epoch.

**`idle` alone says nothing.** On 2026-10-01 an `idle` row was a session
that had committed a minute earlier and exited fourteen seconds after it
was listed; its transcript and its `updatedAt` said prompted.

**`updatedAt` moves for more than a status change**: one session's moved
three and a half minutes past its `statusUpdatedAt` (2026-10-01,
2.1.283). So an `updatedAt` still within a second of `startedAt` means
nothing has touched the entry since the process started, which is
stricter than a status that never changed.

**The `entrypoint` the script prints is not provenance.** A process
inherits it from whatever launched it, by way of
`CLAUDE_CODE_ENTRYPOINT`: one started from a VS Code session's Bash
tool read `claude-vscode`, and a `land-branch` arm called it "a VS Code
panel" on that alone (2026-10-01). The exemption does not read it.

## Why a doubt reads as live

The script passes a name only when exactly one entry carries it, each
field it compares is present with the type above, and the transcript
lookup ran and found nothing. Any other outcome exits 1 and the session
is live: no entry, two (names can repeat; the `[ref]` that ends every
`ListAgents` row tells them apart, and is in no entry), a field renamed
or retyped, a half-written file, a
directory gone, no `jq`. A release that changes the format then costs a
round with the user, as every listed session did before, and never a
switch under a peer. `never-prompted.sh`'s negative-case suite holds
each case.

## Where a listed session sits

**A row's name does not place it.** A `<cwd-basename>-<hash>` names its
session's directory, not its repo: the same for a clone elsewhere, and
another for a subdirectory of this tree. One set by `/rename`, `--name`
or a hook says nothing of where its session sits, and can look like a
derived one. A row nothing places elsewhere sits in this tree, where
`commit-changes` counts it as a peer, and `land-branch`, unless it was
never prompted, makes no `git switch` and keeps its local branch. On
2026-10-14 a `land-branch` run in a client repo placed a busy
`brief: <slug>` row by two indirect checks, both right and neither a
method.

[scripts/placed-elsewhere.sh](../scripts/placed-elsewhere.sh) is the
method. It takes the one registry entry carrying the row's name, the
entry `never-prompted.sh` reads, and asks git for the top level of its
`cwd` and of the tree it runs in. The same top level shares this HEAD
and index; another places the session elsewhere, and so does a `cwd` in
no repository, where git answers `fatal: not a git repository`. Any
doubt keeps the row in this tree, by the rule above: no entry, two, a
`cwd` missing, empty or not a string, or one git cannot read, such as a
directory gone. On 2026-10-15 the registry held seven entries, each with
a `name`, a `nameSource` and a `cwd`, and one `triage-inbox` run placed
its six peers by them, four in this tree and two in a client repo.

**`nameSource` says how the name was set**: `derived` for a
`<cwd-basename>-<hash>`, `user` for one `--name` set (2026-10-22), and
`hook` for one a `UserPromptSubmit` hook set, such as this machine's
`brief: <slug>` (2026-10-15 and 2026-10-16).
The script reads none of it, since a `cwd` places a derived row as
surely as any other.

**A name finds no entry when passed short, or when its session has
gone.** On 2026-10-16 a row `ListAgents` had listed `idle`, three hours
old, had no entry under its whole name 85 seconds later, and the next
`ListAgents` no longer listed it. A hook's `brief: <slug>` opens with
what reads like a label, and a probe arm passed such names as `<slug>`
that day. So each script's no-entry line names every entry whose name
ends in `: <name>`, for the next call to pass whole, and exits 1 all the
same, not the usage error's 2. Since 2026-10-21 the hook appends the
first prompt's local time, `brief: <slug> 2026-10-21 T08:53:42`, so the
match drops a trailing time first, and names a `brief: <slug>` passed
without it too.

A row seconds old can find none too, under a `<cwd-basename>-<hash>`
name a hook is about to replace: on 2026-11-03 one listed `started 0s
ago` read `no registry entry under this name`, and a minute later its
`[<ref>]` carried a hook's name and placed elsewhere (one observation,
2.1.317, unverified). List a young row again before asking about it,
and pass the name its `[<ref>]` now carries; still in doubt, it stays.

**`cwd` follows `EnterWorktree` and `ExitWorktree`, not a Bash `cd`.**
One session's entry read its main checkout, `c:\…`, until it ran
`EnterWorktree`, then the worktree, `C:\…`, with `updatedAt` moving and
`statusUpdatedAt` not. A Bash `cd` into a subdirectory then moved
neither `cwd` nor `updatedAt`, and `ExitWorktree` put the main checkout
back as first spelled, `c:\…` (2026-10-16, 2.1.300). A place is as old
as its read, so each move's command places its rows again. A session
whose shell has left its `cwd`, or that runs git in this tree by path
from elsewhere, stays invisible, as it always was to the derived names.

**One directory has several spellings, and git gives one.** Entries held
one path as `c:\…` and as `C:\…`, one transcript recorded its `cwd` three
ways (2026-10-14), and that session's entry changed its drive letter's
case when it entered the worktree. For a lowercase drive letter, a path
all in lowercase, a trailing backslash, an 8.3 form, and a junction to a
top level or to a folder in one, git 2.55.0.windows.3 answered one
forward-slash `C:/…`, in the filesystem's own case (2026-10-16). So
the script compares git's answers, never the `cwd` strings. It compares
them case-insensitively and as one directory to bash's `-ef` besides,
since either match keeps the row in this tree, the safe side; with both
taken out, every spelling in the suite still passed.

**A linked worktree inside its main checkout is another tree.**
`EnterWorktree` puts one under `.claude/worktrees/`, where a path-prefix
match counts it as the main checkout. git gives it a top level of its
own, and it has its own HEAD and index, so the script places its
sessions elsewhere from the main checkout, and the main checkout's
elsewhere from it.

`placed-elsewhere.sh`'s negative-case suite holds each case, the 8.3
form among the spellings.

## What a switch under one costs

A never-prompted session holds no work, but it is not stateless: its
git snapshot is taken when its process starts, not at its first prompt.
On 2026-09-30 a session whose process started 23 seconds before its
first prompt carried a snapshot without a commit made 8 seconds after
it started. A panel typed into after `land-branch` moved HEAD therefore
starts out believing in the branch HEAD was on, until its first `git` read
says otherwise. That stale belief is what the exemption risks, against
a round with the user at every landing where such a process is listed.

**Run the scripts in the same command as the move, ahead of it.** A
prompt that reaches a never-prompted session between an earlier check
and the switch makes it a peer, a session placed elsewhere can enter
this tree by `EnterWorktree` or `ExitWorktree`, and the chain then
stops before the switch. Step 7's default route, each script given the
rows it passed at step 1, by the path step 1 of `SKILL.md` names it by:

```bash
bash <placed-elsewhere.sh> <name> \
  && bash <never-prompted.sh> <name> \
  && [[ "$(git branch --show-current)" == "<branch>" && "$(git rev-parse <branch>)" == "<sha>" ]] \
  && git switch main && git merge --ff-only <branch> && git push origin main
```

Leave out a script that passed no row: given no name, it prints its
usage and exits 2, and the chain stops there. An exit 1 from either
makes a row a peer: step 7 takes its table's second row, as for a peer
who appeared after step 6, and step 9 keeps the local branch.

## Not established

- What ends such a process: the user's close did not, within thirty
  seconds.
- Why the extension starts one, and whether it always comes in a pair.
- Whether an interactive CLI session shows the same signature; a
  headless one does (§ What it is).
- Whether anything but a prompt moves a never-prompted entry's
  `updatedAt`. If something does, the session reads as live: the safe
  side.
- What `nameSource` a `/rename` writes; `--name` writes `user`.
- Whether git spells one directory one way on a network share or a
  `subst` drive. The script's `-ef` is there for a spelling git does not
  canonicalize, and no case has needed it yet.
