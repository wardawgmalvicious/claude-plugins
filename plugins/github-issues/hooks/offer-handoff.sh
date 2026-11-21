#!/usr/bin/env bash
# offer-handoff.sh — SessionStart hook (matcher "compact"): after a
# compaction, tell Claude that a handoff brief could be written while the
# summary still holds the thread, and list the briefs the repo already keeps,
# so the offer can name the one a thread belongs to. In every repo, queue or
# not, it first says that a new request a skill covers is a new invocation of
# that skill, not a run of the copy re-attached after the summary.
#
# The user decides when to hand off, so this offers and never blocks. A
# PreCompact hook that stopped a bare /compact with a hand-off message was
# tried in a client sandbox repo on 2026-10-01 and dropped the same day: the
# user sometimes runs a session long on purpose and judges when it has run
# long enough. PreCompact could not have offered anything anyway: Claude Code
# discards its systemMessage, and its exit-2 stderr reaches only the user, on
# a manual /compact. PostCompact receives the summary and discards its output
# too. SessionStart with matcher "compact" fires after every compaction, auto
# or manual, and idle compaction (2.1.299) is a kind of auto (hooks docs, read
# 2026-10-21). Its plain stdout joins Claude's context: after a /compact on
# 2.1.291 (2026-10-06), Claude quoted the text back, which it sees prefixed
# "SessionStart:compact hook success:", from a transcript record of type
# attachment, hook_success, written just after the compact_boundary. No hook
# input carries the context's size as it fills, so no hook can warn before an
# auto compaction (code.claude.com/docs/en/hooks, read 2026-10-06). The text
# is statements, not commands: that page warns that text framed as system
# commands can trip Claude's prompt-injection defences, so Claude would show
# it to the user rather than use it.
#
# A subagent's own compaction fires the same event, the subagent's agent_id
# and agent_type in its input, and the stdout joins the subagent's context
# alone: a headless probe drove one subagent through three compactions, each
# firing it with agent_id, and found a marker the hook printed as a
# hook_success attachment in the subagent's transcript, never in the main
# one (observed 2026-11-14, 2.1.325). No user answers a subagent, and it
# holds no thread of the user's to hand off, so an input carrying agent_id
# gets nothing. Before 2.1.323 that input lacked agent_id (its changelog), so
# an older Claude Code still offers there. A main session started with
# --agent carries agent_type alone, and still gets the offer; an in-process
# teammate carries agent_id too (hooks docs, read 2026-11-14), untested here.
#
# The paragraph on skills goes to every main session's compaction, in any
# repo, since this is the one text a session is sure to read at that moment.
# Claude Code re-attaches the most recent invocation of each skill
# after the summary, its first 5,000 tokens within 25,000 for all, and its
# skills docs answer a skill no longer followed after a compaction with
# invoking it again (code.claude.com/docs/en/skills, read 2026-11-20). A
# session that opened a second pull request after a /compact worked from the
# re-attached land-branch copy instead, skipped a step the copy still held,
# and ran the steps past its truncation from memory: the copy's heading,
# skills invoked earlier, for context, not to re-execute, read as a reason
# not to invoke the skill for a new instance of the task (a client repo's
# session, 2.1.326, 2026-11-20). Whether a hook's text is read more reliably
# than that heading is untested.
#
# The queue is the one in the checkout holding the input's `cwd`, the nearest
# folder with a .git, which in a worktree is its own .git file:
# CLAUDE_PROJECT_DIR stays at the main checkout when Claude enters a
# worktree. A brief is what triage-inbox's handoff-status.py counts: any .md under
# docs/handoffs/, dot folders included, but a README.md, CLAUDE.md or
# AGENTS.md, anything under a templates/ or examples/ folder, and
# DECLINED.md at the tree's root. The rule is restated here because a hook
# spawns no Python, and a suite kept with its source holds the two together.
# With no docs/handoffs/ folder it lists nothing.
#
# A repo whose queue moves to a GitHub board keeps its docs/handoffs/ folder
# and no brief in it, and one that audit-repo's board scaffold set up has no
# such folder at all: only the rule for briefs, .claude/rules/handoff-briefs.md,
# which both its scaffolds write. So beside that rule with no folder it makes
# the offer for a board, its briefs filed as issues by the file-issue skill,
# and there or where it finds no brief it names the command that lists a
# board's issues: handoff-status.py, in the triage-inbox skill deployed beside
# this hook or, run from a plugin, in the plugin's own
# skills/triage-inbox/scripts/, where the export ships it beside the skills
# that call it. It names nothing where neither holds it, and never reads the
# board itself: a SessionStart hook must not wait on the network. A repo with
# neither the folder nor the rule, or a cwd in no checkout, gets the paragraph
# on skills alone: an offer there would have nowhere to put a brief.
#
# A plugin's copy stands down beside this setup's own. A hook in both a
# settings file and a plugin's hooks.json runs twice per event (plugins
# docs, "Convert an existing .claude/ setup", read 2026-11-20), which here
# is two offers after one compaction. So a run with CLAUDE_PLUGIN_ROOT set,
# which Claude Code exports to a plugin's hooks alone, prints nothing where
# `<config>/hooks/offer-handoff.sh` exists. The file stands for its
# registration, which this hook does not read: a copy deployed there and
# registered nowhere turns the plugin's off too.
#
# Bash builtins only, so it starts nothing but bash. The list stops at 8,000
# characters, keeping the whole under the 10,000 Claude Code allows a hook's
# stdout, past which Claude would see a file path and a preview instead. It
# never blocks, prints nothing on input it cannot read, and always exits 0.

# Started as `sh`: bash in POSIX mode under Git for Windows, but dash on
# Debian and Ubuntu and bash 3.2 on macOS, where what follows fails. So
# hand over, once, to the bash on PATH, in POSIX syntax; where that is older
# than 4.4 too, it offers nothing, as on input it cannot read.
case ${BASH_VERSION:-} in
    '' | [0-3].* | 4.[0-3].*)
        if [ -z "${OFFER_HANDOFF_BASH:-}" ] && command -v bash >/dev/null 2>&1; then
            OFFER_HANDOFF_BASH=1
            export OFFER_HANDOFF_BASH
            exec bash "$0" "$@"
        fi
        echo "offer-handoff: no bash 4.4 or later on PATH, so no hand-off was offered." >&2
        exit 0
        ;;
esac

IFS= read -r -d '' INPUT || true
CR=$'\r'
LIMIT=8000

# A plugin's copy, beside this setup's deployed one: that one offers.
[[ -n ${CLAUDE_PLUGIN_ROOT:-} && -f ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/offer-handoff.sh ]] && exit 0

# json_value <field>: the field's string value in REPLY, separators as "/".
# Only for fields holding a path or a plain word, which never hold a quote.
json_value() {
    local re="\"$1\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""
    [[ $INPUT =~ $re ]] || return 1
    REPLY=${BASH_REMATCH[1]//\\\\//}
}

# checkout_root <dir>: the checkout holding <dir>, in REPLY.
checkout_root() {
    local d=${1%/}
    while [[ -n $d ]]; do
        if [[ -e $d/.git ]]; then
            REPLY=$d
            return 0
        fi
        [[ $d == */* ]] || return 1
        d=${d%/*}
    done
    return 1
}

# brief_line <file> <path>: the brief's line for the list, in REPLY, from the
# frontmatter between its opening --- and the next. A needs or blocked-by of
# [] says nothing, so it is left out.
brief_line() {
    local line key value n=0 closed=0 status='' priority='' needs='' blocked='' reopen=''
    REPLY="- $2: no frontmatter"
    [[ -f $1 && -r $1 ]] || return 0
    while IFS= read -r line || [[ -n $line ]]; do
        line=${line%"$CR"}
        if ((n++ == 0)); then
            [[ $line == --- ]] || return 0
            continue
        fi
        if [[ $line == --- ]]; then
            closed=1
            break
        fi
        ((n > 20)) && break
        key=${line%%:*}
        value=${line#*:}
        value=${value#"${value%%[![:space:]]*}"}
        value=${value%"${value##*[![:space:]]}"}
        case $key in
        status) status=$value ;;
        priority) priority=$value ;;
        needs) needs=$value ;;
        blocked-by) blocked=$value ;;
        reopen-when) reopen=$value ;;
        esac
    done <"$1"
    ((closed)) || return 0
    REPLY="- $2: ${status:-no status}"
    [[ -n $priority ]] && REPLY+=", P$priority"
    [[ -n $needs && $needs != '[]' ]] && REPLY+=", needs $needs"
    [[ -n $blocked && $blocked != '[]' ]] && REPLY+=", blocked by $blocked"
    [[ -n $reopen ]] && REPLY+=", reopens when $reopen"
    return 0
}

# home_relative <path>: the path in REPLY, its home folder written ~, so the
# profile path stays out of the context; untouched under any other folder.
home_relative() {
    local h
    REPLY=$1
    for h in "${HOME:-}" "${USERPROFILE:-}"; do
        h=${h//\\//}
        h=${h%/}
        if [[ -n $h && ${1,,} == "${h,,}"/* ]]; then
            REPLY="~${1:${#h}}"
            return 0
        fi
    done
    return 0
}

# board_command: the line naming the command that lists a board's issues,
# where handoff-status.py is found; nothing otherwise.
board_command() {
    local base shown
    if [[ -n ${CLAUDE_PLUGIN_ROOT:-} ]]; then
        base=${CLAUDE_PLUGIN_ROOT//\\//}
        base=${base%/}
        [[ -f $base/skills/triage-inbox/scripts/handoff-status.py ]] || return 0
        home_relative "$base"
        shown=$REPLY
    else
        base=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
        base=${base//\\//}
        base=${base%/}
        [[ -f $base/skills/triage-inbox/scripts/handoff-status.py ]] || return 0
        # Shown from ~, so the profile path stays out of the context.
        # shellcheck disable=SC2088 # a literal ~ for Claude's command, never expanded here
        shown="~/${base##*/}"
    fi
    # shellcheck disable=SC2016 # the backticks are literal, marking a command
    printf 'Open issues on a GitHub board linked to this repo, where it keeps its\nqueue on one, are listed by `uv run --no-project %s/skills/triage-inbox/scripts/handoff-status.py . --no-inbox`.\n' \
        "$shown"
}

HEAD='This session was just compacted. A compaction summary keeps conclusions and
drops detail, most often what was not checked and which claims were observed
rather than inferred.'

SKILLS='Skills invoked before the compaction come back after the summary as
context, a long one cut to its start, and past a shared cap the oldest
left out. A new request that a skill covers, even
another instance of a task this session already did, is a new invocation
of that skill, which loads it whole. The re-attached copy serves the work
in progress, and the note in its heading not to re-execute it covers that
work, not a new request; where the copy ends before the step at hand, or
no copy came back, invoking the skill again restores it.'

json_value source && [[ $REPLY == compact ]] || exit 0
json_value agent_id && [[ -n $REPLY ]] && exit 0
printf '%s\n\n%s\n' "$HEAD" "$SKILLS"
json_value cwd || exit 0
checkout_root "$REPLY" || exit 0
ROOT=$REPLY
TREE=$ROOT/docs/handoffs
if [[ ! -d $TREE ]]; then
    [[ -f $ROOT/.claude/rules/handoff-briefs.md ]] || exit 0
    printf '\n%s\n' 'This repo keeps no docs/handoffs/ folder, so its handoff briefs are issues
on a GitHub board, as its rule for them, .claude/rules/handoff-briefs.md,
says, and the user decides when to hand off. After a compaction, the
convention is to mention once that a brief could be filed now, while the
summary still holds the thread, and to file one only if the user says so.
The file-issue skill files it, and folds a thread that belongs to an open
issue into that issue.'
    board_command
    exit 0
fi

LIST=
MORE=0
shopt -s globstar nullglob dotglob
for f in "$TREE"/**/*.md; do
    rel=${f#"$TREE"/}
    name=${rel##*/}
    case ${name,,} in readme.md | claude.md | agents.md) continue ;; esac
    [[ /$rel == */templates/* || /$rel == */examples/* ]] && continue
    [[ $rel != */* && ${name,,} == declined.md ]] && continue
    [[ -f $f ]] || continue
    if ((MORE)); then
        ((MORE++))
        continue
    fi
    brief_line "$f" "$rel"
    if ((${#LIST} + ${#REPLY} >= LIMIT)); then
        MORE=1
        continue
    fi
    LIST+=$REPLY$'\n'
done

MSG='This repo keeps work that outlasts a session in handoff briefs under
docs/handoffs/, and the user decides when to hand off. After a compaction,
the convention is to mention once that a brief could be written now, while
the summary still holds the thread, and to write one only if the user says
so. A thread that belongs to a brief below is handed off by updating that
brief.'

if [[ -z $LIST ]]; then
    printf '\n%s\n\nBriefs under docs/handoffs/: none.\n' "$MSG"
    board_command
else
    printf '\n%s\n\nBriefs under docs/handoffs/:\n%s' "$MSG" "$LIST"
    ((MORE)) && printf -- '- and %d more, past what fits here\n' "$MORE"
fi
exit 0
