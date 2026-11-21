#!/usr/bin/env bash
# Exit 0 only when every named session sits outside this working tree. Any
# doubt keeps it in.
#
# A `ListAgents` row is named `<cwd-basename>-<hash>`, or by `/rename`,
# `--name` or a hook, and no name says where its session sits: a basename
# reads the same for a clone elsewhere and differs for a subdirectory, and
# any other name can look like one. `land-branch` must not move HEAD
# under a session in this tree, and `commit-changes` counts one as a peer.
# Both ask this script.
#
# It reads the session registry never-prompted.sh reads,
# <config>/sessions/<pid>.json, which Claude Code writes and does not
# document: the one entry carrying the name, and its `cwd`, the session's
# working directory, which follows `EnterWorktree`. git gives the top level
# of that `cwd` and of the directory this runs in, and a name sits
# elsewhere when the two differ, or when git finds no repository at the
# `cwd`. A linked worktree has a top level of its own, even inside its main
# checkout. One directory has several spellings, so the two compare as git
# spells them, case-insensitively, or as one directory to bash.
#
# Every other outcome keeps the name in this tree and exits 1: no entry,
# two, a `cwd` missing, empty or of another type, a `cwd` git cannot read,
# an unreadable registry, no jq. A release that changes the format then
# costs a round with the user, never a switch under a real peer. No -e:
# each failure is caught where it happens, so every name still gets its
# line.
#
# Each doubt has a line of its own. No entry can be the caller's own slip:
# a name a hook sets, such as `brief: <slug> 2026-10-21 T08:53:42`, opens
# with what reads like a label and ends in its start time, and a probe arm
# passed such names as `<slug>` (2026-10-16). So that line names each
# entry whose name, less a trailing start time, is <name> or ends in
# ": <name>", for the next call to pass whole. It still exits 1, not 2,
# since a session that has exited leaves no entry either.
#
# A `ListAgents` row ends in a `[<ref>]` that is no part of the name, and
# the registry holds none (2026-10-26: three rows passed with it read as in
# doubt, the same names bare as elsewhere). So a name that finds no entry is
# looked up again less a trailing ` [<ref>]`, and the line keeps the name as
# passed. Whole first, in case a name ever ends that way itself.
#
# land-branch's references/never-prompted-sessions.md has the
# measurements behind each read, and this script's negative-case suite
# holds each case.
#
# <config> is $CLAUDE_CONFIG_DIR when set, as for Claude Code, else
# ~/.claude, and then each other directory the account map names, as
# never-prompted.sh reads them, since a peer under another account
# registers in its own.
#
# Usage, from inside the working tree, each <name> as a `ListAgents` row
# prints it, <skill-dir> the folder holding this skill's SKILL.md:
#   bash <skill-dir>/scripts/placed-elsewhere.sh <name>...
#
# stdout: one line per name. Exit 0 when every name sits elsewhere, 1 when
# any sits in this tree or is in doubt, 2 on a usage error.
set -uo pipefail

if [[ $# -eq 0 ]]; then
    echo "usage: placed-elsewhere.sh <name>..." >&2
    exit 2
fi

if ! command -v jq > /dev/null 2>&1; then
    echo "error: jq not found on PATH, so every session reads as in this tree" >&2
    exit 1
fi

if ! HERE=$(git rev-parse --show-toplevel 2> /dev/null); then
    echo "error: no git working tree here, so none to place a session against" >&2
    exit 2
fi

# A native jq.exe writes CRLF without -b, and Git Bash reports OSTYPE=cygwin.
JQ_BIN=()
case "$OSTYPE" in msys* | cygwin*) JQ_BIN=(-b) ;; esac

CONFIG_DIR=$HOME/.claude
if [[ -n ${CLAUDE_CONFIG_DIR:-} ]]; then
    CONFIG_DIR=$(cygpath -u "$CLAUDE_CONFIG_DIR" 2> /dev/null || printf '%s' "$CLAUDE_CONFIG_DIR")
fi

# Every config directory, this session's first; see the header.
CONFIG_DIRS=("$CONFIG_DIR")
MAP=${CLAUDE_ACCOUNTS_MAP:-$HOME/.config/claude-accounts.json}
if [[ -f $MAP ]]; then
    if listed=$(jq "${JQ_BIN[@]}" -r \
        'if .version == 1 then (.accounts // {})[] | .configDir | strings else error("version") end' \
        "$MAP" 2> /dev/null); then
        while IFS= read -r dir; do
            [[ -n $dir ]] || continue
            dir=$(cygpath -u "$dir" 2> /dev/null || printf '%s' "$dir")
            known=0
            for seen in "${CONFIG_DIRS[@]}"; do
                [[ ${seen,,} == "${dir,,}" ]] && known=1
            done
            ((known)) || CONFIG_DIRS+=("$dir")
        done <<< "$listed"
    else
        echo "warning: $MAP is no version 1 account map, so only $CONFIG_DIR is read" >&2
    fi
fi
# Each directory's registry entries, where it has any.
REGISTRY=()
shopt -s nullglob
for dir in "${CONFIG_DIRS[@]}"; do
    REGISTRY+=("$dir"/sessions/*.json)
done
shopt -u nullglob

# What the registry holds under $n, as "<entries carrying it><tab><detail>":
# for one, its `cwd` when that is a string; for none, a clause naming each
# entry whose name, less a trailing start time, is $n or ends in ": $n",
# shell-quoted, when any does; else nothing.
# shellcheck disable=SC2016 # $n and $e are jq variables
FILTER='
    [.[] | select(.name == $n)] as $e
    | "\($e | length)\t" + (
        if ($e | length) == 1 then
            $e[0].cwd | if type == "string" then . else "" end
        elif ($e | length) == 0 then
            [.[].name | select(type == "string"
                and (sub(" [0-9]{4}-[0-9]{2}-[0-9]{2} T[0-9]{2}:[0-9]{2}:[0-9]{2}$"; "")
                    | . == $n or endswith(": " + $n))) | @sh]
            | if length == 0 then ""
              elif length == 1 then "one is named \(.[0])"
              else "\(length) are named \(join(", "))" end
        else "" end)
'
TAB=$'\t'
RC=0

# kept <name> <text>: report the name as in this tree, and fail the run
kept() {
    printf '%s: %s\n' "$1" "$2"
    RC=1
}

# lookup <name>: the registry's answer in $got; fails when it did not read
lookup() {
    # With no file, jq would read stdin instead.
    ((${#REGISTRY[@]} > 0)) || return 1
    got=$(jq "${JQ_BIN[@]}" -r -s --arg n "$1" "$FILTER" "${REGISTRY[@]}")
}

REF_SUFFIX=' \[[0-9A-Za-z]+\]$'

for name in "$@"; do
    if ! lookup "$name"; then
        kept "$name" "in doubt, the session registry did not read"
        continue
    fi
    # A row as `ListAgents` prints it: retry less its ref, if the name found none.
    if [[ ${got%%"$TAB"*} == 0 && $name =~ $REF_SUFFIX ]]; then
        if ! lookup "${name%"${BASH_REMATCH[0]}"}"; then
            kept "$name" "in doubt, the session registry did not read"
            continue
        fi
    fi
    count=${got%%"$TAB"*}
    detail=${got#*"$TAB"}
    if [[ $count == 0 ]]; then
        kept "$name" "in doubt, no registry entry under this name${detail:+; $detail}"
        continue
    fi
    if [[ $count != 1 ]]; then
        kept "$name" "in doubt, $count registry entries under this name"
        continue
    fi
    cwd=$detail
    if [[ -z $cwd ]]; then
        kept "$name" "in doubt, its registry entry's cwd is missing, empty or of another type"
        continue
    fi
    # stderr stays out of $top: a warning printed beside a top level would
    # fail the compare below, and a failed compare places a session elsewhere.
    if ! top=$(git -C "$cwd" rev-parse --show-toplevel 2> /dev/null); then
        why=$(git -C "$cwd" rev-parse --show-toplevel 2>&1 > /dev/null)
        if [[ $why == *"not a git repository"* ]]; then
            printf '%s: elsewhere, cwd %s, in no git repository\n' "$name" "$cwd"
        else
            kept "$name" "in doubt, git could not read its cwd, $cwd"
        fi
        continue
    fi
    if [[ ${top,,} == "${HERE,,}" || "$top" -ef "$HERE" ]]; then
        kept "$name" "this tree, cwd $cwd"
    else
        printf '%s: elsewhere, cwd %s, top level %s\n' "$name" "$cwd" "$top"
    fi
done
exit "$RC"
