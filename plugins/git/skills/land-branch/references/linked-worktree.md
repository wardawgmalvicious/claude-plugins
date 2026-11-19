# From a linked worktree

What changes when the branch lives in a linked worktree — made by
`claude --worktree <name>`, `EnterWorktree`, `git worktree add` or the
desktop app — rather than in the main checkout. Step 1's last command
detects one; read this before step 3.

## Detecting one

```bash
git rev-parse --path-format=absolute --git-dir --git-common-dir
```

A linked worktree prints two paths: its own git dir, under
`<repo>/.git/worktrees/<name>`, then the shared `<repo>/.git`. The main
checkout prints the same path twice from any subdirectory, as does a
submodule, whose git dir under the superproject's `.git/modules/` is its
own common dir (git 2.55.0, 2026-09-29). `git worktree list` names every
tree, and cannot say which one you are in.

**The desktop app makes one before the session starts**, at
`.claude/worktrees/<dir>` on a branch `claude/<dir>`, and the session's
system prompt says it runs in the app. § "Before step 3"'s rename
applies to that branch as to `worktree-<name>`. The session never called
`EnterWorktree`, so `ExitWorktree` is a no-op there, by its own
description: step 6's removal is no yes for it, and step 9 keeps the
worktree and the branch and hands the user their commands (2.1.304,
2026-10-22, one landing). That landing's user archived the session in
the app, then unarchived it, and it resumed in the main checkout with
the worktree detached but still registered; there `git worktree remove`
exited 255, `Permission denied`, yet unregistered it and emptied the
directory, leaving the folder on a held handle, and the keyed
`git branch -D` then ran. Whether archiving alone detaches the worktree
is unmeasured.

## Before step 3: a generated branch name

`claude --worktree <name>` and `EnterWorktree` put the worktree on a new
branch, `worktree-<name>` (code.claude.com/docs/en/worktrees, read
2026-09-29). That name reaches the PR and any merge title, so rename it
before the push, to the form the user's instructions name for a branch,
else a conventional-commit type and a 2–4-word subject:

```bash
git branch -m <type>/<kebab-slug>
```

The worktree's directory keeps its name, and whatever keys on the
directory keeps working (a client repo, 2026-09-27). Steps 2 to 6 then
run from the worktree unchanged, and step 6 names the tree step 7 writes
from.

A worktree created on its branch needs no rename:
`git worktree add .claude/worktrees/<dir> -b <type>/<kebab-slug> <default>`,
then `EnterWorktree` with `path` set to that directory, which its
description offers for "one you just created with `git worktree add`"
(2.1.294, 2026-10-08). The directory and the branch may be named apart.

## Step 7: `main` is checked out elsewhere

The main checkout holds `main`, and git will not move a branch another
tree has checked out. From a linked worktree `git switch main` exits
128, `fatal: 'main' is already used by worktree at '<path>'`, so the
default route stops at its switch (git 2.55.0, 2026-09-27, again
2026-09-29); `git branch -f main`, `git fetch . <branch>:main` and
`git push . <branch>:main` were refused too (2026-09-27).

**From the worktree, take the write that needs no checkout**: the
refspec push where `main` requires no pull request, the PR merge where
it requires one. **Pin the push by its SHA, as two plain commands**: the
`EnterWorktree` guard refuses the route's `[[ … ]] && git push` as too
complex to verify that it stays inside the worktree, as it does
`commit-changes`'s chain (2.1.294, 2026-10-08).

```bash
git rev-parse <branch>                         # must print <sha>; stop if not
git push origin <sha>:refs/heads/<default>     # pushes exactly <sha>
```

What was checked is what goes, even if the branch moves after the read;
a push to a branch still takes only a fast-forward (git-push § "PUSH
RULES"), and the pre-push hooks still run. Spell the destination in
full: git expands a short one only when it "unambiguously refers to a
ref" on the remote, or from the source ref's namespace, which a SHA
lacks (git-push, read 2026-10-09).

The push goes through from a worktree. It leaves the
main checkout's `main` behind `origin/main`, and a commit made there
before it catches up diverges, so step 8's report names the fix, to run
in the main checkout:

```bash
git merge --ff-only origin/<default>
```

For a landed hook or settings change the catch-up is more than tidying.
A session in a desktop-app worktree reads settings and hooks from the
main checkout (code.claude.com/docs/en/worktrees, read 2026-10-20), so
the change stays inert in every desktop session there until the main
checkout's branch has it: one that widened a guard hook in its worktree
saw a command the new guard refuses run through the live one (2.1.304,
2026-10-22; which script ran was not traced). Test such an edit by
piping synthetic payloads to the worktree's copy.

**From the main checkout, when the user asks for it**, which step 6's
question can carry beside the worktree's removal. `ExitWorktree`
with `keep` returns the session there, leaving the worktree and branch
on disk. Its description scopes it to worktrees `EnterWorktree` made,
and to when the user asks; it worked on a `claude --worktree` launch too
(2.1.282, 2026-09-29). Run `ListAgents` first, since that tree may be
shared. HEAD there is already `main`, so the default route drops its
switch, and its guard checks for `main`:

```bash
[[ "$(git branch --show-current)" == "<default>" && "$(git rev-parse <branch>)" == "<sha>" ]] \
  && git merge --ff-only <branch> && git push origin <default>
```

Without that ask, take the worktree's route above, or hand the user this
command to run there.

## Step 8: verify against `origin/main`

Step 8's ancestor check and merge count read `origin/main` against the
pins, so they run from the worktree unchanged. Its local-`main` line
does not: `git fetch origin <default>:<default>` is refused wherever
another tree has it checked out, `fatal: refusing to fetch into branch
'refs/heads/main' checked out at '<path>'`, exit 128, and moves no ref
(again 2026-09-29). Skip that line and `git rev-parse <default>
origin/<default>`;
step 7's catch-up in the main checkout brings its `main` current.

## Step 9: the worktree goes before the branch

Git will not delete a branch a worktree has checked out, from either
side: `git branch -D` exits 1, `error: cannot delete branch '<branch>'
used by worktree at '<path>'` (2026-09-29).

- **The remote half runs from the worktree** as step 9 has it.
- **The local half waits for the worktree's removal**, from the main
  checkout, since inside the worktree the lock names this session's pid
  and the worktree guard refuses a `git -C` aimed at the main checkout.
  **This session's own worktree, with step 6's yes, goes now**: run
  `ListAgents` and step 1's scripts, then `ExitWorktree` `keep`, which
  releases the lock and returns the session there, then:

  ```bash
  git worktree list --porcelain                # no `locked` line under <worktree>
  git -C <worktree> status --short             # anything here is on no branch
  git worktree remove <worktree>               # refuses a dirty tree, and a locked one
  git merge-base --is-ancestor <branch> <sha> && git branch -D <branch>
  ```

  Measured twice: from a `claude --worktree` launch (2.1.282,
  2026-09-29), and from `EnterWorktree` in VS Code (2.1.301,
  2026-10-16), where `ExitWorktree` still named the branch it had made,
  though `git branch -m` had renamed it: delete by the new name. Whether
  a `claude --worktree` launch's lock still goes on 2.1.301 is untried,
  as is running § "Step 7"'s catch-up from there.

  A worktree `git worktree add` made, entered only by a Bash `cd`, is
  left by a `cd` back to the main checkout, which the harness then
  announces as primary again: `ExitWorktree` is a no-op outside an
  `EnterWorktree` session, by its description, as for the desktop app's
  (§ "Detecting one"). The removal and the keyed `git branch -D` above
  then run as written (twice, 2.1.311, 2026-10-26).

  **A removal that exits 255 leaves the folder held**: git drops the
  worktree's entry and admin folder anyway, but deletes files only up
  to the first one it cannot, which stays with every entry after it
  (observed 2026-11-04, Git 2.56.0). A
  native process working in the folder itself fails only the folder,
  `error: failed to delete '<worktree>': Permission denied`, and leaves
  it empty, holding it until it exits, as a `ping` started there did
  (git 2.55.0, 2026-11-18); one in a subfolder, `Permission denied` on
  that subfolder, or with a file open there, `Invalid argument`, leaves
  files.
  This session is no holder once it has left: `EnterWorktree` moves its
  `claude.exe` into the worktree and `ExitWorktree` moves it back,
  measured after a `remove`, where a `claude --worktree` session's own
  process worked in its worktree (2.1.327, 2026-11-18). Reads of a
  `.py` and a `.ps1` file there started no holder, so 2026-11-05's
  language server, inferred from ancestry and start time, is still a
  guess. One hold ended within the session, `rmdir` passing 2 h 41 min
  after the failure, past another worktree's entry and exit and six
  compactions (observed 2026-11-18, 2.1.325). **Name the holder by its
  working directory**, from the main checkout, since the scan lists its
  own shell too. Unelevated, `handle` printed
  `No matching handles found.` for the `ping`, which the scan listed
  (2026-11-18). It finds only a working-directory holder, and an empty
  result clears nothing: an open-file holder needs Sysinternals'
  `handle -accepteula -nobanner (Resolve-Path '<worktree>').Path`, run
  elevated by the user in PowerShell, since Handle matches only the
  folder's absolute, backslash path. The scan:

  ```bash
  uv run --no-project --with psutil python -I -c "import os,sys,psutil; r=os.path.normcase(os.path.abspath(sys.argv[1])); [print(p.info) for p in psutil.process_iter(['pid','name','ppid','cwd']) if p.info['cwd'] and (os.path.normcase(p.info['cwd'])+os.sep).startswith(r+os.sep)]" '<worktree>'
  ```

  Run the keyed `git branch -D`, retry
  `rmdir <worktree>` later in the session, and if it still fails hand
  the user `rmdir <worktree>` for once the session has ended, or
  `Remove-Item -Recurse <worktree>` if that says it is not empty: only a
  later `work-issue` or `lead-sessions` preflight sweeps an empty one,
  and a repo landing by this skill alone runs neither.

  A lock still naming this session's pid after the `keep` is one a
  refused `EnterWorktree` by name left (2.1.283, 2026-09-30): run
  `git worktree unlock <worktree>` first. A dirty tree is refused,
  `contains modified or untracked files, use --force to delete it`,
  exit 128: never add the `--force`, which discards that work. A lock
  naming another session is refused too, its reason naming that session
  and its pid: leave a live one alone, and see `prune-branches` for a
  lock whose pid is dead.
- **Otherwise keep both** and say so — a dirty tree, another session's
  lock, or no yes at step 6 — handing the user those commands for once
  the session has ended. At `/exit` a worktree holding commits is
  offered keep or remove, and remove deletes the branch with its work
  (code.claude.com/docs/en/worktrees, read 2026-09-29); in VS Code the
  user saw no such offer, more than once (their report, 2026-10-16,
  unmeasured).
- **`ExitWorktree` `remove` is no substitute.** It refuses while the
  branch holds commits past the session's starting commit, counted by
  `git rev-list --count refs/heads/<branch> ^<start>`, which asks no
  remote, and reads a branch `git branch -m` renamed as "another
  branch", as § "Clean up worktrees" says of the exit prompt
  (code.claude.com/docs/en/worktrees, read 2026-11-18): it refused on
  13 commits already on the remote (2.1.325), and after a rename,
  `The worktree is now on another branch, which has 1 commit that this session's starting commit lacks`
  (2.1.327, both 2026-11-18). After the rename it removed the worktree
  and left the renamed branch, saying nothing of it (2.1.282,
  2026-09-29; again 2.1.327, 2026-11-18).
  **It deletes the worktree itself, never by `git worktree remove`**:
  after `git worktree unlock`, with no git process seen, it deletes
  every entry but the `.git` file, then git's admin folder, then the
  folder with its `.git` file. **Under a hold, its
  `could not remove it — kept at` leaves no worktree**: the last step
  fails whole, though `rm <worktree>/.git` alone passed under the same
  hold, so the folder keeps a lone `.git` file naming the deleted admin
  folder, the entry is gone and the branch kept. `git status` there prints
  `fatal: not a git repository: (NULL)`, `git worktree remove` says
  `is not a working tree`, and no preflight sweep takes a folder that
  is not empty. Under the same hold, `keep` then `git worktree remove`
  names its failure and leaves the empty folder a sweep takes, so it
  still wins (each reproduced 2026-11-18, 2.1.327, a `ping` working in
  the folder, under `discard_changes: true`; first seen that day on
  2.1.325). Clear the leftover by the keyed `git branch -D`,
  `rm <worktree>/.git`, and `rmdir <worktree>` once the holder exits.
