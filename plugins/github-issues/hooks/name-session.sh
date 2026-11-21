#!/usr/bin/env bash
# name-session.sh — UserPromptSubmit hook: name a session from its first
# prompt, so ListAgents, `claude agents` and the /resume picker show what it
# is for instead of a default such as `my-repo-67`. Also run on
# SessionStart after /clear, to note the name a cleared session inherits.
#
# A name is an address: SendMessage reaches a live session by it, and a
# rename strands a peer mid-conversation. So this hook decides once per
# session, on the first prompt that reaches it (built-in commands such as
# /model or /color never do), and names the session only when that prompt
# matches a rule. First match wins:
#
#   1. starts with a skill or command  /my-skill notes.md          -> my-skill: notes
#   2. names a handoff brief           docs/handoffs/execute/x.md  -> brief: x
#      or a skill brief                docs/handoffs/skills/x.md   -> brief: x
#   3. names an issue                  work on #7, issue #7        -> issue: #7
#   4. names an inbox note             handoff-inbox/<repo>/<date>-y.md -> inbox: y
#   5. runs in a worktree              .claude/worktrees/w  -> brief: w if that brief exists, else worktree: w
#   6. is on a branch other than main or master             -> the branch name
#
# An issue is how a brief is tracked once its queue moves to a GitHub board
# (docs/handoffs/execute/README.md, "The board is the backlog"). A brief named
# by its file still wins, since the file is the source wherever the queue has
# not moved to a board. A worktree for an issue takes its title's slug, not its
# number, which rule 5 already names.
#
# Each name then ends in the first prompt's local date and time, as in
# `brief: x 2026-10-21 T08:53:42`: a brief can run for days, and the time
# tells its sessions apart. The 80-character cap comes before it, so the
# time is never cut.
#
# Anything else keeps Claude Code's default name; `/rename` with no argument
# names a session from its conversation instead. Against the first prompts
# of 195 past sessions (2026-10-06) the rules would have named about half.
#
# Leaves alone a session that already has a name (`session_title` in the
# input: --name, /rename, a probe's `-n "probe: ..."`), and one whose
# transcript already holds a prompt: a session that was running when this
# hook was deployed, or a resumed one. "Seen" is a marker in the session's
# own temp folder, the parent of `scratchpad_dir`, so every prompt after the
# first costs one bash start and two file tests, and the marker goes when
# that folder does. Without `scratchpad_dir` in the input it names nothing:
# a CLI that drops the field turns this hook off, which
# a suite kept with its source exists to catch.
#
# A session `/clear` starts is named afresh. It has a new id and temp
# folder, but keeps the old session's name (sessions docs, read
# 2026-11-06), so `/resume` listed two sessions under one name, and its
# transcript opens with a `"type":"user"` row for `/clear` itself, which
# read as under way. Its SessionStart, matcher `clear`, also runs this
# script, which records the name it inherited, or none, in
# `.name-session-cleared`; a hook's `sessionTitle` is ignored there. The
# first prompt then skips both checks while the name is still the one
# recorded and is one this hook gave, ending in its time, so a `/rename`
# made since or before stands, and so does `--name`, which Claude Code
# keeps across /clear on purpose. A lead's name stays too, `lead-*`, as
# it is how its workers and lead-edit-guard find it (work-issue's
# references/lead-hand-off.md). With no rule match the old name stays.
# SessionStart after /clear runs in the background (hooks docs), so a
# first prompt that beat it, if one can (unmeasured), finds no record.
# With a name inherited, that prompt leaves it and the next one names it;
# with none, that prompt writes its marker and the session stays unnamed.
#
# Rules 2, 4 and 5 read handoff conventions: a brief file under
# docs/handoffs/execute/, where audit-repo's file-queue scaffold puts one,
# and a note in a handoff inbox, whose path carries a handoff-inbox folder.
# A repo without them never names those paths, so there the rules match
# nothing and cost a regex each; the plugin carrying the issue skills ships
# them unchanged, as it ships this script byte for byte.
#
# Spawns nothing for a new session (git's HEAD is read, not run; one grep
# runs, once, only where a transcript already exists; one mkdir, after a
# /clear, only if its temp folder is not there yet), never blocks, and
# prints nothing but the title JSON: plain stdout from this event is added
# to Claude's context. Always exits 0.

# Started as `sh`: bash in POSIX mode under Git for Windows, but dash on
# Debian and Ubuntu and bash 3.2 on macOS, where what follows fails. So
# hand over, once, to the bash on PATH, in POSIX syntax; where that is older
# than 4.4 too, it names nothing, as on input it cannot read.
case ${BASH_VERSION:-} in
    '' | [0-3].* | 4.[0-3].*)
        if [ -z "${NAME_SESSION_BASH:-}" ] && command -v bash >/dev/null 2>&1; then
            NAME_SESSION_BASH=1
            export NAME_SESSION_BASH
            exec bash "$0" "$@"
        fi
        echo "name-session: no bash 4.4 or later on PATH, so this session was not named." >&2
        exit 0
        ;;
esac

IFS= read -r -d '' INPUT || true
CR=$'\r'
CONFIG_DIR=${CLAUDE_CONFIG_DIR:-$HOME/.claude}

# json_path <field>: the field's string value in REPLY, separators as "/".
# Only for fields holding paths, which never contain a quote.
json_path() {
    local re="\"$1\":\"([^\"]*)\""
    [[ $INPUT =~ $re ]] || return 1
    REPLY=${BASH_REMATCH[1]//\\\\//}
}

# The name as its JSON text, escapes kept, in TITLE; empty when unnamed.
# The prompt's own quotes arrive escaped, so a prompt cannot fake the field.
TITLE=
RE_TITLE='"session_title":"(([^"\\]|\\.)*)"'
[[ $INPUT =~ $RE_TITLE ]] && TITLE=${BASH_REMATCH[1]}

json_path scratchpad_dir || exit 0
SESSION_DIR=${REPLY%/scratchpad}
CLEARED=$SESSION_DIR/.name-session-cleared

# SessionStart after /clear: record the name the session inherited.
if [[ $INPUT == *'"hook_event_name":"SessionStart"'* ]]; then
    [[ $INPUT == *'"source":"clear"'* ]] || exit 0
    [[ -d $SESSION_DIR ]] || mkdir -p "$SESSION_DIR" 2>/dev/null || exit 0
    printf '%s' "$TITLE" >"$CLEARED" 2>/dev/null
    exit 0
fi
[[ $INPUT == *'"prompt":"'* ]] || exit 0

[[ -d $SESSION_DIR ]] || exit 0
MARKER=$SESSION_DIR/.name-session
[[ -e $MARKER ]] && exit 0

# Fresh from /clear while the name is still the one it inherited, and that
# name is none or one this hook gave, by its time; never a lead's.
RE_OURS=' [0-9]{4}-[0-9]{2}-[0-9]{2} T[0-9]{2}:[0-9]{2}:[0-9]{2}$'
FROM_CLEAR=
if [[ -f $CLEARED ]]; then
    INHERITED=
    IFS= read -r -d '' INHERITED <"$CLEARED"
    if [[ $TITLE == "$INHERITED" ]] &&
        { [[ -z $TITLE ]] || [[ $TITLE =~ $RE_OURS && $TITLE != lead-* ]]; }; then
        FROM_CLEAR=1
    fi
fi

# Already named: by --name, /rename, a probe's -n, or this hook.
[[ -n $TITLE && -z $FROM_CLEAR ]] && exit 0

# printf, never `:`: under sh a failed redirect on a special builtin ends the
# shell with 1 before the `||` runs (2026-10-30).
printf '' >"$MARKER" 2>/dev/null || exit 0

# Already under way: running before this hook was deployed, or resumed.
if [[ -z $FROM_CLEAR ]] && json_path transcript_path && [[ -s $REPLY ]] &&
    grep -q -m1 '"type":"user"' "$REPLY" 2>/dev/null; then
    exit 0
fi

CWD=
json_path cwd && CWD=$REPLY
# The prompt's JSON text and whatever fields follow it; the rules below
# match only shapes no other field can hold.
PROMPT=${INPUT#*\"prompt\":\"}
# A cleared session's inherited name may follow the prompt: cut it out.
[[ -n $TITLE ]] && PROMPT=${PROMPT/"\"session_title\":\"$TITLE\""/}
NAME=

# is_command <name>: a skill or custom command this session can see, or a
# plugin's (plugin:name). A prompt that merely starts with a slash, such as
# a path, is not one.
is_command() {
    [[ $1 == *:* ]] ||
        [[ -f $CONFIG_DIR/skills/$1/SKILL.md || -f $CONFIG_DIR/commands/$1.md ]] ||
        [[ -n $CWD && (-f $CWD/.claude/skills/$1/SKILL.md || -f $CWD/.claude/commands/$1.md) ]]
}

# first_slug <regex> <group>: the first match's slug in REPLY, passing over
# README.md, which names a folder's index rather than a piece of work.
first_slug() {
    local rest=$PROMPT
    while [[ $rest =~ $1 ]]; do
        REPLY=${BASH_REMATCH[$2]}
        [[ ${REPLY,,} != readme ]] && return 0
        rest=${rest#*"${BASH_REMATCH[0]}"}
    done
    return 1
}

# git_branch <dir>: the branch checked out in the repo holding <dir>, in
# REPLY, read from HEAD rather than by starting git.
git_branch() {
    local d=$1 gitdir='' head
    while [[ -n $d ]]; do
        if [[ -d $d/.git ]]; then
            gitdir=$d/.git
            break
        elif [[ -f $d/.git ]]; then
            IFS= read -r gitdir <"$d/.git" || return 1
            gitdir=${gitdir%"$CR"}
            gitdir=${gitdir#gitdir: }
            [[ $gitdir == /* || $gitdir == ?:* ]] || gitdir=$d/$gitdir
            break
        fi
        [[ $d == */* ]] || return 1
        d=${d%/*}
    done
    [[ -n $gitdir ]] || return 1
    IFS= read -r head <"$gitdir/HEAD" || return 1
    head=${head%"$CR"}
    [[ $head == 'ref: refs/heads/'* ]] || return 1
    REPLY=${head#ref: refs/heads/}
}

# 1. A skill or command. Its first argument joins the name when it names
#    something, as a path or @-mention, or is the whole first line; prose
#    does not, so "/learn the thing about X" is just "learn". A path keeps
#    its last segment, less a .md extension.
RE_COMMAND='^/([A-Za-z0-9][A-Za-z0-9:_.-]*)(( |\\t)+(([^ "\\]|\\\\)+))?'
if [[ $PROMPT =~ $RE_COMMAND ]] && is_command "${BASH_REMATCH[1]}"; then
    NAME=${BASH_REMATCH[1]}
    arg=${BASH_REMATCH[4]}
    after=${PROMPT:${#BASH_REMATCH[0]}:2}
    if [[ -n $arg && ($arg == *[/@.\\]* || $after == '"'* || $after == '\n'* || $after == '\r'*) ]]; then
        arg=${arg//\\\\//}
        arg=${arg#@}
        arg=${arg%/}
        arg=${arg##*/}
        arg=${arg%.md}
        [[ -n $arg ]] && NAME="$NAME: $arg"
    fi
fi

# 2. A handoff brief.
RE_BRIEF='docs(/|\\\\)+handoffs(/|\\\\)+(execute|skills)(/|\\\\)+([A-Za-z0-9._-]+)\.md'
[[ -z $NAME ]] && first_slug "$RE_BRIEF" 5 && NAME="brief: $REPLY"

# 3. An issue, #<number> after "issue", "work", "work on" or "pick up". A
#    bare #<number> is prose as often: "step #1", a colour's `#333`, a link's
#    (`#12`) each named a session that ran in a worktree, whose rule is the
#    surer one (review, 2026-10-27). A JSON-escaped newline or tab counts
#    as a space.
RE_ISSUE='(^|[^A-Za-z0-9_-]|\\[nt])([Ii]ssues?|[Ww]ork( on)?|[Pp]ick up)( |\\t)+#([0-9]{1,6})([^A-Za-z0-9_]|$)'
[[ -z $NAME && $PROMPT =~ $RE_ISSUE ]] && NAME="issue: #${BASH_REMATCH[5]}"

# 4. An inbox note, less its date prefix.
RE_NOTE='handoff-inbox(/|\\\\)+[A-Za-z0-9._-]+(/|\\\\)+([A-Za-z0-9._-]+)\.md'
if [[ -z $NAME ]] && first_slug "$RE_NOTE" 3; then
    NAME="inbox: ${REPLY#[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-}"
fi

# 5. A worktree, which in a repo that briefs its work is named after one.
RE_WORKTREE='/\.claude/worktrees/([^/]+)'
if [[ -z $NAME && $CWD =~ $RE_WORKTREE ]]; then
    wt=${BASH_REMATCH[1]}
    root=${CWD%%/.claude/worktrees/*}/.claude/worktrees/$wt
    if [[ -f $root/docs/handoffs/execute/$wt.md || -f $root/docs/handoffs/skills/$wt.md ]]; then
        NAME="brief: $wt"
    else
        NAME="worktree: $wt"
    fi
fi

# 6. A branch other than the default.
if [[ -z $NAME && -n $CWD ]] && git_branch "$CWD" &&
    [[ $REPLY != main && $REPLY != master ]]; then
    NAME=$REPLY
fi

[[ -n $NAME ]] || exit 0
NAME=${NAME//[^A-Za-z0-9 ._:\/@+#-]/-}
NAME=${NAME:0:80}
# printf's %(...)T is a builtin, so the time starts nothing either.
printf -v STARTED '%(%Y-%m-%d T%H:%M:%S)T' -1
printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","sessionTitle":"%s"}}\n' "$NAME $STARTED"
exit 0
