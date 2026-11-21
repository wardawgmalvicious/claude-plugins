#!/usr/bin/env bash
# side-session-guard.sh — PreToolUse hook (matcher
# "mcp__ccd_session__start_session"): refuse a Claude desktop side session
# whose start leaves its worktree's base to the app, and point the starting
# session at the hand-back protocol.
#
# Why: on 2026-11-20 a desktop session in a client repo started two side
# sessions with no `source_branch`. The app cut each worktree from a local
# `main` at least 26 commits behind the parent's HEAD, the remote's default
# being another branch, and each child read that `main`'s CLAUDE.md and rules. Neither brief carried a way to hand the
# branch back, so each child pushed and merged its own pull request while the
# parent reviewed ranges that moved under it. The parent ran no skill, so no
# skill's text could reach it, and a rule loaded at launch would cost every
# session: the tool call is the one moment every such parent passes (the
# user's pick, 2026-11-20). A correction sent after the start waits for the
# child's turn to end, so the start itself has to be right.
#
# What it decides, from the call's own input:
#   - `use_worktree` false: allowed, in silence. The child starts in the
#     parent's checkout, as work-issue's references/side-session.md starts one.
#   - a `source_branch` that names a branch, with a brief that says how the
#     branch lands: allowed, in silence. The brief says so by `landReady`, the
#     mark the hand-back block names; by `audit-session.md`, the file a drift
#     audit's child reads to hand its branch to a lead; or by `no hand-back`,
#     for a child the user asked to land its own work.
#   - a `source_branch` and no such brief: exit 2, naming the protocol to
#     Read first. A parent that named the base may still have briefed no
#     hand-back, and context handed back with the tool's result would come
#     after the child had started, when a message can no longer reach it
#     before it commits.
#   - anything else, a start that names neither among them: exit 2, telling
#     Claude both ways through and naming the protocol to Read first. Whether
#     the app makes a worktree when `use_worktree` is left out is not known
#     here, so such a call is asked to say which it means: one more call.
#
# The protocol is work-issue's references/hand-back.md, named by a path the
# refused session can Read from any repo: the plugin's own folder under
# CLAUDE_PLUGIN_ROOT, else the account's config directory, as lead-edit-guard
# finds its file.
#
# A plugin's copy stands down beside this setup's own. The github-issues
# plugin carries one, and a hook in both a settings file and a plugin's
# hooks.json runs twice per event (plugins docs, "Convert an existing
# .claude/ setup", read 2026-11-20), which here is one start refused twice.
# So a run with CLAUDE_PLUGIN_ROOT set, which Claude Code exports to a
# plugin's hooks alone, exits 0 in silence where
# `<config>/hooks/side-session-guard.sh` exists, before it checks anything.
# The file stands for its registration, which this hook does not read: a
# copy deployed there and registered nowhere turns the plugin's off too, and
# every start then passes unchecked.
#
# Parsing: bash's own regex, no jq, so the hook starts nothing. A key's text
# inside the prompt cannot match: a quote inside a JSON string reaches here
# escaped, so `"use_worktree"` there reads `\"use_worktree\"`, whose closing
# quote follows a backslash and never the key.
#
# Unseen: a session the user starts from the app's own controls or a
# suggested task's Options, which call no tool, and a child told the wrong
# thing in a brief that names both fields.
#
# Not measured: whether Claude Code starts a PreToolUse hook for this tool at
# all. A matcher naming Claude Desktop's terminal tool fired in a desktop
# session on 2026-11-14 (2.1.321); this one waits for a desktop probe.
#
# Exit codes: 0 allows; 2 refuses, its stderr read by Claude; 1 when the input
# was empty, shown as a `hook error` notice while the start proceeds. It fails
# open, on the entry's default: this guards a habit, not a leak, so a broken
# hook must not stop every side session. No `set -e`: each failure path says
# so. Its cases are a suite kept with its source, under its name.

set -uo pipefail

IFS= read -r -d '' INPUT || true

# A plugin's copy, beside this setup's deployed one: that one checks.
[[ -n ${CLAUDE_PLUGIN_ROOT:-} && -f ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/side-session-guard.sh ]] && exit 0

[[ -n $INPUT ]] || {
    echo "side-session-guard: the hook input was empty, so this start_session call was not checked" >&2
    exit 1
}

# The matcher names the one tool; this holds a matcher widened by mistake.
RE='"tool_name"[[:space:]]*:[[:space:]]*"mcp__ccd_session__start_session"'
[[ $INPUT =~ $RE ]] || exit 0

RE='"use_worktree"[[:space:]]*:[[:space:]]*false'
[[ $INPUT =~ $RE ]] && exit 0

# The protocol's path, separators as "/".
if [[ -n ${CLAUDE_PLUGIN_ROOT:-} ]]; then
    REF=$CLAUDE_PLUGIN_ROOT
else
    REF=${CLAUDE_CONFIG_DIR:-}
    # shellcheck disable=SC2088 # a path for Claude to read, not for this shell
    [[ -n $REF ]] || REF='~/.claude'
fi
REF=${REF//\\//}
REF=${REF%/}/skills/work-issue/references/hand-back.md

RE='"source_branch"[[:space:]]*:[[:space:]]*"[^"]+"'
if [[ $INPUT =~ $RE ]]; then
    [[ $INPUT != *landReady* && $INPUT != *audit-session.md* && $INPUT != *'no hand-back'* ]] || exit 0
    printf '%s\n' "side-session-guard: not started. This worktree start names its base, but its brief says nothing of how the branch lands, and a message sent after the start reaches the child only once its turn ends. Read $REF, put its hand-back block in the prompt, and start again: the child then commits on its own branch, marks it landReady and pushes nothing, and the session the user started lands it. A drift audit's brief, which names audit-session.md, passes as it is. Where the user asked for a child that lands its own work, write no hand-back in the brief, and it passes." >&2
    exit 2
fi

printf '%s\n' "side-session-guard: not started. This start_session call names neither a source_branch nor use_worktree false, so the app would pick the worktree's base, which can be a stale local default branch whose instructions the child then reads. To start the child in this checkout, pass use_worktree false. For a worktree, pass use_worktree true, a branch_name, and source_branch set to the branch that git ls-remote --symref origin HEAD names. A side session in a worktree, with no board issue, also hands its branch back: Read $REF first, its section on the parent's start, and put its hand-back block in the prompt, so the child commits on its own branch, marks it landReady and pushes nothing, and the session the user started lands it." >&2
exit 2
