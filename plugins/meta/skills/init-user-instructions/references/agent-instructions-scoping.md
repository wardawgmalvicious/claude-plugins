# Agent instruction files: what goes where

Applies when editing a repo's agent instructions: a `CLAUDE.md` at any
depth, an `AGENTS.md` or a `.claude/rules/` file. The question is rarely
what to write and usually where, because each home loads on its own
trigger and each misses in silence: the guidance is on disk, correct,
and never read.

The loader behaviour below was probed on Claude Code 2.1.282 on 2026-09-25;
`AGENTS.md` support needs 2.1.277.

## Where a piece of guidance lives

| Guidance is… | Home | Fails silently when |
| --- | --- | --- |
| Needed before any Read: commands, repo-wide conventions | root `CLAUDE.md` | it passes ~200 lines and adherence drops |
| About one file kind, wherever it sits | `.claude/rules/` file with `paths:` | the glob is wrong, only Grep, a pipe or a multi-file `cat` touch it, or the mistake is a live command or a sync, which touches no file; a Write or Edit loads it only once the file exists |
| About one directory, kept by its owners | nested `CLAUDE.md` | the session never Reads, Writes, Edits or views one file there itself (below), spells the path's drive letter unlike the launch directory, or has compacted and done none of them there since |
| A procedure asked for in words | skill | its description never matches |
| Must hold before the agent acts | hook or `permissions.deny` | the hook itself fails open |
| Long reference for people | README, or a short nested `CLAUDE.md` of `@README.md` | the agent never opens it |
| Shared with another tool, as Codex | `AGENTS.md`, which the `CLAUDE.md` beside it imports (below) | no `@AGENTS.md` imports it, since a `CLAUDE.md` on the path silences it |
| Derivable from the code | nowhere | never; `/doctor` proposes cutting it |

**A README is the agent's choice to open; a nested file is not.** In a
client Fabric repo, 5 of 9 sessions that worked in a folder with a
README opened it late or never, one after 52 Reads and Edits there
(2026-09-24). What a session must know before touching a folder goes in
a rule or a nested file, and the README keeps the rest.

## How Claude Code loads them

- **Root and every ancestor `CLAUDE.md` and `CLAUDE.local.md` load at
  launch.** A subdirectory's loads on the session's own first Read,
  Write or Edit beneath it, after its ancestors' (Write probed 2026-10-06
  and Edit 2026-10-07, on 2.1.291; a refused Edit loads nothing), but not
  one the session wrote or read itself, which is in context already. A
  Bash view of one file loads it as a Read does, a `paths:` rule too, but
  no `paths:` skill: a `cat`, `head`, `sed -n` or matching `grep` did,
  while a pipe, a second file, a `sed -i` and PowerShell's `Get-Content`
  did not (probed 2026-10-15, 2.1.293). Grep and Glob load nothing, and a
  subagent's Read loads it into the subagent only.
- **A `paths:` glob loads a rule's body but only lists a skill.** A
  matching Read, Write or Edit puts a `paths:` skill on the skill
  listing; its body loads only when the model invokes it or the user
  types `/<name>`. An @-mention and a Read of one pipeline item each
  loaded their rules and no skill body, with the skill listed (2.1.311,
  2026-10-27). A body every such file needs goes in a `paths:` rule on
  the same glob, which can name the skill to invoke (untested).
- **A folder added beside the working directory brings little of its
  own guidance**, whether by `--add-dir` or `/add-dir`. Only under
  `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` do its root
  `CLAUDE.md` and its rules with no `paths:` load, at launch. Its
  `paths:` rules and nested `CLAUDE.md` files never load, no user-scope
  `paths:` rule fires on a Read of its files, and of its settings only
  plugin keys apply, so its `claudeMdExcludes` and hooks do not; its
  skills do load. Probed by `--add-dir` without the variable, on 2.1.300 (2026-10-15); settings and skills by
  the permissions docs. So edit a repo from a session launched in it,
  or Read its `CLAUDE.md` and matching rules first.
- **No user-scope `paths:` rule fires on a Read outside the launch
  directory.** The docs anchor a user-level rule's patterns at the
  session's primary working directory (memory docs, read 2026-11-10), so
  a folder added by `--add-dir` misses too (above). A `.md` in a sibling
  folder loaded none, the Read succeeding, where the same kind inside the
  launch folder loaded `coding-markdown.md` (2.1.322, 2026-11-10). So no
  `**/` glob reaches a file outside the launch directory: name the rule
  to Read first in a file that loads anyway.
- **A desktop-app worktree splits its configuration.** A session the
  desktop app starts in a worktree reads settings, hooks, skills, agents,
  commands and `.mcp.json` servers from the main checkout's root, and
  runs hook commands there, while `CLAUDE.md` files and `.claude/rules/`
  load from the worktree (worktrees docs, read 2026-10-24). So a hook,
  skill or setting edited in such a worktree reaches its session only once
  it lands in the main checkout: a `PreToolUse` guard widened in one let
  through a command the worktree's copy refused (2.1.304, 2026-10-22).
- **After `/compact`** root is re-read at once, while nested files and
  `paths:` rules return only at the next matching Read, Write or Edit.
- **A new agent file is not reliably live mid-session.** The docs say
  one is picked up within seconds where `~/.claude/agents/` or
  `.claude/agents/` existed at launch, and the first in a new directory
  needs a restart (sub-agents docs, read 2026-11-05). On 2.1.318 one
  still answered `Agent type '<name>' not found` 96 s after its write,
  and one handed to a `claude -p` session did 31 s after, while two
  others ran at about 50 s (2026-11-05). The session's notice, `New
  agent types are now available`, lags the file and can follow its
  removal, so it is no gate: on `not found`, run the agent from the repo
  root as a child process, `claude -p "<task>" --agent <name>`.
- **A `.claude/rules/` file with no `paths:` loads at launch**, like root.
  A user-scope rule and a same-named project rule both load; neither
  overrides the other unless its text says so.
- **An `@import` in a `paths:` rule loads at launch**, while the rule's
  own text waits for its match (probed 2026-10-15, 2.1.293). So a scoped
  rule cannot defer a long document by importing it: one that sends
  Claude to another file names it in a code span, which import parsing
  skips.
- **`AGENTS.md` is either/or.** Claude reads it only when no `CLAUDE.md`,
  `.claude/CLAUDE.md` or `CLAUDE.local.md` sits in the working directory
  or above it; `~/.claude/CLAUDE.md`, managed files, rules, and a
  `CLAUDE.md` that `claudeMdExcludes` skips do not count. So a root
  `CLAUDE.md` silences every `AGENTS.md` in the repo, nested ones
  included. `AGENTS.local.md`,
  `AGENTS.override.md` and `.agents/` are never read.
- **A repo cannot change that for the people who clone it.**
  `pluginConfigs["agents-md@builtin"].options.instructionFiles` is read
  from user, managed and `--settings` files, and ignored in project and
  local settings.
- **The transcript is the only reliable witness.** A nested `CLAUDE.md`
  arrives as a `nested_memory` attachment after the Read, Write or Edit,
  a nested `AGENTS.md` as `hook_additional_context`. The InstructionsLoaded
  hook never fires for an `AGENTS.md` read directly, and missed two of four
  confirmed rule loads in one test (2026-09-01).
- **On Windows a nested file loads only on a path whose drive letter is
  cased as the launch directory's.** Launched at `c:\`, a Read, Write or
  Edit spelled `C:\` loads no nested `CLAUDE.md` or `AGENTS.md`, and the
  reverse holds, while a `paths:` rule loads on either; the transcript
  records no miss (probed 2026-10-15, 2.1.293). A worktree `EnterWorktree` made is rooted at git's `C:\`. So
  on Windows a folder's must-knows are surer in a `paths:` rule on
  `<dir>/**`. A `claudeMdExcludes` pattern stays driveless,
  `**/<dir>/**`: one naming the drive misses whenever its letter's case
  differs from the path's (2026-09-24).

## Naming a nested file

| Root holds | Nested files are | Because |
| --- | --- | --- |
| `CLAUDE.md` | `CLAUDE.md` | no `AGENTS.md` is read |
| `AGENTS.md` only | `AGENTS.md` | a nested `CLAUDE.md` switches root off for any session launched beneath it |
| `CLAUDE.md` of `@AGENTS.md` | `CLAUDE.md`, importing a sibling `AGENTS.md` where other tools need it | a nested `AGENTS.md` alone is never read |

An instruction file kept as a test fixture or sample is live: Read, it
loads into that session like any other. Inside a Fabric item folder is
untested; a markdown file at a workspace's Git sync root coexists with
sync.

## What a nested file holds, and where it never goes

**A nested file holds what a session must know before working in its
directory, in around 60 lines**: it joins a session already at work, so
its README keeps the reasoning. The number is a judgment, not a
measurement (2026-09-27).

- **Not under `.claude/`**, which Claude Code reads as config.
  `.claude/CLAUDE.md` is no nested file but the project file's second
  home, loaded at launch beside a root `CLAUDE.md` (probed 2026-09-27,
  2.1.282), so keep one of the two; any `.md` under `.claude/rules/` is a
  rule (above).
- **Not in a folder that is copied elsewhere**, such as a skill's. The
  file travels with every copy and loads on a Read inside any of them, so
  notes for the folder's maintainers reach its users; what running a
  skill needs goes in its `SKILL.md`.

## Sharing one file with other tools

**Never cut a root `CLAUDE.md` over to a bare `AGENTS.md`.** With no
`CLAUDE.md` beside it, it loses five things, each silently:

1. A teammate's `CLAUDE.local.md` counts as a `CLAUDE.md`, and switches
   the project's `AGENTS.md` off for them.
2. It is not read before 2.1.277, in the first session after upgrading
   from an earlier release, with the `agents-md` plugin disabled, before
   2.1.281 on Bedrock or with telemetry off, or under `claude-md` or
   `managed-only`, which a client's managed settings can set. Each leaves
   the session with no project instructions.
3. InstructionsLoaded hooks do not fire for it.
4. An `--add-dir` directory's `AGENTS.md` never loads.
5. An `@path` import outside the repo loads only if external imports
   were already approved for the project, and nothing prompts.

**Use the import form instead**, the memory docs' own recipe: shared
content in `AGENTS.md`, and a `CLAUDE.md` that is `@AGENTS.md` followed
by the Claude-only lines. Everything then loads through a `CLAUDE.md`,
so none of the five applies, and the form nests. The cost is upkeep:
every level needs both files, and whatever keys on `CLAUDE.md`, a length
cap or a rule's glob, has to follow the content. On Windows import, never
symlink. An opening import trips markdownlint MD041, and
`<!-- markdownlint-disable-file MD041 -->` at the file's end silences it
at no context cost. It pays only where people use other tools.

**A block between a generator's markers is the generator's.** Next.js
16.4.2's `next dev` writes `AGENTS.md` when it detects a coding agent,
owning the text between `<!-- BEGIN:nextjs-agent-rules -->` and
`<!-- END:nextjs-agent-rules -->`, and rewrites an edit inside on its
next run: a heading changed there came back (a client repo, 2026-10-26;
the markers read in the published package, 2026-10-27). Commit the
generated form once, and keep repo guidance outside the markers, or in
the `CLAUDE.md` that imports the file.

**Other tools read their own files.** Codex reads `AGENTS.md`, nested
ones too.
