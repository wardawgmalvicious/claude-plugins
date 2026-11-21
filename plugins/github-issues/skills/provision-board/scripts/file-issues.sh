#!/usr/bin/env bash
# Files the briefs brief-bodies.py wrote as issues in a repo, each added to
# a board with its Status, Priority, Reopen-when, Work model and Work
# effort set, a needs:* label per need and a platform:* label per platform.
# Labels go on only when an issue is filed or named: one found already filed
# keeps its labels as they are, so a platform added to a filed brief is added
# to its issue by hand, gh issue edit <n> --add-label platform:<value>.
#
# AN ISSUE THAT ALREADY EXISTS IS NAMED, NOT MATCHED. A manifest row with
# "issue": <n>, from a draft naming issue: <n>, puts that issue on the board:
# nothing is created, its body and title stay as they are, and its needs and
# platform labels are added to those it has, removed from none. Its number
# is checked with the links below, a closed one is reported with its card
# untouched, and its card and links then go as any brief's do, the Status
# read-back included.
#
# RESUMABLE, BECAUSE AN ISSUE CANNOT BE UNFILED. Before filing a brief it
# looks on GitHub for an issue already filed from it: each body opens with
# the line brief-bodies.py writes, whose opening the manifest carries, and
# every issue in the repo, open or closed, is listed once and matched on
# that opening exactly; search would be fuzzy and lags a new issue. So a
# rerun from another session, whose out-dir is new, or after a create that
# timed out here once GitHub had made the issue, files nothing twice, as a
# per-session record alone did not (2026-10-27). Two or more issues from
# one brief are reported, never picked between: close all but one as a
# duplicate, which then no longer counts, and rerun. A brief whose one issue
# is closed is reported too, its card untouched: a queued brief's issue
# should be open, so either it landed without its file going, or a new
# brief took a landed one's name, and which is the user's call.
#
# created.<repo>.tsv, beside the manifest, records each issue the moment it
# exists or is found, the fast path within one out-dir; done.<owner>-<board>.tsv
# records each brief whose card is set. A rerun skips both.
#
# A CARD ALREADY ON THE BOARD KEEPS ITS VALUES. A rerun, from a new out-dir
# above all, would otherwise put back the brief's Priority, Reopen-when and
# work advice over what update-issue set since, on either kind of board. A
# blank is still filled, so a run that stopped part way is finished.
#
# THE STATUS IS READ BACK. A template's Item added to project sets Open on
# every card added, and whether that lands before or after this script's
# own Status write is untested. So once every card is set, it waits, reads
# every card's Status, and sets again each one that differs from its brief.
# A rerun with nothing left to file runs that check alone. A card reading
# In flight or Done is left so, by both writes: a session has claimed it,
# or the board's Item closed workflow or a hand has moved it, and a brief's
# frontmatter has no such value to set in its place.
#
# EACH CARD IS READ FROM ITS ISSUE, NOT FROM THE BOARD'S LISTING. gh project
# item-list fetches every field value of every item, 101 points a page of
# 100, so the two listings a run made of a 307-item board cost about 808 of
# GraphQL's 5,000 an hour, and the reruns an orphaned card invited spent the
# hour (2026-11-05). An issue's own projectItems, filtered to this board,
# cost 1 point. The read-back adds one listing of the board's card ids, 1
# point a page, since an issue can hold a card the board does not list:
# one issue's did, so no rerun could see it (2026-11-05). Such a card prints
# "orphaned:" with the steps that restored that one: delete it, add the issue
# again, and set the new card to the values printed. The listing may lag as
# an add does, so a card is deleted only when a rerun names it again, three
# minutes or more after filing: one card was named at filing and by a rerun
# 37 s later, then listed about 3 minutes in, untouched (2026-11-06, one
# card, seen once). A
# listing with no ids names no orphan but stops the run. An issue with no
# card on this board still stops the run, as one whose add has not shown yet.
#
# A RATE-LIMIT REFUSAL NAMES ITS RESET. The board reads go through gh api
# graphql -i, so a RATE_LIMIT refusal stops the run with the reset its own
# response carries, as UTC, and the points this run's board reads spent. No
# gh api rate_limit gates the run: it is a request of its own, and its count
# need not match the next refusal's. Any other gh call that hits the limit
# fails as any failure does.
#
# LINKS ARE GITHUB'S OWN. A brief's parent and each blocker that is an
# issue by number must exist in the repo, checked before anything is
# filed. A new issue is created with its parent and every blocker whose
# issue exists by then; once every card is set, each open issue gains the
# parent and blockers its brief names and it lacks, a found one's read
# from the list, so a blocker filed later in the run is linked too. A link
# is added, never removed, and an issue under another parent than its
# brief names is reported, not moved: a child has one parent, and which is
# the user's call. A blocker whose brief has no issue yet is reported,
# since filing it and rerunning links it.
#
# THE ACCOUNT IS PINNED HERE, SO A CALLER NEED NOT. --login names the
# account that should own the writes, as provision-board passes the one its
# user picked: the token is minted for it, whatever GH_TOKEN holds, and the
# run stops unless gh then acts as it. With no --login, a caller's GH_TOKEN
# is kept, and with none set either, the token is minted for git config
# user.name in the working directory, the account file-issue checks: a
# script's gh is whatever PATH finds first, and the raw gh.exe answers as
# the keyring's active account, which may be another identity. A caller
# needing no pin line matters in a worktree session, whose guard refuses
# any export GH_TOKEN="$(...)" as too complex to verify (2.1.317,
# 2026-11-03). gh reads an empty GH_TOKEN as unset, so one set empty, a
# caller's pin that failed, stops the run, as does a mint that prints
# nothing.
#
# Usage, after brief-bodies.py exited 0:
#   file-issues.sh --owner <login> --project <number> --repo <owner/name> --manifest <path> [--login <account>]
#
# stdout: one "filed:" line per issue filed, "found:" per issue already
# filed, matched on the list or recorded by an earlier run in this out-dir, so
# a rerun's report still names each number, "board:" per existing issue named
# on its first run, "duplicate:" per brief filed more
# than once, "closed:" per brief whose one issue is closed or that names a
# closed one, "linked:" per issue given a link, "unlinked:"
# per blocker whose brief has no issue yet, "parent differs:" per issue
# under another parent, "orphaned:" per card the board does not list, and a
# count. stderr: progress. Exit 0
# every brief on the board as its frontmatter says, 1 a failure part way,
# a rate limit, a brief filed more than once or only as a closed issue, an
# issue under another parent or an orphaned card (fix it and rerun),
# 2 a usage error.
# shellcheck disable=SC2016 # each single-quoted $ is a jq variable
set -euo pipefail

# The range ends on the line closing the exit codes' sentence, so a rewrap
# of it moves the end marker too; the suite's no-arguments case pins it.
usage() {
    sed -n '/^# Usage/,/ 2 a usage error\.$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
    exit 2
}

OWNER="" NUM="" REPO="" MANIFEST="" LOGIN_ARG="" LOGIN_GIVEN=0
while (($# >= 2)); do
    case $1 in
    --owner) OWNER=$2 ;;
    --project) NUM=$2 ;;
    --repo) REPO=$2 ;;
    --manifest) MANIFEST=$2 ;;
    --login) LOGIN_ARG=$2 LOGIN_GIVEN=1 ;;
    *) usage ;;
    esac
    shift 2
done
(($# == 0)) && [[ -n $OWNER && $NUM =~ ^[0-9]+$ && $REPO == */* && -f $MANIFEST ]] || usage
# A --login given empty is a caller's variable gone missing, never a fall
# back to user.name.
((! LOGIN_GIVEN)) || [[ $LOGIN_ARG =~ ^[A-Za-z0-9_-]+$ ]] || usage

for tool in gh jq; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "error: $tool not found on PATH" >&2
        exit 1
    }
done

JQ_BIN=()
case "$OSTYPE" in msys* | cygwin*) JQ_BIN=(-b) ;; esac
jqb() { jq "${JQ_BIN[@]}" "$@"; }

# An empty opening would match every issue, so a manifest from before the
# field existed stops here rather than reading every brief as filed. A row
# naming its issue has none, and is never matched.
jqb -e 'all(.[]; .issue != null or (.opening // "") != "")' "$MANIFEST" >/dev/null || {
    echo "error: a brief in $MANIFEST has no opening to match; rerun brief-bodies.py" >&2
    exit 1
}

# The account; see the header. Before any state file or other gh call, so a
# refused token leaves nothing behind.
LOGIN="" NAMED_BY=""
if ((LOGIN_GIVEN)); then
    unset GH_TOKEN
    LOGIN=$LOGIN_ARG NAMED_BY=--login
elif [[ -n ${GH_TOKEN+set} ]]; then
    [[ -n $GH_TOKEN ]] || {
        echo "error: GH_TOKEN is set but empty, so the caller's pin failed; nothing is filed" >&2
        exit 1
    }
else
    LOGIN=$(git config user.name) || LOGIN=""
    NAMED_BY="git config user.name"
    [[ -n $LOGIN ]] || {
        echo "error: no GH_TOKEN, and git config user.name names no account to pin; nothing is filed" >&2
        exit 1
    }
fi
if [[ -n $LOGIN ]]; then
    GH_TOKEN=$(command gh auth token --user "$LOGIN") || GH_TOKEN=""
    [[ -n $GH_TOKEN ]] || {
        echo "error: gh has no token for $LOGIN, the account $NAMED_BY names; nothing is filed" >&2
        exit 1
    }
    export GH_TOKEN
fi

# Each lookup is an assignment, never inside a command's arguments, where a
# failure would be dropped and the script go on.
ME=$(gh api user -q .login)
echo "acting as $ME" >&2
# Case-blind, as GitHub's logins are: a typed Foo is the account foo.
if ((LOGIN_GIVEN)) && [[ ${ME,,} != "${LOGIN,,}" ]]; then
    echo "error: gh acts as $ME, but --login names $LOGIN; nothing is filed" >&2
    exit 1
fi

# The state files are named for the repo and the board they record, so
# the same out-dir aimed at another repo or board starts afresh rather
# than reusing issues or skipping cards that are not there.
DIR=$(cd "$(dirname "$MANIFEST")" && pwd)
CREATED=$DIR/created.${REPO//\//_}.tsv
DONE=$DIR/done.$OWNER-$NUM.tsv
touch "$CREATED" "$DONE"

PID=$(gh project view "$NUM" --owner "$OWNER" --format json | jqb -r .id)
FIELDS=$(gh project field-list "$NUM" --owner "$OWNER" --format json -L 100)
field_id() { jqb -r --arg n "$1" '[.fields[] | select(.name == $n) | .id][0] // empty' <<<"$FIELDS"; }
option_id() {
    jqb -r --arg f "$1" --arg o "$2" \
        '[.fields[] | select(.name == $f) | .options[]? | select(.name == $o) | .id][0] // empty' <<<"$FIELDS"
}
STATUS=$(field_id Status)
REOPEN=$(field_id Reopen-when)
for field in Status Priority Reopen-when "Work model" "Work effort"; do
    [[ -n $(field_id "$field") ]] || {
        echo "error: the board has no $field field; run provision-board.sh first" >&2
        exit 1
    }
done
# An organization's own Priority, an issue field, lists no options on the
# board and its value lives on the issue, so it takes set_issue_priority;
# with no such field no card could hold a Priority, which stops the run here.
ISSUE_PRIORITY=""
PRIORITY_OPTION=$(jqb -r '[.fields[] | select(.name == "Priority") | .options[]?.name][0] // empty' <<<"$FIELDS")
if [[ -z $PRIORITY_OPTION ]]; then
    ISSUE_PRIORITY=$(printf '%s' 'query($o: String!, $n: String!) { repository(owner: $o, name: $n) {
        issueFields(first: 25) { nodes { ... on IssueFieldSingleSelect { id name options { id name } } } } } }' |
        gh api graphql -F query=@- -f o="${REPO%%/*}" -f n="${REPO#*/}" |
        jqb -c '[.data.repository.issueFields.nodes[]? | select(.name == "Priority")][0] // empty')
    [[ -n $ISSUE_PRIORITY ]] || {
        echo "error: the board's Priority lists no options and $REPO has no such issue field" >&2
        exit 1
    }
fi

# Labels the manifest needs, created where missing, never --force'd.
HAVE_LABELS=$(gh label list --repo "$REPO" --search "needs:" --json name -L 200 | jqb -r '.[].name')
while IFS= read -r need; do
    [[ -n $need ]] || continue
    if ! grep -qixF "needs:$need" <<<"$HAVE_LABELS"; then
        gh label create "needs:$need" --repo "$REPO" --color c5def5 \
            --description "The brief needs: $need" >/dev/null
        echo "created label needs:$need" >&2
    fi
done < <(jqb -r '[.[].needs[]] | unique[]' "$MANIFEST")
# platform:* likewise, with no fixed set: brief-bodies.py has already held
# each value to lowercase kebab and named it for the yes to file, and a
# manifest from before the field carries none.
HAVE_PLATFORMS=$(gh label list --repo "$REPO" --search "platform:" --json name -L 200 | jqb -r '.[].name')
while IFS= read -r platform; do
    [[ -n $platform ]] || continue
    if ! grep -qixF "platform:$platform" <<<"$HAVE_PLATFORMS"; then
        gh label create "platform:$platform" --repo "$REPO" --color d4c5f9 \
            --description "The work touches: $platform" >/dev/null
        echo "created label platform:$platform" >&2
    fi
done < <(jqb -r '[.[].platform // [] | .[]] | unique[]' "$MANIFEST")

# Every issue in the repo, for the match the header describes. A failed
# list stops the script here, and so does a full one, which may have left
# out the issue a brief was filed as: read as none, either would file again.
LIMIT=10000
ISSUES=$(gh issue list --repo "$REPO" --state all \
    --json url,number,body,state,stateReason,parent,blockedBy -L "$LIMIT")
LISTED=$(jqb length <<<"$ISSUES")
((LISTED < LIMIT)) || {
    echo "error: $REPO lists $LISTED issues, the limit; raise LIMIT so none is missed" >&2
    exit 1
}
# filed_from <opening>: the URL of each issue filed from the brief, one a
# line, oldest first
filed_from() {
    jqb -r --arg o "$1" '
        [.[] | select(.stateReason != "DUPLICATE" and ((.body // "") | startswith($o))) | .url]
        | sort_by(split("/") | last | tonumber)[]' <<<"$ISSUES"
}
# issue_state <url>: OPEN or CLOSED, null for one filed after the list
issue_state() { jqb -r --arg u "$1" '[.[] | select(.url == $u) | .state][0]' <<<"$ISSUES"; }
# issue_url <number>: the URL of the repo's issue of that number, empty for none
issue_url() { jqb -r --argjson n "$1" '[.[] | select(.number == $n) | .url][0] // empty' <<<"$ISSUES"; }

# Every issue a brief names as its own, its parent or a blocker, checked
# before anything is filed: a create naming one that is not there fails part
# way, and a row naming its own would be created from a body only counted.
# An assignment, so a failed read stops the script rather than passing the
# guard, as a process substitution would.
NAMED=$(jqb -r '[.[] | (.issue // empty), (.parent // empty), (.blockers // [] | .[] | .issue // empty)] | unique[]' "$MANIFEST")
MISSING=()
while IFS= read -r number; do
    [[ -n $number ]] || continue
    [[ -n $(issue_url "$number") ]] || MISSING+=("#$number")
done <<<"$NAMED"
if ((${#MISSING[@]})); then
    echo "error: the briefs name ${MISSING[*]}, no issue of $REPO; fix their issue, parent or blocked-by" >&2
    exit 1
fi

# blocker_url <blocker>: the URL of the issue a manifest blocker names,
# empty while there is none: an issue by its number, a brief by the issue
# recorded for it or the one its opening finds
blocker_url() {
    local number file url matches
    number=$(jqb -r '.issue // empty' <<<"$1")
    if [[ -n $number ]]; then
        issue_url "$number"
        return
    fi
    file=$(jqb -r .file <<<"$1")
    url=$(awk -F'\t' -v f="$file" '$1 == f { print $2 }' "$CREATED")
    if [[ -n $url ]]; then
        printf '%s\n' "$url"
        return
    fi
    matches=$(filed_from "$(jqb -r .opening <<<"$1")")
    # Two from one brief name no one issue, as the filing loop says.
    [[ -z $matches || $matches == *$'\n'* ]] || printf '%s\n' "$matches"
}

# want_links <row>: sets WANT_PARENT, the parent's URL; WANT_BLOCKERS, each
# blocker's issue URL; and UNRESOLVED, each blocker with no issue yet
want_links() {
    local parent blocker url
    WANT_PARENT="" WANT_BLOCKERS=() UNRESOLVED=()
    parent=$(jqb -r '.parent // empty' <<<"$1")
    [[ -z $parent ]] || WANT_PARENT=$(issue_url "$parent")
    while IFS= read -r blocker; do
        [[ -n $blocker ]] || continue
        url=$(blocker_url "$blocker")
        if [[ -n $url ]]; then
            WANT_BLOCKERS+=("$url")
        else
            UNRESOLVED+=("$(jqb -r '.file // .issue' <<<"$blocker")")
        fi
    done < <(jqb -c '.blockers // [] | .[]' <<<"$1")
}
# joined <item>...: the items, comma-joined, as gh takes a list
joined() { (
    IFS=,
    printf '%s' "$*"
); }
# label_args <row> <flag>: sets LABELS, the flag before each needs:* and
# platform:* label the row names. An assignment, so a failed read stops the
# script rather than marking a named issue's row done with no labels.
label_args() {
    local label names
    names=$(jqb -r '(.needs[] | "needs:\(.)"), (.platform // [] | .[] | "platform:\(.)")' <<<"$1")
    LABELS=()
    while IFS= read -r label; do
        if [[ -n $label ]]; then LABELS+=("$2" "$label"); fi
    done <<<"$names"
}
# The links each issue filed in this run was created with, by URL, as
# "<parent URL>\t<blocker URLs>": the list predates it.
declare -A MADE=()

# set_status <item> <status name>
set_status() {
    local opt
    opt=$(option_id Status "$2")
    [[ -n $opt ]] || {
        echo "error: the Status field has no option $2" >&2
        return 1
    }
    gh project item-edit --id "$1" --project-id "$PID" --field-id "$STATUS" \
        --single-select-option-id "$opt" >/dev/null
}

# set_select <item> <field> <option> <brief>: a blank option is left
# blank, as is one the field lacks, with a warning.
set_select() {
    local opt
    [[ -n $3 ]] || return 0
    opt=$(option_id "$2" "$3")
    if [[ -z $opt ]]; then
        echo "warning: no $2 option $3 for $4; left blank" >&2
        return 0
    fi
    gh project item-edit --id "$1" --project-id "$PID" --field-id "$(field_id "$2")" \
        --single-select-option-id "$opt" >/dev/null
}

# priority_name <P level>: the option a brief's level maps to, the map
# board-contract.md § "Fields" holds, on either kind of board; any other as
# given, so the warning for an option the field lacks names it.
priority_name() {
    case $1 in
    P1) printf High ;;
    P2) printf Medium ;;
    P3) printf Low ;;
    *) printf '%s' "$1" ;;
    esac
}

# set_card_priority <item> <P level> <brief>: a project field's Priority by
# its name, or a board not yet moved off P1 to P3 by the level itself, which
# provision-board moves. Urgent is a person's, and so is any value on a card
# already there, so a rerun leaves either.
set_card_priority() {
    local name by_name by_level current
    name=$(priority_name "$2")
    by_name=$(option_id Priority "$name")
    by_level=$(option_id Priority "$2")
    [[ -n $by_name || -z $by_level ]] || name=$2
    current=$(card_value priority)
    if [[ $current == Urgent ]]; then
        echo "left $3's Priority Urgent, as a person set it" >&2
        return 0
    fi
    if [[ -n $current ]]; then
        echo "left $3's Priority $current, as its card was already on the board" >&2
        return 0
    fi
    set_select "$1" Priority "$name" "$3"
}

# set_issue_priority <issue url> <P level> <brief> <was on the board: 0 or 1>:
# the level as an organization's field names it, with the same warning as
# set_select for a level the field lacks. Urgent is a person's, and so is any
# value on a card already there, so a rerun leaves either.
set_issue_priority() {
    local name opt id field current
    [[ -n $2 ]] || return 0
    name=$(priority_name "$2")
    opt=$(jqb -r --arg o "$name" '[.options[] | select(.name == $o) | .id][0] // empty' <<<"$ISSUE_PRIORITY")
    if [[ -z $opt ]]; then
        echo "warning: no Priority option $name for $3; left blank" >&2
        return 0
    fi
    id=$(gh issue view "$1" --repo "$REPO" --json id -q .id)
    current=$(printf '%s' 'query($i: ID!) { node(id: $i) { ... on Issue { issueFieldValues(first: 25) { nodes {
        ... on IssueFieldSingleSelectValue { name field { ... on IssueFieldSingleSelect { name } } } } } } } }' |
        gh api graphql -F query=@- -f i="$id" |
        jqb -r '[.data.node.issueFieldValues.nodes[]? | select(.field.name == "Priority") | .name][0] // empty')
    if [[ $current == Urgent ]]; then
        echo "left $3's Priority Urgent, as a person set it" >&2
        return 0
    fi
    if [[ -n $current && $4 == 1 ]]; then
        echo "left $3's Priority $current, as its card was already on the board" >&2
        return 0
    fi
    field=$(jqb -r .id <<<"$ISSUE_PRIORITY")
    printf '%s' 'mutation($i: ID!, $f: ID!, $o: ID!) { setIssueFieldValue(input: {issueId: $i,
        issueFields: [{fieldId: $f, singleSelectOptionId: $o}]}) { clientMutationId } }' |
        gh api graphql -F query=@- -f i="$id" -f f="$field" -f o="$opt" >/dev/null
}

# add_item <url>: the id of the issue's card, added if it has none. Adding
# an item the board already holds returns its card (GitHub's "Using the API
# to manage Projects", read 2026-10-28), but a new issue can race the
# board's Auto-add workflow, and an add that loses the race is refused,
# "Content already exists in this project": the cutover stopped there four
# times, and each rerun's add returned the card (2026-10-28). So that
# refusal is retried twice, two seconds apart, in case the workflow's add
# is still landing, and any other stops the run.
ADD_ERR=$(mktemp)
trap 'rm -f "$ADD_ERR"' EXIT
add_item() {
    local out tries=3
    while :; do
        if out=$(gh project item-add "$NUM" --owner "$OWNER" --url "$1" --format json 2>"$ADD_ERR"); then
            [[ ! -s $ADD_ERR ]] || cat "$ADD_ERR" >&2
            jqb -r .id <<<"$out"
            return
        fi
        tries=$((tries - 1))
        if ((tries == 0)) || ! grep -qF "Content already exists in this project" "$ADD_ERR"; then
            cat "$ADD_ERR" >&2
            return 1
        fi
        echo "$1 was on the board before its add, by the board's workflow; adding again for its card" >&2
        sleep 2
    done
}

# The board reads; see the header. response_header <raw response> <name in
# lowercase>: that header's value from gh api -i's output, empty for none
response_header() {
    awk -v k="$2" '/^\r?$/ { exit } { sub(/\r$/, ""); i = index($0, ":") }
        i && tolower(substr($0, 1, i - 1)) == k { v = substr($0, i + 1); sub(/^ +/, "", v); print v; exit }' <<<"$1"
}
# board_query <query> [gh api argument]...: sets GQL to the response's body
# and adds its rateLimit.cost to SPENT, so it is never run in a $(...),
# whose subshell would keep both. A RATE_LIMIT refusal stops the run naming
# its reset; any other failure stops it as gh reported it.
GQL="" SPENT=0 FIRST_USED="" FIRST_LIMIT=""
board_query() {
    local raw rc=0 cost reset
    raw=$(printf '%s' "$1" | gh api graphql -i -F query=@- "${@:2}") || rc=$?
    GQL=$(awk 'p { print; next } /^\r?$/ { p = 1 }' <<<"$raw")
    if [[ -z $FIRST_USED ]]; then
        FIRST_USED=$(response_header "$raw" x-ratelimit-used)
        FIRST_LIMIT=$(response_header "$raw" x-ratelimit-limit)
    fi
    if ((rc == 0)); then
        cost=$(jqb -r '.data.rateLimit.cost // 0' <<<"$GQL")
        [[ $cost =~ ^[0-9]+$ ]] || cost=0
        SPENT=$((SPENT + cost))
        return 0
    fi
    if jqb -e 'any(.errors[]?; .type == "RATE_LIMIT")' <<<"$GQL" >/dev/null 2>&1; then
        reset=$(response_header "$raw" x-ratelimit-reset)
        [[ ! $reset =~ ^[0-9]+$ ]] || reset=$(date -u -d "@$reset" +%Y-%m-%dT%H:%M:%SZ)
        echo "error: GitHub's GraphQL rate limit refused a board read; it resets at ${reset:-a time the response did not give}." \
            "This run's board reads spent $SPENT points, and ${FIRST_USED:-?} of ${FIRST_LIMIT:-?} were used at the first of them; rerun after the reset" >&2
    fi
    exit 1
}

# card <url>: sets CARD to the issue's card on this board, keyed as gh's
# listing keys a card, or null where it has none
CARD_QUERY='query($o: String!, $n: String!, $i: Int!) { repository(owner: $o, name: $n) { issue(number: $i) {
    projectItems(first: 50) { nodes { id isArchived project { id }
        status: fieldValueByName(name: "Status") { ... on ProjectV2ItemFieldSingleSelectValue { name } }
        priority: fieldValueByName(name: "Priority") { ... on ProjectV2ItemFieldSingleSelectValue { name } }
        model: fieldValueByName(name: "Work model") { ... on ProjectV2ItemFieldSingleSelectValue { name } }
        effort: fieldValueByName(name: "Work effort") { ... on ProjectV2ItemFieldSingleSelectValue { name } }
        reopen: fieldValueByName(name: "Reopen-when") { ... on ProjectV2ItemFieldTextValue { text } } } } } }
    rateLimit { cost } }'
CARD=null
card() {
    board_query "$CARD_QUERY" -f o="${REPO%%/*}" -f n="${REPO#*/}" -F i="${1##*/}"
    CARD=$(jqb -c --arg p "$PID" '[.data.repository.issue.projectItems.nodes[]? | select(.project.id == $p)
        | {id, archived: .isArchived, status: (.status.name // ""), priority: (.priority.name // ""),
           "work model": (.model.name // ""), "work effort": (.effort.name // ""),
           "reopen-when": (.reopen.text // "")}][0]' <<<"$GQL")
}

# board_ids: sets BOARD_IDS to the id of every card the board lists, one a
# line, a page of 100 at a time
LIST_QUERY='query($p: ID!, $c: String) { node(id: $p) { ... on ProjectV2 { items(first: 100, after: $c) {
    pageInfo { hasNextPage endCursor } nodes { id } } } } rateLimit { cost } }'
board_ids() {
    local cursor="" args
    BOARD_IDS=""
    while :; do
        args=(-f p="$PID")
        [[ -z $cursor ]] || args+=(-f c="$cursor")
        board_query "$LIST_QUERY" "${args[@]}"
        BOARD_IDS+=$(jqb -r '.data.node.items.nodes[]?.id' <<<"$GQL")$'\n'
        [[ $(jqb -r '.data.node.items.pageInfo.hasNextPage' <<<"$GQL") == true ]] || break
        cursor=$(jqb -r '.data.node.items.pageInfo.endCursor' <<<"$GQL")
    done
}

# Each card is read just before this run's writes to it, for the claims the
# header keeps. A claim made between the read and a write is still written
# over; the window is one card's handful of calls, and is accepted. An
# issue filed in this run had no card before it, so it is not read.
# kept_status <status>: true for a Status no brief's frontmatter can express,
# which both writes leave as they find it
kept_status() { [[ $1 == "In flight" || $1 == "Done" ]]; }
# card_value <gh's lowercase key>: that field's value on CARD, empty for none
card_value() { jqb -r --arg k "$1" '.[$k] // ""' <<<"$CARD"; }
# keeps <key>: true where the card already held a value of that field
keeps() { [[ -n $(card_value "$1") ]]; }

COUNT=$(jqb length "$MANIFEST")
DUPES=0 CLOSED=0
for ((i = 0; i < COUNT; i++)); do
    ROW=$(jqb -c ".[$i]" "$MANIFEST")
    FILE=$(jqb -r .file <<<"$ROW")
    URL=$(awk -F'\t' -v f="$FILE" '$1 == f { print $2 }' "$CREATED")
    if grep -qxF "$FILE" "$DONE"; then
        [[ -z $URL ]] || printf 'found: %s %s\n' "$FILE" "$URL"
        continue
    fi
    RECORDED=$URL
    EXISTING=$(jqb -r '.issue // empty' <<<"$ROW")
    if [[ -z $URL && -n $EXISTING ]]; then
        URL=$(issue_url "$EXISTING")
        if [[ $(issue_state "$URL") == CLOSED ]]; then
            printf 'closed: %s names #%s, which is closed\n' "$FILE" "$EXISTING"
            CLOSED=$((CLOSED + 1))
            continue
        fi
        printf '%s\t%s\n' "$FILE" "$URL" >>"$CREATED"
        printf 'board: %s %s\n' "$FILE" "$URL"
    elif [[ -z $URL ]]; then
        # An assignment, so a failed match stops the script rather than
        # reading as none filed, as a process substitution would.
        MATCHES=$(filed_from "$(jqb -r .opening <<<"$ROW")")
        FOUND=()
        [[ -z $MATCHES ]] || mapfile -t FOUND <<<"$MATCHES"
        if ((${#FOUND[@]} > 1)); then
            printf 'duplicate: %s filed as' "$FILE"
            printf ' #%s' "${FOUND[@]##*/}"
            printf '\n'
            DUPES=$((DUPES + 1))
            continue
        elif ((${#FOUND[@]} == 1)); then
            URL=${FOUND[0]}
            if [[ $(issue_state "$URL") != CLOSED ]]; then
                printf '%s\t%s\n' "$FILE" "$URL" >>"$CREATED"
                printf 'found: %s %s\n' "$FILE" "$URL"
            fi
        fi
    fi
    # Found now or recorded by an earlier run in this out-dir, either way.
    if [[ -n $URL ]]; then
        ISSUE_STATE=$(issue_state "$URL")
        if [[ $ISSUE_STATE == CLOSED ]]; then
            printf 'closed: %s filed as #%s, now closed\n' "$FILE" "${URL##*/}"
            CLOSED=$((CLOSED + 1))
            continue
        fi
        [[ -z $RECORDED ]] || printf 'found: %s %s\n' "$FILE" "$URL"
    fi
    CARD=null
    if [[ -n $URL ]]; then
        card "$URL"
    else
        label_args "$ROW" --label
        # Its parent, and each blocker filed by now; the rest after the loop.
        want_links "$ROW"
        LINKS=()
        [[ -z $WANT_PARENT ]] || LINKS+=(--parent "$WANT_PARENT")
        ((${#WANT_BLOCKERS[@]} == 0)) || LINKS+=(--blocked-by "$(joined "${WANT_BLOCKERS[@]}")")
        URL=$(gh issue create --repo "$REPO" --title "$(jqb -r .title <<<"$ROW")" \
            --body-file "$DIR/$(jqb -r .body <<<"$ROW")" "${LINKS[@]}" "${LABELS[@]}")
        printf '%s\t%s\n' "$FILE" "$URL" >>"$CREATED"
        MADE[$URL]=$WANT_PARENT$'\t'$(joined "${WANT_BLOCKERS[@]}")
        printf 'filed: %s %s\n' "$FILE" "$URL"
    fi
    ITEM=$(add_item "$URL")
    CURRENT=$(card_value status)
    if kept_status "$CURRENT"; then
        echo "left $FILE's Status $CURRENT, as the board set it" >&2
    else
        set_status "$ITEM" "$(jqb -r .status <<<"$ROW")"
    fi
    ON_BOARD=0
    [[ $CARD == null ]] || ON_BOARD=1
    if [[ -n $ISSUE_PRIORITY ]]; then
        set_issue_priority "$URL" "$(jqb -r .priority <<<"$ROW")" "$FILE" "$ON_BOARD"
    else
        set_card_priority "$ITEM" "$(jqb -r .priority <<<"$ROW")" "$FILE"
    fi
    keeps "work model" ||
        set_select "$ITEM" "Work model" "$(jqb -r '.work_model // ""' <<<"$ROW")" "$FILE"
    keeps "work effort" ||
        set_select "$ITEM" "Work effort" "$(jqb -r '.work_effort // ""' <<<"$ROW")" "$FILE"
    REOPEN_WHEN=$(jqb -r .reopen_when <<<"$ROW")
    if [[ -n $REOPEN_WHEN ]] && ! keeps "reopen-when"; then
        gh project item-edit --id "$ITEM" --project-id "$PID" --field-id "$REOPEN" \
            --text "$REOPEN_WHEN" >/dev/null
    fi
    if [[ -n $EXISTING ]]; then
        label_args "$ROW" --add-label
        ((${#LABELS[@]} == 0)) || gh issue edit "$URL" "${LABELS[@]}" >/dev/null
    fi
    printf '%s\n' "$FILE" >>"$DONE"
    echo "set $FILE" >&2
done

# The read-back; see the header. Ten seconds is a guess, not a
# measurement, which is why a rerun repeats the check. A closed issue's card
# was left as it was, so it is not read.
sleep 10
board_ids
RESET=0 ORPHANS=0
while IFS=$'\t' read -r file url; do
    [[ -n $file ]] || continue
    want=$(jqb -r --arg f "$file" '.[] | select(.file == $f) | .status' "$MANIFEST")
    [[ -n $want && $(issue_state "$url") != CLOSED ]] || continue
    card "$url"
    item=$(jqb -r '.id // empty' <<<"$CARD")
    have=$(card_value status)
    if [[ -z $item ]]; then
        echo "error: $url is not on the board; rerun once it shows" >&2
        exit 1
    fi
    # An archived card is checked as one listed, whether the listing holds
    # archived cards or not, so that is never read as an orphan.
    if [[ $(jqb -r .archived <<<"$CARD") != true ]] && ! grep -qxF "$item" <<<"$BOARD_IDS"; then
        if ! grep -q . <<<"$BOARD_IDS"; then
            echo "error: the board's listing came back with no cards, so $url is not called an orphan; rerun" >&2
            exit 1
        fi
        printf 'orphaned: %s %s holds card %s, which the board does not list\n' "$file" "$url" "$item"
        echo "hint: gh project item-delete $NUM --owner $OWNER --id $item" >&2
        echo "hint: gh project item-add $NUM --owner $OWNER --url $url" >&2
        echo "hint: then set the new card as this one reads: $(jqb -r 'def or_blank: if . == "" then "blank" else . end;
            "Status \(.status | or_blank), Priority \(.priority | or_blank), Work model \(."work model" | or_blank), Work effort \(."work effort" | or_blank), Reopen-when \(."reopen-when" | or_blank)"' <<<"$CARD")" >&2
        ORPHANS=$((ORPHANS + 1))
        continue
    fi
    if [[ $have != "$want" ]] && ! kept_status "$have"; then
        set_status "$item" "$want"
        RESET=$((RESET + 1))
        echo "set $file's Status again: read ${have:-blank}, wanted $want" >&2
    fi
done <"$CREATED"

# The links; see the header. Every open issue recorded, so a rerun with
# nothing left to file adds what an earlier run could not.
DIFFERS=0
while IFS=$'\t' read -r file url; do
    [[ -n $file ]] || continue
    ROW=$(jqb -c --arg f "$file" '[.[] | select(.file == $f)][0] // empty' "$MANIFEST")
    [[ -n $ROW && $(issue_state "$url") != CLOSED ]] || continue
    want_links "$ROW"
    if [[ -n ${MADE[$url]+set} ]]; then
        have=${MADE[$url]}
    else
        have=$(jqb -r --arg u "$url" '[.[] | select(.url == $u)][0]
            | "\(.parent.url // "")\t\([.blockedBy.nodes[]?.url] | join(","))"' <<<"$ISSUES")
    fi
    have_parent=${have%%$'\t'*}
    have_blockers=",${have#*$'\t'},"
    EDIT=() ADDED=()
    if [[ -n $WANT_PARENT && -z $have_parent ]]; then
        EDIT+=(--parent "$WANT_PARENT")
        ADDED+=("parent #${WANT_PARENT##*/}")
    elif [[ -n $WANT_PARENT && $have_parent != "$WANT_PARENT" ]]; then
        printf 'parent differs: %s is a sub-issue of %s; its brief names #%s\n' \
            "$url" "$have_parent" "${WANT_PARENT##*/}"
        DIFFERS=$((DIFFERS + 1))
    fi
    missing=()
    for blocker in "${WANT_BLOCKERS[@]}"; do
        [[ $blocker == "$url" || $have_blockers == *",$blocker,"* ]] || missing+=("$blocker")
    done
    if ((${#missing[@]})); then
        EDIT+=(--add-blocked-by "$(joined "${missing[@]}")")
        ADDED+=("blocked by $(printf '#%s ' "${missing[@]##*/}" | sed 's/ $//')")
    fi
    if ((${#EDIT[@]})); then
        # gh reads no stdin here, but the loop's is the record: keep it so.
        gh issue edit "$url" "${EDIT[@]}" >/dev/null </dev/null
        printf 'linked: %s #%s, %s\n' "$file" "${url##*/}" "$(joined "${ADDED[@]}" | sed 's/,/, /g')"
    fi
    for name in "${UNRESOLVED[@]}"; do
        printf 'unlinked: %s is blocked by %s, which has no issue yet\n' "$file" "$name"
    done
done <"$CREATED"

printf '%s of %s briefs on the board; %s Status values set again\n' \
    "$(wc -l <"$DONE" | tr -d ' ')" "$COUNT" "$RESET"
if ((DUPES || CLOSED || DIFFERS || ORPHANS)); then
    ((DUPES == 0)) ||
        echo "error: $DUPES briefs are filed more than once; close all but one of each as a duplicate (gh issue close <n> --duplicate-of <kept>), then rerun" >&2
    ((CLOSED == 0)) ||
        echo "error: $CLOSED briefs match or name only a closed issue; reopen it, drop a draft naming one, or rename a brief that took a landed one's name, then rerun" >&2
    ((DIFFERS == 0)) ||
        echo "error: $DIFFERS issues are sub-issues of another parent than their brief names; move each by hand, or fix its brief, then rerun" >&2
    ((ORPHANS == 0)) ||
        echo "error: $ORPHANS cards are on their issues but not on the board's listing; rerun once, as the listing may lag, three minutes or more after filing, and only if the rerun names a card again delete it, add its issue again and set the new card as hinted" >&2
    exit 1
fi
