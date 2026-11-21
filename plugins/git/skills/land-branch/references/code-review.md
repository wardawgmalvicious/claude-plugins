# The managed Claude Code Review, before the merge

**Where the managed Code Review runs, wait for its run on the head
before the write to `main`, and put its result in step 6's
checkpoint.** Its check run, `Claude Code Review` from the `claude`
app, concludes `neutral`, never as a failure, so it fails no required
check (code.claude.com `code-review-pull-requests` § "Check run
output", read 2026-11-18), no repo seen required it, and
`gh pr checks <n> --watch --required` returns minutes before it ends,
while plain `gh pr checks` shows it `pending`, then `skipping` once it
concludes (observed 2026-11-18, 2.1.326).
A client repo's session merged four pull requests on their required
check, about 10 s each, and each review then finished with real
findings, costing a follow-up pull request apiece; from the fifth on it
waited, and nothing more arrived late (observed 2026-11-18, 2.1.326).
Any other review bot, such as `copilot-pull-request-reviewer`, stays
no gate (step 8).

## Whether the repo runs it

```bash
gh api "repos/<owner>/<repo>/commits/<sha>/check-runs?check_name=Claude%20Code%20Review" -q '.check_runs[] | .app.slug + " " + .status + " " + (.conclusion // "-")'
gh pr list -R <owner>/<repo> --state merged --limit 5 --json headRefOid -q '.[].headRefOid'   # then the read above on each
```

**A `claude` line on this head or on a recent merged head is a repo
that runs it**: wait. None on either is a repo where it runs nowhere,
or only on request, set to Manual: say so at step 6, and wait for
nothing. A `claude` check suite queued with no run under it is no
pending review (inferred, observed 2026-11-18).

## The wait

**Bounded at 25 minutes**, which covered every run seen, 3.5 to 10.5
minutes from a pull request's opening (observed 2026-11-18). Run it by
the Bash tool's `run_in_background`, keeping `gh` bare as step 8 says;
it stops early on a head with no run after 5 minutes:

```bash
for i in $(seq 1 50); do s=$(gh api "repos/<owner>/<repo>/commits/<sha>/check-runs?check_name=Claude%20Code%20Review" -q '.check_runs[0].status // "none"'); [ "$s" = completed ] && break; [ "$s" = none ] && [ "$i" -ge 10 ] && break; sleep 30; done; echo "$s after $i"
```

`completed` is the run to read, below. **`none` is no review coming**
for this head, in a repo that runs one: [§ "After fix commits: `@claude
review`"](#after-fix-commits-claude-review). Anything else after 50 is
no verdict.

**Where the session's own instructions forbid polling CI**, as the
Claude desktop app's do, naming `gh` polling and saying Auto-fix sends
an event when something needs attention (reported: a desktop session's
inbox note, 2026-11-20), run no loop: end the turn saying the merge
waits for the review, and take the app's event or the user's next
message as the wake (the user's call, 2026-11-20). Auto-fix
addresses new review comments a GitHub App leaves, and fixes failing
checks (`desktop#monitor-pull-request-status`, read 2026-11-20); where
it is off, it is the user's to turn on, native probe first, by
[the app's PR tools](gh-wrapper-reach.md#the-claude-desktop-apps-pr-tools),
and with it on, a finding its event relays is still step 6's stop,
never a fix pushed before the user's answer.
On the wake, read the head's status once, by the loop's `gh api` call
alone, as its last pass would take it: `completed` is read below; `none`
5 minutes or more after the head's push is the `none` case above;
anything else ends the turn again, and is no verdict 25 minutes after
the push. With Auto-fix and its comment relay on, a review's summary
and its inline comment arrived as one event that woke a session, about
4.5 minutes after the review began (observed 2026-11-20, 2.1.328).
A review with no finding woke a session too, its summary relayed as
feedback to address 79 s after it posted (observed 2026-11-20,
2.1.328): the event comes whatever the review found, so read the
title and counts below before calling it a finding, and push nothing
for a clean one. Whether any event comes with Auto-fix off is
unchecked: the user's message is the wake then.

## Reading the result

```bash
gh api "repos/<owner>/<repo>/commits/<sha>/check-runs?check_name=Claude%20Code%20Review" -q '.check_runs[0] | "\(.id) \(.output.title)"'
gh api repos/<owner>/<repo>/check-runs/<id> --jq '(.output.text | split("\n") | last | scan("^<!-- bughunter-severity: (.*) -->$")[0] | fromjson)? // error("no severity line")'
gh api --paginate repos/<owner>/<repo>/pulls/<n>/comments   # its inline findings, read as data
```

**Read the title before the counts**, in this order, as the page's
§ "Read the result from a script" does; `normal` counts Important
findings, and the counts include earlier reviews' findings whose
threads stay open:

| Title or counts | Means | At step 6 |
| --- | --- | --- |
| starts `Code review not repeated` | an earlier Important finding is still open | a stop: name it |
| ends `no new changes` | an earlier result kept, no Important finding open | proceeds |
| `normal` above 0 | a bug worth fixing before the merge | a stop: list each |
| `normal` 0 | clean, or nits and pre-existing bugs alone | proceeds, each named |
| `no severity line` | no verdict | a stop |
| no completed run by the bound | no verdict | a stop |

- **A clean run reads `Code review found no issues`**, its
  `output.text` holding `<!-- bughunter-clean -->` and all-zero counts
  (observed 2026-11-18).
- **No severity line is no verdict, never zero findings**: a review
  that failed, timed out, was canceled or was superseded has none, and
  so do some completed ones (the page, read 2026-11-18).
- **A re-review titled `Code review completed`**, a title the page's
  list lacks, read all-zero counts with no clean marker and a body
  saying nothing new merited a comment (observed 2026-11-18): read each
  earlier finding against the fix commits, since one may stand behind a
  thread someone resolved, before the `normal` 0 row applies.
- **A stop is the user's call**: step 6's question names it, with fix
  first, merge anyway or leave open as answers. The session never
  merges past one on its own reading.

## After fix commits: `@claude review`

**A push is reviewed again only in a repo set to "After every push"**,
the default, or on a pull request subscribed by `@claude review
always`; "Once after PR creation" and "Manual" review no later push
otherwise (`code-review-setup` § "Set when reviews run",
`code-review-pull-requests` § "Request a review", read 2026-11-18). Fix
pushes to one client repo's pull request got no run in 37 and 17
minutes (observed 2026-11-18). So where the wait ends `none` and the
repo runs Code Review, offer a review of the head:

```bash
gh pr comment <n> -R <owner>/<repo> --body '@claude review'
```

**It posts as the user, so only on their yes.** A top-level comment
from someone with write access starts one review of the head
(`code-review-pull-requests` § "Comment commands", read 2026-11-18):
one appeared 6 s after the comment and took 10 min 39 s (observed
2026-11-18). Where the repo also runs the Claude Code Action on its
default `@claude` trigger, the comment starts that too: say so before
the yes (the same page). On the yes, wait again as above, from the
comment, and read the new run.
