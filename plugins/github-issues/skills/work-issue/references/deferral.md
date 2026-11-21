# Deferring

Part of the per-issue procedure, read on a deferral: `work-issue`'s
step 7, and `lead-sessions` on a worker's `DEFER:` line. Its
placeholders are [preflight.md](preflight.md)'s.

**A deferral comments its why, then releases the card**, in that order,
so a failed comment leaves the card In flight for a retry rather than
Deferred with no reason given. **Name each issue it blocks**, from
`gh issue view <n> --json blocking`: the view counts a blocker while it
is open, whatever its card's Status, so each stays blocked behind a
deferred card.

**The why and the trigger go in scratchpad files first**, never pasted
into a command: they are text a reader of an issue anyone can file
wrote, so a quote or a `$(…)` in one would run in the main checkout.
`work-issue` writes both with Write, on the user's yes. `lead-sessions`
takes them from its worker's reply, `cut -c 8-` dropping the `DEFER: `
prefix:

```bash
J="<S>/<slug>.json"
jq -b -r '.result' "$J" | grep -E '^(STATUS|NOTES): ' > "<S>/<slug>.defer.md"
jq -b -r '.result' "$J" | grep -E '^DEFER: .*[^[:space:]]' | grep -v -i -E '^DEFER:[[:space:]]*none[[:space:]]*[.]?[[:space:]]*$' | tail -n 1 | cut -c 8- > "<S>/<slug>.trigger"
```

The second `grep` drops `DEFER: none.`, which a finished worker wrote
once (2026-10-31); read as a trigger it would reach the card's
Reopen-when as `none.`.

**Commits land first, if any**, without a `Closes` line, as
[§ "This repo's landing"](fast-forward-landing.md#this-repos-landing)
says, or on a pull request whose number the comment names, by
[§ "Landing by pull
request"](pull-request-landing.md#landing-by-pull-request). Then, from
the main checkout, or, for a `work-issue` session that handed its
branch to a lead, from its worktree on the `landed` or `opened` reply
([lead-hand-off.md](lead-hand-off.md)):

```bash
uv run --no-project "<skills>/triage-inbox/scripts/set-card.py" . <n> --status Deferred --reopen-when "$(cat "<S>/<slug>.trigger")" --unassign --comment "<S>/<slug>.defer.md"
```

**`--comment` posts the why before the card's write**, which it sends
only once the comment went through, as the account `user.name` picks,
whatever `GH_TOKEN` holds (2026-11-14). It refuses a why or a
trigger holding a term of the identity denylist, `a denylisted term in
<file>: <count>`, writing nothing and naming no term: reword the file
by kind, or, for `lead-sessions`, ask the user. The quoted substitution
is never parsed again, so the trigger's text reaches the card as
written.

With no commit there is nothing to rebase or fast-forward: remove the
worktree and delete its branch, which `git branch -d` takes, since it
sits at `HEAD`. A `set-card.py` exit other than 0 prints the card as it
reads after the attempt, which a mutation failing part way may leave
half written, since its fields run in turn: print that and the command,
for the user to rerun, less its `--comment` where a `note: the comment
posted` line names the comment's URL.

**`update-issue` defers a card no session holds**, by the same command,
from its `SKILL.md` § "Defer".
