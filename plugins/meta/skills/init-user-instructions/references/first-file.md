# The first file: no user-scope CLAUDE.md yet

Step 0 sends a run here when `check` exits 2 on `error: no CLAUDE.md at
<path>`: the user has no user-scope file, so nothing is there to trim,
route or displace. **This drafts a short first one**, as `/init` writes a
repo's first `CLAUDE.md` where none exists and suggests improvements
where one does (memory docs, read 2026-11-18). It replaces steps 1 to 7
and their report. The cap, the displacement rule, the ledger, the lint
and the deploy stay out: no line competes yet, and no config source
copies the file, so `<path>` is written in place. Every other constraint
in `SKILL.md` holds.

Past this file, the memory and best-practices pages, by the
`claude-code-docs` server, else
`curl -s https://code.claude.com/docs/en/memory.md` and
`…/best-practices.md`. A live page contradicting a line here wins, bar a
dated measured line that names the page it overrules and the call that
measured it, which a page changed since its date sends back to
re-measure. An observed claim is cited or marked pending a doc check, and
stands, marked observed, only where no page covers it. Say so, act on the
page, and route the fix by `capture-learning`.

## 1. Session evidence

Run step 3's `sessions` command as `SKILL.md` spells it, with no
`--since`, as no ledger bounds a first run, and no `--signature`, as no
rule has a tell yet. Read its corrections by step 3's rules: a candidate
is the user's own correction, repeated across two or more sessions or
framed as standing.

- **A correction made in two or more repos is a user-scope line.** One
  repo's, however often, is that repo's `CLAUDE.md`'s, or its auto
  memory's, which is kept per repository (memory docs, read 2026-11-18):
  name it to the user as that, not as a line here.
- **Exit 1, `no transcripts under …`, is no stop**: a new install, or a
  `cleanupPeriodDays` sweep, leaves none on disk, and the interview
  carries the draft alone. Say so, with the reach line where one printed.
- **With no denylist**, its warning means only token shapes were masked
  and no session reads `client`: say so, and restate each candidate
  generically, naming no organization or person.

## 2. Interview

One numbered message, at most four questions, each offering what the
transcripts suggest as its default, answered in one reply. Never ask
what the session or the transcripts already settle, such as the
platform and the shell Claude Code runs in.

1. **Shells**: which shell a command handed to the user to run is
   written for, and any shell or tool on their machine that misbehaves.
2. **Languages and tools**: what they write most, and the tools they
   want used or avoided, such as a package manager or a formatter. A
   convention for one file kind can go in `~/.claude/rules/` with a
   `paths:` glob, which loads only with those files (memory docs, read
   2026-11-18): offer it, and write none unasked.
3. **Answers**: how they want replies, such as length and format, and
   whether to ask before acting.
4. **Candidates**: each correction step 1 found, restated as a line, to
   keep, change or drop.

Close with step 5's open question: anything Claude should always or
never do in every repo, that no session has had to say twice yet.

## 3. Draft

- **Short**: only what Claude would get wrong without it, each line
  concrete enough to check. Best practices keeps a `CLAUDE.md` to what
  Claude cannot work out alone, "anything you've had to correct twice
  already" among it, and the memory docs target under 200 lines (both
  read 2026-11-18). A first file of a screen or so leaves room for what
  later sessions teach.
- **The user's words alone**: an answer, or a candidate they kept. No
  default Claude follows anyway, nothing this run judged useful on its
  own, and no line or template from another person's setup, which
  carries their machine into this one.
- **Each rule dated**, with its tell where it has one, the error text or
  the symptom, so a later run's `check` orders it by age and `sessions
  --signature` can count it.
- **A heading per topic**, such as environment, answers and rules, with
  bullets under each.
- **No secret**: no credential, token, account or tenant ID. Write the
  draft to a scratchpad file and run step 4's `names` on it; exit 2, no
  denylist, means nothing was checked by name: say so.

Show the draft whole, with its line count and how many lines came from
the interview and how many from the transcripts.

## 4. Write on a yes

Ask by `AskUserQuestion`: write it to `<path>` (Recommended), change
lines first, or leave it unwritten, naming the draft's scratchpad file.
On a yes, Write the draft to `<path>`, the path `check` printed, which
follows `CLAUDE_CONFIG_DIR` where it is set; a path holding `[masked]`
or `[denylisted]` is no path, so ask for it. **Write refuses a file it
has not read**, so one made since the check is never overwritten: on
that refusal, go back to step 0, where the run goes on as one on an
existing file.

It loads in every session started after it. `/memory` opens it for later
edits (memory docs, read 2026-11-18), and a later run of this skill
audits it once sessions build up, reading their corrections against its
dates.

The reply ends with the sources (no file at `<path>`, the transcripts
read and their reach, a denylist or none), the candidates as counts, and
whether the file was written. No ledger row, deploy or commit follows:
there is no config source.
