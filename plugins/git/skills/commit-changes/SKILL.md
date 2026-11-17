---
name: commit-changes
model: inherit  # not sonnet: typed late in a session, a pin rewrites the whole cache, costing more than it saves (editing-skills.md)
effort: high  # a numbered procedure whose commits stay local and reversible; held only once test-skill's cold arm passes at high, the shared-tree guards included
disable-model-invocation: false
description: "Splits working-tree changes into logical, self-consistent commits (ordering so nothing dangles, stepping files that straddle commits through intermediate states), writes conventional-commit messages (feat/fix/docs/refactor/chore) with motivation in the body, stages explicit paths only, uses git mv for renames, never pushes/amends/skips hooks unless explicitly asked, and ends by reporting the resulting hashes against a clean tree. Includes pre-commit checks for Fabric Git-synced repos (core.autocrlf, .gitattributes, whitespace-only portal diffs). In a working tree another session is editing at the same time, gates the commit on the branch and on the index exactly as read, so nothing of theirs is swept in and nothing lands on a branch a peer switched to."
when_to_use: "Use when asked to commit changes — 'commit this', 'make the commits', 'commit these split logically' — and when the commit has to be made in a tree another session is working in: 'another session is live in this tree', 'commit mine without touching theirs'."
---

# Commit workflow

Turn the current working-tree changes into one or more well-formed
commits. Committing only — pushing, amending, rebasing, and tagging
happen only when explicitly requested, never as follow-through.

## Survey first

1. `git status --short` — full picture of modified, renamed, untracked.
   Note anything **already staged that you did not stage**.
2. `git log --oneline -10` — calibrate message style against this
   repo's actual history, not assumptions.
3. Read the diffs (`git diff`, `git diff --stat`, plus untracked
   files) well enough to explain *why* each change exists, not just
   what it touches. Never commit content you haven't looked at.
4. **On `main`? Branch when the work is more than one commit, or an
   intermediate state would break while deployed**, named
   `<type>/<kebab-slug>`, a [type](#messages) and 2–4 words naming the
   subject, where the user's instructions name no other form — and from
   the first commit when it is bound for `land-branch`, which refuses
   to start from `main`. Work in a repo that lands by pull request is
   bound for `land-branch`: a pull-request rule on `main`
   (`land-branch` step 7 has the two reads), or `(#<n>)` and
   `Merge pull request` subjects in the log above; a fast-forward
   landing leaves none. A repo's own
   committed convention wins, in its `CONTRIBUTING.md` or agent
   instructions: one that commits straight to `main` answers *no*, and
   then you commit where you stand. Say which way you went. In a
   shared tree `git switch -c` moves HEAD for everyone — see
   [below](#when-another-session-shares-this-tree).

**An empty `git status --short` is the whole answer.** Report that there
is nothing to commit and stop; don't work through the diffs to confirm
it. `git diff --stat` prints nothing on a clean tree, and reading that
silence as a failed command rather than as the answer is a real failure
mode — observed 2026-09-09, three tool calls spent re-asking the same
question.

## Splitting into commits

- **One logical unit per commit.** A rename, a new feature, and a
  docs catch-up are three commits even when they touch the same file.
  Test: could each commit's subject line be written without "and"?
- **Review grouping is not a commit boundary.** Parts approved
  together in one review are still separate commits when each stands
  on its own in history — independently revertible, citable, worth
  landing alone. Bundle only when the parts are mutually dependent
  for meaning: a claim and the caveat qualifying it, a rename and its
  call sites. Tiebreak for a docs batch — which shape would you
  rather read in `git log` a year from now?
- **Every commit must be self-consistent.** No commit may reference a
  name, file, or skill that doesn't exist yet at that point in
  history, and none may leave the repo in a broken intermediate state.
  Order accordingly (e.g. a rename lands before anything citing the
  new name).
- **When one file straddles commits**, reach for interactive
  `git add -p` where your harness offers it. Some do not: an agent
  shell with no interactive stdin cannot drive it, and the prompt
  either hangs or reads EOF. Where it is unavailable, **stage through
  the index**: [scripts/stage-part.py](scripts/stage-part.py), run as
  `${CLAUDE_SKILL_DIR}/scripts/stage-part.py`, builds
  the next commit's version of the file from the changed blocks a regex
  picks and writes it straight into the index, leaving the working tree
  at its final state. Read the `TAKE` and `skip` line it prints for
  each block, then `git diff --cached`, before each commit; an empty
  `git status --short` after the last commit proves the commits add up
  to the file on disk. Usage, limits, and the blob built by hand for
  changes no unchanged line separates:
  [references/index-staging.md](references/index-staging.md). Stepping
  the file through intermediate states on disk is the fallback — edit
  it down to the first commit's portion, commit, restore the next
  portion, commit again — and rewrites the working tree, so verify the
  final state matches the intended end state exactly.
  **`.pre-commit-config.yaml` steps on disk only**: pre-commit will not
  run while it differs between the index and the working tree, whoever
  made the difference, so a commit staged through the index fails
  `[ERROR] Your pre-commit configuration is unstaged.` and commits
  nothing (pre-commit 4.6.2, 2026-10-25).
  **Stepping assumes you own the whole file.** If another session has
  uncommitted work in it, stepping rewrites their in-flight text —
  commit only what is yours and leave the rest with a note.
- **Stage explicit paths only.** No `git add -A` / `git add .` — they
  silently sweep in untracked or unrelated files.
- **Verify the index before each commit.** `git diff --cached --
  <paths>` must show your change and nothing else. The diff you read in
  the survey is not what `git add` staged: the file can change in
  between, and `git add <path>` takes every hunk in the file, not the
  hunk you meant. `--stat` is not enough — a foreign hunk in a file you
  also edited has a stat line that looks exactly right. This is the last
  point at which a swept-in change is free to fix — and in a shared
  tree it has to *gate* the commit rather than precede it; see
  [below](#when-another-session-shares-this-tree).
- **On the default branch, review the index before committing it**, as
  nothing reviews it later; on any other branch skip this, since the
  whole branch is reviewed where it lands: by `land-branch` before its
  PR, or before the landing the repo's own instructions name. **A
  branch a lead will land is reviewed before its hand-off**, never left
  to the lead: by the prep in `work-issue`'s
  `references/prep.md` § "Preparing to land", where `work-issue` is
  installed. When the
  staged diff touches a language `review-code`'s description names,
  **Markdown aside**, invoke
  `review-code` with `git diff --cached` and those paths as its target,
  and read the count line it opens with. **A critical finding stops the
  commit**: list the findings and ask whether to fix them first or
  commit as is. Lower ones go in the report, as does staged code in a
  language the description does not name, called unreviewed by
  language, never clean. **Markdown is left out because its check fetches
  pages** and most commits touch it, so a branch's range pays that once;
  a commit straight to the default branch gets no such check, and the
  report says its Markdown's claims went unchecked. **Where `review-code`
  is not installed**, invoke the bundled `/code-review` on
  `git diff --cached` and every staged path but Markdown instead (Claude
  Code's skills docs, read 2026-11-16). It runs in the background, so end
  the turn and commit only once its findings arrive, treating each as a
  critical one (code-review-local docs, read 2026-11-16); with neither,
  the report says no review ran. A shared tree's
  `write-tree` gate stands: the review only reads, and the gate still
  refuses an index that moved meanwhile.
- **Renames go through `git mv`** (or are staged so git detects the
  rename) so history follows the file.
  **Never `git add -N` the new path of a move whose deletion is
  unstaged.** pre-commit clears an intent-to-add file only when
  `git diff --diff-filter=A` lists it, and beside the deletion it lists
  as a rename, so the commit fails, exit 1, on
  `already exists in working directory`, leaving every other unstaged
  edit only in `~/.cache/pre-commit/patch<time>-<pid>` and the new file
  empty (pre-commit 4.6.2, git 2.55.0.windows.3, 2026-10-23). Stage both
  paths or neither. To recover: `git reset -- <new>`, delete the empty
  file, then `git apply` the patch.

## Messages

- Subject: `<type>(<scope>): <imperative summary>`, with the scope where
  the log uses one. `<type>` is a conventional-commit type: `feat`,
  `fix`, `docs`, `refactor`, `chore`, `perf`, `test`, `build` or `ci`.
  Lowercase after the colon, no trailing period.
- Body: explain **motivation and non-obvious decisions** — why the
  change exists, what prompted it, provenance ("derived from X, now
  deleted"), and any ordering or scoping rationale. Never restate the
  diff. Wrap near 72 columns. Trivial single-file changes may skip
  the body.
- Multi-line messages: from PowerShell, a single-quoted here-string
  (`@'` ... `'@`, closing delimiter at column 0) handed to `-m`, never
  to `-F -`, which reads stdin and leaves git the here-string as a
  pathspec: `error: pathspec '<subject>…' did not match any file(s)
  known to git`, exit 1, nothing committed (2026-10-09). From Bash, prefer
  `git commit -F -` fed by a quoted heredoc over `-m`, which sidesteps
  the quoting entirely. **Crossing the two exits 0** — a PowerShell
  here-string handed to `-m` in the Bash tool commits `@` as the
  subject with the delimiters in the body, and neither the hooks nor
  the exit code says so. Confirm with `git log -1 --format=%B --stat`
  before reporting the commit — one call gives both the message actually
  recorded and the files actually in it.

## Safety rails

- Never push, amend, force, rebase, or tag unless the user asked for
  that in this conversation. Commit, report, stop.
- Never `--no-verify` / skip hooks; if a hook fails, fix the cause.
- If a change looks accidental or unrelated to the stated work, leave
  it uncommitted and flag it rather than sweeping it in.
- **Scan for identity strings — in the diff *and* in the message you
  are about to write.** An organization's account names (`AzureAD\…`,
  Entra accounts), tenant names and internal hostnames get genericized
  before the commit, whatever the repo's visibility, in every repo but
  that organization's own: where the denylist below is installed, the
  client roots it exempts (2026-10-16). A hardcoded profile path, a home
  folder under the user's own name, gets genericized in every repo.
  gitleaks does not
  cover this: it matches secrets, not identities, and the pre-commit hook only sees
  *staged content*, so the message is unguarded entirely. The trap is
  that a commit documenting machine- or tenant-specific behaviour is
  exactly where real account names read as the subject matter — and a
  message, unlike a file, cannot be fixed forward.
  **Assume nothing catches this for you.** A hook can: an
  `identity-guard` reading a local denylist blocks a commit whose
  staged diff adds a listed term, hands back a message that carries
  one, and blocks the push. But it is a *local* hook reading a *local*
  list — the list is itself the leak, so it lives in no repo and
  travels with no clone. Unless you installed both on this machine,
  nothing above is checked for you and the scan is entirely yours. Even
  where it does run it knows only what is on the list, so a name it has
  never seen is yours to catch, and then to add.

## When another session shares this tree

Two sessions in one working tree share every file, **the index and
HEAD**, so neither staging nor a branch isolates you — only a commit
does, and only if it lands on the branch you meant. Suspect it when the
survey shows a path you never touched, when something is already staged
that you did not stage, when `git diff --cached` holds a hunk you cannot
account for from this conversation, when HEAD is not on the branch you
left it on, or when the user says so. **Rule out the two innocent
explanations first**: your own stepping edits, and a hook that rewrites
files, which leaves its rewrite *unstaged*. Neither is contention.

A linked worktree is a tree of its own: git keeps its index and HEAD
under `.git/worktrees/<name>/`, so a session alone in one has nothing
to suspect and commits with the plain commands. The `EnterWorktree`
guard refuses the chained form in the procedure below there as too complex to verify
(2026-10-06, 2.1.289), and a worktree needs none of it.

**Commit each finished unit unasked while a peer shares the tree**: the
user's standing word since 2026-10-09. **With a peer in the tree, or a
sign of one, Read
[references/shared-tree.md](references/shared-tree.md) before staging
anything.** It holds the procedure: who counts as a peer and what counts
as finished, staging and committing gated on the branch and the index as
read, and what each error a peer's git or pre-commit run raises means. Its
two checks are `land-branch`'s scripts,
`${CLAUDE_SKILL_DIR}/../land-branch/scripts/placed-elsewhere.sh` and
`${CLAUDE_SKILL_DIR}/../land-branch/scripts/never-prompted.sh`. A
solo tree, or a linked worktree of your own, needs none of it. Staging one
hunk out of a file they are also writing:
[references/concurrent-sessions.md](references/concurrent-sessions.md).

## Fabric Git-synced repos

Before the first commit in a repo containing `*.{ItemType}` folders:
check `git config core.autocrlf` and whether `.gitattributes` pins the
item folders (per the `fabric-git-serialization.md` rule, where the
user's config holds one).
Whitespace-only diffs (EOF newline, CR-stripping) in portal-owned files are
translation artifacts — do not commit them as "cleanup"; flag them and
fix the `.gitattributes` instead.

## Finish

- `git status --short` must come back clean, or every remaining line
  must be intentionally left and mentioned in the report.
- Report each commit: hash, subject, and one line on what it contains
  — plus an explicit note that nothing was pushed, and any review
  findings left unfixed.
