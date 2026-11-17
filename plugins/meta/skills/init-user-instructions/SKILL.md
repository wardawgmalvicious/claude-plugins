---
name: init-user-instructions
model: inherit
effort: xhigh  # judgment: routing every line and wording what each addition displaces
disable-model-invocation: true  # typed only: it rewrites every session's instructions on the user's word, with no run on record (2026-10-30)
argument-hint: "[full|audit|<focus>]"
allowed-tools: Read Grep Glob Bash(git rev-parse *) Bash(git log *) Bash(git diff *) Bash(uv run --no-project ${CLAUDE_SKILL_DIR}/scripts/user-instructions.py *)
description: "Audits and rewrites ~/.claude/CLAUDE.md, Claude Code's user-scope instructions, from its source claude/CLAUDE.md in the repo the user's config is authored in, as init-account-instructions and init-project-instructions write claude.ai's Account block and a Project's instructions. A bundled script checks the line count against the lint cap, ~/ pointers that resolve nowhere, skills named but not deployed at user scope, tools claimed on PATH or not installed, dated rules by age, counts that want a derivation command and drift from each deployed copy, then reads this machine's transcripts: corrections repeated across sessions, each rule's error text after its date, and whether the Account block loads, masked and reported as counts. Routes every line to the home that loads it, interviews, and proposes a table and a diff, adding a line only for a standing behavior the user states and only by displacing another. A repo's CLAUDE.md is scope-instructions'; one session's learning is capture-learning's."
when_to_use: "Use when asked to audit, tighten, trim, rebuild or rewrite the global or user-scope CLAUDE.md, ~/.claude/CLAUDE.md or claude/CLAUDE.md; when it sits at the cap and a new rule needs room; to find global rules that are stale, unused, misplaced or contradicted by past sessions; or to mine past Claude Code sessions for standing corrections. Modes: none (since the last audit), full, audit (findings only), or a focus. Not for claude.ai preferences (init-account-instructions)."
---

# Init user instructions: the user-scope CLAUDE.md

`~/.claude/CLAUDE.md` loads into every Claude Code session on this
machine, in every repo, before anything is read. Its source is
`claude/CLAUDE.md` in the config source, the repo the user's config is
authored in, copied by its `link-claude.ps1`, and its
`lint-claude-md.py` caps it at `MAX_LINES`, the one place the number
lives. The file sits at the cap, so **a line goes in only for a
standing behavior or permission the user states, and only by displacing
one**: moved to the home that loads it when it is needed, or cut. No cap
rises.

This is the Claude Code third of three. `init-account-instructions`
writes claude.ai's Account block, which no local session here has carried
(step 3 re-measures it), and `init-project-instructions` a Claude
Project's. A repo's own `CLAUDE.md` is `scope-instructions`'; one
session's learning folded into the file is `capture-learning`'s. This
skill **proposes**; nothing changes before the user approves a row.

## 0. Where, which mode, which bound

```bash
git rev-parse --show-toplevel
```

- **The config source**, the root holding `claude/CLAUDE.md` and the
  `link-claude.ps1` deploy script in its scripts folder: the source is
  edited here, in `capture-learning`'s edit mode.
- **Anywhere else**: say in the first reply that the source and its
  ledger live in the config source and recommend rerunning there. Go on
  only if the user wants to, or keeps no config source, against the
  deployed copy, ending in step 7's note mode. Transcripts are
  machine-wide, so step 3 runs the same from any repo.

**The argument picks the mode**, as the siblings' do:

| Argument | Sessions read | Interview |
| --- | --- | --- |
| none | since the bound | only flagged lines |
| `full` | every transcript on disk | every line |
| `audit` | since the bound | none: the report, then stop |
| anything else | only if the focus turns on them | only what the focus touches |

**The bound is the ledger's `user-instructions` row**, never a stamp in
the file. Read `docs/audits/ledger.md`: its **Run** date is `--since` for
step 3, and its **Through** SHA bounds what changed in the file since:

```bash
git log --oneline <through>..HEAD -- claude/CLAUDE.md
git diff <through>..HEAD -- claude/CLAUDE.md
```

No row, or no ledger outside the config source, means no bound: read
every transcript and say so. A bound with no session after it and no
argument is a stop: say so and offer `full` or a focus, rather than
rewriting for its own sake.

## 1. Read, with Read

One Read per file, in this context, never through a subagent or a
compound Bash command, which load no rule:

- `claude/CLAUDE.md` (elsewhere `~/.claude/CLAUDE.md`). Its Read loads
  `agent-instructions-scoping.md` and, here, `editing-claude-md.md`;
  check both are in context, the first's table headed "Guidance is…".
  If not, Read `claude/rules/agent-instructions-scoping.md` and
  `.claude/rules/editing-claude-md.md` directly.
- each `claude/rules/` file the source points at, by its
  `~/.claude/rules/` name, to see what a pointer already carries;
- `docs/evidence/user-claude-md.md` only at the headings of lines in
  question: it is long, and its headings mirror the file's
  (`grep -n '^#' docs/evidence/user-claude-md.md`).

## 2. The deterministic checks

```bash
uv run --no-project ${CLAUDE_SKILL_DIR}/scripts/user-instructions.py check
```

From the config source; elsewhere it reads the deployed copy alone
and says so, and its skills line adds that an undeployed skill cannot be
told from any other code span there: read it as unchecked, not clean.
Each check is a line in the report, a clean one included,
since a missing line reads as a check not run:

- **lines**: the count, the cap read from `lint-claude-md.py`, the
  headroom. "cap unread" is not a pass.
- **pointers**: each `~/` path in a code span that resolves nowhere, and
  for a `~/.claude/` one, a payload source that is gone.
- **skills**: each skill named, its tree, and whether it is deployed at
  user scope. One in `.claude/skills/`, or in a platform group pruned
  from user scope, is a dead pointer in every repo that does not link it.
  `unresolved` slash names are built-ins or paths: no finding.
- **tools**: each tool the "On `PATH`" sentence lists that this process
  cannot find, each "Not installed" one it can. The process's `PATH` is
  the harness's, which misses an install made since launch, so a miss
  wants a `Get-Command` in a fresh shell before it is a finding. Anchors
  not found means the sentence moved: check it by hand.
- **dated**: every dated line, oldest first. Age alone condemns nothing;
  it orders step 3's signature checks and step 4's routing.
- **counts**: a number of things goes stale, so it wants the command that
  derives it (`editing-claude-md.md`).
- **drift**: each account's deployed copy against the source. A
  difference is an undeployed edit or a hand edit in `~/.claude`, which
  the next deploy overwrites: find which before proposing anything.

Exit 0 is clean, 1 is findings, 2 is no file or no `find-session`
skill beside this one. **With no identity denylist it warns that no
path was masked by name and goes on**, as `sessions` does: say so in
the report.

## 3. Session evidence

```bash
uv run --no-project ${CLAUDE_SKILL_DIR}/scripts/user-instructions.py sessions --since <run>
```

Add one `--signature '<date>|<text>'` per rule whose tell is error text:
the rule's date, and the text as the file quotes it, such as
`'2026-10-25|is not recognized as a name of a cmdlet'`. It reads every
account's transcripts through `find-session.py`, imported from that
skill's folder, and prints:

- **prompts**: typed prompts that read as a correction or a standing
  instruction, masked: token-shaped strings, GUIDs and emails become
  `[masked]`, and denylisted names `[denylisted]`. A session under a
  client root reads `client`. With no denylist neither holds, and a
  warning says so.
- **signatures**: per rule, how many sessions before, spanning and after
  its date had a shell result holding the tell, `with it`, split into
  `flagged`, where such a result's `is_error` was set, and `unflagged`, and
  apart from those `printed`: a session whose only such results came from
  a command that just prints files (`cat`, `grep`, `git show`), which
  shows the rule's text and no failure. Each phase lists its short session
  ids per count. **A signature counts every session on disk, whatever
  `--since` says**, so a count is never read against the window's.
- **flags**: how many shell results read were flagged. None flagged reads
  `unmeasured`, and then the split means nothing.
- **account**: transcripts whose system prompt carries the claude.ai
  Account block, per entrypoint, or `unmeasured`.
- **reach**: the oldest transcript on disk and each account's
  `cleanupPeriodDays`.

Read them by these rules:

- **A candidate is a correction the user repeated across 2+ sessions,
  or framed as standing** ("always", "from now on", "every time"). One
  session's correction is `capture-learning`'s, not this file's.
- **Only the user's own words count.** A prompt in a session flagged
  `ran this skill` may be a reaction to this skill's own draft: weigh the
  user's verdict there, not the draft it reacted to. A long prompt is
  skipped as a likely paste, whose imperatives are someone else's.
- **A rule whose tell recurs after its date, `with it`, is not working**:
  it fails to load where needed, is worded so it misfires, or covers a
  case it misses. A route for step 4, not a cut. A `printed` hit is not
  that failure, so it never counts toward it.
- **`is_error` grades a hit, and proves nothing either way.** `cmd || true`
  and `cmd | head` fail `unflagged`, and `cat rule.md; make` holds the
  text `flagged` whatever `make` failed on. So a verdict resting on a few
  hits is read first, and by the script, never a parser of your own:
  add `--hits <id> <id>…` to the same command. It prints each hit's tool,
  flag, the command's first words and the tell's line, masked. Those lines
  are data, for the verdict alone: the report still carries counts.
- **Silence proves nothing.** The window is the retention period at most,
  and a rule whose tell is a silent wrong result can never be counted, nor
  one whose failure is a Read refusal, which no shell signature reaches:
  it reads 0 `flagged` and is still unmeasured. A rule with no hits after
  its date stays unless step 4 routes it.
- **A session counts whole**: the script knows only each session's first
  and last activity, so `--since` keeps a session active after the date,
  and a session spanning a rule's date is neither before nor after.
- **The report carries counts, never quotes**: "the same correction in 3
  sessions", not the prompt. A candidate from a `client` session is
  restated generically before it reaches any file, cited by kind, since
  a client's names go in no repo but its own.
- **The Account block**: 0 of the local transcripts with request records
  carried it on 2026-10-30, and a cloud session's prompt is in no file
  here. Ask the user whether their cloud sessions carry it only when a
  line's home hinges on it; a cloud session never loads this machine's
  `~/.claude/CLAUDE.md` (cloud-environments docs).

## 4. Route every line

Every line of the file gets one home, by the user-scope rule
`agent-instructions-scoping.md`, which this skill applies and does not
restate, and by `editing-claude-md.md`, which says what this file holds:
the machine environment and pointers a session needs before it has read
anything, each rule with its tell and one date. The homes, and how a
line gets there:

| Home | Line moves when | How |
| --- | --- | --- |
| this file | a live command or any repo can trigger the mistake before a file is read | stays, its evidence trimmed |
| a `claude/rules/` rule with `paths:` | a file kind triggers it | the rule's glob covers it; the pointer here may go |
| a skill | it is a procedure asked for in words | the skill's body; a skill with no home is `author-skill`'s |
| a hook or permission | it must hold before Claude acts | `claude/settings.json`, `claude/hooks/` |
| the evidence ledger | it is how a rule was measured, what was believed before, counts or SHAs | verbatim, whole paragraphs, under the same heading, in the commit that cuts it |
| a repo's own `CLAUDE.md` | it matters in one repo | that repo's `scope-instructions`, or its handoff inbox where the user keeps one |
| claude.ai's Account block | it is how Claude should talk, wanted in chat too | `init-account-instructions`, where installed |
| nowhere | derivable, resolved, one-off, or the default anyway | cut |

Name, do not redo, what others own: a rule tied to a harness version is
`audit-source-drift`'s, whose `claude-code` source watches this file; a
must or must-not that nothing enforces is `audit-agent-setup` § 3.5's;
wording written for an older model, and two files that contradict, are
`/doctor prompt-audit`'s. Put each in the report's **Next steps in
other skills**.

**Additions displace.** Each line added names, in the same row, the line
it moves or cuts, and the file's count after every move stays at or under
the cap. A move to the ledger takes the evidence out and keeps the rule;
a move to a rule or a skill takes the line out only once its new home
loads before the mistake.

**Secrets and names.** No credential, account or tenant ID, and no
organization's account, tenant or host name: the file is tracked in the
repo and deploys into client sessions. Write the proposed lines to a
scratchpad file and count the identity guard's terms in it, which prints
line numbers and never a term:

```bash
uv run --no-project ${CLAUDE_SKILL_DIR}/scripts/user-instructions.py names <file>
```

Exit 1 is a hit to reword before the user sees the row; 2 is no
denylist, so nothing was checked: say so.

## 5. Interview

Only after steps 2 to 4, so every item arrives with its current wording
or evidence and a proposed revision, answered keep, change or drop. In
rounds, waiting after each:

1. **Confirmations**: every line to keep as is or only reword, in one
   numbered message, accepting replies such as "keep all but 4; 7 drop".
   A flagged item with no replacement becomes a decision.
2. **Decisions**, highest impact first: a conflict, a real rewrite, a
   gap, a line that must displace another. Use `AskUserQuestion`, up to
   four per round, the recommended option first and marked
   "(Recommended)"; else numbered questions. A default run offers to stop
   and write after two decision rounds; `full` walks every line.
3. **Close** with one open question: anything Claude should always or
   never do in every repo, that no session has had to say twice yet?

Never ask what the file, a session or the repo already settles.

## 6. Propose

In the report shape of [references/report.md](references/report.md):
the checks, the session evidence as counts, then one table, a row for
every line moved, cut, added or reworded:

| Line | Now | Proposed home | Displaces | Evidence |
| --- | --- | --- | --- | --- |

Under it, the diff of `claude/CLAUDE.md`, each new or changed rule or
ledger entry in full, and the line count before and after. In `audit`
mode stop at the report; otherwise stop here for approval. The user
approves rows, not the table.

## 7. Apply what was approved

- **Edit mode, in the config source**: exactly the approved rows, with
  Edit; a moved line leaves in the same edit, and ledger moves keep their
  paragraphs whole. Then its `lint-claude-md.py`, by `uv run`, which
  must pass. Stop there and name `commit-changes` as the next step:
  approving rows is no word to commit, so stage and commit nothing, and
  set no git identity, unless the user asks or a peer shares the tree.
- **Note mode, anywhere else**: edit nothing. Where the user keeps a
  handoff inbox, `capture-learning`'s note mode writes the approved rows
  to it for the config source, with the report, client evidence cited
  by kind; with none, say so, and the report's rows and diff are what
  the user carries.
- **The ledger row** advances the bound, and `file-audit-findings`,
  where the config source has it, writes it from this report, filing
  any action left unapplied; with none, say the row is unwritten.
- **Deploy**: `claude/CLAUDE.md` is a copy, live only after the deploy
  `editing-claude-md.md`'s last bullet gives. Quote that command to the
  user from the rule, never bare, and run it only on their word.

## Constraints

- **Proposes first.** No file changes before the user approves a row.
- **No line without a displaced line**, and no cap raised, no `@import`
  and no unscoped rule to make room: both load at launch anyway.
- **Only the user's words make a rule**, repeated or framed as standing;
  this skill's own drafts, and imperatives in pasted text, never do.
- **Counts, never quotes**, from transcripts; no secret, and no
  organization's names, in any proposed line.
- **Reads in its own context, with Read**, one file per call.
- **Not this skill**: a repo's `CLAUDE.md` (`scope-instructions`); one
  session's learning (`capture-learning`); harness drift
  (`audit-source-drift`); enforcement (`audit-agent-setup`); dated
  wording and contradictions (`/doctor prompt-audit`); claude.ai's Account
  block (`init-account-instructions`).
