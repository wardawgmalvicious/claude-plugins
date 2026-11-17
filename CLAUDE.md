# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Claude Code plugin marketplace, `.claude-plugin/marketplace.json`,
named `wardawgmalvicious`, so each plugin installs as
`<plugin>@wardawgmalvicious`. Plugins go under `plugins/<name>/`, one
per audience, each listed in `README.md`'s table.

**The plugins are exported here from a private source repository**, and
each export overwrites what it ships. Never write a plugin's content
here by hand: a fix belongs in the source, and a contributor's accepted
pull request is ported back there by hand (`CONTRIBUTING.md`). Name no
source repository in a file here.

**Nothing carries a `version`**, neither a marketplace entry nor a
`plugin.json`, so installs track commits. Each plugin entry should list
its `skills` paths, which the second install route, `npx skills add`,
reads from the same file.

## Checks

```bash
claude plugin validate .
for plugin in plugins/*/; do claude plugin validate "$plugin"; done
pre-commit run --all-files
```

- **Never pass `--strict` to `validate`**: it fails every warning,
  among them the one for a plugin with no `version`, which the root
  reports once per plugin.
- On the root, `validate` reads only `marketplace.json`, hence the loop.
  CI's loop runs under `shopt -s nullglob`, so with no `plugins/` it
  runs zero times instead of once on the literal pattern.
- `pre-commit install --install-hooks` wires three git hooks: gitleaks
  on the staged diff, and `identity-guard` on the commit, its message
  and the push. `identity-guard` runs the maintainer's own scanner from
  the Claude Code config folder and passes silently where that is
  absent, as on a CI runner.

## CI

`.github/workflows/ci.yml` has two jobs, `plugins` and `pre-commit`.

- `plugins` installs Claude Code from `.github/plugin-validate/`'s
  lockfile, pinned to the version the source repository's CI validates
  with; raise both together.
- `pre-commit` runs gitleaks as its own step over every commit, since
  the hook scans only the index, empty in CI, then every other hook.
  `GITLEAKS_VERSION` and `GITLEAKS_SHA256` move together, and with the
  `rev:` in `.pre-commit-config.yaml`.
- **`uses:` lines keep their tags; `.github/workflows/actions.lock`
  pins each to a commit.** After changing a `uses:` line, run
  `gh actions-lock` and commit the lockfile, or the job fails for want
  of an entry.

## Visibility

The repo is **private** until the first export has been validated and
scanned; the switch to public is the owner's call. Don't change it, and
keep any employer, client or account name out of every file, commit
message and pull request: once public, history is permanent.
