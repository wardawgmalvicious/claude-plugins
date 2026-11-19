#!/usr/bin/env bash
# fabric-edit-gate.sh — PreToolUse hook (matcher "Edit|Write"), shipped in
# the fabric plugin's hooks/hooks.json: refuses the first Edit or Write to a
# file inside a Fabric item folder (Sales.Notebook/, Sales.SemanticModel/)
# until the skill that owns that item has been invoked in the same context,
# then refuses no more for that skill in that context.
#
# WHY A REFUSAL AND NOT A HINT. Two hint hooks were probed and retired: one
# PostToolUse on a shell call naming an item (2026-11-11), and one
# PostToolUse on a Read or Edit of an item (2026-11-13, 2.1.323). Each handed
# Claude the owner skill's name as additional context. In the second's only
# failing round, Sonnet working an issue in a crowded context, the hint
# arrived after the batch of Reads and before the Edit, and 3 of 4 hooked
# arms still skipped the skill;
# plain prompts routed by description alone in 16 of 16. Context added beside
# a tool result competes with everything else in the turn. A refused Edit is
# a decision Claude has to answer before the change lands, which is the one
# point where skipping the skill costs anything.
#
# REFUSES ONCE, THEN STEPS ASIDE. The first unowned edit per skill per context
# exits 2; a second attempt passes, whatever the transcript says. So the gate
# can never trap a session: a skill absent from this install, a Skill tool
# denied, a transcript this script misreads, or a model that read the reason
# and chose to go on, each costs one refusal. The marker is an atomic mkdir,
# since the second hint hook saw parallel Reads race a file marker and hint
# twice (2026-11-13); of two
# parallel Edits on one item, one is refused and the other passes.
#
# WHAT COUNTS AS INVOKED. A line of the context's transcript holding a Skill
# tool call for the owner, "name":"Skill","input":{"skill":"<owner>"}, or a
# typed /<owner>, <command-name>/<owner></command-name>, either bare or
# plugin-prefixed (fabric:pbi-items): a client repo links the same skills
# bare at project scope, and the catalog may split them across plugins. Both
# shapes read in this machine's transcripts, 2026-11-13. The match is loose
# on purpose, the gate being a nudge: a Skill call is written before its
# result, so one that failed or was denied still counts, and the typed shape
# counts wherever that text sits unescaped in the transcript. A subagent has its
# own context, so with an agent_id the gate reads that subagent's transcript,
# <transcript dir>/<session_id>/subagents/agent-<agent_id>.jsonl, and keeps
# its own marker: a parent's Skill call put nothing in the subagent's context.
#
# COST. The handler is unfiltered on Edit|Write, so every edit starts `sh`.
# The item check is a bash regex on the raw input before any jq, so an edit
# outside an item folder spends one spawn and nothing more. An `if` per item
# suffix and tool would have spawned nothing for those edits, at 50 handlers
# kept in step with the table below by hand; one table here was chosen.
#
# FAILS OPEN. Input jq cannot read, or no jq on PATH or in the toolchain
# plugin's data folder, exits 1: the edit proceeds under a `hook error`
# notice saying it was not checked. A Bash write to an
# item file runs no Edit|Write hook (a probe saw a `cat` read a model that
# way, 2026-11-13).
#
# RUNS UNDER BASH, WHATEVER `sh` IS. hooks.json starts it as `sh`: bash in
# POSIX mode under Git for Windows and macOS, but dash on Debian and Ubuntu,
# WSL's included, where `set -o pipefail` exits 2 and so would refuse every
# Edit and Write. So the first lines, POSIX alone, re-run it under bash. On
# Windows with no Git for Windows the command runs in PowerShell, where `sh`
# is not found. A PreToolUse hook failing there blocks the call unless its
# entry sets onFailure, so hooks.json sets "onFailure": "continue": that host
# gets every Edit and Write through unchecked, each under a `hook error`
# notice, never every edit blocked (hooks docs, "Failed hooks on Windows
# without Git Bash", read 2026-11-14; the field needs Claude Code 2.1.295
# or later).
#
# Exit codes: 0 allows; 1 allows unchecked, with a notice; 2 refuses, and
# Claude reads stderr as the reason.

if [ -z "${BASH_VERSION:-}" ]; then
    command -v bash >/dev/null 2>&1 && exec bash "$0" "$@"
    echo "fabric-edit-gate: bash is not on PATH, so this edit was not checked." >&2
    exit 1
fi
set -uo pipefail

INPUT=$(cat)

# Item folder suffix -> owning skill. Each suffix is the Fabric ItemType a Git
# sync writes as the folder's extension, as each skill's when_to_use lists it
# (each skill's SKILL.md, 2026-11-13). Keep the two in step.
owner_of() {
    case "$1" in
        DataPipeline | Dataflow | Notebook | Lakehouse | SparkJobDefinition | \
            Environment | Warehouse | SQLEndpoint | WarehouseSnapshot | SQLDatabase)
            echo data-items ;;
        SemanticModel | Report) echo pbi-items ;;
        Eventhouse | KQLDatabase | Eventstream | EventSchemaSet | Reflex | \
            KQLDashboard | KQLQueryset)
            echo rti-items ;;
        Ontology | GraphModel | GraphQuerySet | DataAgent | OperationsAgent)
            echo iq-items ;;
        VariableLibrary) echo variable-library ;;
        *) return 1 ;;
    esac
}
SUFFIXES='DataPipeline|Dataflow|Notebook|Lakehouse|SparkJobDefinition|Environment|Warehouse|SQLEndpoint|WarehouseSnapshot|SQLDatabase|SemanticModel|Report|Eventhouse|KQLDatabase|Eventstream|EventSchemaSet|Reflex|KQLDashboard|KQLQueryset|Ontology|GraphModel|GraphQuerySet|DataAgent|OperationsAgent|VariableLibrary'

# Cheap prefilter on the raw payload: no item suffix followed by a separator
# anywhere, no item edit. Case kept, so Foo.warehouse/ is no item.
[[ $INPUT =~ \.($SUFFIXES)(/|\\\\) ]] || exit 0

unchecked() {
    echo "fabric-edit-gate: $1, so this edit was not checked." >&2
    exit 1
}

# Bounded jq, so a dying shell strands no jq on an open stdin, retried bare
# where timeout cannot run (126, 127) or is Windows' TIMEOUT.EXE, which
# rejects the syntax and exits 1.
jq_input() {
    local rc=0
    printf '%s\n' "$INPUT" | timeout 5 "$JQ" -r "$@" 2>/dev/null || rc=$?
    [[ $rc -eq 1 || $rc -eq 126 || $rc -eq 127 ]] || return "$rc"
    printf '%s\n' "$INPUT" | "$JQ" -r "$@" 2>/dev/null
}

# jq off PATH: the toolchain plugin, which this plugin depends on, fetches
# one into its own data folder, a sibling of this one, and the PATH it adds
# reaches the Bash tool and no plugin's hook (toolchain.sh's header). A
# C:/ path globs as it is, and is run by its full path, never put on PATH,
# whose colon would split it.
JQ=jq
if ! command -v jq >/dev/null 2>&1; then
    JQ=
    DATA=${CLAUDE_PLUGIN_DATA:-}
    DATA=${DATA//\\//}
    if [[ -n $DATA ]]; then
        for f in "${DATA%/}"/../toolchain-*/bin/jq.exe "${DATA%/}"/../toolchain-*/bin/jq; do
            [[ -x $f ]] && JQ=$f && break
        done
    fi
    [[ -n $JQ ]] || unchecked "jq is not on PATH, nor in the toolchain plugin's data folder"
fi
# Joined on the unit separator, not a tab: IFS collapses runs of whitespace,
# so a main session's empty agent_id would shift transcript_path into it.
FIELDS=$(jq_input '[.tool_input.file_path // "", .session_id // "",
    .agent_id // "", .transcript_path // ""] | join("\u001f")') ||
    unchecked "jq could not read the hook input (exit $?)"
IFS=$'\x1f' read -r FILE_PATH SESSION_ID AGENT_ID TRANSCRIPT <<<"$FIELDS"

# The item is the innermost folder named <name>.<Suffix> on the file's own
# path, never a suffix that only new_string or content mentioned.
SUFFIX=
NORM=${FILE_PATH//\\//}
while [[ $NORM =~ \.($SUFFIXES)/ ]]; do
    SUFFIX=${BASH_REMATCH[1]}
    NORM=${NORM#*"${BASH_REMATCH[0]}"}
done
[[ -n $SUFFIX ]] || exit 0
OWNER=$(owner_of "$SUFFIX") || exit 0

# The context's own transcript: the subagent's when there is one.
to_unix() { cygpath -u "$1" 2>/dev/null || printf '%s\n' "$1"; }
LOG=
if [[ -n $TRANSCRIPT ]]; then
    LOG=$(to_unix "$TRANSCRIPT")
    if [[ -n $AGENT_ID ]]; then
        LOG="${LOG%/*}/$SESSION_ID/subagents/agent-$AGENT_ID.jsonl"
    fi
fi

# One refusal per skill per context. CLAUDE_PLUGIN_DATA is set for an
# installed or --plugin-dir plugin (2026-11-13); TMPDIR may be unset in Git Bash,
# so the last fallback is the user's temp folder. Once this context has been
# refused, every answer is allow, so the transcript, tens of MB in a long
# session, is not searched again.
STATE="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-${TEMP:-/tmp}}}"
STATE="$(to_unix "$STATE")/fabric-edit-gate"
MARK="$STATE/${SESSION_ID:-nosession}${AGENT_ID:+-$AGENT_ID}.$OWNER"
[[ -d $MARK ]] && exit 0

NAME="([A-Za-z0-9_.-]+:)?$OWNER"
if [[ -n $LOG && -f $LOG ]] &&
    grep -qE "\"name\":\"Skill\",\"input\":\{\"skill\":\"$NAME\"|<command-name>/$NAME</command-name>" "$LOG"; then
    exit 0
fi

# Not invoked: refuse, unless a parallel edit made the marker first.
mkdir -p "$STATE" 2>/dev/null || unchecked "it could not create $STATE"
mkdir "$MARK" 2>/dev/null || exit 0

cat >&2 <<EOF
fabric-edit-gate: $FILE_PATH is inside a .$SUFFIX item, which the $OWNER skill covers, and $OWNER has not been invoked in this context.
Invoke $OWNER with the Skill tool (it may be listed with a plugin prefix, such as fabric:$OWNER), read the reference it names for a .$SUFFIX item, then make this edit again.
This gate refuses once per skill: a second attempt goes through.
EOF
exit 2
