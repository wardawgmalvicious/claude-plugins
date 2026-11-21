# A drift audit as a desktop session

**A Claude desktop session can start each due drift source's audit
as a child session of its own**, shown under it in the sidebar, which
runs `audit-source-drift` and `file-audit-findings` for that one source,
or for a source and its `with` partner, and hands its ledger rows to a
lead. `lead-sessions` starts them in its audit mode (2026-11-21),
where `report-backlog` offered them after its picks from 2026-11-14. Placeholders are
[preflight.md](preflight.md)'s, `<S>` being the scratchpad of the
session that reads the line.

## Starting the sessions

**Only where `mcp__ccd_session__start_session` is among the session's
tools**, loaded or deferred: a Claude desktop session has it, and a
terminal session or a `claude -p` has none. Where it is deferred, load
it by `ToolSearch` with `select:mcp__ccd_session__start_session` alone
in its message. Without it, nothing here runs: `lead-sessions`' audit
mode audits each source by a headless `claude -p` worker instead, which
asks its questions itself.

**Start every due source's session at once, one call each**, on the
user's yes, each with what follows. **A session that Claude started
starts at most 5**, the first 5 in the launch table's order, a source and
its partner counting as one, and names the rest in its report as due
for a session the user started. Since desktop v5.11492.0, a session
Claude started can start sessions in Auto mode with no approval, within
"10 per message you type and 5 at once" (the Claude Desktop changelog,
v5.11492.0, 2026-11-12, read 2026-11-15); no docs page states the
limits. Such a session is a child the app started, whose first message
reads `Background: … Task: …`. The changelog states no limit for a
session the user started. Each takes:

| Field | Value |
| --- | --- |
| `initiation` | `user_asked`: the yes is the user's word to start them |
| `context` | `fresh` |
| `use_worktree` | `true`, with `source_branch` `<default>`, the branch `git ls-remote --symref origin HEAD` names |
| `title` | `Audit <id> drift` |
| `name`, `branch_name` | `audit-<id>`, cut to 24 characters |
| `model` | `opus`, the two audit skills' pin, so a lead on a higher model hands none down |
| `effort` | left out, so the child inherits |
| `prompt` | the brief below, filled |
| `background` | the background below |

`<id>` is the source's registry id. `<through>`, `<next-floor>` and
`<run>` are its `docs/audits/ledger.md` row's **Through**, **Next
floor** and **Run**, each `—` where it has no row. `<issues>` lists the
deferred issues waiting on its next audit, as the lead's table names them,
or reads `none`. **A source another one's `with` field names is that
one's partner**, and their session is one: in the brief `<id>` is both,
`fabric,fabric-iq-ontology`, the partner first, and the ledger sentence
is written once per id, as `Its fabric-iq-ontology row reads …`, while
`title`, `name` and `branch_name` take the partner's id alone.

**Write the two slash commands bare, never in backticks, with a space
after each**: that is what lets the child call them (§ "Why each
choice"). `<audit-command>` and `<file-command>` are the commands of
`audit-source-drift` and `file-audit-findings`, each a `/` and the
skill's name, as the repo or its plugin gives it, and `<audit-session>`
is this worktree's own copy of this file, the path
`git ls-files '*work-issue/references/audit-session.md'` prints from
its root.
Leave the brief's other text as it is:

```text
Audit the drift source <id> and put its findings on the board, then
hand this worktree's branch to a lead. Its ledger row reads Through
<through>, Next floor <next-floor>, Run <run>. Deferred issues waiting
on this audit, each owed a verdict: <issues>. Read
<audit-session> in this worktree whole, then follow its § "The child's steps" for source <id>,
running <audit-command> --sources <id> and then <file-command>
in this same turn.
```

```text
The user ran lead-sessions under `audit` in this repo's main checkout
and said yes to one audit session per due drift source. Both audit
skills are typed only: the bare names in the task let this session call
them in its first turn, at their own effort pin. This session changes
only the ledger rows of the sources in its task, one per id, and lands
them through a lead, which the parent session is.
```

**Then the parent waits.** Each child's note, as its turns end, is one
line of the parent's report, its first line as the child wrote it.

## The child's steps

1. **Audit, then file, in the first turn.** In this worktree,
   `git status --porcelain` must print nothing. Call the Skill tool on
   `audit-source-drift` with `--sources <id>` and follow it, asking the
   user by `AskUserQuestion` what it asks, such as before auditing past
   an Open issue in the source's row. Its closing line tells the user
   to type `file-audit-findings`' slash command: instead, call the Skill
   tool on `file-audit-findings` yourself, in the same turn, and follow it.
   Where either skill says to run from the main checkout, run here:
   this worktree was cut from `main`, and step 2 checks the ledger
   against `main` before writing. **`audit-source-drift`'s read-only
   contract, its § 3 and § 8's "throughout the turn", its Bash limits
   included, holds until its report is printed**: `file-audit-findings`,
   the `file-issue` it hands to, step 2 and the ledger commit, run
   later in the same turn, are this route's. The user's yes to this
   session is their word to run `file-audit-findings`, whose § 4 table
   still takes its own yes before anything is filed.
   - **A refused call**, `cannot be used with Skill tool due to
     disable-model-invocation`, or a turn that ends before
     `file-audit-findings` runs, never falls back to reading the
     `SKILL.md` and following it, which runs without the skill's
     effort pin. Ask the user to type the skill's slash command, which
     at a message's start runs it on its pins, and wait.
2. **Write only this run's rows, against `main`'s**, one per id in
   `--sources`. Before `file-audit-findings` § 5's Edit, compare each
   one's row in `git show main:docs/audits/ledger.md` with this
   worktree's copy. A difference means another run of that source has
   landed since this worktree was cut: stop, write nothing, and tell
   the user. Otherwise edit those rows alone, and let its § 7 commit
   them here, on this branch.
3. **Prep and mark.** Run [prep.md](prep.md)'s commands and its fix,
   as another sender does, not its gate. Find a lead by
   [lead-hand-off.md](lead-hand-off.md)'s first lines, then mark the
   branch and message as its "A branch with no issue" says,
   `git branch --show-current` standing for `worktree-<slug>`. **With
   no lead live, mark the branch, send nothing, and tell the user its
   name**: a lead's queue reads the app's `claude/…` marks too, where
   the worktree sits inside the main checkout (`lead-sessions`'
   landing gate, § "The landing queue", since 2026-11-17), but a
   lead runs a round only on a launch, a worker's exit or a
   `land-ready` message. Send that message when the user says a lead is
   live. Never `land-branch`, which pushes.
4. **Stay in the worktree**, never leaving it, and act on the lead's
   replies by `lead-hand-off.md`'s table. Here a `conflict` naming
   `docs/audits/ledger.md` is another source's row landed beside this
   run's: `git rebase main`, keep every other row as `main` has it and
   this run's rows as this branch has them, then prep and mark again.
   **A lead restarted or compacted before its reply** finds this branch
   by its mark only at its next round: with no reply when the user
   asks, find the lead again by `lead-hand-off.md`'s first lines and
   send the same `land-ready` message. On `landed`, check each SHA as
   that table says, report, and ask the user to close this session.
5. **Open each turn's report with one line**, the wrap-up recap where
   the session writes one: `audit <id>: <f> filed, <o> folded, <c>
   closed, <d> declined`, or `stopped: <why>`, then `marked`, `handed
   to <lead>` or `landed <first>..<last>` once it is, since the
   parent's note quotes the first 400 characters of the recap.

## Why each choice

- **Bare names in the brief**, the user's pick on 2026-11-14,
  over the user typing two lines per child or a `claude -p` wrapper,
  which cannot ask the user mid-audit; a lead with no `start_session`
  runs one all the same, asking for it. Both skills are
  `disable-model-invocation: true`, and a bare `/<name>` in a turn's
  prompt permits the model's Skill call on such a skill for that turn,
  where a backticked one is refused (`.claude/rules/editing-skills.md`
  § "Invocation and spend fields"), untried for these two. Both
  pin `model: opus` (the user's call, 2026-11-14), which a bare-name
  call leaves unapplied, so a child runs on the model it starts on: the
  start's `model`, the parent session's or a lower one, never a higher
  one (`start_session`'s `model`). Each start passes `opus`, as
  the user's default became Fable on 2026-11-21, which a lead on it
  would hand down. Their `effort: xhigh` holds for the
  turn that calls them. On 2026-11-14 every call of four children ran
  on Opus 5.5 by its transcript's `message.model`: three started from
  the parent's Opus 5.5 turn at `xhigh`, and one from its
  `report-backlog` turn on Haiku 5.5 at `medium`, so a child takes the
  session's model and level, not the pinned turn's. On 2026-11-14
  three children briefed "Run `<audit-command> --sources <id>`",
  backticked, made no Skill call: each read the `SKILL.md` and followed
  it at the session's `high`, and one's later call on
  `file-audit-findings` was refused.
- **Both in the first turn**: the permit and the effort pin each last
  the turn alone, so a turn begun by the user's typed reply, or any
  later one, runs at the session's level and refuses the call.
  **An auto-compaction ends the permit too**: child A's
  first turn compacted at 267k tokens between the two calls, and its
  call on `file-audit-findings` was refused, so the user typed it
  (2026-11-14). An answer by `AskUserQuestion` returns as a tool result
  inside the turn, so it should keep the permit and the pin;
  unmeasured, as § "Measured, and not" lists.
- **No `effort` on the start**, the user's call on 2026-11-14:
  `start_session` takes a level at or below the parent's, and the
  skills' pin covers the turn that matters. The parent's turn then ran
  `report-backlog` at its `medium` pin, where `xhigh` might have been
  capped or refused.
- **`user_asked`, each in a worktree from `main`**: on 2026-11-14 an
  `offer` card started the fabric child in the main checkout, while
  `user_asked` with `use_worktree: true` gave the github and power-bi
  children their own, and a brief written for a worktree was wrong for
  the first.
- **One row each, checked against `main`, landed through a lead**:
  each `file-audit-findings` overwrites its source's row, and the rows
  sit a line or two apart, so parallel landings can conflict.
  The lead takes one branch at a time and bounces a conflict back. This
  repo's worktrees land with no push (`.claude/rules/handoff-briefs.md`),
  never by `land-branch`, which 2026-11-14's briefs named until each
  child was corrected by message.
- **A mark and a message, not `land-branch`**: a session in a worktree
  the app made cannot `ExitWorktree` to the main checkout, where this
  repo's landing runs, and `land-branch` pushes. A lead's queue matched
  only `^branch\.worktree-.*\.landready$` until 2026-11-17, and the app's
  branches are `claude/<slug>-<hex>`, as `main`'s reflog showed for
  2026-11-14's five retest children, `merge claude/pbi-items-retest-3d8139`
  among them, each handed by message to a lead already live. It
  reads every branch's mark now, so the mark is what the lead lands
  from, as `lead-hand-off.md` says, and a message wakes it.
- **At most 5 from a session Claude started, the rest left to one the
  user started**, over starting a sixth as one ends: the changelog says
  neither what a start past a limit does, ask or refuse, nor whether an
  idle child counts toward "at once", and each child here stays open
  until a lead lands its branch (child step 4), so a sixth could wait
  on landings. 5 is under the 10 per message as well (2026-11-15).
- **Started by a lead's own due rule**, by age and upstream, the user's
  call on 2026-11-21: `report-backlog` started these from its
  picks under `source` or `audit` alone, since a report with no
  argument picks no drift source and nothing defined a due rule.
  `lead-sessions`' audit mode says the rest of why.

## Measured, and not

**Measured on the first real run**, four children started from an
Opus 5.5 session at `xhigh` on 2026-11-14, one per repo, A to D below,
each landed through a lead, read from their transcripts:

- **The bare names load both skills in the first turn**: each child
  made a Skill call on `audit-source-drift`, then on
  `file-audit-findings`, bar child A, whose call came
  after an auto-compaction and was refused (§ "Why each choice").
- **Model and level**: every call ran on Opus 5.5, at `xhigh` until
  `commit-changes`, whose `effort: high` pin held the rest of that turn:
  the child's own prep and mark ran at `high`, 11 or 12 calls a child,
  while each `review-code` fork ran at its own `effort: xhigh` pin.
- **A ledger conflict** bounced child A's branch once,
  and its rebase onto `main` cleared it.
- **Cost**, Claude Code's own `cost-state` total by
  `measure-session-cost.py` on each transcript: $10.43 for A,
  which compacted twice at a 267k peak; $6.19 for B,
  compacted once; $6.33 for C, two `review-code` forks
  among it; $3.57 for D; $26.52 in all. Each child's first
  call held about 94k tokens of context, and each `review-code` fork
  cost $0.67 to $1.14.

**Unmeasured still**: whether an `AskUserQuestion` answer keeps the
permit and the pin, since each child asked only after both calls; and
whether the skills' `effort: xhigh` pin or the session's `xhigh` set
the level, since the two were equal; what a sixth start from a session
Claude started does, and whether a child waiting on a lead counts
toward its 5 at once; and whether `start_session` takes `model: opus`
from a parent on Fable, which no start has passed yet.
