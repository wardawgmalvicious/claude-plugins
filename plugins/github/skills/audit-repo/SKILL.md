---
name: audit-repo
description: "Audits a GitHub repo against a personal or org policy, with a read-only script: its merge methods, branch auto-delete, secret scanning, Actions token and pins, deploy keys, rulesets and bypasses, required checks no job reports, CODEOWNERS and release-tag ruleset, its About panel (description, homepage, topics), social preview card and community profile (README, licence, CONTRIBUTING, code of conduct, PR template). Reports each finding's reason and fix. Then, one yes at a time, proposes About text as a diff, renders three card candidates, snapshots settings with its repo-settings.ps1, and adds the scaffolds a repo lacks: a handoff queue with lint hook and inbox, a pre-commit baseline (gitleaks, identity-guard) and CI workflow, an instruction file, a licence, CONTRIBUTING, a conduct code, a PR template. On a new repo that is its setup; on an old one, its gaps. Changes nothing without the user's yes. For a leak already pushed, or to put back settings after a recreate, use recreate-repo; to merge, land-branch."
when_to_use: "Use when asked to audit, check or review a repo's GitHub settings, branch protection, merge settings or branch strategy; to set up a new repo or before people publish from one; to make a repo public or change visibility, or before going public; to write or set its About, description or topics; to make or upload a social preview card or Open Graph image; to scaffold a handoff queue, pre-commit hooks or a licence, or add a CI workflow that runs them; or when a PR sits on 'Waiting for status to be reported'."
argument-hint: "[owner/name] [personal|org-internal|org-published|releases]"
model: inherit
effort: high
disable-model-invocation: false
---

# Auditing a repo

Read one GitHub repository's live settings and About panel, compare them
with the policy chosen for it, and report each finding with its reason
and the change that fixes it, **for the repo's owners to make**. Then
offer, one yes at a time, what the repo lacks: About text, a social
card, a settings snapshot and the files a repo here is set up with. On
a new repo that is its setup; on an old one, its gaps.

Past `references/`, docs.github.com by its search,
`curl -s 'https://docs.github.com/api/search/v1?query=<q>&language=en&client_name=x'`
(no `client_name`: 400), then a hit's body,
`curl -s 'https://docs.github.com/api/article/body?pathname=<hit url>'`,
and code.claude.com by `curl -s` of its page plus `.md`. A live page
that contradicts a line here wins: say so, act on the page, and route
the fix by `capture-learning`, bar a dated measured line that names the
page it overrules and the call that measured it, which a page changed since
its date sends back to re-measure. An observed claim is cited or marked
pending a doc check, and stands, marked observed, only where no page covers
it.

## Reports first, writes only on a yes

The script only reads, and nothing here writes unasked. A repo's
settings are its owners' to change, an organization's above all, and
the `fix:` lines it prints, `gh api -X PATCH` and `PUT` and
`gh repo edit`, change them for everyone at once. A user who asks for
one is asking for an outward action: confirm it on its own, run it, and
rerun the audit. **Files land only in the repo the session runs in**, a
card and a scaffold included, and in that repo's inbox directory; never
in this skill's own repo or another.

## Before step 1: an instruction file

**Where the working directory is a clone of the repo audited and its
root holds neither `CLAUDE.md` nor `AGENTS.md`, offer `/init` before
step 1.** Two later steps need that file: step 6 drafts the About text
from it, and step 8's handoff queue writes its lines into it. Skipping
`/init` before an audit has happened more than once (2026-11-02).

On a yes, run `init` through the Skill tool, since `/init` is one of the
built-in commands that tool can reach (the skills page, § "Restrict
Claude's skill access", 2026-11-02). Then read the file it wrote and go
on to step 1. If the user types `/init` instead, rerun `audit-repo` in
a fresh turn after it.

Go on without one only on the user's word, and then step 8 reports the
gap again. **A request to list or walk through every change at once,
with "change nothing yet" or "then stop", is not that word**: the offer
still comes first, since step 6's About draft and step 8's queue lines
need the file, and a walkthrough that ran the audit on the README alone
drafted its About text without it (2026-11-03). Skip the check only for a repo the user keeps for reference
only, or one the user says holds only an app's installers, the
`releases` policy of step 2, as it holds no code to instruct a session
about. An organization's repo gets it too: the check writes nothing
without a yes, so where the file is someone else's call, the user just
goes on without it.

## 1. Pick the account

`gh` can act as an account other than the one that administers the
repo, and a 404 from the wrong account looks
exactly like a missing repo. **Pass each script below `-Login <login>`**:
the repo's owner, or for an organization's repo an account with admin
rights there. The script mints that account's token itself, by
`gh auth token --user`, and stops before reading the repo where gh holds
none or acts as another; left out, it reads as gh's own account.

**A pin exported in a Bash block of its own reaches no later call**:
each Bash call is a fresh shell, and in a worktree the guard refuses the
export as too complex to verify (2026-11-05). So a write this session runs
itself, a `fix:` line or step 6's `gh repo edit`, pins in the same call,
by the PowerShell tool where the guard refuses the Bash form:

```bash
export GH_TOKEN="$(command gh auth token --user <login>)"
[ -n "$GH_TOKEN" ] || { echo "no token for <login>: not pinned"; exit 1; }
gh repo edit <owner>/<repo> --description '<text>'
```

```powershell
$env:GH_TOKEN = gh auth token --user '<login>'; if ($env:GH_TOKEN) { gh repo edit <owner>/<repo> --description '<text>' } else { 'no token for <login>: not pinned' }
```

The script's first line names the account it read as; check that
before reading anything else. Without admin rights the merge settings
come back `null`, and the script stops with exit 2 instead of reading
a `null` as a setting. With write but not admin, it runs, warns, and
cannot see a ruleset's bypass list.

## 2. Pick the policy

`personal`, `org-internal`, `org-published` or `releases`: [references/profiles.md](references/profiles.md)
says which fits a repo, and the strategy each encodes. **The choice is
the audit**, so when the repo's purpose doesn't settle it, ask.
**`releases` is for a repo holding only an app's installers and update
feed**, its source in another repo, whoever owns it: it judges
immutable releases, Actions off, the branch guard, issues, wiki and
projects off, and private vulnerability reporting on, in place of what
a source repo is asked. Where
the repo releases by tags, pass the tag ruleset's pattern without
`refs/tags/` as `-ReleaseTagPattern`.

**A private repo going public is judged as it will be afterwards**,
under `-AsPublic` and the policy picked here. `org-internal` stays open
to it, since an organization's repo can open its source and publish
nothing from its default branch; [references/profiles.md](references/profiles.md)
gives a public one the branch guard.

## 3. Run the script

**A private repo the user says is going public is scanned first**, from
a clone of it, before the audit:

```bash
pwsh -NoProfile -NonInteractive -File "${CLAUDE_SKILL_DIR}/scripts/going-public.ps1" -Repo <owner>/<repo> -Login <login>
```

It reads only, and prints counts, never a denylist term: the terms and
gitleaks' findings in every commit a ref the remote lists reaches, pull
request refs included, and in the issues, pull requests, comments,
discussions, wiki and releases; then the Actions runs and push
rulesets, and each project's own visibility. Exit 0 is nothing found, 1 a `[HIT]`
or `[WARN]`, and 2 no scan, which is never a pass. **With no identity
denylist the scan reads on and warns once that no part was scanned for
a term**, so it never exits 0: say so, and that the user's own denylist
is what names a client or an employer. A `[WARN]` naming ref tips the
clone lacks prints the fetch that reads them: offer it, and on a yes
run it, then scan again. Then
run the audit below with `-AsPublic`, which judges the settings as
public, under step 2's policy. [references/going-public.md](references/going-public.md) has
what the switch exposes, each source's command and how to read it, and
what the scan cannot see.

```bash
pwsh -NoProfile -File "${CLAUDE_SKILL_DIR}/scripts/audit-repo.ps1" -Policy <personal|org-internal|org-published|releases> -Repo <owner>/<repo> -Login <login> -ReleaseTagPattern '<pattern>'
```

`-Repo` defaults to the origin of the clone the working directory is
in, and `-ReleaseTagPattern` is optional. Exit 0 means no `[FAIL]`, 1
one or more, and 2 that the repo could not be audited. Don't swap the
script for ad hoc `gh api` calls: it treats a 404 from
`codeowners/errors` as "no file", reads classic protection from the
only endpoint that answers it, and reads `gh` under UTF-8.

**A `[STOP]` saying gh cannot read the repo is a question for the
user**: `gh, acting as <login>, cannot read <owner>/<repo> -- the wrong
account, or no such repo`, then gh's own line, such as
`gh: Not Found (HTTP 404)`. Report that line and the account, then ask
by `AskUserQuestion` which repo was meant, or which account reads it,
offering a near match from `gh repo list <owner> --limit 200` under
the same pin, since it lists 30 by default.
**Audit no other repo, and drop no pin, unasked**: each acts on a
guess. Asked for a misspelled `fabric-tool`, one arm audited its near
match, `fabric-tools`, unasked, and another unset the pin to read as
gh's own account before asking (2026-11-06).

**Where the clone keeps `.github/repo-settings.json` for the repo
audited**, compare with it too, since the script compares with a
policy, never a snapshot:

```bash
pwsh -NoProfile -File "${CLAUDE_SKILL_DIR}/scripts/repo-settings.ps1" -Check -Login <login>
```

It reads only, refuses a file naming another repo, and exits 1 on any
drift, which goes in the report beside the findings. **It exits 1 on
every refusal and failed read too**, a `-Login` gh holds no token for or
does not act as among them, where `audit-repo.ps1` exits 2: read the
output before the code.

**Where the clone keeps its own copy of that script**, as
`scripts/repo-settings.ps1` or wherever its docs name the snapshot's
owner, read it, then run it for this `-Check` and step 5's `-Export`,
and say so in the report. A copy taken before 2026-10-01 writes no
`_repo` key, so this skill's script refuses its snapshot, `it names no
repo in a _repo key.`, and adding the key by hand, as the script's help
says to adopt one, fights the script that owns the file (an
organization's repo, 2026-11-03). **A clone's own copy taken before
`cb123cec` (2026-11-05) has no `-Login`**: it fails at binding, `A
parameter cannot be found that matches parameter name 'Login'`, so read
its `param` block, and
where it has none, drop the switch and pin in the same call, as step 1
shows.

## 4. Read the report

- **`[FAIL]`**: the setting contradicts the policy. The `why:` line is
  the policy's reason, and the `fix:` line is the change.
- **`[WARN]`**: allowed, but the owner should know, such as an account
  that can bypass the default branch's rules, or an About panel with no
  description. The About panel never fails.
- **`[INFO]` and `[ok]`**: context, and settings already as the policy
  wants. The About section prints the live description, homepage and
  topics as `[INFO]` lines, which step 6 diffs against.

**A required check reported on none of the commits read** is the cause
behind a pull request stuck on "Waiting for status to be reported". Its
`fix:` lists every name GitHub did record, so the matching one is
usually plain: a matrix job reports as `test (20)`, never as `test`.
With no check runs at all, as in a repo whose CI has never run or whose
records Actions retention has deleted, the script says it could not
compare.

**Hardening warns under either policy**: an action pinned by tag, the
server's SHA-pin rule off, secret scanning or push protection off, a
deploy key that can write, a bypass on any active ruleset, a
code-owner rule that keeps an approval across a new push, and, on a
public repo, a pre-commit config that no workflow runs. **Secret
scanning on a private or internal organization repo is a spend**, as its
`fix:` line says, so it runs only after its bill is agreed. An action's
pin is the commit its tag names, the `^{}` line of
`git ls-remote --tags https://github.com/<owner>/<action> '<tag>' '<tag>^{}'`
where there is one, else the plain line, with the tag kept as a comment.

**Four settings print as `[INFO]` and never warn**, each the owner's
choice or bill: Actions policies, a lockfile with none active, a public
repo's pull request cap, and AI secret detection. No lockfile rule type
is documented, so a policy's rule types are read, not judged.

**The Claude Code Action prints under `org-internal` and
`org-published` alone**, as `[INFO]`: each workflow whose `uses:` names
`anthropics/claude-code-action`, or that none does, which step 8 offers.

**The handoff board** is the linked project carrying
`provision-board`'s contract, judged on its fields, workflows and the
repo's `needs:user` label, the one every board's repo gets. A gap
warns under either
policy, and no board is `[INFO]`. A field or label gap's `fix:` names
`provision-board`, for the user to type; a workflow's is the project's
Workflows menu, since no API sets one. A board left unread, for want of
`read:project`, is never a board missing. Beside a board, a default
branch with no `.github/workflows/close-parent.yml`, or Actions off,
warns too: GitHub closes no parent with its last sub-issue. Its `fix:`
is step 8's close-parent workflow.

**The handoff landing** warns, under either policy, where a board or
`docs/handoffs/` holds a queue and `.claude/rules/handoff-briefs.md` is
missing or names neither landing bullet: `work-issue` and
`lead-sessions` stop until it names one. Its `fix:` is step 8's
handoff-queue step 2, with the bullet the default branch's rules imply.

Give the user each `[FAIL]` and `[WARN]` with its reason, grouped as
the script groups them, rather than the whole output.

**A going-public report leads with the scan**: each `[HIT]` and
`[WARN]` from `going-public.ps1`, as it groups them, then the audit's.
Its `fix:` lines delete runs, artifacts, revisions and history, which
nothing restores, so each takes its own yes, as step 5's do. **The
switch itself is the user's**: Settings, then Change visibility in the
Danger Zone, or
`gh repo edit <owner>/<repo> --visibility public --accept-visibility-change-consequences`.
Never run it here.

## 5. Propose the changes

- **Repo toggles and the Actions token**: the `fix:` lines, as they
  print. Run none unasked, and each in one call with step 1's pin.
- **Rules**: where a finding names a `ruleset-*.json` scaffold, offer
  that ruleset as step 8 does, created by API on a yes; otherwise the
  repo's rules settings page, which the `fix:` line links, with the rule
  to add or change.
- **After any change**: rerun the script. For a repo that
  keeps `.github/repo-settings.json`, record the new values from a clone
  of it with
  `pwsh -NoProfile -File "${CLAUDE_SKILL_DIR}/scripts/repo-settings.ps1" -Export -Login <login>`,
  or the clone's own copy where step 3 ran one, as its owner or an
  organization's admin. `-Apply` refuses any
  organization's repo.
- **`delete_branch_on_merge` was off**: merged branches have been piling
  up, so offer `prune-branches`.

An organization's names, its repos' included, go into no other repo's
files. The report stays in the conversation, and a follow-up for that
repo goes to its folder in the user's handoff inbox, where one exists;
with none, say the follow-up and stop.

## 6. The About panel

Draft the description, topics and homepage from what the repo says of
itself: the opening paragraph of its `README.md`, then its root
`CLAUDE.md`, or its `AGENTS.md` where no `CLAUDE.md` is, then any
manifest's own description (`package.json`, `pyproject.toml`,
`.claude-plugin/plugin.json`). Read GitHub's limits on a description
and on topics from docs.github.com at the run, never from memory, and
say so where the page states none.

Propose the result as a diff against the live values step 4's `[INFO]`
lines printed, one line per field, and run nothing unasked. On a yes,
in one call with step 1's pin:

```bash
gh repo edit <owner>/<repo> --description '<text>' --homepage '<url>' --add-topic <a>,<b> --remove-topic <c>
```

Then rerun the script, and where the repo keeps
`.github/repo-settings.json`, which records all three, `-Export` as
step 5 does.

## 7. The social card

Offer one where step 4 reported none, or when asked for a new one. Every
card is the house template filled with a repo's own words, so a user's
repos share one look; [references/social-card.md](references/social-card.md)
has the spec's keys, the design limits and what was measured.

**GitHub shares a card only from a public repo**, so where step 4's
line is `[INFO]`, on a private or internal one, say the upload cannot be
made there, and draft a card only if the owner wants a file kept in
`docs/social/` for a later public release; step 6 is then skipped. A
repo audited `-AsPublic` warns of a missing card, and the upload still
waits for the switch.

1. **Draft three angles**, A, B and C, from the README and the About
   text: each a spec in its own scratchpad folder, alike in owner, name,
   accent and licence, unlike in tagline, bold words, chips and the
   footer's right side. **Where the repo has no licence yet**, the
   footer's left side takes another short fact: step 8 offers the
   licence after the card, so naming one here guesses the owner's pick.
2. **Render each**. No image model draws one, so the script renders HTML
   to PNG with headless Edge's **x86** path, exit 0 meaning written and
   checked:

   ```bash
   uv run --no-project "${CLAUDE_SKILL_DIR}/scripts/render-card.py" <scratchpad>/card-a/spec.json --out <scratchpad>/card-a
   ```

3. **Read each PNG** and check it reads at half size: the name on one
   line, the tagline in three lines or fewer, nothing near the edge.
   Redraft and render again where one fails.
4. **Give their full paths**, expanded by `cygpath -lw`, then ask once
   with `AskUserQuestion`: A, B and C, each with its tagline and chips
   in `preview`, which shows text only, and **Skip**. A typed direction
   under *Other* is drafted, rendered and asked again.
5. **Write the pick** into the repo's `docs/social/` by rendering its
   spec with `--out docs/social`, and commit both files through
   `commit-changes`.
6. **The upload is a UI step, on a public repo only**: Settings,
   General, Social preview, Edit, Upload an image. No API uploads one.
   With Claude in Chrome connected, offer to make it, by
   [references/browser-steps.md](references/browser-steps.md), which
   checks the browser's login first; else hand it to the user. Rerun
   the script afterwards: it reads `usesCustomOpenGraphImage`, so the
   WARN or INFO becomes `[ok]`.

## 8. Scaffolds

Report what the repo lacks and offer each piece on its own yes, never
forced: branch rulesets (a guard against force pushes and deletion on
any repo, a pull-request tier, and branch names on an organization's),
a handoff queue with its inbox directory, a
`.worktreeinclude` for the gitignored files its worktrees need and,
beside a board, the workflow that closes its parents, a
pre-commit baseline
and the workflow that runs it, a settings snapshot, an instruction file, a licence, a pull request
template, under `org-published` a CONTRIBUTING file and a code of
conduct, and under either organization policy the Claude Code Action
workflow, its credential chosen at the offer.
[references/scaffolds.md](references/scaffolds.md) says how to tell
each is missing, what each writes and in what order; its templates are
in `${CLAUDE_SKILL_DIR}/assets/scaffolds/`. **Under `releases`
the offers are four**: the guard ruleset, a licence (the source repo's),
a README for downloaders and a `SECURITY.md`, by its § "A releases
repo"; nothing else
here serves a repo where no work lands. A README written then sends the
About text back to step 6, which drafts from it.

**The queue is a board first**: offer `provision-board` for the user to
type where the owner can hold a project, and the file queue only where
it cannot or the user declines.

**A repo's Claude Code hooks, permission rules, skills, MCP servers and
`.claude/launch.json` are no scaffold here**: they are
`audit-agent-setup`'s, which § 9 lists on a repo where sessions work.

## 9. Next steps

End the run with a **Next steps** list, so that the last thing the user
reads is what to do next. List first what this run left for the user:
a `fix:` they did not run, a card to upload by hand, a typed-only
skill this run offered, such as `provision-board`, and, after the
Claude Code Action's copy, what it cannot do: the app's install, each
secret or variable, an allowlist entry, and the audit's rerun
(`references/scaffolds.md` § "A Claude Code Action workflow"). Then,
on any repo
bar one audited under `releases`, where no session works, or one the
user keeps for reference only, list what follows the audit, each for
the user to type:

1. `audit-agent-setup`, for the repo's hooks, permissions, skills and
   MCP servers.
2. `scope-instructions`, once sessions have run in the repo, since it
   measures their transcripts.

Leave out an item the run already settled or the user says has run
here: `audit-agent-setup` writes nothing, so the repo cannot show it
ran. Write "none" rather than leave the list empty.

## Constraints

- **No writes unasked**: not a `fix:` line, not `gh repo edit`, not a
  ruleset, a card, a scaffold or a snapshot, unless the user said yes
  to that one.
  The visibility switch is never this skill's to make.
- **A `null` is never a setting.** Exit 2 means the audit didn't
  happen: on a `null`, switch account rather than reading around it,
  and on a repo gh cannot read, ask which repo was meant or which
  account reads it, as step 3 says.
- **No silent policy.** The policy decides every finding, so a guessed
  one produces guessed defects.
- **The account the script read as is part of the result.** Report it
  with the findings.
