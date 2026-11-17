# Contributing

**The plugins here are exported from a private source repository**, where
the skills are written. Each export overwrites what it ships, so a change
committed only here would be lost at the next one.

## How a change lands

- **Issues and pull requests are welcome.** An accepted change is ported
  back to the source by hand and reaches this repo in a later export;
  the pull request is then closed with a note saying which export
  carried it, rather than merged.
- **Keep a change to one plugin and one subject**, so it ports as one
  commit.
- **No version fields.** Plugins and their marketplace entries carry no
  `version`, so an install tracks commits; a pull request adding one is
  asked to drop it.

Follow the [code of conduct](CODE_OF_CONDUCT.md). Report a security hole
privately, as [SECURITY.md](SECURITY.md) says, never in an issue.

## Checks to run before a push

CI runs these on every push to `main` and every pull request:

```bash
claude plugin validate .
for plugin in plugins/*/; do claude plugin validate "$plugin"; done
```

Run `validate` without `--strict`, which turns every warning into a
failure, among them the one for a plugin with no `version`, which every
plugin here omits on purpose.

The repo keeps a [pre-commit](https://pre-commit.com/) baseline, which
scans each commit for secrets with gitleaks. Install it once per clone:

```bash
pre-commit install --install-hooks
```

Its `identity-guard` hooks run the maintainer's own scanner, and pass
without doing anything in a clone that lacks it.
