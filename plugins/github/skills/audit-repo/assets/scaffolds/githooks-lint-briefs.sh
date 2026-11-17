#!/usr/bin/env bash
# The handoff queue's check for a repo whose core.hooksPath is set, where
# `pre-commit install` refuses and pre-commit-lint-briefs.yaml would be
# committed and never run. Copy it to the directory core.hooksPath names,
# as `pre-commit` (or call it from the one already there), and make it
# executable: `git update-index --chmod=+x <path>`.
#
# It runs the triage-inbox skill's handoff-status.py when a staged path,
# a deletion included, is under docs/handoffs/, since a landing whose only
# change is a deleted brief is the commit that strands a blocked-by.
# --no-inbox, or every other repo's inbox directory reads as an orphan. A
# clone without the skill or uv, a co-developer's, skips with a line and
# exit 0 rather than failing every commit. The script is a user-scope
# install's, in the Claude Code config folder, unless HANDOFF_STATUS_PY
# names another copy, such as a plugin's.
set -u

if ! git diff --cached --name-only | grep -q '^docs/handoffs/'; then
    exit 0
fi

script="${HANDOFF_STATUS_PY:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/triage-inbox/scripts/handoff-status.py}"
if [ ! -f "$script" ] || ! command -v uv > /dev/null; then
    echo "lint-briefs skipped, no uv or no triage-inbox skill at $script"
    exit 0
fi

exec uv run --no-project --quiet "$script" . --check --no-inbox
