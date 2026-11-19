---
name: measure-session-cost
model: inherit  # a haiku pin would rewrite a long session at $1/MTok past a 100k prompt, against Opus 5.5's $0.20 read
effort: high  # runs a bundled script and reads its report; tiers in editing-skills.md
disable-model-invocation: true  # typed only: the user's call of 2026-11-05
argument-hint: "[session id | --repo <folder> --last <n>]"
allowed-tools: Bash(uv run --no-project ${CLAUDE_SKILL_DIR}/scripts/measure-session-cost.py *)
description: "Reports what a Claude Code session cost at API list prices, by phase, by model and by subagent, from its transcripts on disk, through a bundled script holding a dated price table. Prices each call's context, read from or written to the prompt cache, and its output; splits the session at each compaction and each idle gap over an hour; names every call that rewrote its context to the cache and why, whether the start, a compaction, an expired cache or a model switch; gives the context at the first call, before any work, and the tools called with the size of what they returned. Takes a session id or its start, the current session, or a repo's newest sessions, in every account's config directory. A model, speed or usage shape the table lacks is reported unpriced, never guessed. Reads only. Finding a session by what was said in it is find-session's. Typed only: measure-session-cost [id | --repo <folder> --last <n>]."
---

# Measuring what a session cost

**A session's bill is its context times its calls, not its output.**
Each API call re-reads everything before it from the prompt cache, and
writes what is new, so a long session is dear because every call carries
the whole conversation. Two work-issue sessions in a client repo cost
about \$23 and \$11 at list prices, of which output was about \$4, and
resuming each after nine idle hours rewrote its whole context to the
cache, about \$5 between them (2026-11-05). The bundled script
reads a session's transcripts and says where its cost went, so a change
meant to lower it can be measured, not assumed.

Past this file, the live page: code.claude.com by the
`claude-code-docs` MCP server or
`curl -s https://code.claude.com/docs/en/<page>.md`, and the prices by
`curl -s https://platform.claude.com/docs/en/about-claude/pricing.md`.
A live page that contradicts a line here wins: say so, act on the page,
and route the fix by `capture-learning`, bar a dated measured line that
names the page it overrules and the call that measured it, which a page
changed since its date sends back to re-measure. An observed claim is cited
or marked pending a doc check, and stands, marked observed, only where no
page covers it.

## 1. Run

```bash
uv run --no-project ${CLAUDE_SKILL_DIR}/scripts/measure-session-cost.py [<id> | --repo <folder> --last <n>] [--json]
```

- **No argument** measures the current session, so far.
- **An id, or its first eight characters**, measures that session: from
  `find-session`'s `claude --resume` line, or the transcript's name.
  Words after `measure-session-cost` are the arguments.
- **`--repo <folder> --last <n>`** measures the newest n sessions run in
  that repo, by its folder name, its worktrees counted as it, the asking
  session left out; `--last` is 1 by default.
- **`--json`** prints the same as JSON, for parsing; its stamps are UTC,
  where the text's times are local.
- **Keep `--no-project`**: without it, `uv run` in a repo with its own
  Python project syncs that project first. The script needs no
  dependencies.

## 2. Read the report

- **The total line** gives the cost of the calls the script priced, at
  the list prices of the date it names, split between the main thread
  and its subagents. A compaction's, an away summary's and a prompt
  suggestion's own calls are not in it (Phases, below).
- **Claude Code's own total**, the line below, is `totalCostUSD` from
  the session's last `cost-state` record, which holds those calls too.
  Each process writes one as it ends, holding the session's total so
  far, so the last is the session's. The line names what any gap above
  holds: the compactions and away summaries counted, any prompt
  suggestions, which leave no record to count, and any unpriced calls.
  A session still running has no record, or calls after its last, and
  the line says there is none to compare.
- **Start-up** is the context of the first call: system prompt, tools,
  instruction files and the first prompt. Every later call re-reads at
  least that much.
- **The model table** gives, per model, the calls, their average and
  peak context, which counts uncached input, cache reads and cache
  writes, and the cost of each part. Weigh reads and writes together:
  neither dominates, as reads ran 0.9 to 2.6 times writes in this
  machine's 33 sessions over \$5 and 150 calls (2026-11-05). Writes are
  what was new to the cache.
- **Phases** split the main thread at each compaction, which names its
  trigger and the context before and after, and at each gap over an
  hour, the one-hour cache's life. By default Claude Code asks for the
  hour for the main thread only on a subscription within plan usage; an
  API key, usage credits or a cloud provider get five minutes, as
  subagents do on either, unless `promptCacheTtl` or
  `subagentPromptCacheTtl` sets one (Claude Code docs,
  `prompt-caching#choose-the-ttl-yourself`, 2026-11-05), so on five
  minutes a shorter gap expires the cache with no split. A
  compaction's own call writes no assistant record, so it is named with
  the context it summarized and not priced, and neither is the recap
  an `away_summary` record shows, nor a next-prompt suggestion, a
  background call on the session's model that reuses its cache
  (Claude Code docs, `interactive-mode#prompt-suggestions`): the total
  is a floor. Claude Code's own holds a compaction's and an away
  summary's calls, shown by the gap they leave, and a suggestion's, by
  inference. Over this repo's 80 newest sessions (2026-11-05, 2.1.318),
  it matched the script to half a cent in 49 of the 50 with neither a
  compaction nor an away summary, and ran up to \$0.94 above in 26 of
  the 27 with either. The fiftieth, a CLI session, ran \$0.02 above by
  one call no record holds, which read the last turn's whole cached
  prefix, wrote 84 tokens to the cache and output 148: a suggestion's
  shape, inferred, not confirmed.
- **Rewrites** are calls that wrote at least half their context, and
  20,000 tokens or more, to the cache, each with its likeliest cause: the
  session's first call, a compaction, an idle gap (`the one-hour cache
  had expired`), a model switch, since a cache serves only the model
  that wrote it, or a miss mid-phase, which on the five-minute cache
  may be an idle gap of minutes. A call after an idle hour may still read a
  prefix other sessions share: of 32 on this machine, 19 read 33k to 36k
  tokens and 13 read nothing (2026-11-05). So a cold call shows by what
  it wrote, not by a read of nothing.
- **Tools** gives the main thread's calls per tool and the text their
  results returned, in characters, not tokens; images are not counted.
  A result stays in context, so each later call re-reads it.
- **Subagents** gives each agent's type, model, calls, peak context and
  cost, with its description or the forked skill that ran it, dearest
  first.
- **Unpriced** names calls left out of every total: a model the table
  has no row for, a speed it does not price, or a cache write with no
  5-minute and 1-hour split.

## 3. Report

- **Lead with the total and where it went**: the dearest phase, each
  rewrite and its cost, the subagents' share, against the start-up
  context. Give Claude Code's own total beside it where the report has
  one, with the gap as the report names it, never a cause it did not.
- **Name the lever a finding points at**, and only from what the report
  measured: a rewrite after an idle gap points at compacting before
  walking away or starting fresh after an idle hour, or after five
  minutes on the five-minute cache, as § 2's phases say; a large start-up
  context, at what loads before the task; a dear subagent, at its model
  or its prompt; a large tool result, at reading less. Quote the report's
  numbers, and never a saving it did not measure.
- **Say the prices are list prices** from the dated table, and name any
  unpriced calls. What a subscription or Enterprise plan bills was not
  checked, so the report compares sessions and changes, not invoices.
- **Never Read a transcript whole** to check a number: one holds every
  tool result.

## 4. When it fails

- **Exit 1, `no session <id>`**: find the id with `find-session`; a
  transcript older than `cleanupPeriodDays` has been deleted.
- **Exit 1, `<n> sessions start <id>`**: give more of the id.
- **Exit 1, `name a session id`**: `CLAUDE_CODE_SESSION_ID` is unset,
  which happens outside Claude Code: give an id or `--repo`.
- **Exit 2, `the transcript format may have changed`**: it read
  assistant records with no usage in them. Report that, and do not parse
  the transcripts by hand as a stand-in.
- **`warning: find-session.py did not load`**: the script reads only its
  own config directory, not the other account's. It loads
  `find-session`'s reader of the account map from the sibling skill
  folder, so a deploy without `find-session` drops the other accounts.
- **A model newer than the table** reports unpriced. Its row comes from
  the pricing page, with the table's date, in the repo this skill is
  authored in; from another repo, report the model and the page to the
  skill's maintainer, by `capture-learning` where it is installed, not
  an edit here.

## Constraints

- **Reads only.** It writes, renames, resumes and deletes nothing.
- **List prices, not a bill**, as § 3 says.
- **Not this skill**: finding a session by what was said in it is
  `find-session`; a skill's listing and use across sessions is no part
  of this one.
- **Out of reach**, itemised: the price of a compaction's, an away
  summary's or a prompt suggestion's own call, which only `cost-state`'s
  total holds, so the report gives the gap, which holds their sum and
  any unpriced calls, and no single one; a cloud session's transcript, a transcript `cleanupPeriodDays`
  deleted, and a tool result's tokens.
