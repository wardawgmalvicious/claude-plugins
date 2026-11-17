# claude plugin eval

Testing whether a plugin's own skills change what Claude does. Read
2026-10-22 from code.claude.com's `plugin-evals` and `plugins/cli-reference`,
against Claude Code 2.1.308; `claude plugin eval` needs 2.1.269 or
later, and git 2.31 or later when git is installed. First run against
the user's own plugins on 2026-11-14, this repo's `admin` and
`essentials` suites: three cases, 18 runs, $2.26, from the PowerShell
tool with `--trust-plugin` (observed 2026-11-14, 2.1.325).

## The suite

```text
evals/
├── <case>/
│   ├── prompt.md         # frontmatter: case and run fields; body: the prompt, sent as written
│   ├── case.yaml         # optional: context.* fields, or the whole case
│   ├── graders/<name>.md # one grader per file; at least one per case
│   └── mocks/            # optional: this case's mocks, overriding the suite's file by file
├── mocks/<server>/
│   ├── <tool>.md         # one mocked tool; body: what the tool returns
│   ├── _server.md        # optional: one agent answering several tools
│   └── _tools.json       # optional: the real tools/list, for real schemas
└── results/<timestamp>/  # written by each run: gitignore it
```

- **`claude plugin eval init`**, from the plugin root, interviews the user
  and writes the cases; inside a Claude Code session it prints the
  interview for that session to follow. `--bare <name>` writes a blank
  case instead, and is the only form without a terminal.
- **The directory moves** with `"experimental": { "evals": "<dir>" }` in
  `plugin.json` or `--eval-dir`, a plain relative path.
- **A case is a directory holding `prompt.md` or `case.yaml`**; one with
  no grader fails to load, naming `graders`.
- **`context.scaffold_script` runs only under `--scaffold`**: a Bash
  script in the case directory, run as the user and outside the run's
  sandbox, so pass the flag only for a suite the user or their
  organization wrote. A script that exits non-zero or runs past 120
  seconds scores that run 0 with `scaffold failed` (plugin-evals, read
  2026-11-07).
- **A `context.history_file` case on a path target runs one arm** by
  default, as the recorded conversation is taken to reflect the plugin,
  and stderr names it `single-arm (no Δ)`; `--ablation with-without`
  compares the resumed turn with and without the plugin (plugin-evals,
  read 2026-11-07).

`prompt.md` frontmatter rejects an unknown key. The fields most cases
set:

| Field | Default | Purpose |
| --- | --- | --- |
| `runs` | `3` | runs per arm, 1 to 50 |
| `max_turns` | `10` | turn cap, up to 200; hitting it is a run error |
| `timeout_seconds` | `300` | wall clock per run, up to 3600 |
| `allowed_tools` | `[]` | read-only tools the case may use, such as `[Read, Glob, Grep, Skill]` |
| `plugins` | the nearest enclosing plugin | set `["../.."]` when the run finds no plugin |
| `env` | `{}` | keys must match `EVAL_[A-Z0-9_]*` |

## Graders

| Type | Passes when | Costs a judge call |
| --- | --- | --- |
| `regex` | the JavaScript pattern is found in its `target` | no |
| `tool_used` | calls to `tool`, filtered by `input_match`, number between `min` and `max` | no |
| `tool_order` | the first `before` call precedes the first `after` call | no |
| `file_exists` | a file the run created matches the `path` glob | no |
| `llm` | the judge passes the rubric in two of three votes | yes |
| `baseline` | the judge rates the run at least as good as a reference `.jsonl` | yes |

- **The judge is the background-tasks model** unless `--judge-model`.
- **Pair two graders per case**: one on the result, one on the steps,
  such as `tool_used` with `tool: Skill`.
- **A two-arm run leaves three kinds of grader out of the score**, each
  one the without-arm could never pass, bar the last, which the author
  chooses: a `tool_used: Skill` grader; a `regex` grader on `target:
  mock_calls` or an `llm` grader on `focus: mock_calls`, when every
  mocked server in the case is the plugin's own; and any grader marked
  `arm: with-only`. Each shows as an indicator. **A case whose every
  grader is one of these scores them all normally.** `arm: both` scores
  one anyway, which a "must not invoke the skill" check with `min: 0`
  and `max: 0` wants. **`--ablation none` leaves out nothing**, so one
  suite can score differently in the two modes (plugin-evals, read
  2026-11-07).
- **The commonest first finding is `Δ` near zero with the `Skill` grader
  failing**: Claude does not pick the skill on natural phrasing, so
  rework its `description`.
- **A `regex` grader meant for the inside of a fenced block pairs the
  fences from the reply's start**, with `flags: m`, `match:
  not_contains` and `<term>` the text the block must not hold:

  ```text
  (?<![\s\S])(?:(?:(?!^`{3})[\s\S])*^`{3}[^\n]*\n(?:(?!^`{3})[\s\S])*^`{3}[^\n]*\n)*(?:(?!^`{3})[\s\S])*^`{3}[^\n]*\n(?:(?!^`{3})[\s\S])*?<term>
  ```

  One that starts at an opening fence carrying a language tag passed
  every baseline run: they opened the block with a bare ```` ``` ````,
  so facts left in the block scored as a pass, which only a
  `--keep-temp` run's `trace.jsonl` showed, since `report.html` keeps no
  reply. It scopes every fenced block at column 0, not only the last: a
  block indented under a list item is skipped, so a term in it passes;
  a fence nested inside a block, or a column-0 block's closing fence
  indented, breaks the pairing; and a reply with no fence passes, as
  nothing is scoped (observed 2026-11-14, 2.1.325).

## Mocks

A run never starts the plugin's real MCP servers unless asked. Each
server is replaced under its own name; a tool with a file under
`mocks/<server>/` answers from it, needing no grant, and a tool without
one is not available to Claude.

| Mock key | Default | Purpose |
| --- | --- | --- |
| `type` | `fixed` | `fixed` returns the body; `agent` has the judge model answer from the body's instructions |
| `expect` | unset | input guards by dotted path; a violation aborts the run at score 0 |
| `error` | `false` | `fixed` only: return the body as a tool error |
| `abort_when` | unset | `agent` only: when the agent may abort the run |

The body takes `{{input.<field>}}` and `{{file:fixtures/<name>}}`
substitutions. Agent-mock answers from clean runs land in
`results/<timestamp>/mock-recordings/`; copying one into
`mocks/.replay/<server>/`, as its `ADOPT.txt` says, replays it with no
model call.

`--allow-real-servers` starts the real process for unmocked servers, and
`--mocks off` ignores every mock. Either way the server runs as the user,
outside the run's sandbox, and its tools need an `--allow-tools` grant
such as `"mcp__plugin_<plugin>_<server>__*"`.

## Running it

| Option | Default | Effect |
| --- | --- | --- |
| `--runs <n>` | each case's `runs`, else 3 | runs per case per arm |
| `-j`, `--concurrency <n>` | `1` | up to this many runs at once, 1 to 8; they share the account's rate limit, so this cuts wall-clock time, never lifting throughput past it |
| `--model <model>` | each case's `model`, else `ANTHROPIC_MODEL`, else Claude Code's default | the model under test; pin it in CI, so a model rollout is not read as a plugin regression |
| `--ablation <mode>` | decided per case | `none` runs the with-plugin arm only, half the cost |
| `--threshold <0..1>` | `1.0` | a case passes at a with-arm score of at least this; one below exits 1 |
| `--case <glob>` | all | filter cases by name |
| `--tag <tag...>` | all | keep cases with any of the tags |
| `--max-cost-usd <usd>` | no ceiling | a list-price ceiling checked before each run; runs already started finish, so spend can pass it; exit 2 |
| `--allow-tools <tools...>` | none | grants beyond the read-only set, for every case |
| `--scaffold` | off | run each case's `scaffold_script` |
| `--trust-plugin` | off | skip the trust prompt, for a plugin the user would run |
| `--mocks <mode>` | `record` | `off` ignores every mock and starts the plugin's real servers |
| `--output-dir <dir>` | `<eval dir>/results/<timestamp>/` | where `aggregate-result.json` and `report.html` go |
| `--keep-temp` | off | keep each run's sandbox directory and print its path |
| `--no-publish` | | keep the report local |
| `--publish-report` | | publish where the report would stay local, as when Claude started the run |
| `--json [path]` | off | the result document; quiet run |

The rows from `-j` to `--keep-temp` are from plugin-evals, read
2026-11-07. `claude plugin eval --help` lists every option, among them
`--eval-dir`, `--no-scaffold`, `--report` and `--verbose`.

- **Put the target first**: `--tag`, `--allow-tools` and `--json` read a
  following target as their own value.
- **Granting Bash or PowerShell needs a sandbox backend.** Native Windows
  has none, so each run is refused and scores 0: run shell-granting
  suites under WSL2.
- **Iterate cheaply** with `--case <name> --runs 1 --ablation none`, and
  confirm a change at the default three runs. The two modes' absolute
  scores can differ, since `--ablation none` scores every grader: set a
  confirming run beside an earlier run in its own mode.
- **The trust prompt's yes reaches past the run**: inside a git
  repository it trusts the whole repository, for interactive sessions
  too, and a yes already given there in an interactive session skips
  the prompt. A target named rather than given as a path, an installed
  plugin or a skills-directory plugin, skips it as well (plugin-evals,
  read 2026-11-07).
- **Isolation**: each run gets a temporary home, workspace and config, as
  a `claude -p` child with only the plugin loaded. No user settings,
  hooks, `CLAUDE.md`, MCP servers, memory or other plugins load, the
  Artifact tool is off, and the run cannot read the eval directory.
- **Publishing**: signed in to a claude.ai plan with artifacts, a run from
  the user's shell publishes the report as a private artifact and prints
  `Published:`; a run a Claude Code session started prints `kept local`.

| Exit | Meaning |
| --- | --- |
| `0` | every case met `--threshold` |
| `1` | a case below threshold, a load error, no cases, an untrusted directory, an API error, an invalid option |
| `2` | partial: the cost ceiling, or a rejected credential |
| `130`, `143` | interrupted, terminated |
