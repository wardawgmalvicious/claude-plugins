# What reaches the gh wrapper

Behind step 2's second consequence: which callers a folder-scoped `gh`
wrapper catches, which fall through to the keyring's active account,
and the probe for the ones that fall through.

## Who misses the wrapper

**What reaches the wrapper depends on how it is built.** A shell
function is invisible to anything that execs `gh` — `timeout`, `env`,
`xargs`, a script. A wrapper file on `PATH` catches those unless a
`gh.exe` sits earlier on `PATH`, and never catches a native program,
which on Windows looks only for `gh.exe`. Whatever misses the wrapper
acts as the keyring's active account, so step 2's probe passes while
the action runs as someone else. On the machine this skill was written
for, the wrappers and the `GH_TOKEN` pin for a caller they cannot reach
are in its user-scope `CLAUDE.md` § "Git identity is folder-scoped";
elsewhere, set `GH_TOKEN` from `gh auth token --user <login>` for such a
caller (gh 2.104.0's `--help`, 2026-11-16).

## The native probe

A native caller acts as the account `gh.exe` reports with no token in
its environment. Run it as two plain commands: a worktree session's
guard refuses the one-line form, `"$(command -v gh.exe)"` where the
program stands, as "too complex to verify" (2026-11-06, 2.1.319).

```bash
command -v gh.exe                                              # <gh.exe>, its full path
env -u GH_TOKEN -u GITHUB_TOKEN <gh.exe> api user -q .login    # the keyring's active account
```

Compare its answer with the repo's owner, as step 2 compares its own
probe. On 2026-11-06, in a personal repo, the wrapper answered as the
personal account and this probe as a client one, on another machine,
taken to be the work one: the commits recording it reached the personal
machine only by a later pull. On the personal machine that evening both
answered as the personal account, its keyring's active one since
2026-11-02: the answer is the machine's, not the repo's.

## The Claude desktop app's PR tools

**The app's PR tools run on the machine's `gh`**: "PR monitoring
requires the GitHub CLI (`gh`) to be installed and authenticated on your
machine" (Claude Code docs, `desktop#monitor-pull-request-status`, read
2026-11-06), and one run's inference is that they act as the keyring's
active account, not the wrapper's. With the personal account active,
they could not see a PR the session had just opened in a client
organization's repo, while `gh pr view` through the wrapper read it as
`OPEN`:

- `get_status` reported its checks as `"error": "Not Found"`.
- `set_monitor`, behind Auto-fix, said it "is not bound to this
  session".
- `bind_pr` "could not read it as an open pull request (it may be merged
  or closed, not exist, or live on a host `gh` is not signed in to)".

**The failure reads as a missing PR, not a wrong account.** Seen once,
2026-10-25 (2.1.308), with the cause inferred from `gh auth status`.

**In a desktop session, run the native probe before turning on Auto-fix
or binding the PR**, and on a mismatch ask the user to run
`gh auth switch --user <account>`; never run it yourself. The active
account is machine-wide, so a switch moves every session's native
callers, the app's PR tools in other repos among them (the user's call,
2026-11-06).

**A switch alone did not fix it; one run after a launch worked.** After
the user switched, the native `gh.exe` read the PR as `OPEN`, yet
`bind_pr` failed the same way twice, a minute apart (2026-10-25). On
2026-11-06, with the native probe answering the repo's owner minutes
after the app's launch, its tools read a PR the session had just opened
in a personal repo, a throwaway PR opened for the test: after
`gh pr create` an Auto-fix event arrived and `get_status` read
`bound: true` with its state and checks before any `bind_pr` call, and
`bind_pr` answered "Restored" after an `unbind_pr` (desktop 4.23118).
That repo had no earlier failure to clear, so whether a restart is what
separates the two runs is unchecked, as are the cause (an identity
resolved at launch, the app's own `GH_TOKEN` or `PATH`, a cached
failure) and a client organization's repo. After a switch, ask the user
to restart the app before binding, the one remedy not yet tried.
