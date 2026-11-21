#!/usr/bin/env bash
# Exit 0 only when every named session reads as never prompted. Any doubt
# reads as live.
#
# `ListAgents` lists a Claude Code process nobody has typed into exactly as
# it lists a working peer: the VS Code extension can leave one running
# that the user does not know is there (2026-09-30). `land-branch` must
# not move HEAD under a live session, and `commit-changes` must not
# message one that was never prompted, since the message would prompt it.
# Both ask this script.
#
# It reads two things Claude Code writes and does not document: the
# session registry, <config>/sessions/<pid>.json, and the transcripts,
# <config>/projects/**/<sessionId>.jsonl. A name passes when exactly one
# registry entry carries it, that entry is still `idle` with `updatedAt`
# under 1000 ms after `startedAt`, and a transcript lookup that ran found
# nothing. Every other outcome reads as live and exits 1: no entry, two, a
# field missing or of another type, an unreadable file or directory, a
# transcript, no jq. A release that changes the format then costs a round
# with the user, never a switch under a real peer. No -e: each failure is
# caught where it happens, so every name still gets its line.
#
# No entry, two, and one not still idle from its start each have a line of
# their own, and the first names each entry whose name, less a trailing
# start time, is <name> or ends in ": <name>": a name passed short finds
# no entry, and placed-elsewhere.sh has why.
#
# A `ListAgents` row ends in a `[<ref>]` that is no part of the name, and
# the registry holds none, so a name passed whole found no entry and a
# session never prompted read as live, to be messaged (2026-11-06).
# So a name that finds no entry is looked up again less a trailing
# ` [<ref>]`, as placed-elsewhere.sh does, and the line keeps the name as
# passed. Whole first, in case a name ever ends that way itself.
#
# land-branch's references/never-prompted-sessions.md has the
# measurements behind each read, and this script's negative-case suite
# holds each case.
#
# <config> is $CLAUDE_CONFIG_DIR when set, as for Claude Code, else
# ~/.claude, and then each other directory the account map names,
# $CLAUDE_ACCOUNTS_MAP or else ~/.config/claude-accounts.json: a login is a
# config directory, so a peer under another account registers in its own
# (the claude-accounts.md rule of the repo this skill is authored in). A map
# of another version adds none and says so on stderr.
#
# Usage, each <name> as a `ListAgents` row prints it, <skill-dir> the folder
# holding this skill's SKILL.md:
#   bash <skill-dir>/scripts/never-prompted.sh <name>...
#
# stdout: one line per name. Exit 0 when every name passes, 1 when any
# reads as live, 2 on a usage error.
set -uo pipefail

if [[ $# -eq 0 ]]; then
    echo "usage: never-prompted.sh <name>..." >&2
    exit 2
fi

if ! command -v jq > /dev/null 2>&1; then
    echo "error: jq not found on PATH, so every session reads as live" >&2
    exit 1
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
# Each directory's registry entries and transcript folder, where it has
# them: a directory no session has run under yet holds neither.
REGISTRY=()
PROJECTS=()
shopt -s nullglob
for dir in "${CONFIG_DIRS[@]}"; do
    REGISTRY+=("$dir"/sessions/*.json)
    [[ -d $dir/projects ]] && PROJECTS+=("$dir/projects")
done
shopt -u nullglob

# What the registry holds under $n, as "<entries carrying it><tab><detail>":
# for one still idle and touched under a second after its start,
# "<sessionId> <pid> <minutes since its start> <ms from start to updatedAt>
# <entrypoint>", where a field missing or of another type selects nothing;
# for none, a clause naming each entry whose name, less a trailing start
# time, is $n or ends in ": $n", shell-quoted, when any does; else nothing.
# shellcheck disable=SC2016 # $n, $e and $d are jq variables
FILTER='
    [.[] | select(.name == $n)] as $e
    | "\($e | length)\t" + (
        if ($e | length) == 1 then
            ($e[0]
            | select(.status == "idle"
                and (.sessionId | type) == "string"
                and (.startedAt | type) == "number"
                and (.updatedAt | type) == "number")
            | (.updatedAt - .startedAt) as $d
            | select($d >= 0 and $d < 1000)
            | "\(.sessionId) \(.pid) \((now - .startedAt / 1000) / 60 | floor) \($d) \(.entrypoint)"
            ) // ""
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
UUID='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
RC=0

# live <name> <why>: report the name as live, and fail the run
live() {
    printf '%s: live, %s\n' "$1" "$2"
    RC=1
}

# lookup <name>: the registry's answer in $got; fails when it did not read
lookup() {
    # No entry at all is a registry that did not read: with no file, jq
    # would read stdin instead.
    ((${#REGISTRY[@]} > 0)) || return 1
    got=$(jq "${JQ_BIN[@]}" -r -s --arg n "$1" "$FILTER" "${REGISTRY[@]}")
}

REF_SUFFIX=' \[[0-9A-Za-z]+\]$'

for name in "$@"; do
    if ! lookup "$name"; then
        live "$name" "the session registry did not read"
        continue
    fi
    # A row as `ListAgents` prints it: retry less its ref, if the name found none.
    if [[ ${got%%"$TAB"*} == 0 && $name =~ $REF_SUFFIX ]]; then
        if ! lookup "${name%"${BASH_REMATCH[0]}"}"; then
            live "$name" "the session registry did not read"
            continue
        fi
    fi
    count=${got%%"$TAB"*}
    detail=${got#*"$TAB"}
    if [[ $count == 0 ]]; then
        live "$name" "no registry entry under this name${detail:+; $detail}"
        continue
    fi
    if [[ $count != 1 ]]; then
        live "$name" "$count registry entries under this name"
        continue
    fi
    if [[ -z $detail ]]; then
        live "$name" "its registry entry is not still idle from its start"
        continue
    fi
    read -r sid pid minutes delta entrypoint <<< "$detail"
    # A UUID, so the lookup below can match no other session's transcript.
    if [[ ! $sid =~ $UUID ]]; then
        live "$name" "its sessionId is not a UUID"
        continue
    fi
    if ((${#PROJECTS[@]} == 0)) ||
        ! transcript=$(find "${PROJECTS[@]}" -name "$sid.jsonl" -print -quit); then
        live "$name" "the transcript lookup failed"
        continue
    fi
    if [[ -n $transcript ]]; then
        live "$name" "it has a transcript"
        continue
    fi
    printf '%s: never prompted, pid %s, %s, started %s min ago, updatedAt %s ms after start, no transcript\n' \
        "$name" "$pid" "$entrypoint" "$minutes" "$delta"
done
exit "$RC"
