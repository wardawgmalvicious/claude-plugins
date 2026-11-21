# Working an issue in a cloud session

**A cloud session works an issue without the board and lands it as a pull
request**, so nothing it does touches the Windows machine's setup. With
`CLAUDE_CODE_REMOTE=true`, this file replaces the per-issue procedure's
parts, [preflight.md](preflight.md) and those it lists, and the
claim, card and landing steps of `work-issue`, its "never push" among
them. `lead-sessions` stops there instead: it has no route in a container.

Written 2026-11-01 from the cloud environments docs and what one cloud
session observed. **The route as a whole has not run**, so its first
use is its test.

## Why there is no board

**GitHub's proxy refuses GraphQL whatever the credentials**, with a 403
opening `GitHub GraphQL is not available from Claude Code sessions`, and a
`GH_TOKEN` you set gets the same (cloud environments docs, § "GitHub
proxy", read 2026-11-01). `set-card.py` and `handoff-status.py` are GraphQL,
as are `gh issue` and `gh pr`, so none of them runs. No board token goes in
the environment: every session there could read it, and anything an issue
body steers.

**The card keeps reading Open while the work runs.** The merge closes the
issue, and the board's Item closed workflow moves the card to Done. Until
then the issue's assignee and comment are the only sign, and a Windows
session stops on neither, so don't start one issue on both.

## The route

Use the session's GitHub tools, or `gh api` on these REST routes, which
answered for this repo from Windows on 2026-11-01:

```bash
gh api repos/<owner>/<repo>/issues/<n>                        # state, assignees, labels, sub_issues_summary
gh api repos/<owner>/<repo>/issues/<n>/comments
gh api repos/<owner>/<repo>/issues/<n>/sub_issues             # a parent's, to pick one
gh api repos/<owner>/<repo>/issues/<n>/dependencies/blocked_by
```

1. **Read the issue and its comments.** Stop on a closed issue, an assignee
   other than the user, or an open blocker. A `sub_issues_summary.total`
   above 0 is a parent: offer its open sub-issues. A `needs:*` label is a
   question for the user. With no number, ask for one, since the ready
   order is the board's. Stop too where `test -f .pre-commit-config.yaml`
   fails, since step 5's lint then exits 1: name the fix
   `preflight.md` § "Preflight, from the main checkout" names.
2. **Claim it**: assign the user, and comment that a cloud session is
   working it on `<type>/<slug>`.
3. **Branch from `origin/<default>`**, as `<type>/<slug>`, with no
   worktree: the container holds this session alone. `<default>` is the
   default branch, `ref: refs/heads/<default>` from `git ls-remote
   --symref origin HEAD`, else `gh api repos/<owner>/<repo> --jq
   .default_branch`, as `preflight.md` says why; `main` below names it.
4. **Work and commit** by `commit-changes`, as `work-issue`'s steps 5 and
   6 say: `Closes #<n>` on its own line of the finishing commit, and
   never `Closes #<parent>`.
5. **Prepare**: `pre-commit run --from-ref origin/<default> --to-ref
   HEAD`, then `review-code` on the range, or `prep.md`'s
   `/code-review` fallback without it, `intent: <S>/<n>.intent.md`
   after it: the proxy refuses the `gh issue view` an `intent: #<n>`
   runs, so save step 1's two reads there first, outside the repo, by
   `--jq .body` and `--jq '.[].body'`. A hook needing what the container
   lacks, such as `pwsh`, goes in the pull request's body, since CI runs
   every hook on it.
6. **Push the branch and open the pull request** through the session's
   GitHub tools, its body saying `Closes #<n>` on its own line. **Never
   push `main`**, which the proxy does not stop, and never merge.
7. **Report the URL and the merge below.** A deferral is a comment giving
   the why and the trigger, with the assignee removed; its card waits for a
   Windows session's `update-issue`.

**A session left idle may lose its container**, so nothing counts as done
until it is pushed.

## The merge, on the user's word

**Push local `main` first**, because the merge moves `origin/<default>`
past it, and a local commit not yet pushed would then need a rebase. So
a merge can wait for the machine. The repo allows a merge commit alone.
From the main checkout, with no session it would cost:

```bash
git rev-list --left-right --count <default>...origin/<default>   # before the merge: 0 0
git fetch origin && git merge --ff-only origin/<default>         # after it
```

**The machine runs none of it until then**, nor a deployed skill or
payload until the repo's deploy line, `<deploy>`, runs.

## What stays out of reach

- **`file-issue`**: `brief-bodies.py` exits 2 with no denylist, and stays
  so, so nothing is filed unchecked (the user, 2026-11-01). `update-issue`
  needs `set-card.py`.
- **The identity scan**: `identity-guard` prints `no denylist` and passes,
  as in CI, so nothing scans a commit or a pull request here for client
  names. The container holds this repo alone, so one arrives only if it is
  typed in.

## The environment's setup script

**The user's personal environment for the config source holds this script**,
saved 2026-11-15 with `SKIP=psscriptanalyzer,pester` as its one variable,
CI's Linux list, and no hosts or secrets past the defaults. It runs one
directory above the checkouts (2026-11-01) with the environment's variables
unset, and a non-zero exit stops the session starting (docs, as above).
It enters the config source's checkout, not the session's own repo, so a
session for another repo gets the payload too when the config source is
attached as a second repository on this environment (2026-11-15). A
script cannot clone it itself, since it is private and the script gets no
token. In the script below, `<config-source>` is that checkout's folder
and `<machine>` its bootstrap folder; the saved script spells both out:

```bash
[ -d <config-source> ] || exit 0
cd <config-source> || exit 0
# sh is bash, as in Git for Windows and the suites' container: the hooks
# set -o pipefail, which dash rejects.
ln -sf bash /usr/bin/sh
# Skill groups from the bootstrap's config, so this list never drifts.
groups=$(grep -oP "ClaudeSkillGroups\s*=\s*@\(\K[^)]*" <machine>/config.psd1 | tr -d "'" | tr ',' ' ')
mkdir -p ~/.claude/skills ~/.claude/rules
for g in $groups; do
  for d in skills/"$g"/*/; do
    [ -f "$d/SKILL.md" ] && ln -sfn "$PWD/${d%/}" ~/.claude/skills/"$(basename "$d")"
  done
done
cp claude/CLAUDE.md ~/.claude/CLAUDE.md
cp -r claude/rules/. ~/.claude/rules/
uv tool install pre-commit==4.7.0 || true
pre-commit install --install-hooks || true
# yq for close-parent's suite, the suites image's pinned build.
curl -fsSL -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.54.1/yq_linux_amd64 \
  && echo '8e34fc298390875de416e6a4afcb8cabeceb25d9aa8506c1a2f9353cf702ea5f  /usr/local/bin/yq' | sha256sum -c - \
  && chmod 0755 /usr/local/bin/yq || rm -f /usr/local/bin/yq
exit 0
```

**Run by hand in one session, 2026-11-15, it took 58 s and exited 0**: 35
skills linked, none a platform skill, and `pre-commit run --all-files`
passed every hook bar the two skipped. **A new session on the environment
ran it at its container's build, 2026-11-15**, with nothing typed: the same
35 links and 26 rules, `sh` as bash, pre-commit's three hook types and
their environments, `yq`, and `SKIP` set. Its listing held
`commit-changes` and `land-branch`, not `work-issue`, whose
`disable-model-invocation: true` keeps it typed only, as intended.
**Of 76 suites, 58 passed**: 45 before `sh` became
bash, every hook suite failing on `set: Illegal option -o pipefail`. Of the
other 18, 16 need real `pwsh`, not the image's stub, so they fail here
rather than read NOT RUN; `edit-video`'s render got ffmpeg exit 8,
unexamined; and `spec-ops` fails on a uv warning the container's own
`UV_NATIVE_TLS` prints, which an environment variable cannot override.
`packages.microsoft.com` answered, so `pwsh` could be installed, but no one
has measured those 16 under Linux `pwsh`.

**The copied `claude/CLAUDE.md` is Windows guidance**: in the container it
says `python` resolves nowhere and that commands for the user are
PowerShell, both wrong there (2026-11-15). The script sets no commit
identity, since the environment would store it in plain text, so commits
stay `Claude <noreply@anthropic.com>`.

**The script runs whenever a session's container is built fresh**, as
the environment tools describe it and the run above showed. The skills are
links into that session's clone, so they are as new as its checkout; the
`CLAUDE.md` and rules are copies, as new as the build. Whether a later
session ever reuses an older container, with older copies, is
unmeasured: an empty `ls ~/.claude/skills` says its script did not run.
