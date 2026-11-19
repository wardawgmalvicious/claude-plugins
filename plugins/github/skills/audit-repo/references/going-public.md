# Going public

A private repo made public shows everyone every commit and thread it
has ever held, not only what its default branch holds now. Before that
switch, `going-public.ps1`, by the path `SKILL.md` names, reads
each part the switch exposes and counts what it finds in each:
identity-denylist terms, gitleaks' findings, mailbox addresses. It
prints no term. The settings the switch leaves alone are
`audit-repo.ps1`'s, run with `-AsPublic` after the scan. The script's
own help has its exit codes and what it reads.

## What GitHub says the switch does

GitHub's "Setting repository visibility" (docs.github.com, read
2026-11-04), under "Changing from private to public":

> - The code will be visible to everyone who can visit GitHub.com.
> - Anyone can fork your repository.
> - All push rulesets will be disabled.
> - Your changes will be published as activity.
> - Actions history and logs will be visible to everyone.
> - Stars and watchers for this repository will be erased.

The same page, under "Making a repository public", says GitHub "will
detach private forks and turn them into a standalone private
repository". It also says a reusable or required workflow shared from
another repository in the organization shows "the workflow file path
including the repository name" in the logs. So a fork's owner keeps
the whole history, cut off from the repo, and an organization's
Actions logs name its other repositories.

## What is exposed, and how the scan reads it

| Exposed | How the scan reads it | Reading the result |
| --- | --- | --- |
| Every commit a ref the remote lists reaches | `git ls-remote origin` for the tips, then `git rev-list --stdin` and `git log -p -U0 --no-renames` over the clone, matched by one regex | `[HIT]` names the commits by short SHA: a changed line or path, a message, an author or committer |
| Pull request refs, `refs/pull/N/head` | listed by `ls-remote`, which a plain clone never fetches | a tip the clone lacks is a `[WARN]` printing the fetch; run it, then scan again |
| Ref names and annotated tags | the `ls-remote` names; each tag object's message and tagger | a `[HIT]` counts them, and a name holding a term prints as a placeholder |
| Addresses on commits | each author, committer and tagger address | a `[WARN]` lists each that is no noreply one, as `<id>+<login>@users.noreply.github.com` and `noreply@...` are |
| Secrets | `gitleaks git --redact` over the clone, with none of the repo's own suppressions | `[HIT]` for a commit the remote serves; `[INFO]` for one only the clone holds |
| The About panel | the repo's description, homepage and topics | a `[HIT]`, with the `gh repo edit` that changes it |
| Issues and pull requests, closed ones too | REST `issues?state=all`, `pulls?state=all`, `issues/comments`, `pulls/comments` with each diff hunk | `[HIT]` lists the threads by `#` number |
| Earlier titles, a body's edit history, reviews | GraphQL `timelineItems` of `RENAMED_TITLE_EVENT`, `userContentEdits`, `reviews` | a `[WARN]` counts the thread parts past 50, unread |
| Discussions | GraphQL, where `has_discussions` is on, with comments and replies | as the threads above |
| The wiki | `<repo>.wiki.git` cloned `--mirror` into a temp folder, then the history and gitleaks reads | as the history above, labelled `wiki` |
| Releases | REST `releases`: each published name, note and asset name | `[HIT]` by tag; drafts and assets are `[INFO]` |
| Actions runs and artifacts | REST `actions/runs`' `total_count`, `actions/artifacts` | a `[WARN]` each, with the delete; no log is read |
| Push rulesets | REST `rulesets?targets=push&includes_parents=true` | a `[WARN]`: move what each blocks into the hooks first |
| Projects | GraphQL `projectsV2` | `[INFO]`: each keeps its own visibility |
| Stars, watchers and forks | the repo's own counts | `[INFO]`: the switch erases the first two and detaches the forks |

**A pull request ref pins every commit its pull request touched**, so
the history the switch exposes can be far larger than the default
branch. On this repo, 2026-11-04: 1 branch and 5 pull request refs
reached 5,638 commits, 3,257 of them on `main`, so 2,381 only through
the pull request refs.

**A history `[HIT]` is no force push.** The pull request refs and
GitHub's serving of a commit by its SHA keep the old commits readable
after a rewrite, as `recreate-repo`'s `references/pushed-leaks.md`
quotes GitHub saying. So the fix is the rewrite published as a new
repo, by `recreate-repo`'s route, or the repo kept private. A pull
request ref is GitHub's, and goes only with the repo.

**A thread `[HIT]` is an edit, then a delete of each revision.**
GitHub's "Tracking changes in a comment" (docs.github.com, read
2026-11-04): "Anyone with read access to a repository can view a
comment's edit history". Its author or anyone with write access can
open **edited**, then **Options**, then **Delete revision from
history**, after which "the person who made the edit and when they
made the edit is still visible". GitHub keeps "the original content
and the most recent 99 edits" of each issue, comment and pull request.
A renamed title stays in the timeline. An issue can be deleted by the
owning account in a personal repo, and by an admin in an
organization's once an owner has enabled it (GitHub's "Deleting an
issue", read 2026-11-04), and GitHub's
docs, searched that day, name no delete for a pull request, so its old
title goes only with the repo.

## Measured

- **`totalCount` is no page count.** On a filtered `timelineItems`
  connection it counts the items the `itemTypes` filter leaves out: 10
  against a `filteredCount` of 0, so a scan reading it warned of 5
  partial pull requests that were whole (2026-11-04). The scan reads
  `pageInfo.hasNextPage` instead.
- **A co-author trailer's tool commits as `noreply@`.** The scan first
  warned of `noreply@anthropic.com` as a mailbox, so any `noreply@` or
  `no-reply@` address now passes with GitHub's own (2026-11-04).
- **390 workflow runs** were this repo's on 2026-11-04, each log
  readable after a switch and none read by the scan.
- **gitleaks honours a repo's own suppressions by default.** A token
  marked `gitleaks:allow` gave 0 findings under `gitleaks git` with
  the clone as its ignore path, and 2 with `--ignore-gitleaks-allow`, a
  config of the default rules alone and an empty ignore folder, the
  flags the scan passes (8.30.1, 2026-11-04). gitleaks still reads a
  `.gitleaksignore` at the root of its source, whatever the ignore path
  says: a token fingerprinted in a committed one gave 0 findings with
  the work tree as the source, and 2 with the git directory, which the
  scan passes instead (8.30.1, 2026-11-04). On this repo the flags
  above surfaced 4 findings in served commits, each in a `tests/`
  fixture its `.gitleaks.toml` allowlists as a fake credential: a
  `[HIT]` the user reads and may accept, never one the scan drops.
- **A failed `gh` call can print the body it read before its error**:
  a paginated GraphQL answer came ahead of the `gh:` line (gh 2.103.3,
  2026-11-04), and gh's source writes each REST page as it arrives, so
  a later page's failure follows the earlier ones. So the scan names a
  failure by gh's own line, and withholds any printed line holding a
  term.

## What the scan cannot see

- **An edited comment's earlier versions**, which any reader can open:
  the scan reads the edit history of an issue's and a pull request's
  body only, and says so in an `[INFO]` line.
- **Labels, milestones and commit comments**, each public once the
  repo is, named in the same line.
- **A binary file's content**, though its name is read; **Actions logs
  and artifacts**, and **release assets**, which it counts.
- **GitHub Pages and packages.**
- **A commit no ref lists that GitHub still serves by its SHA**, such
  as the head a force push replaced, which a pull request's timeline
  links.
- **`exempt:` lines.** They name no exception here, so a client's own
  repo hits on its own name: point `IDENTITY_DENYLIST` at a copy
  without that term.

## `claude-plugins`, read before its flip

**`wardawgmalvicious/claude-plugins` is the public marketplace's repo,
made public on 2026-11-17 once its first export was validated and
scanned**. Read
2026-11-17 at `8907587`, after the first release's export merged, as
`wardawgmalvicious`; the same day at `5f22d00`, an empty marketplace,
both gave the same counts.

- **`going-public.ps1`: 0 `[HIT]`, 1 `[WARN]`**, 6 workflow runs whose
  logs the switch makes readable, each CI's validate and pre-commit
  output over the history the scan read.
- **`audit-repo.ps1 -Policy org-published -AsPublic`: 1 `[FAIL]`, 3
  `[WARN]`**, before `sha_pinning_required` went on below.
  - `[FAIL]` no pull request rule requires a code owner review. The
    owner is its only code owner, and an author cannot approve their
    own pull request, so the rule would leave every merge to the admin
    bypass; turn it on only once a second maintainer is named in
    `CODEOWNERS`.
  - `[WARN]` `sha_pinning_required` was off. The workflow pins by tag
    through `.github/workflows/actions.lock`, as this repo's does, and
    with it turned on, by `PUT actions/permissions`, a rerun of CI
    passed both jobs (2026-11-17): it blocks only a workflow the
    lockfile does not onboard.
  - `[WARN]` the repository admin role bypasses the pull request
    ruleset, fine while one person maintains it.
  - `[WARN]` no social preview uploaded: GitHub takes an upload from a
    public repo, or from a private one that has held one before, which
    this has not, so upload `docs/social/social-preview.png` there right
    after the switch.
- **Secret scanning and push protection, which the `-AsPublic` run
  above never named**: right after the switch the same audit without
  `-AsPublic` warned `secret_scanning is disabled` and
  `secret_scanning_push_protection is disabled`, since GitHub turns
  neither on at the switch, and both were turned on then, by
  `PATCH repos/<repo>` with `security_and_analysis` (2026-11-17). An
  `-AsPublic` run now warns of each on a private repo.
