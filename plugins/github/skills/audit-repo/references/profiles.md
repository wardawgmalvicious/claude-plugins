# Choosing a policy, and the strategy behind it

The script holds each policy's rules and prints the reason for each
finding, so this file does not list them again. It says which policy
fits a repo, what branch and repo strategy the policies encode, and
what was measured to build the script. The script's own help,
`audit-repo.ps1` by the path `SKILL.md` names, lists what it does not
audit.

## Which policy

- **`personal`**: a repo a user account owns, landed by its owner. No
  pull request rule is required: `land-branch` fast-forwards `main`
  itself, and such a rule would only route it through a server-side
  merge. A public one is warned of where no active rule on its default
  branch blocks force pushes and deletion, which a fast-forward never
  trips (below); a private one is offered the same rules as context.
  What the policy still wants: merge commits as the only
  merge method, merged branches deleted, and a read-only Actions token.
- **`org-published`**: a repo whose default branch publishes to other
  people as soon as a change lands. Examples: a plugin marketplace that
  claude.ai organization sync reads from the default branch; a service
  deployed from `main`; a package released from tags. Everything in
  `personal`, plus a branch ruleset that only a pull request with a
  code owner's review and passing checks can get past, and a
  CODEOWNERS file that parses.
- **`org-internal`**: an organization's repo whose default branch
  publishes to no one outside its team (the user, 2026-11-01). It asks what
  `personal` asks, without the warning about whose repo it is, and
  adds no required ruleset; a rule the repo does have is still judged.
  A public one takes the branch guard too, warned of the same way (the
  user's call, 2026-11-03, extended from `personal` that day).
- **`releases`**: a repo that holds only an app's installers and update
  feed, its source in another repo, as a private app's public downloads
  do, whoever owns it. Its own checks replace what a source repo is
  asked (§ "A releases repo", below), so the merge settings and the
  Actions token print as context and its scaffolds are those
  [scaffolds.md](scaffolds.md) § "A releases repo" lists. A fourth value,
  not a flag beside the other three, is the user's call
  (2026-11-10): beside it, the other policies would decide almost
  nothing, and `org-published`'s required checks could never report
  with Actions off.
- **Unsure whether a change on the default branch publishes**: the policy
  is the user's call, so ask. Don't pick one quietly and report its
  findings as defects.

## The strategy the policies encode

These are the user's decisions of 2026-10-22, made while planning an
organization's skills catalog and MCP server repos:

- **Trunk-based.** The default branch is what publishes. Work happens
  on short-lived `<type>/<kebab-slug>` branches, `<type>` a
  conventional-commit type. There's no long-lived
  branch per platform and no release branch.
- **Merge commits only.** `land-branch` refuses a squash, which
  collapses the commits a branch was split into, and a rebase merge,
  which rewrites their SHAs. Its `references/integration-routes.md`
  gives both reasons. So both are turned off in the repo's settings, and
  a pull-request rule allows only `merge`.
- **One repo, split only when someone needs to own part of it.** Hand
  one area to a co-maintainer through CODEOWNERS on its folders first.
  Split the repo only once they need their own admin rights or their
  own release cadence.
- **A bypass on pull requests is the solo stage.** An admin who can
  bypass on pull requests can merge their own pull request without the
  review or the checks. The script warns about it rather than failing,
  because one maintainer has no one else to review. Drop the bypass
  once a second code owner can. **Keep the bypass off the guard**: it
  covers its whole ruleset, so an `always` bypass on one that also holds
  `deletion` and `non_fast_forward` lets the admin force-push and delete
  the branch, as an organization's repo's single ruleset did
  (2026-11-04). The guard goes in a ruleset of its own with no bypass,
  and the script's bypass `[WARN]` names the split where it sees one.
- **CODEOWNERS lands before the code-owner rule.** With the rule on,
  GitHub asks a code owner's approval only of content an owner covers
  ("Available rules for rulesets", read 2026-10-27), so until a
  CODEOWNERS file on the default branch names one, the rule asks no one.
  Land `* @<owner>` first, then the rule, as an organization's repo did
  (2026-10-26).
- **Hardening is advice under either policy** (the user's call,
  2026-10-30). An action pinned by tag, the server's SHA-pin rule off,
  secret scanning or push protection off, a deploy key that can write,
  a bypass on any active ruleset and a code-owner rule that keeps an
  approval across a new push each warn and never fail, since none
  changes what a merge does.
- **A public repo's default branch takes no force push and no
  deletion**, under `personal` and `org-internal` alike (the user's
  call, 2026-11-03; `org-internal` joined it the same day, as the reason
  holds whoever owns the repo), warned of and never failed,
  as hardening is. **A private one is offered them as `[INFO]`**, never
  warned of (the user, 2026-11-04), where it used to print
  `[ok] no rules`. The fix is a branch ruleset on `~DEFAULT_BRANCH` with
  Restrict deletions and Block force pushes alone, no pull request rule
  and no bypass: the `ruleset-guard.json` scaffold, which
  [scaffolds.md](scaffolds.md) § "Branch rulesets" creates on a yes. A fast-forward
  is no force push, and `land-branch`'s default route pushed `main`
  through that ruleset on another public personal repo, exit 0
  (2026-11-02, not re-run here). While force pushes are blocked, an
  admin cannot change or rename the default branch without a bypass
  ("Available rules for rulesets", read 2026-11-03).
- **Release tags don't move.** Where releases are tags, a tag ruleset
  blocks updating and deleting them. Pass the ruleset's pattern as
  `-ReleaseTagPattern`.
- **A handoff board is advice under either policy** (the user's call,
  2026-10-29). A gap against `provision-board`'s board contract warns and
  never fails, since a board changes nothing a merge does, and a repo
  with no board is context: a queue may live in files, or nowhere.

## A releases repo

The user's calls of 2026-11-10, from a public releases repo set
up for a personal desktop app that day:

- **Immutable releases off fails**: a published release's assets could
  be replaced and its tag moved, so a download or the update feed
  could serve a file other than the one released. Once on, a release
  published afterwards is immutable: its tag cannot be moved, or deleted
  while the release exists, and its assets cannot be changed or deleted.
  A deleted immutable release's tag name cannot be reused, even by a
  repo recreated under the same name. **Releases published before it
  was turned on stay as they were** (GitHub's "Immutable releases" and
  "Preventing changes to your releases", read 2026-11-10), so the
  `why:` line says so.
- **Actions on fails**: nothing is built there, and with Actions off a
  token that can write contents and workflows, a classic token's
  workflow scope or a fine-grained one's Workflows permission, cannot
  add a workflow that runs with this repo's token. Contents alone, as a
  release job's token may hold, writes no workflow (REST "Create or
  update file contents" and "Permissions required for fine-grained
  personal access tokens" § 'Repository permissions for "Workflows"',
  read 2026-11-10).
- **An unrun pre-commit config is context**: the runner it would need
  means turning Actions on, which the line above fails.
- **The guard warns, on any visibility**: the same `ruleset-guard.json`
  as § "The strategy the policies encode" asks of a public repo, which
  the README's edits never trip.
- **Issues, wiki and projects on each warn**: a releases repo holds no
  work to track, so the README names where reports go: the source
  repo's issues, or where the source is private, this repo's
  Discussions, whose Q&A category GitHub makes by default (GitHub's
  "Managing categories for discussions", read 2026-11-11).
  `has_discussions` is left unjudged as a feature, so that route keeps
  the audit clean (the user's call, 2026-11-11).
- **With issues and Discussions both off, the README must name a
  route**, or the audit warns that downloaders have nowhere to report.
  A `mailto:` or a link to another repo's `/issues` or
  `/discussions` counts; a link to this repo's own does not, both being
  off. The linked repo is read, matched case-blind: a private or
  archived one is no route, nor one with the linked tracker off, and one
  that cannot be read is `[INFO]`, never a pass or a fail. Where issues or
  Discussions are on, or the README went unread, this check warns of
  nothing. The fix is `gh repo edit <o>/<r> --enable-discussions` and a
  README line linking the Q&A category.
- **Private vulnerability reporting off warns, and a missing security
  policy is context** (the user's calls, 2026-11-13): the routes
  above are public, so a hole in the installer or the update feed
  reported there is disclosed before it is fixed. Turned on, it gives a
  public repo a **Report a vulnerability** button that opens a private
  form (GitHub's "Configuring private vulnerability reporting for a
  repository", read 2026-11-13). Its read answered `{"enabled": ...}` to
  an account without admin rights on two public repos and 404 on a
  private one, where the setting does not exist (measured 2026-11-13,
  gh 2.103.3), so a 404 or a refusal is `[INFO]`, never judged. The
  security policy is GraphQL's `isSecurityPolicyEnabled`, since the
  community profile's REST schema lists none (both read 2026-11-13);
  none is `[INFO]`, and `references/scaffolds.md` § "A security
  policy" offers one. **On any other public repo the two are one
  `[INFO]` line**, judged nowhere, and a private repo under another
  policy reads neither.
- **The merge settings and the Actions token are context**: no pull
  request lands and no workflow runs.

## Measured while building the script (2026-10-22, gh 2.101.0)

- **A check run is named after its job**: its `name:`, or its id
  without one. A matrix job reports one run per value, `test (20)` and
  `test (24)`, so a required check has to name that form. The script
  therefore matches required checks against the check runs and commit
  statuses GitHub recorded, not against workflow files. **Those records
  expire**: since 2026-10-01 they are deleted with the repo's Actions
  retention, 90 days by default ([changelog](https://github.blog/changelog/2026-10-01-actions-retention-now-covers-checks-runs-and-statuses),
  docs read 2026-11-02). So a quiet repo can have none left, and the
  script then skips the comparison and says so. Reasoned from the docs:
  no repo has been seen in this state.
- **`codeowners/errors` answers 404 where no CODEOWNERS file exists**,
  and `{"errors":[]}` where a clean one does.
- **A branch's `protected` flag is `true` under a ruleset alone**, while
  `branches/<branch>/protection` answers 404 `Branch not protected`. So
  only the second shows classic protection.
- **An organization's repo reads in full for an account with admin
  rights**, bypass lists included. GitHub returns a ruleset's
  `bypass_actors` only to an account with write access to it.
- **A ruleset's `allowed_merge_methods` and the repo's merge toggles are
  separate settings**: one repo allowed all three methods while its
  `main` ruleset allowed only `merge`. The script judges each on its
  own. How the merge box combines them was not read.

## Measured while adding the board check (2026-10-29, gh 2.102.0)

- **GraphQL reads a project workflow's `name` and `enabled`, nothing
  more**, and lists 9 of the UI's 11 defaults: Code changes requested and
  Code review approved are missing, so the script cannot judge them. A
  workflow whose target option vanished reads off, as five did on one
  personal board (2026-10-27); a filter left at GitHub's
  default shows only in the browser.
- **The board is the linked project the queue's scripts pick**: open,
  not titled `Backlog template`, with Status and Reopen-when as the
  contract has them and Priority offering High, Medium and Low, a
  project field, the owner's issue field, an organization's or a user's,
  or a board's older P1 to P3, as
  `handoff-status.py`'s `carries_contract` reads one. Two such projects
  are a WARN, since `set-card.py` then refuses both.
- **A token without `read:project` is reported unreadable, never
  missing.** The script reads the error by the `INSUFFICIENT_SCOPES`
  type `handoff-status.py` reads, or by the scope's name in `gh`'s line;
  neither was seen live, as no account here lacks the scope.

## Measured while adding the hardening checks (2026-10-30, gh 2.101.0)

- **`security_and_analysis` is null on a private repo of a personal
  account**, and carries each feature's status on a public one, so the
  script reads an absent block as context. An organization's repo
  returned secret scanning and push protection `disabled` to an admin
  (2026-10-26). Which roles can read the block was not checked.
- **`actions/permissions` answers `enabled`, `allowed_actions` and
  `sha_pinning_required`**: a personal repo read `all` and `false`
  (2026-10-30), and `all` and `true` from 2026-11-02.
  Only `enabled` is required by its PUT (REST docs, read 2026-10-30),
  so the script's fix is the settings page, which leaves
  `allowed_actions` as it stands.
  The fix line says so, since a reader of the report opens no
  reference: one took the page for the only route (2026-11-03). A PUT
  naming `allowed_actions` as read, `all`, with
  `sha_pinning_required=true`, set the rule and left `all` as it was, on
  an organization's repo as its admin (reported from there, 2026-11-03,
  Claude Code 2.1.317); what it leaves of a `selected` repo's list is
  unread.
- **The contents API answers 404 for a repo with no
  `.github/workflows/`** (fabric-tools), and a workflow file's text in
  base64 broken into lines.
- **A lockfile, `.github/workflows/actions.lock`, records each action's
  commit and supersedes SHA pinning for the workflows it onboards, but
  not a reusable workflow's**, which still needs a full SHA (GitHub's
  "Workflow dependency lockfiles", read 2026-10-30). The script reads
  the onboarded paths from its `workflows:` keys, the shape a personal
  repo's lockfile has, written by `gh-actions-lock` v0.4.0
  (2026-11-02). The page names no `docker://` image, so an image's tag
  still warns.
- **`gh api codes_of_conduct` lists `django` and `contributor_covenant`**,
  the second version 2.0 with one placeholder, `[INSERT CONTACT METHOD]`,
  at line 63 of its body (gh 2.101.0, 2026-10-27, re-read 2026-10-30).
- **Not read**: GitHub's semantics for a `DeployKey` bypass actor, whose
  `actor_id` the script prints only where one is returned.

## Measured while adding October's settings (2026-11-02, gh 2.103.3)

- **`actions/policies` answers `{"total_count":0,"policies":[]}`** on a
  private and on two public repos of a personal account. The REST docs
  list two rule types, `restrict_actions_actors` and
  `restrict_action_events`, and no lockfile rule, though the settings page
  offers **Require lockfile**. No policy has been read here, so what a
  lockfile rule's type reads is unknown: the script prints each type as
  returned and judges none.
- **`sha_pinning_required` still gates a workflow the lockfile does not
  onboard**: it blocks one whose `uses:` names a tag or branch, and passes
  one pinned by full SHAs, which only **Require lockfile** blocks
  (GitHub's "Governing execution of GitHub Actions workflows" § "Require
  lockfile", read 2026-11-02). So the script's lockfile line names the pin
  rule where it is on. **Evaluate**, a policy's dry run, is GitHub
  Enterprise Cloud's alone, so a personal repo's policy has no dry run:
  it is Active or Disabled.
- **`interaction-limits/pulls/creation-cap` and `bypass-list` answer on a
  public repo** (fabric-tools: cap off, `max_open_pull_requests` 1, an
  empty list), and **405 on a private one**, "Interaction limits are not
  available for private repositories". The schema carries `enabled`,
  `max_open_pull_requests` and `include_drafts`, not the exemptions by
  account age or merged pull requests. `interaction-limits/pulls` alone
  is a 404.
- **`secret_scanning_ai_detection` is in the repo schema, with no key for
  its push protection**, and two public personal repos returned neither.
  Push protection for AI-detected secrets bills Secret Protection AI
  credits for each push scanned, to the organization that owns the repo
  (billing docs).
- **`community/profile` lists no accessibility file** in its schema or on
  three repos read. The page reads `.github/`, the root and `docs/`, in
  that order, for `ACCESSIBILITY.md`, so a read would take the contents
  API; the script names it as unread instead, the user's call.

## Measured while adding the releases policy (2026-11-10)

- **`GET repos/<o>/<r>/immutable-releases` answers 200 with `enabled`
  and `enforced_by_owner` where immutable releases are on, and 404 where
  they are off**, to an account with admin read access (REST "Check if
  immutable releases are enabled for a repository", read 2026-11-10).
  So the script fails a 404 only for an admin, and leaves it unjudged
  for anyone else, since what a non-admin is answered is unread. The
  releases repo scaffold, [scaffolds.md](scaffolds.md) § "A releases
  repo", was written from read back `{"enabled":true}` after
  `PUT repos/<o>/<r>/immutable-releases` (observed 2026-11-10, gh
  version unrecorded); no off state has been read here.
- **`PUT repos/<o>/<r>/actions/permissions` requires `enabled` alone**
  (REST docs, read 2026-11-10), so the script's fix sends `enabled=false`
  and nothing else.
