# Before touching a brief

A brief is an issue on the repo's board, one unit of work, written so a
session with none of its writer's context can pick it up. `file-issue`
files it from a draft whose frontmatter becomes the card's fields, its
labels and its links, so the body restates none of them: edit the issue,
never a file. No file lists the queue; this prints it from the board:

```bash
uv run --no-project "${HANDOFF_STATUS_PY:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/triage-inbox/scripts/handoff-status.py}" . --no-inbox
```

| Draft key | Takes, and becomes on the board |
| --- | --- |
| `status` | `open` or `deferred`: Status Open or Deferred; In flight is a session's claim, and Done any close |
| `priority` | `1` now, `2` next, `3` later: Priority High, Medium or Low; Urgent is set by a person alone |
| `needs` | a list: `user`, `tenant` or a short phrase, an app as `<app> session` (`power-bi-desktop session`), each a `needs:<value>` label; `[]` when a session can act alone |
| `blocked-by` | a list of issue numbers, bare: `[62, 71]`, each a blocked-by link |
| `parent` | optional: the issue number it is a sub-issue of, bare |
| `reopen-when` | the trigger, Reopen-when; required when `deferred` |
| `written` | `YYYY-MM-DD`; the queue reads the issue's creation date |
| `work-model` | optional: `haiku`, `sonnet`, `opus` or `fable`, Work model |
| `work-effort` | optional: `low`, `medium`, `high`, `xhigh` or `max`, Work effort |
| `platform` | optional list, each lowercase kebab, as `power-bi`: its `platform:*` label, made at filing where the repo lacks it |

Each is `key: value` or `key: [a, b]`; YAML misreads a value opening with
a quote or backtick, or holding a colon before a space or `#` after one,
so an issue is `62`, never `#62`.

- **Work a brief in a worktree named after its subject**, never its
  number, its card claimed In flight first, since the board's Status is
  all the queue view reads for an issue. `work-issue` and
  `lead-sessions` do both.
- **A `needs:user` label is a question for the user**, not a call to
  make for them. A decision lands as yes, no or defer; a defer sets the
  card Deferred with its Reopen-when, and the issue stays open.
- **A brief's worktree lands from the main checkout, with no push**:
  rebase its branch on `main`, lint what it changed with
  `pre-commit run --from-ref main --to-ref HEAD` in the worktree,
  `git merge --ff-only` the branch from the main checkout,
  then remove the worktree and delete its branch. The user pushes.
  `lead-sessions` lands by this line, and stops in a repo that has none.
- **Landing closes the issue**: the commit that finishes its work says
  `Closes #<n>` on a line of its own, and the issue closes when that
  commit reaches the default branch. No commit closes a parent: where
  `.github/workflows/close-parent.yml` runs, it closes one with its last
  sub-issue, bar one labelled `standing`; elsewhere the user closes it
  once the queue view reads `all <total> sub-issues closed: close it`.
