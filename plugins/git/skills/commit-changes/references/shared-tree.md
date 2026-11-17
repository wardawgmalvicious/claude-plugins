# When another session shares this tree: the procedure

Read this before staging whenever `SKILL.md`'s "When another session
shares this tree" applies: a live peer, or a sign of one. In a solo tree,
or alone in a linked worktree, none of it applies.

**Commit each finished unit unasked while a peer shares the tree**: the
user's standing word since 2026-10-09. Held for their review, it can
vanish under a peer's stash, checkout or pre-commit run before they
look, and nothing reports it; a commit they did not want costs a revert.
A peer is any live `ListAgents` row that
`bash <placed-elsewhere.sh> <name>`, by the path `SKILL.md` names,
does not place elsewhere, idle or never prompted alike, since the user can
prompt it at any moment. Pass each name whole, as its row prints it,
with or without the `[<ref>]`, which the script strips when the whole
name finds no entry: a hook's name ends in its start time, and one
passed without it reads as in doubt, the script's line naming the entry
to pass again (2026-10-22). The script places a row by its session's
working directory, which a name set by `/rename`, `--name` or a hook
does not give, and keeps in this tree a row it cannot place:
`land-branch` step 1 has why. With no `land-branch` installed beside
this skill neither script is there, and every live row is a peer.
Finished means the hooks pass and nothing
in it dangles; work in progress stays out, and the report says it is at
risk. Only the user's word in this conversation holds a finished unit back.
Run the whole procedure, but on `main` where `SKILL.md`'s step 4 would branch, ask
instead, since `git switch -c` moves the peer's HEAD too. Open the report
with the commit and why it was made unasked.

- **Ask them.** `ListAgents` names every live session by its
  `/rename` or `--name` name, or one a hook set, else
  `<cwd-basename>-<hash>` — its
  working directory, not its repo — and
  `SendMessage` reaches one. **Read every row rather than filtering by
  repo name**: a peer sitting in a subdirectory of this tree is both the
  likeliest contender and invisible to a prefix match (measured
  2026-09-17). A peer is the only source for what is in its working tree
  and not in `HEAD`, so ask it — "are you editing `<path>` right now?" —
  before cutting a patch, not after a collision. What they say about
  *committed* state is
  as old as their session, so check that yourself. **Skip a session
  that was never prompted**, for which
  `bash <never-prompted.sh> <name>`, by the path `SKILL.md` names,
  exits 0: it holds nothing in this tree, and a message would prompt it,
  making it a peer `land-branch` then has to count (2026-09-30).
- **Stage and read in one chained command, commit in a second, and
  read the branch inside both** — with `git write-tree` carrying the
  index you read into the commit. The gap between reading a diff and
  running `git add` is where their hunk gets swept in, and HEAD is
  shared the same way: a peer's `git switch` moves the branch your
  commit lands on, with no error on either side. `git status` cannot
  show it — it reports files relative to HEAD, so a clean tree after
  someone moved HEAD reads exactly like one before, and "the tree is
  clean, so nothing is at risk" has been said and been wrong. One
  chain from `add` to `commit` closes that gap by dropping the index
  check: nothing can be read between two `&&`, and a `git diff
  --cached` printed mid-chain exits 0 and gates nothing (measured
  2026-09-23: 3 of 3 probes on that form never verified the index).

  ```bash
  [[ "$(git branch --show-current)" == "<branch>" ]] \
    && git add <paths> && git diff --cached && git write-tree
  # read the diff -- your hunks and nothing else -- and note the tree id
  [[ "$(git branch --show-current)" == "<branch>" \
     && "$(git write-tree)" == "<tree>" ]] && git commit -F - <<'MSG'
  …
  MSG
  ```

  `git write-tree` hashes the whole index, so the second chain refuses
  if anything reached it since you read — their hunk in your file, a
  file of theirs — and ignores what they left unstaged, which `commit`
  would not take either (all four cases measured 2026-09-23). From
  PowerShell both tests have to be an `if`: pwsh's `&&` runs its right
  side whenever the left side *ran*, true or false, so a literal port
  never refuses (measured 2026-09-23, pwsh 7.6).

  ```powershell
  if ((git branch --show-current) -eq '<branch>') { git add <paths> && git diff --cached && git write-tree }
  if ((git branch --show-current) -eq '<branch>' -and (git write-tree) -eq '<tree>') { git commit … }
  ```

  A mismatch means someone moved HEAD: stop, `ListAgents`, ask —
  switching back is a HEAD move for them too. Recorded 2026-09-22, and
  `land-branch` step 1 has the other seat: a peer's `git switch main`
  landed between this session's `switch -c` and its `git add`, and the
  commit went to `main` unnoticed for over an hour. If it already happened,
  propose the repair rather than run it — the stray commit onto
  `<branch>`, the wrong branch back to `<sha>^` — since both move refs
  a peer may be standing on, and resetting to the upstream instead
  would drop anything unpushed.
- **Don't route around a staged file with `git commit -- <path>`.** With
  `core.filemode` false, the Windows default, a pathspec commit ignores the
  index's mode: a new script lands 100644 though `git add --chmod=+x`
  staged 100755, a tracked one keeps HEAD's mode, and the index keeps
  100755 staged as `M` for the next plain commit, whoever makes it. It
  exits 0 (git 2.55.0.windows.3, 2026-10-01). With a peer's file staged,
  ask them to commit or unstage it first.
- **`fatal: Unable to create '.git/index.lock': File exists` is their
  git command in flight**, not a stale lock. Wait and retry; never
  delete it.
- **`[ERROR] Your pre-commit configuration is unstaged.` is their
  edit** when you never touched `.pre-commit-config.yaml`: pre-commit
  refuses every commit in the tree while that file has unstaged changes,
  whoever made them. Don't run the `git add` it suggests, which commits
  their half-made config under your message; ask them to finish or
  revert it. A config edit of yours blocks them the same way: make it
  last, and stage it in the chain that commits it (pre-commit 4.6.2,
  2026-10-06).
- **`[WARNING] Unstaged files detected.` on your commit is pre-commit
  taking their edits off disk.** It saves every unstaged change in the
  tree, theirs included, as a patch, runs `git checkout -- .`, runs the
  hooks, and applies the patch back, so for the hooks' seconds their
  files read as `HEAD`. A write of theirs in that window fails the commit
  as `files were modified by this hook` under whichever hook was running,
  though the hook passed; one that makes the patch conflict is discarded
  by a second `git checkout -- .`, under `Stashed changes conflicted with
  hook auto-fixes`, which names nothing of theirs. With a peer busy in
  the tree, commit from a throwaway worktree, whose index, HEAD and files
  are yours alone, and fast-forward the shared tree, where no hook runs.
  Stage the path first: `--ff-only` refuses an unstaged file as `Your
  local changes to the following files would be overwritten by merge`,
  even one already identical, and refuses once a peer's commit has moved
  `main`: branch again from the new `main` in the worktree and redo each
  commit, `git -C <wt> cherry-pick -n <sha>`, `git diff --cached`, then
  `commit -C <sha>`. Never `checkout <sha> -- <path>` there: that is your
  commit's whole file, built on the old `main`, so where their commit
  touched the same path, as one stamp manifest, it reverts their change
  and the fast-forward takes it (2026-10-13, read off its blob). The
  cherry-pick was run twice that day: the manifest auto-merged, and every
  peer stamp survived.
  When the shared copy also holds a peer's uncommitted
  edit beside yours, as one manifest several testers stamp at once does,
  `git diff --quiet` exits 1 with no output, and `git add` takes their
  edit too, which `--ff-only` refuses as above. Stage your commit's blob
  alone, `git update-index --cacheinfo <mode>,<blob>,<path>` with both
  read off `git ls-tree <branch> -- <path>`: an index already at the
  target lets the fast-forward through and leaves their edit on disk,
  unstaged. Tell this from their stash window by
  `git diff <branch> -- <path>`, which adds only their lines here and
  removes yours there (2026-10-13, git 2.55.0.windows.3, then both ways
  in a scratch repo). The route writes the index alone, so a change made
  only in the worktree, as a stamp run there, never reaches the shared
  copy: that diff then adds their lines *and* removes yours, and after
  the fast-forward the copy reads as reverting your commit, unstaged,
  for the next whole-file `git add` to commit, exit 0 throughout. Write
  your change into the shared copy, a stamp by re-running it there once
  the fast-forward lands (a manifest's `commit` field, 2026-10-23, then
  in a scratch repo). Copy nothing from the shared tree while a peer
  commits: a `cp` inside their stash window takes `HEAD`'s version, and
  the worktree's staged diff comes back empty, so write the edit into
  the worktree's copy instead, or carry one already made as a blob, from
  `git hash-object -w <path>` or, for one commit's share of a split
  file, the blob `stage-part.py` staged, `git rev-parse :<path>`. A
  blob equal to `HEAD:<path>`'s was read inside their window: take it
  again (six commits through two worktrees, 2026-10-13). The
  `git diff --quiet` before the
  fast-forward is the shared side's check: it refuses while their stash
  has your file reading as `HEAD`, the moment a fast-forward would fail
  their restore twice and leave their edits in the patch file alone.
  It cannot pass a file your commit adds, untracked here: `git diff`
  skips untracked files, so it reads the path as deleted, exit 1, every
  time. Check a new file with `diff -r <path> <scratch>/wt/<path>`
  before its `git add` instead (2026-10-23).
  The work itself never leaves the main checkout (pre-commit 4.6.2
  `staged_files_only.py`; the spurious failure, the clean restore, the
  empty copy and both refusals measured 2026-10-08, git
  2.55.0.windows.3; the rollback and the failed restore read, not run).
  **In a client repo, put the worktree under the repo**, at
  `.claude/worktrees/<dir>` where git ignores it, and read `<scratch>/wt`
  below as that path: an `identity-guard` hook, where installed, exempts
  a client root by its path, so from the scratchpad the repo's own names
  fail the commit as a leak, and `git worktree move` carries a staged
  index over intact. There a `shell-write-guard` hook, where installed,
  refuses the `cat-file blob >` line as a shell write inside a checkout:
  write the file with Write, then match
  `git hash-object <path>` against the blob (a client repo's session,
  each case run both ways, 2026-10-26).

  ```bash
  git worktree add -b <branch> <scratch>/wt HEAD   # then write your edit into <scratch>/wt/<path>
  git -C <scratch>/wt cat-file blob <sha> > <scratch>/wt/<path>   # or carry it as a blob, <sha> from git hash-object -w <path>
  git -C <scratch>/wt add <path> && git -C <scratch>/wt diff --cached   # your hunk alone; commit there
  git diff --quiet <branch> -- <path> && git add <path> && git merge --ff-only <branch>   # refuses mid-stash: retry
  git update-index --cacheinfo <mode>,<blob>,<path> && git merge --ff-only <branch>   # a peer's edit beside yours; <mode>,<blob> from git ls-tree
  git -C <scratch>/wt switch -c <branch>-2 main && git -C <scratch>/wt cherry-pick -n <sha>   # main moved: redo each commit, then commit -C <sha>
  git worktree remove <scratch>/wt && git branch -d <branch>   # a superseded <branch> takes -D
  ```
- **Record what you left.** Commit only what is yours, and name the
  deferred piece in the commit message so `git log` carries it rather
  than this conversation.

Staging one hunk out of a file they are also writing:
[concurrent-sessions.md](concurrent-sessions.md).
