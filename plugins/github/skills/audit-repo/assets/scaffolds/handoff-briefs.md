---
paths:
  - "docs/handoffs/**"
---

# Before touching a brief

A brief, a file in `docs/handoffs/execute/`, is one unit of work,
written so a session with none of its writer's context can pick it up.
Its frontmatter is its whole state, and its body restates none of it.
No file lists the queue; this prints it from the briefs:

```bash
uv run --no-project "${HANDOFF_STATUS_PY:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/triage-inbox/scripts/handoff-status.py}" . --no-inbox
```

The `lint-briefs` pre-commit hook runs the same script with `--check`, and
fails a commit on a bad value, a brief with no frontmatter, or a
`blocked-by` naming a brief that is gone.

| Key | Takes |
| --- | --- |
| `status` | `open` or `deferred`; landing deletes the brief |
| `priority` | `1` now, `2` next, `3` later; no order within one |
| `needs` | a list: `user`, `tenant` or a short phrase, an app as `<app> session` (`power-bi-desktop session`); `[]` when a session can act alone |
| `blocked-by` | a list of brief filenames in `execute/`, bare: `[a.md, b.md]` |
| `reopen-when` | the trigger; required when `deferred` |
| `written` | `YYYY-MM-DD` |
| `work-model` | optional: `haiku`, `sonnet`, `opus` or `fable` |
| `work-effort` | optional: `low`, `medium`, `high`, `xhigh` or `max` |
| `platform` | optional list, each lowercase kebab, as `power-bi`: its `platform:*` label, made at filing where the repo lacks it |

Each is `key: value` or `key: [a, b]`; YAML misreads a value opening with
a quote or backtick, or holding a colon before a space or `#` after one.

- **Work a brief in a worktree named after it**, its filename less
  `.md`, which the queue view marks in flight while that worktree
  exists. `lead-sessions` names its workers' so.
- **`needs: [user]` is a question for the user**, not a call to make for
  them. A decision lands as yes, no or defer; a defer keeps the brief,
  `deferred` with its `reopen-when`.
- **A brief's worktree lands from the main checkout, with no push**:
  rebase its branch on `main`, lint what it changed with
  `pre-commit run --from-ref main --to-ref HEAD` in the worktree,
  `git merge --ff-only` the branch from the main checkout,
  then remove the worktree and delete its branch. The user pushes.
  `lead-sessions` lands by this line, and stops in a repo that has none.
- **Landing deletes the brief** in the commit that finishes its work:
  drop its name from every `blocked-by`, and re-point what linked to
  it.
- **A filename is a link target**, so it carries no date or number.
