#!/usr/bin/env bash
# command-runner-write-scope.sh — PreToolUse hook (matcher "Write") that holds
# the command-runner subagent's Write tool to the session's scratchpad.
#
# Why: command-runner runs a named operation on a cheap model and reports its
# output; it decides nothing and edits no tracked file. It keeps Write for one
# job, a payload or query file a command reads (a request body, a .sql file),
# which a quoted heredoc can corrupt on this machine (~/.claude/CLAUDE.md
# § "Shell traps"). A Write anywhere else is out of its contract.
#
# Registered in the agent's own frontmatter (claude/agents/command-runner.md),
# not in settings.json, so it starts only for that agent's Write calls and
# costs every other session nothing; security-reviewer-memory-scope.sh is the
# settings.json shape, keyed by agent_type, which runs on every Edit and Write.
# A user-scope agent's frontmatter hooks need no workspace trust (subagent
# docs, read 2026-11-05).
#
# Installed as the github-issues plugin, which carries the agent for
# work-issue's landing runs, it takes that settings.json shape: a plugin
# agent's `hooks` field is ignored, so the plugin's hooks/hooks.json registers
# it on every Write, and with CLAUDE_PLUGIN_ROOT set it holds only an agent
# whose agent_type ends `:command-runner`, the plugin-scoped name, such as
# `github-issues:command-runner` (plugins and hooks docs, read 2026-11-20).
# The suffix outlasts a plugin's rename, and a bare `command-runner`, this
# setup's deployed agent, keeps its own frontmatter hook, so no Write is
# checked twice. jq comes from PATH, else from the toolchain plugin's data
# folder, as the guards find it.
#
# The allowed root is the input's `scratchpad_dir` (Claude Code 2.1.257 on),
# the session's own scratchpad, so no temp-folder layout is assumed. Both it
# and the target are compared in one form: on Windows each existing ancestor
# is expanded to its long name, since %TEMP% arrives as an 8.3 path (the
# profile folder as NAME~1) and the model may write either form, and `cygpath -l`
# expands only a path that exists (probed 2026-11-05); then lowercased, as
# NTFS compares. `..` is resolved first, so a path that climbs out is refused,
# and a path that resolves to nothing is refused too.
#
# Not held: Bash and PowerShell, which can write anywhere; the agent's body
# forbids that and auto mode's classifier reviews it. A junction or symlink
# inside the scratchpad that points elsewhere is followed by Write and not by
# this check.
#
# No `scratchpad_dir` refuses every Write. A `claude -p` session has no
# scratchpad, nor does one on an API key or another provider (claude-directory
# docs; print mode is missing from their list): 0 of 14 headless subagents
# carried one, against 234 of 234 interactive ones (transcripts, 2026-11-05).
# There it is the normal case, not a fault, and failing open let a cold
# probe's Write land outside any scratchpad.
#
# Exit codes: 0 allows; 2 refuses, its stderr read by the agent, naming the
# scratchpad, saying there is none, or saying a path could not be resolved
# (every Write on BSD or macOS, which lack GNU `realpath -m`); 1 when jq is
# missing or cannot read the input, or no bash 4.4 or later is on PATH,
# shown as a `hook error` notice while the Write proceeds: that crash fails
# open as the other guards do (claude/hooks/README.md).
# Its cases are in tests/hooks/, under its name.

# Started as `sh`: bash in POSIX mode under Git for Windows, but dash on
# Debian and Ubuntu and bash 3.2 on macOS, where what follows fails. So
# hand over, once, to the bash on PATH, in POSIX syntax, and stop where
# that is older than 4.4 too, as a check that never ran, as the guards do.
case ${BASH_VERSION:-} in
    '' | [0-3].* | 4.[0-3].*)
        if [ -z "${COMMAND_RUNNER_BASH:-}" ] && command -v bash >/dev/null 2>&1; then
            COMMAND_RUNNER_BASH=1
            export COMMAND_RUNNER_BASH
            exec bash "$0" "$@"
        fi
        echo "command-runner-write-scope: no bash 4.4 or later on PATH, so this Write was not checked." >&2
        exit 1
        ;;
esac

set -uo pipefail

# jq reads stdin, so bound it (coding-bash.md § "Claude Code hooks"): 126 and
# 127 are a timeout that could not run, 1 Windows' TIMEOUT.EXE; each retries
# bare jq, whose own errors never use them here.
jq_input() {
    local rc=0
    printf '%s\n' "$INPUT" | timeout 5 "$JQ" -r "$@" 2>/dev/null || rc=$?
    [ "$rc" -eq 1 ] || [ "$rc" -eq 126 ] || [ "$rc" -eq 127 ] || return "$rc"
    printf '%s\n' "$INPUT" | "$JQ" -r "$@" 2>/dev/null
}

unchecked() {
    echo "command-runner-write-scope: $1, so this Write was not checked." >&2
    exit 1
}

# canon <path>: one comparable spelling of a path, existing or not.
canon() {
    local p long rest=
    case "${OSTYPE:-}" in
        msys* | cygwin*)
            p=$(cygpath -m -a "$1" 2>/dev/null) || p=$1
            p=${p%/}
            while [ -n "$p" ] && [ ! -e "$p" ] && [ "${p%/*}" != "$p" ]; do
                rest="/${p##*/}$rest"
                p=${p%/*}
            done
            # A bare drive (`C:`) is drive-relative to cygpath, which would
            # print `<cwd>/C`: keep it as it is.
            case $p in
                [A-Za-z]:) ;;
                *) long=$(cygpath -m -l "$p" 2>/dev/null) && p=$long ;;
            esac
            p="${p%/}$rest"
            printf '%s' "${p,,}"
            ;;
        *)
            # Without GNU `realpath -m` (BSD, macOS) there is nothing to
            # resolve `..` with, so print nothing and let the caller refuse.
            p=$(realpath -m -- "$1" 2>/dev/null) || p=
            printf '%s' "${p%/}"
            ;;
    esac
}

INPUT=$(cat)

# jq from PATH, else in a plugin install the toolchain plugin's copy, whose
# PATH reaches the Bash tool but no other plugin's hook.
JQ=jq
if ! command -v jq >/dev/null 2>&1; then
    JQ=
    DATA=${CLAUDE_PLUGIN_DATA:-}
    DATA=${DATA//\\//}
    if [[ -n $DATA ]]; then
        for candidate in "${DATA%/}"/../toolchain-*/bin/jq.exe "${DATA%/}"/../toolchain-*/bin/jq; do
            [[ -x $candidate ]] && JQ=$candidate && break
        done
    fi
    [[ -n $JQ ]] || unchecked "jq is not on PATH, nor in the toolchain plugin's data folder"
fi

# A plugin's hook fires on every Write in the session: hold only the
# plugin's own agent, by its plugin-scoped name.
if [[ -n ${CLAUDE_PLUGIN_ROOT:-} ]]; then
    AGENT_TYPE=$(jq_input '.agent_type // empty') || unchecked "jq could not read the hook input (exit $?)"
    case $AGENT_TYPE in
        *:command-runner) ;;
        *) exit 0 ;;
    esac
fi

FILE_PATH=$(jq_input '.tool_input.file_path // empty') || unchecked "jq could not read the hook input (exit $?)"
SCRATCH=$(jq_input '.scratchpad_dir // empty') || unchecked "jq could not read the hook input (exit $?)"

# No path is no write to judge: the Write itself fails on it.
[ -n "$FILE_PATH" ] || exit 0
if [ -z "$SCRATCH" ]; then
    cat >&2 <<EOF
Blocked by command-runner-write-scope: this session has no scratchpad (a claude -p session has none), so this agent writes no file.
  attempted:  $FILE_PATH
Report the content to the caller instead, for it to write.
EOF
    exit 2
fi

ROOT=$(canon "$SCRATCH")
TARGET=$(canon "$FILE_PATH")

# An empty root would make the pattern below `/?*`, which allows any target:
# refuse instead (on POSIX, a scratchpad of `/`, which on Windows resolves to
# Git's install root; or a path no tool here could resolve).
if [ -z "$ROOT" ] || [ -z "$TARGET" ]; then
    cat >&2 <<EOF
Blocked by command-runner-write-scope: a path could not be resolved, so this Write was refused.
  scratchpad: $SCRATCH
  attempted:  $FILE_PATH
Report the content to the caller instead, for it to write.
EOF
    exit 2
fi

case "$TARGET" in
    "$ROOT"/?*) exit 0 ;;
esac

cat >&2 <<EOF
Blocked by command-runner-write-scope: this agent writes only inside the session's scratchpad.
  scratchpad: $SCRATCH
  attempted:  $FILE_PATH
Write the payload under the scratchpad instead, and edit no tracked file: report what needs changing to the caller.
EOF
exit 2
