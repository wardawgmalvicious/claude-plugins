# The board contract

What every handoff-queue board carries, in one place. A template project
carries it live; `provision-board.sh` writes the same values on the
build path, and `audit-repo`'s `audit-repo.ps1` judges a board by them,
so a change here changes both scripts in the same commit. The audit's
suite builds its board from this file's Fields and Workflows sections,
and fails where the script and they part.
`audit-repo`'s board check, `handoff-status.py`, `lead-sessions` and
`work-issue` cite this file, since the queue of the repo this skill is
authored in moved to its board on 2026-10-28, and no second skill sets
workflows apart from it.

## The template

A project titled **Backlog template**, under the owner whose
boards copy it: a user's own projects, or an organization's.
`provision-board.sh` looks for it under the board's owner, then under the
acting account, and for any other account's takes `--template
<owner>/<number>`. **Every script finds it by that title, never by the
`template` flag** (`handoff-status.py`, `audit-repo.ps1`, the script's
lookup), so a marked live board still reads as a board, and is no
template to the next `provision-board` run.

**Another account's template must be readable by the acting one.** A
private user project reads `Could not resolve to a ProjectV2 with the
number <n>` to it; made public for the copy, it copied with read access
alone; collaborator access was not tried (2026-10-30).

**What a copy keeps**, in GitHub's words: "the same views, custom
fields, draft issues and associated field values", and "configured
workflows (except any auto-add workflows), and insights". It "will not
contain the original project's items, collaborators, or team and
repository links" (docs.github.com, read 2026-10-27). A live copy also
came without its readme and description, and kept every single-select
option's ID, so its workflows' targets point at options that exist
(2026-10-27). They resolve, read only in the browser: on an
organization's copy of a user's template, Item added to project and Item
reopened read Open, and Item closed Done (2026-10-30). That copy exited
0, linked its repo, wrote its description and readme, made all 11 labels,
kept Status's four option IDs and all three views, By parent's filter and
grouping included, and read not public; its only `todo:` was auto-add.

**An organization keeps two projects**: its board, and a copy within it
titled as above, which is the one marked, so the next board copies it and
members creating from it take no live board's drafts (the user,
2026-10-30). `gh project copy` leaves drafts out unless given `--drafts`.
The copy read no repo link and no items, the same views and option IDs,
and every workflow the board had on, bar auto-add.

**An organization's template can be marked as one**, so members find it
in the "Create a project" dialog: `gh project mark-template <number>
--owner <org>`, by an account with admin on the project, and `--undo`
unmarks. Only an organization's project can be marked
(`markProjectV2AsTemplate`, GraphQL schema, 2026-10-27); a user's
template is found by its title alone. It exits 0 and prints nothing, and
`gh project view --format json` has no `template` key, so read it by
GraphQL. A marked project lists under the organization's Templates as
"Private template", and its page gains **Use this template** (2026-10-30).
**Do not press the organization's New project button to look at the
dialog**: it is a form that POSTs and creates a project (read in the DOM,
2026-10-30).

**An organization's template is Internal, base role Read**, so every
member can find and copy it and only owners and admins change it (the
user's standard, 2026-10-30). A copy within the organization came
Internal, so its visibility needs no step, though GraphQL reads only
`public: false` and the Templates list's "Private template" is that
list's label, read on the marked board. It came with base role Write.
Set that in the UI: the project's **Settings**, **Manage access**,
**Base role**, **Read**.

## Fields

| Field | Type | Values |
| --- | --- | --- |
| Status | single select | Open, Deferred, In flight, Done |
| Priority | single select | Urgent, High, Medium, Low |
| Reopen-when | text | the brief's trigger |
| Work model | single select | haiku, sonnet, opus, fable |
| Work effort | single select | low, medium, high, xhigh, max |

| Status option | Color | Description |
| --- | --- | --- |
| Open | `BLUE` | Ready for a session |
| Deferred | `GRAY` | Waits on its Reopen-when |
| In flight | `YELLOW` | A worktree holds it |
| Done | `PURPLE` | Closed, landed or dropped |

A brief's frontmatter maps onto them: `status: open` to Open,
`status: deferred` to Deferred, `priority: 2` to Medium, `reopen-when` to
Reopen-when. In flight is the claim, set when a session takes the issue;
Done is any close, which Item closed sets: an issue closed as not planned
read Done about 8 seconds later (2026-10-30), so only its `stateReason`
says it landed. `work-model`
and `work-effort` map to Work model and Work effort, the writer's advice
on how to work it; blank, like an omitted key, leaves the session's
default. An issue filed in the pilot carried no such advice, so its
session ran at that default (2026-10-27). A project holds up to 50
fields, built-in ones included (docs.github.com, 2026-10-27).

**Every option kept is passed with its `id`.** `updateProjectV2Field`
replaces the whole option list, and the schema says of an option's `id`:
"Include this to preserve the option's identity during updates,
preventing item field values from being cleared." The pilot's build
passed none, so every option took a new ID, and the five default
workflows that set a Status value read off with a warning mark, Item
closed among them (2026-10-27, inferred from the vanished IDs). A fresh
project's Todo keeps its ID as Open, and In Progress as In flight, where
those names exist.

**Every board offers the same Priority: Urgent, High, Medium and Low** (the
user, 2026-11-01). **A board uses its owner's own**, an issue field, where
the owner defines one offering High, Medium and Low: an organization's (the
user, 2026-10-30), or a user's, as personal accounts have had issue fields
since 2026-11-11 (the user, 2026-11-14). Else the board holds them as a
project field. **A personal account may define none**: GitHub creates its four
fields "when issue fields are enabled", and the user's own account read none
three days on (2026-11-14). Every reader and writer of Priority handles both. A brief's
`priority` stays 1 to 3 on either, and the queue still prints it so: P1 is
High, P2 Medium and P3 Low. **Urgent is left for a person**: no script writes
it, a filing rerun leaves a card or issue reading it, and it reads as P0, above
P1.

**A board with the older P1, P2 and P3 moves under the same IDs**:
`provision-board.sh` renames each and adds Urgent, so no card loses its value,
and the readers take either until it has. An owner's Priority offering anything
else, by any case, leaves the board on its project field, with a `todo:`.

- **The board lists it with `options: []`**, and a card's value comes as a
  `ProjectV2ItemIssueFieldValue` holding an `IssueFieldSingleSelectValue`
  `name`. A text field has no `options` key, which tells the two apart; `gh
  project field-list` prints no options for it (2026-10-30).
- **Its value lives on the issue**: `setIssueFieldValue(input: {issueId,
  issueFields: [{fieldId, singleSelectOptionId}]})`, by the IDs
  `repository.issueFields` lists, not the board's. That connection read
  `null` on a user's repo, with no error, before personal accounts had
  issue fields (2026-10-30), and an empty list on one defining none after
  (2026-11-14).
- **Moving a board in use has one order**, since a project holds no two
  fields of one name: copy each card's value to the issue, then
  `deleteProjectV2Field` the project's, then `createProjectV2IssueField`
  (`projectId`, `issueFieldId`) the owner's. Done another way, every
  card loses its value (one organization's 8 cards, 2026-10-30).
  `provision-board.sh` swaps them on a board with no cards, and names this
  as a todo on one with cards. The delete is expected to take Priority from
  each view, so on a copy made that run the script shows the added fields again;
  on any other board a view of views.json without Priority is a todo. That
  restore ran live on an organization's board, showing Priority in all three
  views, from a source staged to hold a project Priority (2026-11-01).
  **A copy within the organization carries its
  issue fields**, all four read back from a copy of its template with no
  options, and needs neither (2026-10-30), so only a template holding a project
  Priority reaches the swap: a user's, or an organization's older one. A
  user's copy carrying the user's issue fields is unseen: none was made by
  2026-11-14.
- **The board also carries Start date, Target date and Effort** where the
  owner defines them. **Effort is not Work effort**, though the names invite
  a merge: Effort sizes the work for a person, and Work effort is the model
  session's reasoning level, so keep both. A brief has no key for them, so
  filing leaves them blank, and the Views below hold no Roadmap until a brief
  needs a date. A user's board carries them where the user defines them, as
  an organization's does (2026-11-14).
- **The script reads every issue field type**: GraphQL's `IssueFields` union
  also holds number, text and multi-select, and an owner's Effort may be any of
  them (schema, 2026-11-01). **The script asks `viewerCanSeeIssueFields` of
  an organization's repo alone**, and a `false` there is a `todo:`. It read
  `false` on a user's repo too before personal accounts had issue fields
  (2026-11-01), and `true` on the user's own account after, with none defined
  (2026-11-14); a `false` on a user's repo since is unseen.

## Labels

**Every board's repo gets one label, `needs:user`**; each other label is
made by filing, the first time a brief names it, so a repo carries only
the labels its own issues use. The user narrowed the set so on
2026-11-06, as the two other boards on the account carried all eight
platform labels then standard and used none, nor `needs:tenant`: only
`needs:user`. Filing makes each label the repo lacks with no prompt of
its own, so `brief-bodies.py` prints each value a manifest holds, bar
`user`, as a `phrase label:` line, for the yes to file to cover it. An
existing label is left as it is, and a repo that has one this contract
no longer makes keeps it until removed by hand.

`needs:<value>`, one per value a brief's `needs` list holds, colour
`c5def5`, described "The brief needs: <value>". `user` is
`NEEDS_LABELS` in `provision-board.sh` and `STANDARD_NEEDS` in
`brief-bodies.py`, changed together; any other value is a phrase, such
as `tenant`. **A need for an app names the app**, as `<app> session`:
`power-bi-desktop session`, `claude-desktop session`. A bare `desktop`
was retired (2026-11-06), as it read as either app.

`platform:<value>`, one per value a brief's optional `platform` list
holds, colour `d4c5f9`, described "The work touches: <value>". **A
repo's `platform:*` labels are its list**: no set is fixed, as one
repo's platforms are not another's. A value must be lowercase kebab,
`[a-z0-9]+(-[a-z0-9]+)*`, as `power-bi`, which `brief-bodies.py` and
`handoff-status.py` each check; the yes to file is the guard against a
second spelling of a platform the repo already has. A label, not a
single-select field, since one issue can touch two platforms; the cost
is that a view cannot group by it, as GitHub groups by no label
(docs.github.com, 2026-10-28), only filter.

## Views

**[views.json](views.json) is the views' one home**: each view's name,
layout, filter, grouping, a board's columns and the fields it shows, in
column order. `provision-board.sh` reads it, so a view is changed there
and nowhere else. It holds what the user set on project 2 by hand,
read back by GraphQL (2026-11-04):

| View | Layout | Filter | Grouped by |
| --- | --- | --- | --- |
| Board | board, a column per Status | `-status:Deferred` | none |
| List: Open | table | `status:Open sub-issues.status:Open` | none |
| List: In flight | table | `status:"In flight"` | none |
| List: Deferred | table | `status:Deferred` | none |
| Parent: Open Sub: Open | table | `status:Open sub-issues.status:Open` | Parent issue |
| Parent: Open Sub: Deferred | table | `status:Open sub-issues.status:Deferred` | Parent issue |

**On an organization's board the table views also show** the Start date,
Target date and Effort its owner defines, as § "Fields" has it.

**A view is matched by its name**, which GitHub does not keep unique: a
second POST of one name made a second view (2026-11-03). So on every
board, copied, built or already there, the script makes each view the
spec names and the board lacks; reads one it has against the spec and
reports any difference, never rewriting it; and reports a view the spec
does not name, such as an older contract's `View 1` or `By parent`, for
the user to delete. Only on a board it built that run does it delete
`View 1`, GitHub's default, which no one has used yet. On a user's board
the build, the rerun and the copy each ran live, their views read back
by GraphQL (2026-11-04): the build made the four and deleted `View 1`,
and the rerun and the copy made none. No view there differed from the
spec or lay outside it, so those todos have run against the suite's shim
alone, and the `/orgs/<org>/...` route had not run by that date.

**The template carries the same views**, or each copy takes its old
ones beside the spec's: the user's took the four then in views.json
(Board, List: Open, By Parent: Open, List: Deferred) by the calls
below, and lost `View 1` and `By parent`, read back by GraphQL
(2026-11-03); then took the six above, its List: Open refiltered by
`updateProjectV2View`'s `filter` and `By Parent: Open` deleted, read
back by GraphQL (2026-11-04).
An organization's template takes the same step when views.json changes.

**REST makes a view; GraphQL fills its fields.** `POST
/users/<login>/projectsV2/<n>/views`, or `/orgs/<org>/...`, under API
version `2026-03-10`, takes `name`, `layout`, `filter`, `visible_fields`,
`sort_by`, `group_by` and `vertical_group_by`, by the integer IDs its own
`.../fields` lists, and grouped a table by Parent issue (probed
2026-11-03). Its page names the user path by numeric `user_id`, which
answered 404; the login worked. It refuses Created, Updated and Closed,
`unsupported_ids`, and its field list leaves them out, so a view showing
them then takes its whole list by GraphQL's `updateProjectV2View`
`visibleFieldIds`, which kept the grouping. That mutation also takes
`name`, `layout` and `filter`, and `deleteProjectV2View` deletes one;
neither GraphQL mutation sets a grouping, a sort or columns (schema,
2026-11-03). No API sets the order of the tabs, which the UI changes by
dragging, and the leftmost is the default; GraphQL's `views` reads in
view-number order whatever the tabs show (2026-11-01).

**`visibleFieldIds` sets a view's column order, and no API reads it back.**
GitHub shows the list in the order sent, one sorted by neither integer nor
string ID included, while `view.fields` reads in integer-ID order whatever the
UI shows, a drag included. So sending that read back sorts the columns by ID:
it undid a drag and moved Priority from 10th to 13th (an organization's board,
2026-11-01). `provision-board.sh`'s restore therefore sends the contract's
order, the view's other fields after it, and its todo says to drag back any
column a template placed otherwise; that code has run against a shim alone.
One organization's template puts Parent issue 5th, where views.json puts it
last: the spec's order wins (2026-11-01).

## Workflows

All built in, and none turned on by any API: GraphQL reads a workflow's
`name` and `enabled` and nothing more, and `deleteProjectV2Workflow` is
the only workflow mutation (2026-10-27).

| Workflow | Setting | Why |
| --- | --- | --- |
| Item added to project | issues, Status Open | a new card is ready unless set otherwise |
| Item reopened | issues, Status Open | a reopened issue is work again |
| Item closed | issues, Status Done | a closed issue is off the queue, landed or dropped |
| Auto-archive items | `is:issue is:closed updated:<@today-14d` | Done stays short |
| Auto-add to project | `is:issue is:open`, one per repo | an issue anyone files reaches the board |
| Auto-add sub-issues to project | on | a sub-issue from another repo joins its parent's board |

Auto-add sub-issues reads on in a new project and in the template
(2026-10-27), so no board needs a UI step for it; the repo's auto-add
already takes that repo's own sub-issues.

**Auto-add is set by hand on every board**, since a copy never carries
it. Existing issues are not added, and the number allowed is per plan:
Free 1, Pro and Team 5, Enterprise 20 (docs.github.com, 2026-10-27). Its
filters take `is`, `label`, `reason`, `assignee` and `no`; Auto-archive's
take `is`, `reason` and `updated`.

**The board holds issues, not pull requests**, so each standard
workflow's Pull request box is cleared, and auto-add, which has no such
box, says `is:issue` in its filter (project 2 and an organization's board,
2026-10-30). A pull request shows on its issue's card under
Linked pull requests, and merging one that says `Closes #N` closes the
issue, which Item closed moves. Off, then:

- Pull request merged, for that reason;
- Auto-close issue, since a card dragged to Done would close an issue
  whose work has not landed;
- Pull request linked to issue, until a repo lands by pull request,
  where In flight suits it. A `pull_request` rule on the default branch marks
  that, and both scripts then ask nothing of this workflow: a repo that lands
  so under classic protection, which neither reads, still reads as wanting it off;
- Code changes requested and Code review approved, which act on pull
  requests.

**Auto-close issue and Pull request linked to issue show a warning mark
while off**, on the template, on project 2 and on a copy, the first
reading "A value is required" for its Status (2026-10-30). That is no
broken copy.

**Setting one in the UI**: the project's **⋯** menu, **Workflows**, the
workflow, **Edit**, its value, **Save and turn on workflow**. A session
with Claude in Chrome can make it, and read back what GraphQL cannot,
by `audit-repo`'s `references/browser-steps.md`.

## Parents and sub-issues

**A parent tracks; its sub-issues hold the work.** A parent holds no
work of its own, so it closes with its last sub-issue: by the repo's
`.github/workflows/close-parent.yml` where it has one, else by the user
on the queue view's `close it` line, never by a commit, which cannot
know it is the last while siblings land in parallel (2026-11-04).
Blocked-by orders siblings, and a parent groups them (the pilot's
tracking issue, 2026-10-29).

- **A brief names both by number**: `parent: <n>`, and a `blocked-by`
  item that is an issue's number, bare beside the brief filenames,
  since YAML reads a space and a `#` as the start of a comment.
  `file-issues.sh` makes each
  GitHub's native link, at create where it can and after otherwise.
- **An issue that merely touches another says so in prose**: the contract
  does not use GitHub's Relates to link (`addRelatesTo` in GraphQL), which
  orders and blocks nothing, so no brief key or script writes it (the
  user's call, 2026-11-02).
- **The queue view nests a sub-issue under its parent**, holds a parent
  with open sub-issues blocked, so no session takes the tracking issue
  for work, and flags one whose sub-issues are all closed to close.
- **A Deferred parent reads Open once it gains an open sub-issue**:
  `file-issue` and `group-issues` reopen it, comment first, as they link
  the child. A sub-issue linked by hand on GitHub leaves it
  Deferred, for `update-issue` with `<n> reopen` (2026-11-05).
- **GitHub's limits**: up to 100 sub-issues per parent, and eight levels
  of nesting. An issue has one parent. A view can group by Parent issue
  and filter by it, `parent-issue:<owner>/<repo>#<n>` (docs.github.com,
  2026-10-29).
- **Labels stay the metadata that crosses owners**, `needs:*` and
  `platform:*`. Issue types are an owner's, an organization's or a user's,
  whose repo listed Task, Bug and Feature enabled (2026-11-14), and the
  contract uses none; of the owner's issue fields it uses those § "Fields"
  names. **So on a board that keeps the project's Priority, an owner's own,
  in an issue sidebar's Fields section, is not the brief's**: the board
  neither reads nor writes it, so it can read "Choose an option" beside a
  card at P2. Only the Projects card's Priority counts (seen in one
  organization's sidebar, 2026-10-30).

## Claims

**In flight and an assignee are the claim**, which `set-card.py` sets
when a session takes the issue. They hold across machines and people,
where a worktree claims only on its own machine, so co-developers share
one.

**An assignee is a login, never an email**: `gh issue edit
--add-assignee` takes logins (its help, read 2026-10-28). Asked to
assign by a colleague's email, an organization repo's session listed the
assignable logins with `gh api repos/<owner>/<repo>/assignees --paginate
-q '.[].login'`, read each one's `gh api users/<login> -q .name`, and
assigned the match. A private email is not visible, so the match rests
on the profile name: say so to the user. Passing the email itself was
not tried (inbox note, 2026-10-27).

## Who can write it

The token needs the `project` scope for any write, `read:project` for a
read (docs.github.com, 2026-10-27). An organization's owners can turn
projects off there, after which "it won't be possible to create new
projects at the organization level"; whether members may create projects
otherwise is stated on none of the pages read, and whether a member who
is no owner can, or sees a marked template, is untested, needing a member
account (2026-10-30). On one Enterprise organization, the `project` scope
was all an owner's token needed for the copy, link, labels, mark, filing,
claim and close, with no single sign-on prompt; whether it enforces SAML
was not read (2026-10-30). **Where it does, a token not yet authorized reads
404 or 403**, the 403's `X-GitHub-SSO` header holding a link to authorize it,
good for an hour, and an unauthorized multi-organization list omits that
organization's results (docs.github.com, 2026-11-01; not seen here). `gh api -i`
shows the header. A project holds up to
50,000 items, archived ones included. Whether a user's board needs
Projects on in the repo is not stated either; the repo this skill is
authored in turned it on regardless (2026-10-27). `provision-board.sh` reports a repo with Projects
off as a todo, and stops on one with issues off, whose board could hold nothing.

**`gh` makes every write.** github-mcp sets fields and makes views only
in the remote server's `projects` toolset, through `projects_write`'s
`update_project_item`, `create_project_view` and `update_project_view`,
and that toolset is not a default one: it takes an `X-MCP-Toolsets`
header in `.mcp.json` and project access on the token (its README,
2026-10-27). An Actions workflow can set Status through
`updateProjectV2ItemFieldValue`, but `GITHUB_TOKEN` "cannot access
projects": a user's project takes a classic PAT with `project` and
`repo`, stored as a secret, and an organization's a GitHub App
(docs.github.com, 2026-10-27). That is kept for what no built-in
workflow does.
