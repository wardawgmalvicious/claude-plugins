# Scaffolds

What a repo set up on this machine is expected to keep, how to tell each
is missing, and what each writes, branch rulesets on GitHub included. Report every gap first, as its own
finding, then offer each on its own yes: never forced, and written only
in the repo the session runs in. The templates are in the skill's
`assets/scaffolds/`, by the path `SKILL.md` step 8 names; copy each,
never retype it.

Surveyed across the 12 local repos on 2026-10-24: two kept a
`.pre-commit-config.yaml`, three a settings snapshot, six a handoff
queue, and three no `CLAUDE.md`.

## A releases repo

**A repo audited under `releases` is offered four pieces, and none of
the rest**: the guard (§ "Branch rulesets", item 1), a licence where it
is public, copied from the source repo, a README for downloaders,
below, and a security policy (§ "A security policy",
2026-11-13). The handoff queue, the inbox directory, `.worktreeinclude`, the
close-parent, pre-commit and Claude Code Action workflows, the
pre-commit baseline, an
instruction file, a pull request template, CONTRIBUTING and a code of
conduct each serve work that lands in the repo, and none does in one
holding only an app's installers and update feed (the user's call,
2026-11-10). The settings it needs, immutable releases, Actions
off, and issues, wiki and projects off, are `fix:` lines, run as
`SKILL.md` step 5 runs one. **A settings snapshot is not offered** (the
user's call, 2026-11-11): each rerun of the audit judges Actions, the
guard and the three features, `recreate-repo` exports its own before a
deliberate delete, and what is left to it, `has_discussions`, the
Actions token and merge settings that decide nothing here, would guard
only against losing the repo unawares. Export one on the user's ask; it does not record
immutable releases, which `repo-settings.ps1` does not read.

### A README for downloaders

**Missing when** step 4 prints `no README`, or the one there was written
for the source. No template: it is built from the app's own facts, read
from its source repo, so it promises nothing the releases do not hold.
What a releases repo was given (2026-11-10), and since (dated):

- what the app is, in a sentence, and which systems it installs on;
- the latest release's link, `https://github.com/<owner>/<repo>/releases/latest`,
  and which asset to download for each system;
- while the Windows installer is unsigned, the SmartScreen prompt:
  "Windows protected your PC", then **More info** and **Run anyway**,
  once the reader trusts where the download came from (Microsoft
  Learn, *Publish your first Windows app* § "Handle SmartScreen for new
  apps", read 2026-11-10);
- while immutable releases are on, how to check a download, the check
  an unsigned installer has: GitHub attests each release as it is
  published, so `gh release verify-asset <file> -R <owner>/<repo>`
  checks a file against the latest release, or a tag's given before the
  file, and `gh release verify` the release itself, listing each
  asset's SHA-256; neither covers the source zip or tarball. Without the
  CLI, the **Immutable** lock under the release's title. No checksum
  file is needed, since the attestation lists each digest (GitHub's "Immutable releases" and "Verifying the
  integrity of a release", read 2026-11-13; `gh release verify` passed
  on a releases repo's release, observed 2026-11-13, gh 2.103.3);
- how updates arrive, by the app's own updater or by a new download;
- what the app connects to, read from its source and never assumed:
  the updater's fetch of `latest.json` and then the installer from this
  repo's release assets, anything else that leaves the machine, or a
  line saying nothing else does (the user's call, 2026-11-13);
- how to uninstall, and what that leaves behind;
- where to report a problem: the source repo's issues, since this
  repo's are off, or where the source is private, this repo's
  Discussions Q&A category,
  `https://github.com/<owner>/<repo>/discussions/categories/q-a`
  (observed 2026-11-11, 2.1.321), once
  `gh repo edit <owner>/<repo> --enable-discussions` turns them on, a
  setting write that takes its own yes. Discussions are public and
  publish no email address, as an owner's contact would (the user's
  call, 2026-11-11). Where the repo keeps a `SECURITY.md`, the bullet
  sends a security hole there instead, as a releases repo's did
  (2026-11-13).

Propose it as a draft, then write `README.md` at the root. Step 6 ran
before it, with no README for downloaders to draft from, so **offer
step 6 again once it is written**, its opening paragraph the About
description's source.

### A security policy

**Missing when** step 4 prints `[INFO] no security policy`, under
`releases` alone; elsewhere it is part of one context line, offered
nothing (the user's calls, 2026-11-13). The template,
`SECURITY.md`, holds what a releases repo kept that day: report
privately by the **Security and quality** tab's **Report a
vulnerability** button (GitHub's "Privately reporting a security
vulnerability", read 2026-11-13), not
in Discussions or an issue; in scope the installer, the update feed and
the app; only the latest release gets fixes. **Fill its blanks from the
source repo**, as the README for downloaders is built: the systems the
installer ships for, each file the updater fetches, and how a fix
arrives. Write it at the root, then point the README's report bullet at
it.

**The button exists only while private vulnerability reporting is on**
(GitHub's "Configuring private vulnerability reporting for a
repository", read 2026-11-13), so where step 4 warned it off, offer
that `fix:` line first, on its own yes: a policy naming the button
before then sends a reporter nowhere.

## The handoff queue

**Missing when** the repo has no `docs/handoffs/`. Offer it where work
outlives a session: briefs for the next one, learnings from other repos
arriving through the inbox. A repo whose queue lives elsewhere, or in
its root `CLAUDE.md` as grep lines, gets a finding naming what it has
and the offer to move it over. A repo with the queue but with no landing
in its rule, no worktree base, or a gitignored file its scripts read
that no `.worktreeinclude` copies, gets a finding for each and the offer
of that step alone: steps 2, 6 and 7. **The script reports the first**,
under `Handoff landing`: a board or `docs/handoffs/` on the default
branch whose rule is missing or holds neither bullet's bold opening
(step 2) warns, its `fix:` naming the bullet for the route. A rule
written by hand never had the bullet, and an audit reading this
paragraph alone raised no finding for one (a client repo, 2026-11-03).
The base and the `.worktreeinclude` it does not read.

**Offer the board first, where the owner can hold a project**: the
`provision-board` skill, given `<owner> <owner>/<repo>`, which the user
types, since the skill is typed-only (it writes a project, labels and
issues). A personal account's repo can hold one (one did,
2026-10-27). An organization's owners can turn projects off, which no
read here shows (`provision-board`'s `references/board-contract.md`
§ "Who can write it"): ask where the owner is an organization, and take
a refusal from `provision-board` as the answer. **The file queue is the
fallback**, for an owner that cannot hold a project or a user who
declines the board, and the finding says which. A repo whose step 4
board line reads `[INFO]` for no board has this gap; one with a board
already has its queue, so `docs/handoffs/` is not missing there, and it
is offered steps 2, 3, 5, 6 and 7 alone. **A board's repo is offered
§ "A close-parent workflow" too**, once the board exists.

**The board's path skips steps 1 and 4**, the README and the check, which
read brief files, and `--check` never reads a board. Step 3's first line
then reads as below, the queue command left to the rule, which carries
it, and the second line, the grep over brief files, is left out:

```markdown
Handoff briefs are issues on the repo's board, filed by `file-issue`, and
`.claude/rules/handoff-briefs.md` has their keys, the landing and the command that prints the queue.
```

**On the board's path the rule loads at launch, with no `paths:`** (the
user, 2026-11-13, reversing for this path alone a decline of
2026-11-03). A glob there matches no brief: its briefs are issues, their
drafts sit in the scratchpad, and no `docs/handoffs/` exists at scaffold
time, so no Read, Write or Edit of a brief would load it. Of 19 sessions
in a board-only repo, none loaded the globbed rule (measured there,
2026-11-03, 2.1.317). Whether loading it every session costs more than
the skills' own Reads was not measured. The file queue's rule keeps its
glob, which its brief files match; the skills that need either still
reach it by path: `work-issue` and `lead-sessions` print its landing
bullet at their preflight, and `file-issue` and `triage-inbox`
Read it before drafting a brief.

On a yes, in this order:

1. `docs/handoffs/execute/README.md`, from `handoff-queue-README.md`.
   Where one exists, keep its own sections and replace only its keys
   with a pointer to the rule in step 2.
2. `.claude/rules/handoff-briefs.md`, from the template for the queue's
   route: `handoff-briefs.md` for files, the keys and the landing on
   `docs/handoffs/**`, a rule that loads on a file it matches and so
   cannot govern creating the first brief; `handoff-briefs-board.md` for
   a board, the same with each key mapped onto the card, and no `paths:`.
   **Its landing
   bullet is a default**, a fast-forward with no push: `lead-sessions`
   stops in a repo whose instructions name no landing, as it did in one
   this skill had scaffolded (2026-10-25). Keep the bullet where the
   audit's `Active rules on <branch>` section lists no `pull_request`
   among its `active:` types. Where it lists one, or reads classic
   protection on, which the script does not audit, `main` may take no
   fast-forward: ask how a brief lands there, offer a pull request, and
   write the answer in the bullet's place, this for a pull request, with
   the merge method the repo's settings allow:

   ```markdown
   - **A brief's worktree lands by pull request**: the session runs `pre-commit run --from-ref origin/main --to-ref HEAD`, pushes its branch and opens a pull request saying `Closes #<n>`, by `land-branch`'s account checks, and stops short of the merge, which a reviewer makes by <merge method>. The worktree stays until that merge. `work-issue` and `lead-sessions` land by this line, and `lead-sessions` parks what the branch blocks until then.
   ```

   Neither skill has run this route yet, so say that in the finding.
   **Either bullet keeps its bold opening as written**, `worktree lands
   from the main checkout` or `worktree lands by pull request`: it is
   what `file-issue`, `provision-board` and the script grep for,
   warning where a rule holds neither. **Either bullet's lint needs a
   `.pre-commit-config.yaml`**, without which `pre-commit run
   --from-ref` exits 1 and `work-issue` and `lead-sessions` stop at
   their preflight. Where the repo has none, say so in the finding and
   offer § "A pre-commit baseline" first, with `repo: local` hooks for
   the repo's own checks beside its two; under `core.hooksPath` a range
   run still takes it (2026-11-03).
3. So root `CLAUDE.md` gains two lines, which is what reaches a session
   before any brief exists. Where the root holds `AGENTS.md` and no
   `CLAUDE.md`, they go into `AGENTS.md`; don't create a `CLAUDE.md` for
   them. Where it holds neither, because the user went on without
   `/init`, ask before creating one for these lines alone:

   ```markdown
   Handoff briefs wait in `docs/handoffs/execute/`, and
   `.claude/rules/handoff-briefs.md` has their keys; print the queue with `uv run --no-project "${HANDOFF_STATUS_PY:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/triage-inbox/scripts/handoff-status.py}" . --no-inbox`.
   ```

   The script is the `triage-inbox` skill's, at a user-scope install's
   path unless `HANDOFF_STATUS_PY` names another copy, such as a
   plugin's. A repo others clone also gets a line that needs none, as
   the user chose for an organization's repo on 2026-10-25:

   ```markdown
   Without that script: `grep -H -E '^(status|priority|needs|blocked-by|reopen-when):' docs/handoffs/execute/*.md`
   ```

4. The check, `pre-commit-lint-briefs.yaml`, appended under `repos:` in
   the repo's `.pre-commit-config.yaml`; with no such file, offer the
   baseline below first. Run `git config core.hooksPath` before either:
   where it prints a directory, `pre-commit install` refuses, so neither
   would ever run at a git event. Say so in the finding, and offer
   `githooks-lint-briefs.sh` instead, copied to that directory as
   `pre-commit` or called from the one there, executable. Unsetting
   `core.hooksPath` is what the framework form needs, and is the repo's
   call.
5. The repo's folder in the user's handoff inbox, `<inbox>/<repo>/`, a
   directory only, `<repo>` being the main checkout's directory name,
   under the inbox README's contract: read that README first.
   `DECLINED.md` is `triage-inbox`'s to create, at its first decline.
   `<inbox>` is `handoff-inbox` in the user's home folder where one
   exists; with none, say so and skip this step.
6. **The worktree base, on its own yes**, since it changes how every
   worktree in the repo branches: `"worktree": {"baseRef": "head"}` in
   `.claude/settings.json`, merged into the keys already there, or a new
   file holding it alone. Missing when
   `jq -e '.worktree.baseRef == "head"' .claude/settings.json` exits
   other than 0, a missing file included. Under the default, `fresh`, a worktree branches
   from the remote's default branch and misses every commit on local
   `main` not yet pushed, a brief's own among them, so the preflight
   `lead-sessions` and `work-issue` share stops without it. The repo that
   stopped was eight commits ahead of `origin/main` (2026-10-25). **A
   landing that names a pull request is no gap**: there `fresh` is the
   base, since a server's merge leaves local `main` behind, so skip this
   step. Chosen from the worktrees page and not yet tested.
7. **A `.worktreeinclude`, on its own yes**, since a worktree is a fresh
   checkout: a gitignored file the repo's scripts read is absent from
   every one, so a brief's session fails at prep, after its claim, as a
   client repo's data scripts each failed `error: .env not found`
   (2026-11-03). Claude Code copies each gitignored file the root's
   `.worktreeinclude` matches, in `.gitignore` syntax, into every
   worktree it makes with git (worktrees page, read 2026-11-03), and
   `EnterWorktree`'s too, which the page does not name: in a scratch
   repo one received the `.env` and `config/secrets.json` the file
   named and no ignored file it left out (2.1.318, 2026-11-03).
   **Missing when** a tracked script reads a gitignored file that no
   `.worktreeinclude` copies, read in the main checkout, where those
   files are:

   ```bash
   git status --ignored --porcelain | grep '^!! ' | cut -c 4-             # the gitignored entries; a trailing / is a directory
   git grep -n -w -F -e '<name>' -- ':!.gitignore' ':!.worktreeinclude'   # per file entry: a hit in a script or a tool's config reads it, prose does not
   git ls-files -o -i --exclude-from=.worktreeinclude | git check-ignore --stdin   # what it copies now, bar a **/ pattern into an ignored directory; no file: "fatal: cannot use .worktreeinclude"
   ```

   `ls-files` alone lists every untracked file the patterns name, and
   `check-ignore` keeps the gitignored ones (git 2.56.0, 2026-11-03),
   which alone are copied (worktrees page). **A file no script names
   can still be read**: a root `.env` with no `git grep` hit, where a
   script calls a dotenv loader or Compose reads it by default, is
   offered all the same.

   Offer the file at the root, or the lines it lacks, one path a line
   as the first command printed it. **Small files only**, never a
   directory such as `node_modules/`: it copies rather than links, so a
   full copy per worktree, and `worktree.symlinkDirectories` serves a
   large one (best practices page, read 2026-11-03). A file inside a
   wholly ignored directory prints as the directory alone, so name it
   by its own path: the scratch repo ignored `config/` whole, and its
   `config/secrets.json` line was copied.
   **A landing by pull request takes this step too**, unlike step 6,
   and a repo whose `WorktreeCreate` hook makes its worktrees skips it:
   no `.worktreeinclude` is read there, so the hook's script copies the
   files (worktrees page, read 2026-11-03). The
   audit script reads only GitHub, where no gitignored file is, so it
   has no line for this.

Then run the view and the check once:

```bash
uv run --no-project "${HANDOFF_STATUS_PY:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/triage-inbox/scripts/handoff-status.py}" . --check --no-inbox
```

With no such file, say the `triage-inbox` skill is not installed and
skip the run.

The view reads frontmatter and index rows both, so an existing queue
kept as a table still prints; its `--check` names each brief the table
does not reach.

## A pre-commit baseline

**Missing when** the repo has no `.pre-commit-config.yaml`, or one
without `gitleaks` and `identity-guard`. The strongest of these offers:
both hooks stop what `recreate-repo` cleans up after, a secret or a
denylisted name pushed, which happened twice.

First run `git config core.hooksPath`. Where it prints a directory,
`pre-commit install` exits 1 (`Cowardly refusing to install hooks with
core.hooksPath set`), so no git event would run the baseline, though a
landing's `pre-commit run --from-ref` still does (2026-11-03): say so in
the finding, and leave the choice of unsetting it to the repo
(2026-10-27).

On a yes, copy `pre-commit-baseline.yaml` to `.pre-commit-config.yaml`,
or merge it into an existing one, its two top-level keys as well as its
`repos:`: `default_install_hook_types` is what makes the bootstrap wire
the commit-msg and pre-push hooks, without which identity-guard's
message and push scans never run, and under `default_stages` an existing
hook with no `stages:` stays on pre-commit alone (2026-10-25). Then:

```bash
pre-commit install --install-hooks   # each type default_install_hook_types names, wired and primed
```

Where the user keeps a bootstrap script of their own for this, such as
`~/scripts/pre-commit-bootstrap.ps1 -RunAll`, run that instead.

The template's gitleaks `rev:` is already a full commit SHA. Do not run
`pre-commit autoupdate --freeze` on it: gitleaks' v8.30.1 sits off its
default branch, so autoupdate moved the pin back to v8.30.0 and stored the
tag object's SHA, not a commit (2026-10-27). To re-pin, take the `^{}` line
of `git ls-remote --tags <repo> '<tag>' '<tag>^{}'` when there is one, else
the plain line, as `# frozen: <tag>`.

The hooks see only new commits, so then scan the history once, and read
the count:

```bash
gitleaks git . --redact                     # "N commits scanned" against: git rev-list --all --count
git show --remerge-diff --format= <merge> | wc -l   # per merge the scan skipped: 0 means it adds nothing
```

A short count is the merge commits, which `gitleaks git` skipped in the
one repo measured (8 of 12 scanned, gitleaks 8.30.1, 2026-10-26): a merge
that adds content of its own, a conflict resolution, would go unscanned.
Also check that every ref `git ls-remote origin` lists, `refs/pull/*/head`
included, is an ancestor of the default branch.

Each `identity-guard` entry runs the user's `identity-guard.sh` hook,
`$IDENTITY_GUARD` or else `hooks/identity-guard.sh` in the Claude Code
config folder, against the user's identity denylist, and skips with
exit 0 where the script is absent, so a co-developer's commit is not
blocked; `lint-briefs` does the same without `triage-inbox` or `uv`.
The repo this skill is authored in tests each entry both ways.

## A pre-commit workflow

**Missing when** step 4's `Pre-commit in CI` section reads
`.pre-commit-config.yaml on <branch>, and no workflow runs pre-commit`,
or `Actions is disabled` in its place: a `[WARN]` on a public repo, and
`[INFO]` on any other. The hooks gate only a clone where
`pre-commit install` ran, so a co-developer's clone without them, an
outside pull request and a commit made in GitHub's web editor skip every
one. Offer it after the baseline above, which it runs. On a private
repo, say first that its runs draw on the account's included compute
usage, a dollar amount and not minutes, where a public repo's standard
runners are free (GitHub's Actions billing page, read 2026-11-03).

On a yes:

1. Copy `pre-commit-ci.yml` to `.github/workflows/pre-commit.yml`, with
   the default branch in `branches:` where it is not `main`. Its header
   says why gitleaks runs as its own step over the whole history and
   the hook is skipped, and that identity-guard and lint-briefs pass on
   the runner having run nothing. Read the copy, which loads
   `coding-ci-workflows.md`.
2. Read the repo's `.pre-commit-config.yaml` for each `language: system`
   hook beyond those two: each runs a tool the runner must have, so add
   its install step before the last, or the hook fails there.
3. Where the config pins a gitleaks other than v8.30.1, raise
   `GITLEAKS_VERSION` and `GITLEAKS_SHA256` together, the hash from that
   release's `gitleaks_<version>_checksums.txt`; where it has no gitleaks
   hook, drop the step and the `SKIP`.
4. Where step 4 printed an active Actions policy, read whether it
   requires the lockfile: under **Require lockfile** a workflow not
   onboarded is blocked even with every `uses:` a full SHA, so onboard
   it with `gh actions-lock`, a `gh` extension
   (`gh extension install github/gh-actions-lock`), and commit the
   lockfile beside it.

It runs on the pull request that adds it, but the audit reads the
default branch: rerun it once the workflow lands there, and its line
becomes `[ok] pre-commit runs on the server`.

**Leave the job out of the required checks.** Whether a ruleset's
required check blocks `land-branch`'s direct fast-forward push of a
commit whose checks passed on its pull request's branch is not stated on
the page read for it (2026-11-02), and is unmeasured: measure it before
anyone requires the job.

## A close-parent workflow

**Missing when** step 4's `Handoff board` section warns
`board: no .github/workflows/close-parent.yml on <branch>`, or that
Actions is disabled, so no workflow closes a parent: a repo with a
board, whose parents wait for the user. GitHub closes no parent with its
last sub-issue, and no commit can say it is the last while a sibling
lands beside it, so the queue view reads `all <total> sub-issues closed:
close it` and the parent stays open until the user closes it
(`provision-board`'s `references/board-contract.md` § "Parents and
sub-issues"). The script finds the file by its name alone. Offer it
after the board, and on a private repo say first that each issue's
close starts a run that draws on the account's included compute usage,
as § "A pre-commit workflow" says; 114 runs in a personal repo took 6
to 28 seconds each, 102 of them 10 or under (`gh run list`, start to
last update, 2026-11-04).

On a yes:

1. Where the WARN said Actions is disabled, the user allows it first,
   at the settings page its `fix:` line names: a copy made before that
   runs nothing.
2. Copy `close-parent.yml` to `.github/workflows/close-parent.yml`,
   unchanged. Its header says what it closes and what it leaves open.
   It takes no `uses:`, so it has nothing to pin; it grants
   `issues: write` alone and passes the issue's number through `env:`.
   Read the copy, which loads `coding-ci-workflows.md`.
3. Where the audit's step 4 printed an active Actions policy that
   requires the lockfile, onboard the workflow with `gh actions-lock`,
   as § "A pre-commit workflow" step 4 does. The lockfile then lists it
   with an empty list, since it uses no action.
4. **The `standing` label, on its own yes.** The workflow leaves open a
   parent labelled `standing`, one that takes more sub-issues later, and
   walks no higher. With no such label every parent closes with its last
   sub-issue, so offer it only where the repo keeps a tracking issue
   open on purpose:

   ```bash
   gh label create standing --description 'Takes more sub-issues later: close-parent leaves it open'
   ```

It runs from the default branch alone, on each issue's close, so it
proves itself at the first close after it lands there. Rerun the audit
then, and its line becomes:

```text
[ok]    board: .github/workflows/close-parent.yml on <branch> closes a parent with its last sub-issue
```

## A Claude Code Action workflow

**Missing when** step 4's `Claude Code Action` section reads
`no workflow on <branch> runs anthropics/claude-code-action`, or that
none runs it as Actions is disabled, which it prints under
`org-internal` and `org-published` alone. A line naming a workflow that
a comment starts and that calls another repo's reusable workflow may be
the docs' organization setup, which can define the job once that way,
or something else the script did not read: ask which, and offer only on
the second, since a second workflow would answer each mention twice.
Shared CI on push or pull request prints no such line. The user adopted
the Action for an organization's repo and kept it out of a personal one
(2026-11-16), and no work lands in a releases repo. **It is offered
whatever the collaborator count**: no read tells whether a co-developer
would mention `@claude`, and the offer waits for its own yes. The
workflow, `claude-code-action.yml`, answers an `@claude` mention in an
issue or pull request comment or review, or in a new issue's title or
body, and Claude replies in a comment and can push commits and open pull
requests (code.claude.com `github-actions`, read 2026-11-16).

**Read what Claude already runs before the offer.** The Action, Code
Review and auto-fix share one Claude GitHub App (`github-actions` §
"GitHub App permissions", read 2026-11-17), so an owner who installed
it for Code Review can take the offer as done: one dropped the copied
workflow so, in a repo whose credential lists were all empty (observed
2026-11-17, 2.1.325). Read the install, with an organization owner's
token, whose 403 is no answer, the credential names the repo sees,
never a value, and a recent pull request's head for a review (GitHub's
REST reference, read 2026-11-17):

```bash
gh api --paginate orgs/<org>/installations -q '.installations[] | .app_slug + " " + .repository_selection'
for k in secrets organization-secrets variables organization-variables; do gh api --paginate "repos/<owner>/<repo>/actions/$k" -q '(.secrets // .variables)[].name'; done
gh api "repos/<owner>/<repo>/commits/<sha>/check-runs?check_name=Claude%20Code%20Review" -q '.check_runs[] | .app.slug + " " + .conclusion'
```

`claude all` is the app on every repo; `claude selected` on those the
owner picked, which may not include this one, so it counts here only
where the last read prints a `claude` line or the owner confirms this
repo. A `claude` line from the last read is Code Review. **The app
alone answers no `@claude`**: Code Review answers `@claude review` on a
pull request, from someone with write access, and pushes no commits
(`code-review`, read 2026-11-17), while any other mention takes this
workflow and a credential. Where Code Review runs, an `@claude review`
starts this workflow as well, its `if:` matching any `@claude`
(`code-review-pull-requests`, read 2026-11-17): offer a
`trigger_phrase` other than `@claude`, with the `if:` matches changed
to it. Say what the reads found before
the yes: an install drops the first caveat below, never the credential
question, and where Code Review runs and reviews are all the user
wants, the Action adds nothing.

**Say four things before the yes**:

- where the read found no install, installing the Claude GitHub App on
  an organization's repository takes an organization owner, who
  approves each permission the app adds later;
- the official app's permission set is accepted whole, GitHub taking no
  subset, and is broad: Administration read, and Actions, Repository
  creation, Repository hooks and Workflows write, among others. A custom
  app needs only Contents, Issues and Pull requests write, but covers
  the Action alone: Code Review and auto-fix still need the official one
  (`github-actions` § "GitHub App permissions", read 2026-11-16);
- each run costs runner time, which on a private repo draws on the
  account's included compute usage, as § "A pre-commit workflow" says,
  and Claude usage on the credential chosen below (§ "Manage costs");
- on a public repo a mention from any account starts a run, and every
  step before the action's own write-access check runs for it, the
  Azure sign-in included, leaving audit-log entries and spending
  minutes (`github-actions-cloud-providers`, read 2026-11-16).

**Ask which credential at the offer**, by `AskUserQuestion`: the template
holds a block for each, and the copy keeps one.

| Choice | Stores | Fits |
| --- | --- | --- |
| Console API key | `ANTHROPIC_API_KEY` secret | an organization secret serving every repo |
| Subscription token, `claude setup-token` | `CLAUDE_CODE_OAUTH_TOKEN` secret | one person's repo: it is tied to that person's subscription |
| Console workload identity federation | no secret: `ANTHROPIC_FEDERATION_RULE_ID` and `ANTHROPIC_ORGANIZATION_ID` Actions variables | an organization on the Claude API storing no key |
| Microsoft Foundry by OIDC | `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` secrets, IDs and not keys | an organization with a Claude deployment in Foundry |

Federation takes a Console issuer for
`https://token.actions.githubusercontent.com`, a service account and a
federation rule matched to the repo's OIDC subject, its `fdrl_...` ID
the rule variable (the action's `docs/setup.md`, read 2026-11-16).
Foundry takes an Entra application, or a user-assigned managed identity,
with a federated credential for the repo and the `Foundry User` role on
the resource (`github-actions-cloud-providers`, read 2026-11-16). A
static credential set beside the federation inputs wins over them, so
the copy keeps exactly one block.

**`/install-github-app` is the other route**, where the user prefers it:
it installs the app, sets an API key or subscription token as the
secret, and pushes a branch for a pull request adding the docs'
workflow, which names the action `@v1` (`github-actions` § "Quick
setup", read 2026-11-16). Step 4's pin check then warns of the tag, so
re-pin it as that step says. It offers neither federation nor Foundry,
which this copy does.

On a yes:

1. Where the line said Actions is disabled, the user allows it first,
   at the settings page that line names.
2. Copy `claude-code-action.yml` to `.github/workflows/claude.yml`.
   Keep the chosen block under `with:` and delete the other three; for
   Foundry, uncomment the `azure/login` step and the `env:` block and
   fill the resource name and the deployment's model ID. Read the copy,
   which loads `coding-ci-workflows.md`.
3. Where step 4 printed `allowed_actions is selected`, the allowlist
   must name `anthropics/claude-code-action@*`, and for Foundry
   `azure/login@*`, unless the verified-creators option covers them, and
   `actions/checkout@*` unless "Allow actions created by GitHub" is
   ticked; the script reads neither box. Under that setting only the
   owner's own actions pass unlisted, and a tag-pinned entry matches no
   SHA-pinned use (GitHub's "Managing GitHub Actions settings for a
   repository", read 2026-11-16). That is an
   organization owner's change: list it in `SKILL.md` step 9's Next
   steps.
4. Where step 4 printed an active Actions policy that requires the
   lockfile, onboard the workflow with `gh actions-lock`, as § "A
   pre-commit workflow" step 4 does.

**The copy installs nothing and sets no secret.** Step 9's Next steps
lists what it cannot do: the app's install, by an organization owner,
where the read found none; each secret or variable the chosen block
names, at the repo or the organization; for federation or Foundry, the
Console or Entra side above; and a rerun of the audit once the workflow
is on the default branch, whose line becomes:

```text
[INFO]  anthropics/claude-code-action runs in .github/workflows/claude.yml
```

Then a first `@claude` comment on an issue shows it answering.

## Branch rulesets

**Missing when** step 4 names a ruleset scaffold: a `[FAIL]`, `[WARN]`
or `[INFO]` line `no active deletion rule` or `no active
non_fast_forward rule`, whose text names `ruleset-guard.json`; a
`[FAIL]` `no active pull_request rule` or `no active
required_status_checks rule`, under `org-published`, naming
`ruleset-pull-request.json`; or, on an organization's repo, `[INFO]
branch names: no branch_name_pattern rule is active`. The three come from
an organization's repo's two rulesets (2026-11-04), split so that no
bypass reaches the guard: a bypass covers its whole ruleset, so an
admin who bypasses `always` on one holding the pull request rule beside
`deletion` and `non_fast_forward` can force-push and delete the branch
as well, and the audit's bypass `[WARN]` says so where it sees it.

Offer them in this order, each on its own yes:

1. **The guard**, `ruleset-guard.json`, on any repo: Restrict deletions
   and Block force pushes on `~DEFAULT_BRANCH`, with no bypass. It
   changes no landing, since a fast-forward is no force push
   ([profiles.md](profiles.md) § "The strategy the policies encode").
2. **The pull-request tier**, `ruleset-pull-request.json`: required
   under `org-published`, and elsewhere only where the user wants every
   change through a pull request. A pull request with no approval
   required, review threads resolved, merge commits only, one required
   check, and the admin role bypassing on pull requests alone, the solo
   stage. Before the copy is sent, replace
   `REPLACE-WITH-A-RECORDED-CHECK-NAME` with a name step 4's
   `Required status checks` section shows GitHub recorded, or drop the
   `required_status_checks` rule where none is recorded: a check nothing
   reports holds every pull request on "Waiting for status to be
   reported". Its `integration_id`, 15368, is GitHub Actions' app, as
   the organization's repo reads it; drop the key for a check another
   app reports. Turn on `require_code_owner_review` only once a
   CODEOWNERS file on the default branch names an owner. Say first what
   it changes: `land-branch` then lands by its server-side merge, the
   handoff rule's landing bullet becomes the pull-request one
   (§ "The handoff queue" step 2), and whether a required check stops
   a direct push is unmeasured (§ "A pre-commit workflow").
3. **Branch names**, `ruleset-branch-names.json`, on an organization's
   repo alone: every branch but the default must read
   `<type>/<kebab-slug>`, `<type>` a conventional-commit type, as the
   user's own instructions may list them. A worktree branch such as
   `worktree-<name>`, a `dependabot/` branch or `gh-pages` is refused a
   push, so add each one the repo pushes to `exclude` first. GitHub's
   docs place metadata rules under Enterprise Cloud (About rulesets,
   read 2026-11-04), so a refused create means the plan lacks them:
   report it and offer nothing in its place.

On a yes, copy the template to the scratchpad, edit the copy where step
2 says, and create it as the acting account step 1 checked, in one call
with step 1's pin:

```bash
gh api -X POST repos/<owner>/<repo>/rulesets --input <scratchpad>/ruleset-guard.json
```

Rulesets on a private repo need a paid plan: GitHub's plans page lists
protected branches in private repos under Pro and Team, not Free (read
2026-11-04), and what the create answers on a Free one is unread. Then
rerun the audit, and `-Export` where the clone keeps
`.github/repo-settings.json`, as step 5 says. An existing ruleset
holding these rules is changed in the rules settings page, never
created twice: GitHub enforces every ruleset at once, the strictest
winning.

## A settings snapshot

**Missing when** a repo the acting account owns or administers has no
`.github/repo-settings.json`. Offer `-Export` as step 5 runs it. On an
organization's repo it reads only and lands in that repo's own clone, where
its name is at home; `-Apply` still refuses that repo.

## The inbox directory

**Missing when** the user keeps a handoff inbox, `handoff-inbox` in
their home folder, and its `<repo>/` does not exist, whatever the
queue: a session elsewhere has nowhere to leave a learning for this
repo. Create the directory only. With no inbox, report nothing here.

## An instruction file

**Missing when** the repo has neither `CLAUDE.md` nor `AGENTS.md`, and is
not one the user keeps for reference only or one holding only an app's
installers (§ "A releases repo"). The check is in `SKILL.md`
§ "Before step 1: an instruction file", which offers `/init` before the
run starts. It shows up here only when the user chose to go on without
one: report it again, and never write one unasked.

## A licence

**Missing when** the community profile reports none, which step 4's
`[WARN] no licence` already says on a public repo. Which licence is the
owner's call: ask, then add `LICENSE` with GitHub's text for it.

**Under `releases` the licence is the source repo's**, whose build the
installers are: read it before asking, pinned as `SKILL.md` step 1
shows, with the source named by the user, the README or the update feed:

```bash
gh api repos/<owner>/<source>/license -q '.license.spdx_id + " " + .path'
gh api repos/<owner>/<source>/license -H 'Accept: application/vnd.github.raw+json' > <its path>
```

The second writes the source's file byte for byte, its copyright line
included (REST "Get the license for a repository", read 2026-11-11;
matched with `cmp` on a public repo, observed 2026-11-11, gh 2.103.3),
so offer that copy on a yes. Ask open-ended only where the source has
none or cannot be read.

## A code of conduct

**Missing when** step 4 prints `no code of conduct`, a WARN under
`org-published`. GitHub's API serves the text, so it is fetched, never
retyped: `gh api codes_of_conduct` lists the codes it holds, and

```bash
gh api codes_of_conduct/contributor_covenant -q .body > CODE_OF_CONDUCT.md
```

writes Contributor Covenant 2.0, whose one placeholder,
`[INSERT CONTACT METHOD]`, takes how people report a breach
(`references/profiles.md` § "Measured while adding the hardening
checks"). Which code and that contact are the owner's: ask both before
writing. The text is vendored, so it keeps GitHub's wrap.

## A CONTRIBUTING file

**Missing when** step 4 prints `no CONTRIBUTING`, a WARN under
`org-published`. No template: it is built from what the repo enforces,
read live, so it names no rule the repo lacks, as an organization's
repo's was (2026-10-26):

- how a change lands: the ruleset's pull request, its approvals and
  code-owner review, the required checks by the names step 4 printed,
  and the merge method;
- the CI job's commands, from its workflow file, to run before a push;
- `pre-commit install`, or the repo's own bootstrap, where it keeps a
  `.pre-commit-config.yaml`;
- the traps in the repo's `CLAUDE.md` or `AGENTS.md` that a person hits
  as well as an agent;
- a link to the code of conduct, where there is one.

Propose it as a draft, then write `CONTRIBUTING.md` at the root. Rerun
the audit once both files reach the default branch; whether the WARNs
then clear on a private repo was not checked.

## A pull request template

**Missing when** step 4 prints `no pull request template`, a WARN under
`org-published` and context otherwise. Offer it on any repo: it is a
starting point the repo then adapts. The script looks behind the
community profile, which reports a single file alone, in the repo and
then the owner's public `.github` repo. A repo reading `in a folder only`
has templates its authors must choose with `?template=`: say so, and
adding a single file beside them is the owner's call.

GitHub sets where the file goes, not what it says, and has no API serving
one (2026-11-01), so `pull_request_template.md` here is this skill's own,
not a standard. On a yes, copy it to `.github/pull_request_template.md`,
then offer to adapt it to what the repo enforces, such as its required
checks under `Verified`. It takes effect once it reaches the default
branch. A pull request opened with a body of its own does not start from
it (`gh pr create --help`, 2026-11-02), so `land-branch` step 5 reads the
file and fills its headings.
