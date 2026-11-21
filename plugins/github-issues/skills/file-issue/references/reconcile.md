# Reconciling a batch

Every item takes one verb before anything is filed, and one table shows
them all for one yes ([SKILL.md](../SKILL.md) step 4). The vocabulary is
shared: `triage-inbox`'s board verdicts and `file-audit-findings`'s findings
map onto it, as the last section says.

| Verb | When | What it writes |
| --- | --- | --- |
| new | no open issue owns the subject | an issue, filed by `file-issues.sh`, its card set from the draft |
| sub-issue | the subject is one part of an open parent's work, by that parent's body, which step 3 reads for every open parent | the same, its draft naming `parent: <n>` |
| board | an open issue owns the subject and has no card | that issue's card and labels, set by `file-issues.sh` from a draft naming `issue: <n>`; its title and body stay |
| fold | an open issue owns the subject | a comment, by `gh issue comment`, or with each card field the table showed by one `set-card.py --comment` command, then that issue's body edited |
| close | the item made an open issue outdated | a comment, then that issue closed as not planned |
| declined | nothing should be filed | nothing here; the caller's ledger, where it has one |

**An item that replaces an issue is two rows**: a new issue, and a
close of the old one that cites it.

## New

- **One subject per issue.** What resolves apart is filed apart, and
  what resolves together shares one: a brief is the unit of deletion,
  and an issue the unit of closing.
- **`blocked-by` orders the work.** A blocker drafted in the same batch
  is named by its draft's filename; `file-issues.sh` links it once both
  exist, and prints `unlinked:` until then.

## Sub-issue

- **A parent tracks; its sub-issues hold the work.** It closes with its
  last sub-issue, by a workflow or the user, never by a commit
  (`provision-board`'s `references/board-contract.md` § "Parents and
  sub-issues").
- **The parent must already be an open issue on this board**:
  `brief-bodies.py` takes `parent` as a bare number only. A new tracking
  issue is filed first, as a new issue, and its sub-issues in a second
  run that names its number.
- **An issue has one parent**, and a parent up to 100 sub-issues, eight
  levels deep. An issue found under another parent prints
  `parent differs:` and is the user's to move.

**Which parent, from [SKILL.md](../SKILL.md) step 3's list of open
parents.** Test each item against every parent's body, where a tracking
parent's scope sits, never its title alone:

- **One parent clearly holds it**: the verb is **sub-issue**, that
  parent in the row's Links, and the reason in a line under the table,
  its body's words. The user's yes covers it as any row.
- **Two fit**: name both in the row, and ask which beside the table, in
  the same `AskUserQuestion`.
- **None fits**: **new**, with no parent, and the report says
  `group-issues` can group it later. **A guess costs more than no
  parent**: a link made is the user's to move, by `parent differs:`,
  where a standalone issue joins one in a regroup.
- **A new tracking parent takes none**, as `group-issues` step 6 hands
  one over: a parent joins no parent there, and `link-parents.sh`
  refuses a child of a nested one.
- **A Deferred parent that gains an open sub-issue reads Open**, by
  § "Reopening a Deferred parent" below, under the same yes: a line
  under the table names each one.
- **A parent whose body lists its sub-issues by number**, as one parent's
  stage lines do, can take a fold beside the row: its list gains the new
  issue's line. The fold's diff and its step 5 count carry the stem
  where the number will go; step 6 files the issue first, then writes
  the fold with the number its `filed:` line printed.

### Reopening a Deferred parent

**A parent whose card reads Deferred reads Open once it gains an open
sub-issue**, set by the skill that linked the child:
[SKILL.md](../SKILL.md) step 6, after `file-issues.sh`, and
`group-issues` step 9, after `link-parents.sh`. Left Deferred, the queue
view prints the open child under its deferred parent until the user
runs `update-issue` with `<parent> reopen`, as one child under its
parent needed (2026-11-05).

- **Only an open child reopens it**: a sub-issue filed Deferred, or one
  whose card reads Deferred, leaves its parent as it is, as
  `group-issues`' new-parent card does.
- **The table's yes covers it only where the table shows it**: a line
  under it names each Deferred parent that will read Open, and the open
  child that moves it. A caller's table with no such line is asked again
  for it, by [SKILL.md](../SKILL.md) step 4.
- **Its Priority stays**: the view holds a parent with an open sub-issue
  `blocked`, so its Priority orders nothing a session can take. A change
  is a fold's, shown old → new by § "Fold", or `update-issue`'s, typed
  by the user; one parent stayed P3 under a P2 child.
- **Its Reopen-when stays on the card**, as `update-issue` § Reopen
  says: `set-card.py` writes that field only with Deferred.

Once the child reads under it, `filed:` or `linked: … parent #<p>` from
`file-issues.sh`, `linked:`, `moved:` or `found:` from `link-parents.sh`,
never a `parent differs:` line, one parent at a time, `<set-card.py>`
being `triage-inbox`'s script by the path [SKILL.md](../SKILL.md)
step 3 names it:

```bash
uv run --no-project <set-card.py> . <parent>   # skip it unless status Deferred, state OPEN, item set and mirrors null
uv run --no-project <set-card.py> . <parent> --status Open --comment "<scratchpad>/file-issue/<parent>.reopen.md"
```

**`--comment` posts first**, from a file written with Write, and a
failed one leaves the card Deferred rather than Open with no reason
given. It opens with the move, first person, as `update-issue`'s do:
`Reopened: #<child> joined as an open sub-issue, <today>.`, naming each
child where several joined. This is `update-issue` § Reopen's command
less its trigger test and its stops, since the open child is the
trigger met and the first read tests what the stops would. A write that
failed or did not hold exits 1 and prints the card as it then reads:
report it, with the command, for the user to rerun, less its
`--comment` where a `note: the comment posted` line names the comment's
URL. A refusal, a mirror or an issue off the board, exits 1 with only its reason on stderr and
nothing posted.

## Board

**An open issue with no card gains one, and keeps its words**: it was
filed by hand, or before the board or its Auto-add existed, so
`set-card.py` refuses it as `not on board`, the read that picks this
verb. One already on the board is `update-issue`'s, and a closed one
takes a new issue that cites it; `file-issues.sh` prints `closed:` and
leaves it.

- **Draft it from the issue**: read `gh issue view <n> --json
  title,body,labels,subIssuesSummary`, then write `<scratchpad>/file-issue/drafts/board-<n>.md`
  with Write: `issue: <n>` and the proposed fields as frontmatter, `# `
  and its title, then its body. One whose `subIssuesSummary` reads a
  `total` above 0 is a tracking parent: `tracking: true`, and no `work-`
  key, by [SKILL.md](../SKILL.md) step 2. `brief-bodies.py` reads that frontmatter
  and counts that text. Nothing of the wrapping is ever filed, and no
  opening line is added, since the number finds the issue on a rerun.
- **The table's Needs and Platform show what it will have.** Labels are
  only added: name any `needs:*` or `platform:*` it holds already, since
  dropping one is `update-issue`'s move.
- **A denylist hit here is already on GitHub**, so no rewrite in the
  draft fixes it, and rewording the draft would only hide it from the
  count. Stop that row, say which draft counted, and name `recreate-repo`,
  whose call the user makes.
- **Its `parent` and `blocked-by` link as any brief's do**, and another
  draft in the batch can name `board-<n>.md` as its blocker.

## Fold

**A fold edits the body where its reader will look**, with the date and
the kind of source, and corrects in place what it supersedes rather
than appending a contradiction.

- **Draft from the body as it stands**: `gh issue view <n> --json body
  -q .body` into `<scratchpad>/file-issue/<n>.body.md` with Write, then
  edit that file.
- **Its first line never changes.** `file-issues.sh` finds an issue by
  its body's opening, and `brief-bodies.py` would write today's date
  into the line it makes. So the body written is the issue's own,
  edited, and only the copy counted is wrapped: `status: open`
  frontmatter and the issue's title as a `# ` heading, in
  `<scratchpad>/file-issue/folds/briefs/`, passed as `--brief` with
  `<scratchpad>/file-issue/folds/` as the output folder: the script
  refuses a `--brief` that sits in its output folder. The card's own
  values were counted when it was filed.
- **The comment says what changed and from where**, first person, since
  it posts as the user: `Folded in: <what changed>, from <the kind of
  source>, <date>.`
- **A fold may move its card's fields, each where the table shows it,
  old value → new**: a new Reopen-when with Status Deferred, on a card
  Deferred or Open; Status Open from Deferred; Priority; a `needs:*`
  label added or removed. A drop stays the close verb's. The yes covers
  only a field shown so: a caller's table that showed none is asked
  again, by [SKILL.md](../SKILL.md) step 4, and the field stays as it
  was meanwhile (the user's call, 2026-11-14). A card In flight
  takes no fold at all.
- **One command comments, then moves the fields**: `set-card.py
  --comment` with them, before the body's edit ([SKILL.md](../SKILL.md)
  step 6), so a failed comment leaves every field as it was. A
  trigger goes in `<scratchpad>/file-issue/<n>.trigger`, read by
  `"$(cat …)"`, never pasted, as `update-issue` § Defer runs it, and
  `set-card.py` counts it and the comment against the identity
  denylist. The comment opens with each move, as `update-issue`'s do:
  `Reopen-when "<old>" → "<new>"; folded in: <what changed>, from <the
  kind of source>, <date>.` A reopen leaves the old Reopen-when on the
  card, as `update-issue` § Reopen says.
- **Read it back**: the first line of `gh issue view <n> --json body -q
  .body` is still the opening it had.

## Close

The same command as `update-issue` § Drop, `set-card.py --close`.

- **Not planned, always**, or `--duplicate-of <m>` where the issue
  duplicates another in this repo; never completed, which is the push of
  a commit carrying `Closes #<n>`.
- **Name each issue it blocks**: the queue view counts only an open
  blocker, so each turns ready once this closes, with nothing said.
- **A parent with open sub-issues** asks whether each goes too.
- **The comment opens with the move**: `Closed as not planned: <why>,
  from <the kind of source>.` It comes from a file, and records the
  card's Reopen-when where it has one, since the close clears it.
- **`set-card.py --close` comments, clears and closes**: the comment,
  then every `needs:*` label off and Reopen-when cleared while the issue
  is open, then the close, and a failed comment writes nothing. A bare
  `gh issue close` kept both (2026-11-12).
- **The card then reads Done**, since Item closed sets Done on any
  close, and only the issue's `stateReason` tells a drop from a landing:
  the read back prints it as `state_reason`. Say so.

## Declined

Nothing is filed. The reason is one the next reader can test, with what
would change it. A caller with a ledger records it there:
`triage-inbox` in `docs/handoffs/DECLINED.md`, `file-audit-findings` in the
message of its run's commit to `docs/audits/ledger.md`, whose row
counts them.

**From `work-issue` step 9 or a review finding left unfixed, propose
declined for a defect no run has shown**: a draft whose body calls its
case unobserved, rare or untested, or names no failure seen in a real
run, a log or a user's report, and is no guard failing open on input a
real command would produce. The reason says so, and that a real
failure, routed by `capture-learning`, would change it. A question
waiting on the user's decision is no defect, and takes its verb as any
item does (`review-code`'s `choosing-fixes.md` § 5, the user,
2026-11-05). **Other callers' items are not held to this bar**: a
drift finding, an owed re-check, a skill brief or a learning names no
failed run by its nature, and takes its verb as the table below says.

## How the callers map onto it

| Caller | Its item | Verb |
| --- | --- | --- |
| `triage-inbox` step 6 | Briefed, on a board | new, or sub-issue |
| `triage-inbox` step 6 | Folded into an issue | fold |
| `triage-inbox` | Declined | none: its ledger, never here |
| `author-skill`'s filing reference | a skill brief, pushed to `main` | new, from the file's path |
| `capture-learning` Step 6 | a learning too big to land | new, or fold where step 3 finds its issue |
| `file-audit-findings` step 3 | a finding, or an owed re-check | any |
| `work-issue` step 9 | an open item or an unfixed finding from its session | any |
| the user, in words | a subject | any |
