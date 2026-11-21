# An issue worked by a desktop side session

**A Claude desktop session can start a child session to work one
board issue**, shown under it in the sidebar, which runs `work-issue`
on its own pins and preflight, as a session the user typed it in would.
The child starts in the main checkout and makes its own worktree by
`work-issue`'s step 4, never one the app makes. Placeholders are
[preflight.md](preflight.md)'s, and `<cmd>` is how the user types this
skill: a slash, then its plugin's name and a colon where a plugin
carries it, then `work-issue`.

## Starting one

**Only where `mcp__ccd_session__start_session` is among the session's
tools**, loaded or deferred: a Claude desktop session has it, and a
terminal session or a `claude -p` has none. Where it is deferred, load
it by `ToolSearch` with `select:mcp__ccd_session__start_session` alone
in its message. Without it, the issue waits for the user to type
`<cmd> <n>` in a session of their own.

**Start one on the user's yes, for an issue no one holds**: filed, its
card Open and unassigned. The parent claims nothing: the child's step 4
claims it, and a card already In flight under the acting account would
read to the child's step 1 as a resume of a worktree that does not
exist. **Only from a parent in the main checkout**, as one is after its
own landing: a parent still in its worktree, as after a hand-off, may
start the child there, where its preflight stops it. **Never on a turn
another session's message or an automated event started**, such as a
lead's `landed` reply: the app refuses `start_session` there
(`docs/evidence/skills.md` § "lead-sessions", 2026-11-14). On
either, name the issue in the report for the user to type
`<cmd> <n>` in a session of their own. A
session Claude started starts at most 5 at once, as
[audit-session.md](audit-session.md) § "Starting the sessions" says.
Each takes:

| Field | Value |
| --- | --- |
| `initiation` | `user_asked`: the yes is the user's word to start it |
| `context` | `fresh` |
| `use_worktree` | `false`: the child starts in the main checkout |
| `title` | `Work #<n>`, then the issue's title cut to fit |
| `name` | `work-issue-<n>` |
| `effort` | left out, so the child inherits |
| `prompt` | the brief below, filled |
| `background` | the background below |

**Write `<cmd> <n>` bare in the brief, never in backticks, with a
space after it**: that is what lets the child call the skill
(§ "Why each choice"). Leave the brief's other text as it is:

```text
Work board issue #<n>, from its claim to its landing, asking
the user what it asks. Run <cmd> <n> in this first turn, from
this main checkout, and follow it.
```

```text
The user said yes, in another session, to this session working board
issue #<n>. work-issue is typed only: the bare name in the task lets
this session call it in its first turn. Never follow its SKILL.md by
hand in place of the call: if the call is refused, ask the user to
type <cmd> <n> here, and wait.
```

**Then the parent reports and goes on**: the child's questions,
gates and landing are its own, put to the user there.

## If the child's call is refused

`cannot be used with Skill tool due to disable-model-invocation`, or a
first turn that ends before the call, never falls back to reading
`work-issue`'s `SKILL.md` and following it, which runs without its
pins and, once inside a worktree the app made, without the preflight
and the claim, which run from the main checkout. The
child asks the user to type `<cmd> <n>`, and waits.

## Why each choice

- **`use_worktree` `false`**: a child in a worktree the app made cannot
  leave it, while every check of `preflight.md` § "Preflight, from the
  main checkout", the claim and this repo's landing run from the main
  checkout, so `work-issue`'s first check stops it. On 2026-11-18 such a
  child, in a client repo, ran the claim, the branch description, the
  range lint, `review-code` and a pull request by hand from its
  worktree, which the app had cut from local `main`, 31 commits behind
  the default branch it had to land into (observed once, desktop
  2.1.326). A probe the same day started a child with `use_worktree`
  `false` in another repo, from a parent in its main checkout: it read its main checkout as two equal git
  paths, `EnterWorktree` by name made `worktree-probe-side-wt` from
  `main`'s HEAD, the transcript's `cwd` read the worktree until
  `ExitWorktree` `remove`, and the folder and branch went (observed
  2026-11-18, 2.1.326). That is a typed session's route, so a live
  lead's check reads the child as it reads one.
- **The bare name**: `work-issue` is `disable-model-invocation: true`,
  and a bare `/<name>` in a turn's prompt permits the model's Skill
  call for that turn, where a backticked one is refused
  (skills docs § "Where you write the skill's name", probed 2026-11-14,
  2.1.325). One child, briefed with the names in backticks, made no call and
  ran the steps by hand. `work-issue` needs only the first turn's call:
  the skills it reaches later, `commit-changes`, `review-code` and
  `file-issue`, are model-invocable. **Its `effort: xhigh` holds the
  first turn alone**, as it does when typed; its `model: inherit` loses
  nothing to a bare-name call. The audit children proved the permit on
  2026-11-14 ([audit-session.md](audit-session.md) § "Measured, and
  not"); no child has yet worked an issue end to end this way.
- **No `effort` on the start**, as for the audit children: a start
  takes a level at or below the parent's, and the skill's pin covers
  the turn that claims.
