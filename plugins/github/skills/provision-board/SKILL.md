---
name: provision-board
description: "Sets up a GitHub Projects board for a repo's handoff queue, under a user or an organization, by copying a template project, which keeps views, fields and configured workflows, bar auto-add; with no template it builds the board from nothing. Its bundled provision-board.sh links the repo, sets the description and readme, makes the Status options (Open, Deferred, In flight, Done) through updateProjectV2Field with each kept option's id, the Priority and Reopen-when fields, the needs:* labels and any view of its views.json the board lacks, then reads each workflow's enabled flag against the contract. Optionally files the queue's briefs as issues on the board, after a denylist check that prints counts only, resumable, reading back each card's Status. Ends by naming what only GitHub's UI does: auto-add, and on a built board the standard workflows. Takes the owner and repo as arguments, names the acting gh account first, and runs nothing without the user's yes. The contract lives in its references/."
argument-hint: "[owner] [owner/repo]"
disable-model-invocation: true  # typed only: it writes a project, labels and issues to GitHub as the account the user picks, so it waits for the user's word; audit-repo's board check names provision-board for the user to type
model: inherit
effort: xhigh  # governs the slash turn alone, the account and token-scope check and the plan, which an arm at high skipped (2026-10-27); each turn after a yes, the writes included, ran at the session level (2026-10-28)
---

# Provisioning a board

Set up a GitHub Projects board for one repo's handoff queue, owned by
the user or by an organization, so each brief can be an issue whose card
moves Open, Deferred, In flight, Done. **Copy a template; build only
where there is none.** No API turns a project workflow on, while a copy
keeps the views, fields and configured workflows, bar auto-add, so a
copied board needs one UI step, auto-add, where a built one needs every
workflow set by hand.
[references/board-contract.md](references/board-contract.md) is what
every board carries, and its one home.

Past `references/`, docs.github.com by its search,
`curl -s 'https://docs.github.com/api/search/v1?query=<q>&language=en&client_name=x'`
(no `client_name`: 400), then a hit's body,
`curl -s 'https://docs.github.com/api/article/body?pathname=<hit url>'`.
A live page that contradicts a line here wins: say so, act on the page,
and route the fix by `capture-learning`, bar a dated measured line that
names the page it overrules and the call that measured it, which a page
changed since its date sends back to re-measure. An observed claim is cited
or marked pending a doc check, and stands, marked observed, only where no
page covers it.

The arguments are the owner, a user or organization login, and the
repo, `owner/name`. An organization's names go into no file in any repo
but its own: the report stays in the conversation.

## 1. Pick the account

`gh` can act as an account other than the one meant, and a 404 or
`Could not resolve to a Repository` from the wrong one looks exactly like
a missing project or repo (`~/.claude/CLAUDE.md`). Name the account this
session's `gh` acts as, and pick `<login>`, the one that should own the
writes:

```bash
git config user.name   # the account the Bash tool's gh picks here
gh api user -q .login
```

**Each script takes `<login>` as `--login`**, mints its token, and
stops unless `gh` then acts as it. No block pins `GH_TOKEN`: each Bash
call is a fresh shell, so an export in step 1 reached no later step, and
a worktree session's guard refuses the export outright, "too complex to
verify", with the login spelled out too (2.1.317, 2026-11-03). **Every
`gh` call outside the scripts runs as the login printed here**, not
`<login>`: step 2's reads and its template's `gh project copy` and
`mark-template`, and step 4's reads and view mutations. Where the two
differ, run them from a checkout whose `user.name` is `<login>`, such as
the repo's own.

`<login>` needs the `project` scope on its token, and for an
organization's board the right to create projects there; an
organization's owners can turn projects off for it entirely. A missing
scope reads `your authentication token is missing required scopes`. An
organization that enforces single sign-on answers an unauthorized token
404 or 403 (references/board-contract.md § Who can write it), so read a
403 for its authorize link before switching account.
**Leave `gh auth refresh` to the user**: it widens the keyring's active
account, which may not be `<login>`.

## 2. Find the template

The template is the project titled **Backlog template**.
`provision-board.sh` looks for it under the owner, then under the acting
account. **It finds none another account owns**: where a work account
acts and the template is the user's personal one, pass `--template
<user>/<number>`, and the acting account must be able to read it
(references/board-contract.md § The template). With no template found,
the script says so on stderr before it builds, too late to stop the
build, and a rerun finds the built board by its title. So read both
accounts it searches, and the boards the repo links, before asking:

```bash
gh project list --owner <owner> --format json
gh project list --owner <acting-login> --format json
gh api graphql -f query='query{repository(owner:"<owner>",name:"<name>"){projectsV2(first:10){nodes{number title}}}}'
```

A linked board carrying the contract is the one step 3 takes, whatever its
title, and nothing is copied. With none linked, a project already holding
the title is the one the repo joins, so where that is another repo's board,
name it and offer another title.

- **Found**: the board is a copy. Its workflows come across as the
  template has them, so a template with one off yields a board with it
  off; step 4's report says which.
- **None**: the board is built from nothing, and step 6 lists every
  workflow to set by hand. Once they are set, offer to copy the board as
  the template, by `gh project copy` with that title, so the next board
  copies.
- **An organization with no template of its own**: the board copies the
  acting account's, or by `--template` the user's, as it did on
  2026-10-30. Then give the organization its own, **a
  second project, never the live board**, since every script finds a
  template by title, not by the mark, and members creating from a marked
  board would take its drafts:

  ```bash
  gh project copy <board> --source-owner <org> --target-owner <org> --title "Backlog template"
  gh project mark-template <template> --owner <org>
  ```

  Then its base role, step 6. The contract's § The template has what
  each command prints and how to read the result back.

## 3. Run the script

Ask once, naming the owner, the repo, the board's title (`<repo-name>
backlog` unless the user gives one), the template it will copy or that
it will build, and that it links the repo and adds labels there. On a yes:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/provision-board.sh" --owner <owner> --repo <owner/name> --login <login>
```

Add `--title <title>`, `--template <owner>/<number>` or `--no-template`,
`--description <text>` and `--readme <text>` as agreed. **A rerun is
safe**: the board linked to the repo and carrying the contract is taken
whatever its title, else the one of that title, and each step changes only
what differs, so a run that stopped part way is fixed and run again, and a
second repo given the same title links to the same board. Exit 0 is
done, 1 a failure part way or a repo linking two boards, 2 a usage error, a
`--login` with no token or not the account `gh` then acts as, an owner or
repo the account cannot see, a repo with issues off, or a board another
owner holds.

On every path it links the repo, writes the description and readme
where the project has none, and creates the `needs:user` label where
missing, the one label every board's repo gets: filing makes the rest,
as the contract's § "Labels" says. The Status
options are rewritten only where they differ from the contract, **each
kept option passed with its `id`**: the pilot's build passed none, every
option took a new ID, and the workflows that set one lost their target
(2026-10-27). On a board already in use, an option outside the contract
is reported rather than dropped, since dropping it clears every card on
it. Priority, Reopen-when, Work model and Work effort are created where
missing, and a select's options that differ are reported, bar Priority's older
P1 to P3, which move to High, Medium and Low under the same IDs. **An
organization that defines its own Priority gets that issue field instead**,
by the contract's § "Fields": a project Priority on a board with cards is
reported, never deleted.
**The views are [references/views.json](references/views.json)'s**, on
every path: each one it names that the board lacks is made, with its
filter, grouping and columns, and one already there, matched by name, is
read against it and reported where it differs, never rewritten. A view
it does not name, an older contract's `View 1` or `By parent` among them,
is reported for the user to delete; only a board built that run loses
`View 1`, GitHub's default. A copy that gains an organization's issue
field lists its views' columns in the spec's order, and a todo says so.
To change the views every board gets, edit views.json, and the template
too, or each new copy carries the template's old ones beside them.

## 4. Read the report

- **`account:`**: who wrote. Check it is the one meant before anything
  else.
- **`project:`** and **`path:`**: the board's URL, and whether it was
  copied, built or already there.
- **`todo:`**: what is left, each line one step: a workflow the
  contract wants on or off, a Status option dropped with its cards, a
  view that differs from views.json or that it does not name, and always
  auto-add: the workflow to add where it reads off or absent, and where
  it reads on, a look at its repo and filter. Give the user these lines as
  printed, a view's with its route below, the rest with step 6's link
  and clicks.

**A view todo takes an API where one writes it**, one yes per view,
naming the view and the call: the script reports a view and rewrites
none, bar `View 1` on a board it built and a copy's column list when it
adds fields. The calls are the mutations the script sends, by a view's
`id` from these reads and a field's from
`gh project field-list <n> --owner <owner> --format json` (all read on
project 2, 2026-11-03), two commands, as a worktree's guard refused the
nested form:

```bash
gh project view <n> --owner <owner> --format json --jq .id   # <project-id>
gh api graphql -f query='query($p: ID!) { node(id: $p) { ... on ProjectV2 { views(first: 50) { nodes { id number name layout filter } } } } }' -f p=<project-id> --jq '.data.node.views.nodes[] | [.id, .number, .name, .layout, .filter] | @tsv'
```

| The todo reads | The route |
| --- | --- |
| `<count> views are named <name>` | `deleteProjectV2View` on all but the one the user keeps |
| `the views <names> are not in views.json` | `deleteProjectV2View` on each the user says an older contract made |
| `the view <name>` with only `filters`, `lacks` or `also shows` | `updateProjectV2View`'s `filter`, its `configuration.visibleFieldIds` (every field the view wants, in views.json's order), or both |
| `the view <name>` with `is a`, `groups by` or `has columns by` | `deleteProjectV2View`, then rerun the script, which makes it from views.json: no mutation sets a grouping or columns, and `updateProjectV2View`'s `layout`, which would suit a view views.json gives neither, is never yet sent |
| `the view <name> wants a grouping or columns by a field the board lacks` | as the row above, once the board has the field |
| `the copy's views now list their columns in the contract's order` | step 6: no API reads the order a template had |

`updateProjectV2View`'s `filter` has been sent once, refiltering the
template's List: Open, read back by GraphQL (2026-11-04), and where REST
puts a new view among the tabs is unread (2026-11-03): after
remaking the view on the leftmost tab, the default, check the tab
order, step 6. A rerun of
the script reads each view back: its todo for one goes once the view
matches.

**Then read the repo's landing, which the script does not**, in its
checkout, the `<repo-root>` step 5 takes:

```bash
grep -c -E 'worktree lands (from the main checkout|by pull request)' <repo-root>/.claude/rules/handoff-briefs.md   # 0, or no such file: no landing
```

**A `0` or `No such file or directory` is a warning beside the `todo:`
lines, never a stop**: the board takes issues, but the first
`work-issue` run on one stops at its preflight until the rule for briefs
names a landing (2026-11-02). Name the fix,
`audit-repo`'s handoff-queue step 2, which copies the bullet from its
template for the repo's route.
`file-issue`'s step 1 runs the same grep and says why it reads those
words, so a change to either is made in both. With no checkout at hand,
say the landing went unread.

## 5. File the briefs, optionally

Offer this where the repo has a queue, `docs/handoffs/execute/`. **An
issue cannot be unfiled**, so the bodies are written and checked first,
filed after a yes:

```bash
uv run --no-project python "${CLAUDE_SKILL_DIR}/scripts/brief-bodies.py" <repo-root> <scratchpad>/briefs --blob https://github.com/<owner>/<repo>/blob/<default-branch>/ --allow-no-denylist
```

It writes one body per brief, opening with a line that names the file,
every relative link made absolute, and a `manifest.json`; `--status
deferred` or `--status open` narrows it. Then it counts the identity
denylist's terms in every title and body it wrote, **counts only, never
a term**; in a repo under an `exempt:` root it counts nothing and says
so, as identity-guard passes that repo. Exit 1 is a hit: report the file names and counts, and file
nothing until the user has changed the brief. It is also exit 1, named
on stderr before any count, when a brief's `work-model` or
`work-effort` is outside the board's options, a `platform` value is not
lowercase kebab, its `parent` is not a bare
issue number, or a `blocked-by` item names neither an issue number nor a
brief beside it or in the manifest. **With no identity denylist, or
none holding a term, `--allow-no-denylist` counts nothing and exits 0**
on a `denylist:` line saying so: put that line in the question that
asks to file, since the user's yes then files unchecked. Without the
flag it exits 2, as `file-issue`, which runs the same script, relies on.

On exit 0, give the count and each `phrase label:` line, and ask once,
so the yes covers those labels: `file-issues.sh` makes a `needs:<value>`
or `platform:<value>` label of any value the repo lacks, with no prompt,
and step 3 made only `needs:user`.
On a yes:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/file-issues.sh" --owner <owner> --project <number> --repo <owner/name> --manifest <scratchpad>/briefs/manifest.json --login <login>
```

**A rerun never files twice, from any session**: before filing a brief
it lists the repo's issues, open and closed, and takes one whose body
opens with that brief's first line as already filed, `found:`, the line
a rerun in the same folder prints for each it recorded. Two or
more from one brief print `duplicate:` with their numbers and exit 1,
filing neither: the user closes all but one as a duplicate, which then
no longer counts, and reruns. A brief whose one issue is closed prints
`closed:` and exits 1 too, its card untouched: the user reopens the
issue, or renames a brief that took a landed one's name. It sets each
card's Status, Priority,
Reopen-when, Work model and Work effort from the brief; a card already on
the board keeps any of the last four it holds, so a rerun undoes no
`update-issue` move. A template's
Item added to project sets Open on every new card,
and whether that lands after the script's own write is untested, so the
script waits, reads every card back and sets again any that differ; a
rerun repeats that check alone. A card reading In flight, a session's
claim, or Done is left so.

**It makes each brief's `parent` and `blocked-by` GitHub's native
links**, at create where the other issue exists by then, and after the
cards otherwise, adding what a found issue lacks and removing nothing:
`linked:` per issue given one. A parent or blocker number with no issue
stops the run before any create. A blocker whose brief has no issue yet
prints `unlinked:`; filing it and rerunning links it. An issue under
another parent prints `parent differs:` and exits 1, left for the user
to move or the brief to change.

**The files stay the source while they exist**: each issue says so in
its first line, and an edit to a brief does not reach its issue.

## 6. The UI-only steps

No API does these: a project's workflows (2026-10-27), the tab order,
restoring a template's column order, which no read returns
(2026-11-01), and a base role (2026-10-30).
**With Claude in Chrome connected,
offer to make each but the last**, one yes at a time, by `audit-repo`'s
[references/browser-steps.md](../audit-repo/references/browser-steps.md),
which checks the browser's login first. Otherwise hand them over, a
workflow as a link to the project's workflows page, then the workflow in
its left list, **Edit**, its value, **Save and turn on workflow**. The
link is `https://github.com/users/<owner>/projects/<n>/workflows`, opened
on a user's board (2026-11-02), or `/orgs/<org>/projects/<n>/workflows`,
by analogy and unopened; never a workflow's own, whose ID changes on
saving (browser-steps.md):

- **Auto-add to project**, on every board, since a copy never carries
  it: the repo, filter `is:issue is:open`. One per repo; a plan allows a
  set number, one on Free (references/board-contract.md).
- **On a built board, the standard workflows** step 4 named: Item added
  to project and Item reopened to Open, Item closed to Done,
  Auto-archive items with `is:issue is:closed updated:<@today-14d`, each
  with its Pull request box cleared, and off each one step 4 names to
  turn off, Pull request merged among them on a new project.
- **The default tab**, which is the leftmost view, moved by dragging.
- **A copy's column order**, where its todo names it: drag back each
  header the template placed otherwise, then save the view. No API
  reads the template's order (references/board-contract.md § Views).
- **An organization's template's base role**: **Settings**, **Manage
  access**, **Base role**, **Read**. Auto mode's classifier refused this
  click, giving no reason, so it is the user's own (2026-10-30). GraphQL's
  `ProjectV2` has no field for it (schema, 2026-10-30), so no audit reads
  it.

Afterwards, rerun `provision-board.sh` with the same arguments: the
`todo:` lines it no longer prints are done, bar the tab order, which it
never reads, a copy's column order, which only a run that copies and
adds fields prints,
and auto-add's, which turns to `auto-add: on;` once the
workflow is on, still asking for a look, since only the browser reads
its repo and filter (browser-steps.md).

## 7. Report

The board's URL, the account that wrote it, whether it was copied or
built, the issues filed if any, the UI steps left, and a landing step 4
found missing, with its fix. Nothing goes in a file.

## Constraints

- **Nothing runs without its yes**: not the board, not the filing, and
  `file-issues.sh` only after `brief-bodies.py` exited 0.
- **The account is part of the result.** A 404 or `Could not resolve`
  means switch account, never read around it, unless it names another
  account's private template, which the acting account must be able to
  read.
- **An option is never replaced without its `id`.** Rewriting the Status
  options by hand, outside the script, repeats the pilot's loss.
- **The contract has one home**, references/board-contract.md; a change
  there changes `provision-board.sh` in the same commit.
- **No denylisted term reaches an issue**, and the check's output names
  none.
