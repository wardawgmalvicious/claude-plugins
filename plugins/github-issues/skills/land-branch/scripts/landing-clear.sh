#!/usr/bin/env bash
# Exit 0 only when fast-forwarding this checkout to <tip> harms no session in
# it, and 3 when it costs one only a stale view, for the caller to land and
# tell it. Any doubt holds the landing.
#
# WHY NOT PLACEMENT ALONE: placed-elsewhere.sh says where a session sits, never
# what a move would cost it, so an idle report held every landing until the
# user closed it (2026-10-29, 2026-10-30). A fast-forward costs an idle session
# only its memory of the files that changed, and git refuses one that would
# overwrite an uncommitted file, so what a session can lose is narrower than
# where it sits:
#
#   elsewhere          clear: it has its own HEAD
#   idle in this tree  clear
#   a tester           by the range, whatever its status, since its turns end
#                      while its probe arms run: held when the range touches
#                      what it tests, or the deployed claude/ its arms load
#   a tester's probe   the same by the range, when its name is `probe: <skill>
#                      <arm>` and <skill> is one skill; else idle clears and
#                      anything else holds, a clean tree included
#   a lead           held: it lands for the others, idle between rounds
#   no process         clear: see below
#   finished, away     clear: see below
#   busy or waiting    notice where this tree is clean, else held: see below
#   anything else      held: a row placed-elsewhere doubts, or another status
#
# NOTICE, EXIT 3: a busy or waiting session in this tree, no tester, probe or
# lead, loses nothing on disk to a fast-forward of a clean tree, `git status
# --porcelain` empty: what it loses is its view of the changed files, and a
# command it has running may read both sides of the move. The user chose a
# landing with a message over a wait (2026-11-07): a lead's run had a
# busy, then waiting, audit session hold four landings that touched none of
# its files, the tree clean each time. So such a row reads notice, and the
# script exits 3 when no row holds; the caller lands and tells each one the
# range and the files. A dirty tree keeps the hold: a session there is
# mid-edit. A caller that reads anything but 0 as stop stays safe.
#
# A row with no process clears only when all of these hold: `kind` background,
# `pid` and `status` null or absent, `state` exactly blocked or done, and no
# registry entry under its name, with none named like it. Such a row holds no
# tree and waiting cannot clear it: a worker retired after 8 hours idle leaves
# its row listed, `state: blocked`, the daemon gone (daemon.log, 2026-10-31,
# 2.1.316). A blocked one still waits on its user, so the line says no process,
# never finished. "No registry entry" alone will not do, as a live interactive session
# or a `-p` probe has read that way. Two background rows read with a worker
# behind them each carried a pid and a status, running and done (2026-10-31).
# Start-up was not measured: a row starting up should read neither blocked nor
# done, so a null or `working` state holds, and that state test is what covers
# it. Two entries under one name are another doubt, and hold.
#
# A finished row away clears whatever its process: `kind` background, `state`
# exactly done, and a `cwd` of its own outside this checkout, compared as paths
# (a folder holding repos is in no git tree, so git cannot be asked there). Such a
# row has its own HEAD. Two finished probes, `probe-bg-147`, kept a live process
# for 8h40m, and their two registry entries under one name held every landing
# as `in doubt, 2 registry entries` (2026-10-31, 2.1.316). So it is judged by
# the row, before the registry is read. Still held: an interactive row sharing
# the name, a background row in this checkout, one `working` or `blocked`
# (which waits on its user), and a row whose `cwd` is missing, empty, relative
# or has a `..` segment: only an absolute path can be placed.
#
# A tester is a row the name-session hook named `test-skill: <skill>`. It holds
# its skill's group under skills/, whose rivals can load beside it, or its own
# folder under .claude/skills/, then tests/skills/<skill>/ and claude/. A name
# that resolves to no one skill holds every skill and all of claude/. A tester
# renamed by hand reads as anything else, so idle clears it.
#
# A tester's probe arm is a row named `probe: <skill> <arm>`, a `claude -p` run
# from this checkout, and reads the skill from it, so it takes its tester's rule
# when <skill> resolves to exactly one skill: a range touching that skill would
# change the arm mid-run, and one that misses it costs the arm nothing. Without
# this, every busy probe fell to the last case and held whatever the range, while
# its tester read clear (2026-11-04, report-backlog and deploy-payload). A probe
# whose first word names no one skill, or none, keeps the rule other rows had
# before notice: idle clears it, anything else holds, a clean tree included. A free-form cold probe, `-n 'probe: <topic>'`,
# takes the same rule when <topic> starts with a skill's name.
#
# Usage, from the checkout that would move, <session-id> as this session's own
# id or pid, <tip> the branch or commit to fast-forward to:
#   claude agents --json | bash landing-clear.sh <session-id> <tip>
#
# stdout: one line per other session. Exit 0 clear, 1 held, 2 when it cannot
# tell: a usage error, no git tree, a list without this session's row (an empty
# read or output that is not JSON among them), a tip git cannot compare, a
# status git cannot read; 3 clear but for notice rows.
set -uo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: claude agents --json | landing-clear.sh <session-id> <tip>" >&2
    exit 2
fi
ME=$1
TIP=$2

if ! command -v jq > /dev/null 2>&1; then
    echo "error: jq not found on PATH" >&2
    exit 2
fi

if ! TOP=$(git rev-parse --show-toplevel 2> /dev/null); then
    echo "error: no git working tree here" >&2
    exit 2
fi

PLACED="$(dirname "${BASH_SOURCE[0]}")/placed-elsewhere.sh"

# A native jq.exe writes CRLF without -b, and Git Bash reports OSTYPE=cygwin.
JQ_BIN=()
case "$OSTYPE" in msys* | cygwin*) JQ_BIN=(-b) ;; esac

# Without the check on this session's row, a list that read as nothing would
# show no one, and pass.
# shellcheck disable=SC2016 # $me is a jq variable
if ! ROWS=$(jq "${JQ_BIN[@]}" -n -r --arg me "$ME" '
    def mine: .sessionId == $me or (.pid | tostring) == $me;
    (input? // [])
    | if any(.[]; mine) then .[] | select(mine | not)
        | [(.status // "unknown"),
           (if .kind == "background" and .pid == null and .status == null
               and (.state == "blocked" or .state == "done")
            then "no-process" else "-" end),
           (.name // ""),
           (if .kind == "background" and .state == "done" then "finished" else "-" end),
           (.cwd | if type == "string" then . else "" end)] | join("\u001f")
      else error("no row is this session") end
'); then
    echo "error: stdin is not a claude agents --json list holding row '$ME'" >&2
    exit 2
fi

# --no-renames lists both sides, so a move out of a held path still touches it.
if ! CHANGED=$(git -c core.quotepath=off diff --no-renames --name-only "HEAD...$TIP" 2> /dev/null); then
    echo "error: git cannot compare HEAD with $TIP" >&2
    exit 2
fi

# dirty_tree: whether this tree holds any change, read once on first need, so
# a call with no busy or waiting row pays nothing. Untracked files count, a
# session's new file being work in progress too, whatever
# status.showUntrackedFiles says; --no-optional-locks keeps the read off the
# index lock a busy session may want.
DIRTY_READ=0
DIRTY=
dirty_tree() {
    if ((DIRTY_READ == 0)); then
        DIRTY_READ=1
        if ! DIRTY=$(git --no-optional-locks status --porcelain --untracked-files=normal 2> /dev/null); then
            echo "error: git cannot read this tree's status" >&2
            exit 2
        fi
    fi
    [[ -n $DIRTY ]]
}

# skill_files <skill>: in FOUND, every SKILL.md the name resolves to
skill_files() {
    local skill=$1
    FOUND=()
    if [[ $skill =~ ^[A-Za-z0-9_-]+$ ]]; then
        shopt -s nullglob
        FOUND=("$TOP"/skills/*/"$skill"/SKILL.md)
        shopt -u nullglob
        # No wildcard in this one, so nullglob would never drop it.
        [[ -f "$TOP/.claude/skills/$skill/SKILL.md" ]] && FOUND+=("$TOP/.claude/skills/$skill/SKILL.md")
    fi
}

# tester_holds <skill>: the path prefixes that tester holds, one per line
tester_holds() {
    local skill=$1
    skill_files "$skill"
    if ((${#FOUND[@]} != 1)); then
        printf '%s\n' skills/ .claude/skills/ tests/skills/ claude/
        return
    fi
    local dir=${FOUND[0]#"$TOP"/}
    dir=${dir%/SKILL.md}
    case "$dir" in
        skills/*) printf '%s\n' "${dir%/*}/" ;;
        *) printf '%s\n' "$dir/" ;;
    esac
    printf '%s\n' "tests/skills/$skill/" claude/
}

# first_touched: the first changed path under a prefix on stdin, if any
first_touched() {
    local prefix path
    while IFS= read -r prefix; do
        while IFS= read -r path; do
            if [[ -n $path && $path == "$prefix"* ]]; then
                printf '%s\n' "$path"
                return
            fi
        done <<< "$CHANGED"
    done
}

# norm_path <path>: in REPLY, "/"-separated, lower case, no trailing "/", and a
# "/c/..." spelling as "c:/..."
norm_path() {
    local p=${1//\\//}
    p=${p,,}
    p=${p%/}
    [[ $p =~ ^/([a-z])/ ]] && p=${BASH_REMATCH[1]}:/${p:3}
    REPLY=$p
}

# absolute_path <cwd>: whether a row's cwd can be placed at all: a drive or
# "/" or UNC root, and no ".." segment that could walk back in. A relative or
# malformed value is a doubt, and holds.
absolute_path() {
    [[ $1 =~ ^([A-Za-z]:[\\/]|/|\\\\) ]] || return 1
    [[ $1 =~ (^|[\\/])\.\.([\\/]|$) ]] && return 1
    return 0
}

# inside_checkout <cwd>: whether a row's cwd is this checkout or under it, by
# path, then by the tree git finds for it, which also sees an 8.3 spelling or a
# junction that the path compare cannot
inside_checkout() {
    local cwd here top
    norm_path "$TOP"
    here=$REPLY
    norm_path "$1"
    cwd=$REPLY
    [[ $cwd == "$here" || $cwd == "$here"/* ]] && return 0
    if top=$(git -C "$1" rev-parse --show-toplevel 2> /dev/null); then
        [[ ${top,,} == "${TOP,,}" || $top -ef $TOP ]] && return 0
    fi
    return 1
}

# The fields join on the unit separator, which read keeps empty, unlike a tab.
RC=0
NOTICE=0
while IFS=$'\x1f' read -r status shape name finished rowcwd; do
    # The one empty line an empty $ROWS gives; a status is never empty.
    [[ -n $status ]] || continue
    if [[ -z $name ]]; then
        printf '(a row with no name, %s): held, nothing to place\n' "$status"
        RC=1
        continue
    fi
    if [[ $finished == finished ]] && absolute_path "$rowcwd" && ! inside_checkout "$rowcwd"; then
        printf '%s: clear, elsewhere\n' "$name"
        continue
    fi
    placed=$(bash "$PLACED" "$name" < /dev/null 2>&1)
    prc=$?
    if ((prc == 0)); then
        printf '%s: clear, elsewhere\n' "$name"
        continue
    fi
    # The whole line, so a warning beside it or a near name in it still holds.
    if [[ $shape == no-process && $prc == 1 && $placed == "$name: in doubt, no registry entry under this name" ]]; then
        printf '%s: clear, no process\n' "$name"
        continue
    fi
    if [[ $prc != 1 || $placed != *": this tree, cwd "* ]]; then
        printf '%s: held, not placed: %s\n' "$name" "$placed"
        RC=1
        continue
    fi

    # The hook closes a name with its start time.
    bare=$name
    [[ $name =~ ^(.*)\ [0-9]{4}-[0-9]{2}-[0-9]{2}\ T[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]] && bare=${BASH_REMATCH[1]}
    case "$bare" in
        "test-skill: "*)
            holds=$(tester_holds "${bare#test-skill: }")
            touched=$(first_touched <<< "$holds")
            if [[ -n $touched ]]; then
                printf '%s: held, a tester, and the range touches %s\n' "$name" "$touched"
                RC=1
            else
                printf '%s: clear, a tester the range misses\n' "$name"
            fi
            ;;
        "probe: "*)
            # A test-skill arm is `probe: <skill> <arm>`; the first word is read
            # by the tester rule only when it resolves to one skill.
            word=${bare#probe: }
            word=${word%% *}
            skill_files "$word"
            if ((${#FOUND[@]} == 1)); then
                touched=$(first_touched <<< "$(tester_holds "$word")")
                if [[ -n $touched ]]; then
                    printf '%s: held, a probe of %s, and the range touches %s\n' "$name" "$word" "$touched"
                    RC=1
                else
                    printf '%s: clear, a probe of %s the range misses\n' "$name" "$word"
                fi
            elif [[ $status == idle ]]; then
                printf '%s: clear, idle in this tree\n' "$name"
            else
                printf '%s: held, %s in this tree\n' "$name" "$status"
                RC=1
            fi
            ;;
        lead-sessions* | lead-issues*) # lead-issues: the lead's name until 2026-11-02
            printf '%s: held, a lead in this tree\n' "$name"
            RC=1
            ;;
        *)
            if [[ $status == idle ]]; then
                printf '%s: clear, idle in this tree\n' "$name"
            elif [[ $status == busy || $status == waiting ]] && ! dirty_tree; then
                printf '%s: notice, %s in this tree, which is clean\n' "$name" "$status"
                NOTICE=1
            else
                printf '%s: held, %s in this tree\n' "$name" "$status"
                RC=1
            fi
            ;;
    esac
done <<< "$ROWS"
((RC == 0 && NOTICE == 1)) && RC=3
exit "$RC"
