# The report

Plain markdown, about a screen before the table, in this order. The
headings are fixed: a `user-instructions` row in
`file-audit-findings`' table of other audits would recognize the
report by `## Session evidence` and `## Proposed moves`, take its head
from the `## Sources` line, and its actions from
`## Recommended actions`. Leave a heading out only where this file says
so.

```text
# User instructions audit: <YYYY-MM-DD>
## Sources              one paragraph (below)
## Checks               a line per check of step 2, a clean one included
## Session evidence     counts (below)
## Proposed moves       the table, then the diff
## Next steps in other skills  what audit-source-drift, audit-agent-setup or /doctor prompt-audit owns, for the user to run
## Recommended actions  numbered, or _(none)_
```

## Sources

One paragraph: the mode; the file read and its line count; `Head
<sha>` from `git rev-parse --short HEAD` in the config source, or
"deployed copy, no head" elsewhere; the bound, the ledger row's **Run**
and **Through** or "none"; the transcripts read, their reach and each
account's `cleanupPeriodDays`; and any source unavailable.

## Session evidence

Counts only, never a prompt or a result:

- each candidate rule, restated in the user's terms and generically, and
  how many sessions carried it;
- each rule checked by its tell: sessions with it before, spanning and
  after its date, over every session on disk, not the window. A table
  keeps three columns by these names, each with its 0s: `flagged` and
  `unflagged`, which sum to `with it`, and `printed` (a command that only
  printed files, no failure). A hit read by `--hits` gets its grade beside
  the count, in words, never its line. Then the rules whose tell is a
  silence or a Read refusal, which no count reaches;
- the Account block, by entrypoint, or unmeasured;
- what was masked, by kind, and how many long prompts were skipped.

## Proposed moves

The table of step 6, a row per line moved, cut, added or reworded. Below
it the diff of `claude/CLAUDE.md`, each new or changed rule or ledger
entry in full, and the line count before and after against the cap.

In `audit` mode the table carries no diff, and each row's **Now** names
its finding, one of:

| Finding | Means |
| --- | --- |
| stale | a check or a session says it no longer holds |
| missing | a correction repeated across sessions that no line carries |
| redundant | a rewording of another line, a default, or what a rule already loads |
| conflicting | it contradicts another line or a file it points at |
| vague | it names no tell, or no date |
| misrouted | it belongs in a rule, a skill, a hook, the ledger, a repo or nowhere |
| not working | its tell recurs after its date |

## Recommended actions

Numbered `1.`, `2.`, …: one line per row not applied in this session,
naming the row and where it lands, such as `1. L52, the jq CRLF rule:
its evidence to docs/evidence/user-claude-md.md § Native jq`. A row
applied in the session takes none. Every row applied, or `audit` mode
with nothing to edit, reads `_(none)_`.
