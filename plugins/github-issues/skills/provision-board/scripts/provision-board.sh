#!/usr/bin/env bash
# Sets up a handoff-queue board: a GitHub project, owned by a user or an
# organization, linked to one repo, carrying the contract in
# references/board-contract.md beside this script's folder.
#
# COPY FIRST, BUILD SECOND, ONE PATH. No API turns a project workflow on,
# but a copy keeps views, fields and configured workflows, bar auto-add
# (GitHub's docs, 2026-10-27). So with a template the project is copied,
# and each step after it is an ensure that a copy already satisfies;
# without one the same steps build the board from nothing, and the
# workflows are left for the UI. A rerun on either path is safe: the
# project is found by its title, and each step changes only what differs.
# A second repo passed with the same title links to the same board.
#
# THE STATUS OPTIONS KEEP THEIR IDS. updateProjectV2Field replaces the
# whole option list, and an option passed without its id is a new option:
# every item's value on the old one is cleared and every workflow that set
# it loses its target, as the pilot's build found (2026-10-27). So each
# option kept is passed with its id, and a fresh project's Todo and In
# Progress keep theirs as Open and In flight.
#
# On a board already in use, a Status option outside the contract is
# reported, not dropped, since dropping it clears each card on it. Labels are
# created where missing, never --force'd.
#
# ONE LABEL, needs:user, IS EVERY BOARD'S. Filing makes each other needs:*
# and every platform:* label the first time a brief names it, so a repo
# carries only the labels its own issues use: two other boards carried a
# fixed eight platform labels and used none (references/board-contract.md,
# Labels, 2026-11-06).
#
# THE VIEWS ARE references/views.json, MATCHED BY NAME. Each view it names
# that the board lacks is created, on a copy as on a build, by REST's
# POST .../projectsV2/<n>/views, the one API that sets a filter, a grouping
# and a board's columns (API version 2026-03-10). That POST refuses Created,
# Updated and Closed as unsupported_ids, so a view wanting them then takes
# its whole field list by GraphQL's updateProjectV2View, which keeps the
# grouping (both probed 2026-11-03). A view already there, matched by name,
# is read against the spec and reported where it differs, never rewritten,
# bar a copy that gained an owner's issue field, whose views take the
# spec's column order; a view the spec does not name is reported, bar View 1
# on a board this run built, GitHub's default, which is deleted.
#
# THE OWNER'S OWN PRIORITY REPLACES THE PROJECT'S. Where the repo's
# owner defines an issue field Priority offering High, Medium and Low, and
# --owner is that same owner, the board carries it and the other issue fields
# the contract names, in place of a project field
# (references/board-contract.md). An organization or a user alike: personal
# accounts have had issue fields since 2026-11-11. A project cannot hold two
# fields of one name, so a project Priority is deleted first, and only on a
# board with no cards: deleting it clears every card's value, so on one with
# cards it is reported, the copy being the owner's call. An owner's Priority
# offering anything else leaves the project's in place, and a todo says so.
#
# THE REPO'S OWN BOARD WINS OVER A TITLE. A board renamed in the UI no longer
# matches --title, and a second board linked to one repo makes set-card.py and
# the queue refuse both. So a linked project carrying the contract is taken
# first, whatever its title; two are an error, and one another owner holds
# stops the run, since only that owner's account can act on it.
#
# PRIORITY'S OPTIONS ARE URGENT, HIGH, MEDIUM AND LOW. A board with the older
# P1, P2 and P3 keeps each ID under its new name, so no card loses its value.
#
# THE ACCOUNT IS --login, PINNED HERE. The token is minted for it, whatever
# GH_TOKEN holds, and the run stops unless gh then acts as it, since a 404
# from the wrong account reads as a missing project or repo. A caller's pin
# held no better: each Bash tool call is a fresh shell, so an export of
# GH_TOKEN in one reached no later call, and a worktree session's guard
# refuses the export outright as too complex to verify (2.1.317,
# 2026-11-03).
#
# Usage:
#   provision-board.sh --owner <login> --repo <owner/name> --login <account>
#       [--title <title>] [--template <owner>/<number> | --no-template]
#       [--description <text>] [--readme <text>]
#
# --title defaults to "<name> backlog", <name> from --repo, so two repos'
# boards differ in one owner's list. --template defaults to the project
# titled "Backlog template" under --owner, else under the acting
# account, so another account's takes --template; with none found, or
# --no-template, the board is built, and only the first says so on stderr.
# --description and --readme are written when given, or when the project
# has none.
#
# stdout: the report, one "<key>: <value>" line each, "todo:" lines last.
# stderr: progress. Exit 0 done, 1 a failure part way (fix it and rerun),
# 2 a usage error, a --login gh cannot act as, or nothing to act on.
# shellcheck disable=SC2016 # each single-quoted $ is a jq or GraphQL variable
set -euo pipefail

TEMPLATE_TITLE="Backlog template"
STATUS_WANT='Open,Deferred,In flight,Done'
VIEWS_SPEC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../references/views.json"
REST_VERSION=2026-03-10 # the Projects REST API's, which creates a view
PRIORITIES=Urgent,High,Medium,Low
ISSUE_FIELDS_WANTED=("Start date" "Target date" Effort) # beside Priority, where an owner defines them
WORK_MODELS=haiku,sonnet,opus,fable
WORK_EFFORTS=low,medium,high,xhigh,max
NEEDS_LABELS=(user)
WANT_ON=("Item added to project" "Item reopened" "Item closed" "Auto-archive items"
    "Auto-add sub-issues to project")
WANT_OFF=("Auto-close issue" "Pull request linked to issue" "Pull request merged"
    "Code changes requested" "Code review approved")

usage() {
    sed -n '/^# Usage/,/^# 2 a usage/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
    exit 2
}

OWNER="" REPO="" LOGIN="" TITLE="" TITLE_GIVEN=0 TEMPLATE="" NO_TEMPLATE=0
DESCRIPTION="" README=""
while (($#)); do
    case $1 in
    --no-template)
        NO_TEMPLATE=1
        shift
        continue
        ;;
    --owner | --repo | --login | --title | --template | --description | --readme)
        (($# >= 2)) || usage
        ;;
    *)
        echo "error: unknown argument $1" >&2
        usage
        ;;
    esac
    case $1 in
    --owner) OWNER=$2 ;;
    --repo) REPO=$2 ;;
    --login) LOGIN=$2 ;;
    --title) TITLE=$2 TITLE_GIVEN=1 ;;
    --template) TEMPLATE=$2 ;;
    --description) DESCRIPTION=$2 ;;
    --readme) README=$2 ;;
    esac
    shift 2
done
[[ -n $OWNER && $REPO == */* ]] || usage
[[ $LOGIN =~ ^[A-Za-z0-9_-]+$ ]] || {
    echo "error: --login takes the account that should own the writes${LOGIN:+, not $LOGIN}" >&2
    usage
}
REPO_NAME=${REPO#*/}
((TITLE_GIVEN)) || TITLE="$REPO_NAME backlog"
[[ -n $TITLE ]] || usage
[[ $TITLE != "$TEMPLATE_TITLE" ]] || {
    echo "error: --title is the template's own title; name the board something else" >&2
    exit 2
}
if [[ -n $TEMPLATE && ! $TEMPLATE =~ ^[^/]+/[0-9]+$ ]]; then
    echo "error: --template takes <owner>/<number>, not $TEMPLATE" >&2
    exit 2
fi

for tool in gh jq; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "error: $tool not found on PATH" >&2
        exit 1
    }
done

# A native jq.exe writes CRLF without -b, and Git Bash reports OSTYPE=cygwin.
JQ_BIN=()
case "$OSTYPE" in msys* | cygwin*) JQ_BIN=(-b) ;; esac
jqb() { jq "${JQ_BIN[@]}" "$@"; }

# The views, read before any call, so a spec that does not parse writes nothing.
# TABLE_FIELDS, the first table view's fields, orders a copy's columns below and
# gains the owner's issue fields; BOARD_FIELDS is the board view's, bar Title.
VIEWS_JSON=$(jqb -c '.views' "$VIEWS_SPEC") || {
    echo "error: cannot read $VIEWS_SPEC" >&2
    exit 1
}
mapfile -t TABLE_FIELDS <<<"$(jqb -r '[.[] | select(.layout == "table")][0].fields[]' <<<"$VIEWS_JSON")"
mapfile -t BOARD_FIELDS <<<"$(jqb -r '[.[] | select(.layout == "board")][0].fields[] | select(. != "Title")' <<<"$VIEWS_JSON")"

# gql <query> [jq args for the variables object]: the query and its
# variables go on stdin as one JSON body, off argv.
gql() {
    local query=$1
    shift
    jqb -n --arg q "$query" "$@" '{query: $q, variables: $ARGS.named | del(.q)}' |
        gh api graphql --input -
}

# The account; see the header. Before any other gh call, so a refused token
# reads and writes nothing.
unset GH_TOKEN
GH_TOKEN=$(command gh auth token --user "$LOGIN") || GH_TOKEN=""
[[ -n $GH_TOKEN ]] || {
    echo "error: gh has no token for $LOGIN, the account --login names; nothing is written" >&2
    exit 2
}
export GH_TOKEN
ME=$(gh api user -q .login)
echo "acting as $ME" >&2
# Case-blind, as GitHub's logins are: a typed Foo is the account foo.
[[ ${ME,,} == "${LOGIN,,}" ]] || {
    echo "error: gh acts as $ME, but --login names $LOGIN; nothing is written" >&2
    exit 2
}

OWNER_TYPE=$(gql 'query($o: String!) { repositoryOwner(login: $o) { __typename } }' --arg o "$OWNER" |
    jqb -r '.data.repositoryOwner.__typename // empty')
[[ -n $OWNER_TYPE ]] || {
    echo "error: no user or organization $OWNER visible to $ME" >&2
    exit 2
}
REPO_READ=$(gh repo view "$REPO" --json name,hasIssuesEnabled,hasProjectsEnabled,defaultBranchRef) || {
    echo "error: $REPO not visible to $ME; an account not authorized for an organization's single sign-on reads 404 or 403 too" >&2
    exit 2
}
# Stops before any write: a board holds issues, and this repo can file none.
if [[ $(jqb -r '.hasIssuesEnabled == false' <<<"$REPO_READ") == true ]]; then
    echo "error: $REPO has issues turned off, so a board has nothing to hold; turn them on in its settings" >&2
    exit 2
fi

# find_project <owner> <title>: the number of the one project so titled,
# empty for none; two or more is an error, since either could be meant.
# It runs inside $(...), where bash drops errexit, so a failed list returns
# 1 by hand: read as none, it copies or builds a second board of the title,
# as a token lacking read:project went on to do (2026-10-27).
find_project() {
    local found
    found=$(gh project list --owner "$1" --format json -L 500 |
        jqb -r --arg t "$2" '[.projects[] | select(.title == $t) | .number] | map(tostring) | join(" ")') ||
        return 1
    if [[ $found == *" "* ]]; then
        echo "error: projects $found under $1 are all titled \"$2\"; rename all but one" >&2
        return 1
    fi
    printf '%s' "$found"
}

TEMPLATE_OWNER="" TEMPLATE_NUM=""
if ((! NO_TEMPLATE)); then
    if [[ -n $TEMPLATE ]]; then
        TEMPLATE_OWNER=${TEMPLATE%/*} TEMPLATE_NUM=${TEMPLATE#*/}
    else
        for candidate in "$OWNER" "$ME"; do
            TEMPLATE_NUM=$(find_project "$candidate" "$TEMPLATE_TITLE")
            if [[ -n $TEMPLATE_NUM ]]; then
                TEMPLATE_OWNER=$candidate
                break
            fi
        done
    fi
fi

# The projects linked to the repo that carry the contract, one
# "<owner>\t<number>\t<title>" a line. A null node is one this account cannot see.
LINKED_BOARDS=$(gql 'query($o: String!, $n: String!) { repository(owner: $o, name: $n) { projectsV2(first: 20) { nodes {
      number title closed owner { ... on User { login } ... on Organization { login } }
      fields(first: 50) { nodes { ... on ProjectV2FieldCommon { name }
        ... on ProjectV2SingleSelectField { options { name } } } } } } } }' \
    --arg o "${REPO%%/*}" --arg n "${REPO#*/}" | jqb -r --arg template "$TEMPLATE_TITLE" '
    def opts($f): [$f[] | .options[]?.name];
    .data.repository.projectsV2.nodes[]? | select(. != null and (.closed | not) and .title != $template)
    | [.fields.nodes[]? | select(. != null)] as $fields
    | [$fields[] | select(.name == "Status")] as $status
    | [$fields[] | select(.name == "Priority")] as $priority
    | select((["Open", "Deferred", "In flight", "Done"] - opts($status)) == [])
    | select(any($fields[]; .name == "Reopen-when"))
    | select(any($priority[]; has("options"))
        and (opts($priority) == []
             or (["High", "Medium", "Low"] - opts($priority)) == []
             or (["P1", "P2", "P3"] - opts($priority)) == []))
    | [.owner.login, (.number | tostring), .title] | @tsv')
if [[ $LINKED_BOARDS == *$'\n'* ]]; then
    echo "error: $REPO links more than one board, which set-card.py refuses; unlink all but one:" >&2
    printf '%s\n' "$LINKED_BOARDS" >&2
    exit 1
fi
NUM=""
if [[ -n $LINKED_BOARDS ]]; then
    IFS=$'\t' read -r LINKED_OWNER LINKED_NUM LINKED_TITLE <<<"$LINKED_BOARDS"
    if [[ ${LINKED_OWNER,,} != "${OWNER,,}" ]]; then
        echo "error: $REPO's board is $LINKED_OWNER's project $LINKED_NUM, not $OWNER's; rerun with --owner $LINKED_OWNER" >&2
        exit 2
    fi
    NUM=$LINKED_NUM
    HOW="existing project, found by its link to $REPO, titled \"$LINKED_TITLE\", left as found"
else
    NUM=$(find_project "$OWNER" "$TITLE")
    HOW="existing project, left as found"
fi
if [[ -n $NUM ]]; then
    :
elif [[ -n $TEMPLATE_NUM ]]; then
    NUM=$(gh project copy "$TEMPLATE_NUM" --source-owner "$TEMPLATE_OWNER" \
        --target-owner "$OWNER" --title "$TITLE" --format json | jqb -r .number)
    HOW="copied from $TEMPLATE_OWNER/$TEMPLATE_NUM"
    echo "copied $TEMPLATE_OWNER/$TEMPLATE_NUM to $OWNER/$NUM" >&2
else
    # The lookup covers only $OWNER and $ME, so a template under a third
    # account goes unfound: a work account acting on an organization's
    # board did not see the user's (2026-10-30).
    if ((! NO_TEMPLATE)); then
        where=$OWNER
        [[ $ME == "$OWNER" ]] || where="$OWNER or $ME"
        echo "note: no \"$TEMPLATE_TITLE\" under $where, so building from nothing; to copy another account's, pass --template <owner>/<number>" >&2
    fi
    NUM=$(gh project create --owner "$OWNER" --title "$TITLE" --format json | jqb -r .number)
    HOW="built, no template"
    echo "created $OWNER/$NUM" >&2
fi
BUILT=0
[[ $HOW == built* ]] && BUILT=1

PROJECT=$(gh project view "$NUM" --owner "$OWNER" --format json)
PID=$(jqb -r .id <<<"$PROJECT")
URL=$(jqb -r .url <<<"$PROJECT")

TODO=()
# Whether the board then works with the repo's Projects tab off is stated on
# no page read (board-contract.md), so it is reported and the run goes on.
if [[ $(jqb -r '.hasProjectsEnabled == false' <<<"$REPO_READ") == true ]]; then
    TODO+=("$REPO has Projects turned off in its settings; turn them on if the board does not show there")
fi

# --- description and readme: written when given, or when there is none
if [[ -z $DESCRIPTION && -z $(jqb -r '.shortDescription // empty' <<<"$PROJECT") ]]; then
    DESCRIPTION="Backlog: one issue per brief, its Status, Priority, Reopen-when, Work model and Work effort from the brief."
fi
if [[ -z $README && -z $(jqb -r '.readme // empty' <<<"$PROJECT") ]]; then
    README="Each issue is one handoff brief from $REPO_NAME's queue. Status: Open, ready for a session; Deferred, waiting on its Reopen-when; In flight, a session has claimed it; Done, closed, landed or dropped. A needs:* label names what a session cannot supply alone. Work model and Work effort advise how a session works it, blank for the session's default. Closing an issue as completed is landing it."
fi
EDIT=()
[[ -n $DESCRIPTION ]] && EDIT+=(--description "$DESCRIPTION")
[[ -n $README ]] && EDIT+=(--readme "$README")
if ((${#EDIT[@]})); then
    gh project edit "$NUM" --owner "$OWNER" "${EDIT[@]}" >/dev/null
    echo "set description or readme" >&2
fi

# --- the repo link
LINKED=$(gql 'query($p: ID!) { node(id: $p) { ... on ProjectV2 { repositories(first: 100) { nodes { nameWithOwner } } } } }' \
    --arg p "$PID" | jqb -r --arg r "$REPO" \
    '($r | ascii_downcase) as $want | any(.data.node.repositories.nodes[]; (.nameWithOwner | ascii_downcase) == $want)')
if [[ $LINKED != true ]]; then
    gh project link "$NUM" --owner "$OWNER" --repo "$REPO"
    echo "linked $REPO" >&2
fi

# --- fields
read_fields() { FIELDS=$(gh project field-list "$NUM" --owner "$OWNER" --format json -L 100); }
field_id() { jqb -r --arg n "$1" '[.fields[] | select(.name == $n) | .id][0] // empty' <<<"$FIELDS"; }
read_fields

STATUS=$(field_id Status)
[[ -n $STATUS ]] || {
    echo "error: $URL has no Status field" >&2
    exit 1
}
HAVE=$(jqb -r '[.fields[] | select(.name == "Status") | .options[]?.name] | join(",")' <<<"$FIELDS")
if [[ $HAVE != "$STATUS_WANT" ]]; then
    # Each target option takes the id of an existing option of its name,
    # any case, or of its alias; every other existing option is dropped.
    OPTIONS=$(jqb -c '
        [.fields[] | select(.name == "Status") | .options[]?] as $have
        | {"open": "todo", "in flight": "in progress"} as $alias
        | [
            {name: "Open", color: "BLUE", description: "Ready for a session"},
            {name: "Deferred", color: "GRAY", description: "Waits on its Reopen-when"},
            {name: "In flight", color: "YELLOW", description: "A worktree holds it"},
            {name: "Done", color: "PURPLE", description: "Closed, landed or dropped"}
          ]
        | map(. as $want
            | ($want.name | ascii_downcase) as $n
            | ([$have[] | select((.name | ascii_downcase) == $n)][0]
               // [$have[] | select((.name | ascii_downcase) == ($alias[$n] // ""))][0]) as $kept
            | if $kept then $want + {id: $kept.id} else $want end)' <<<"$FIELDS")
    KEPT=$(jqb -r '[.[] | .id // empty] | join(" ")' <<<"$OPTIONS")
    DROPPED=$(jqb -r --argjson o "$OPTIONS" \
        '[.fields[] | select(.name == "Status") | .options[]? | select(.id as $i | [$o[].id] | index($i) | not) | .name] | join(", ")' \
        <<<"$FIELDS")
    if [[ -n $DROPPED && $HOW == existing* ]]; then
        # Dropping an option clears every card on it: on a board in use,
        # that is the owner's call, not a rerun's.
        TODO+=("Status options $DROPPED are outside the contract; left as found, since dropping them clears each card on one")
    else
        gql 'mutation($id: ID!, $opts: [ProjectV2SingleSelectFieldOptionInput!]) {
              updateProjectV2Field(input: {fieldId: $id, singleSelectOptions: $opts}) {
                projectV2Field { ... on ProjectV2SingleSelectField { id } } } }' \
            --arg id "$STATUS" --argjson opts "$OPTIONS" >/dev/null
        echo "set Status options (were: $HAVE; ids kept: ${KEPT:-none})" >&2
        [[ -z $DROPPED ]] || TODO+=("Status options $DROPPED were dropped; any card on one has no Status now")
    fi
fi
# ensure_select <field> <options>: created where missing; one already
# there is checked after, never rewritten, since its cards hold its IDs.
ensure_select() {
    if [[ -z $(field_id "$1") ]]; then
        gh project field-create "$NUM" --owner "$OWNER" --name "$1" \
            --data-type SINGLE_SELECT --single-select-options "$2" >/dev/null
        echo "created $1" >&2
    fi
}
# check_options <field> <options>: a todo where the options differ
check_options() {
    local have
    have=$(jqb -r --arg n "$1" '[.fields[] | select(.name == $n) | .options[]?.name] | join(",")' <<<"$FIELDS")
    [[ $have == "$2" ]] || TODO+=("$1's options read $have, not $2; left as found")
}
# The owner's issue fields: a user's repo read null before personal accounts
# had them (2026-10-30), and an empty list on one defining none (2026-11-14).
ISSUE_READ=$(gql 'query($o: String!, $n: String!) { repository(owner: $o, name: $n) {
      viewerCanSeeIssueFields
      issueFields(first: 25) { nodes { __typename
        ... on IssueFieldSingleSelect { id name options { name } }
        ... on IssueFieldMultiSelect { id name options { name } }
        ... on IssueFieldDate { id name }
        ... on IssueFieldNumber { id name }
        ... on IssueFieldText { id name } } } } }' \
    --arg o "${REPO%%/*}" --arg n "${REPO#*/}")
ISSUE_FIELDS=$(jqb -c '.data.repository.issueFields.nodes // []' <<<"$ISSUE_READ")
# Asked of an organization alone: its fields hidden from this account read
# exactly as none defined. It read false on a user's repo too before personal
# accounts had issue fields (2026-11-01), and true on the owner's after, with
# none defined (2026-11-14).
REPO_OWNER=${REPO%%/*}
if [[ $OWNER_TYPE == Organization && ${REPO_OWNER,,} == "${OWNER,,}" &&
    $(jqb -r '.data.repository.viewerCanSeeIssueFields == false' <<<"$ISSUE_READ") == true ]]; then
    TODO+=("$ME cannot see $OWNER's issue fields, so any Priority it defines goes unread; rerun as an account that can")
fi
# They are the repo owner's, so they serve only a board it owns: where --owner
# and --repo's owner differ, the board keeps its project field.
if [[ ${REPO_OWNER,,} != "${OWNER,,}" && $ISSUE_FIELDS != '[]' ]]; then
    echo "note: $REPO's issue fields are $REPO_OWNER's, and the board is $OWNER's; keeping its project field" >&2
    ISSUE_FIELDS='[]'
fi
issue_field_id() { jqb -r --arg n "$1" '[.[] | select(.name == $n) | .id][0] // empty' <<<"$ISSUE_FIELDS"; }
# add_issue_field <name> <issue field id>: on the board by its own mutation,
# since gh project field-create makes only project fields
ADDED_FIELDS=() EXTRA_TABLE_FIELDS=()
add_issue_field() {
    gql 'mutation($p: ID!, $f: ID!) { createProjectV2IssueField(input: {projectId: $p, issueFieldId: $f}) { clientMutationId } }' \
        --arg p "$PID" --arg f "$2" >/dev/null
    ADDED_FIELDS+=("$1")
    echo "added $OWNER's $1" >&2
}
# The id of the owner's Priority, where it offers what a brief's level maps to.
ISSUE_PRIORITY=$(jqb -r '[.[] | select(.name == "Priority" and
    ((["High", "Medium", "Low"] - [.options[]?.name]) == [])) | .id][0] // empty' <<<"$ISSUE_FIELDS")
if [[ -n $ISSUE_PRIORITY ]]; then
    HAVE_PRIORITY=$(jqb -r '[.fields[] | select(.name == "Priority") | .options[]?.name] | join(",")' <<<"$FIELDS")
    if [[ -z $(field_id Priority) ]]; then
        add_issue_field Priority "$ISSUE_PRIORITY"
    elif [[ -n $HAVE_PRIORITY ]]; then
        # Archived cards count: Auto-archive leaves them holding a value, and
        # gh project item-list lists none of them.
        CARDS=$(gql 'query($p: ID!) { node(id: $p) { ... on ProjectV2 {
              items(first: 1, archivedStates: [ARCHIVED, NOT_ARCHIVED]) { totalCount } } } }' \
            --arg p "$PID" | jqb '.data.node.items.totalCount')
        if ((CARDS == 0)); then
            gql 'mutation($f: ID!) { deleteProjectV2Field(input: {fieldId: $f}) { clientMutationId } }' \
                --arg f "$(field_id Priority)" >/dev/null
            echo "deleted the project's Priority, on a board with no cards" >&2
            add_issue_field Priority "$ISSUE_PRIORITY"
        else
            TODO+=("Priority is the project's, on a board with cards; to take $OWNER's, copy each card's value to it, delete the project's, then add $OWNER's, in that order (board-contract.md)")
        fi
    fi
    for name in "${ISSUE_FIELDS_WANTED[@]}"; do
        ID=$(issue_field_id "$name")
        if [[ -n $ID && -z $(field_id "$name") ]]; then
            add_issue_field "$name" "$ID"
        fi
        # Every table view shows it too, as the contract's Views says.
        [[ -z $ID ]] || TABLE_FIELDS+=("$name") EXTRA_TABLE_FIELDS+=("$name")
    done
    read_fields
else
    # The owner's Priority, by any case, that this board then cannot use.
    OTHER_PRIORITY=$(jqb -r '[.[] | select((.name | ascii_downcase) == "priority") | .options[]?.name] | join(", ")' \
        <<<"$ISSUE_FIELDS")
    if [[ -n $OTHER_PRIORITY ]]; then
        TODO+=("the owner's Priority offers $OTHER_PRIORITY, not High, Medium and Low, so the board keeps its own, and an issue sidebar's is not the card's; add those options to use the owner's")
    fi
    ensure_select Priority "$PRIORITIES"
    read_fields
    # The older P1 to P3 become High, Medium and Low under the same IDs, as
    # Status keeps its own. Anything else is left for check_options to report.
    HAVE_PRIORITY=$(jqb -r '[.fields[] | select(.name == "Priority") | .options[]?.name] | join(",")' <<<"$FIELDS")
    if [[ $HAVE_PRIORITY != "$PRIORITIES" ]] && jqb -e '
        [.fields[] | select(.name == "Priority") | .options[]?.name]
        | length > 0 and all(. as $n | ["P1", "P2", "P3", "Urgent", "High", "Medium", "Low"] | index($n))' \
        <<<"$FIELDS" >/dev/null; then
        OPTIONS=$(jqb -c '
            [.fields[] | select(.name == "Priority") | .options[]?] as $have
            | {"High": "P1", "Medium": "P2", "Low": "P3"} as $was
            | ["Urgent", "High", "Medium", "Low"]
            | map(. as $n
                | ([$have[] | select(.name == $n)][0] // [$have[] | select(.name == ($was[$n] // ""))][0]) as $kept
                | {name: $n, color: "GRAY", description: ""} + (if $kept then {id: $kept.id} else {} end))' <<<"$FIELDS")
        # An option the list leaves out would be deleted, and every card on it
        # cleared: P1 beside High has no name to move to, so that board is reported.
        if jqb -e --argjson o "$OPTIONS" '
            ([.fields[] | select(.name == "Priority") | .options[]?.id] - [$o[].id]) == []' \
            <<<"$FIELDS" >/dev/null; then
            gql 'mutation($id: ID!, $opts: [ProjectV2SingleSelectFieldOptionInput!]) {
                  updateProjectV2Field(input: {fieldId: $id, singleSelectOptions: $opts}) {
                    projectV2Field { ... on ProjectV2SingleSelectField { id } } } }' \
                --arg id "$(field_id Priority)" --argjson opts "$OPTIONS" >/dev/null
            echo "set Priority's options (were: $HAVE_PRIORITY; IDs kept)" >&2
            read_fields
        fi
    fi
fi
if [[ -z $(field_id Reopen-when) ]]; then
    gh project field-create "$NUM" --owner "$OWNER" --name Reopen-when --data-type TEXT >/dev/null
    echo "created Reopen-when" >&2
fi
# A brief's work-model and work-effort, its writer's advice on how to
# work it; a blank leaves the session's default.
ensure_select "Work model" "$WORK_MODELS"
ensure_select "Work effort" "$WORK_EFFORTS"
read_fields
[[ -n $ISSUE_PRIORITY ]] || check_options Priority "$PRIORITIES"
check_options "Work model" "$WORK_MODELS"
check_options "Work effort" "$WORK_EFFORTS"

# --- views
read_views() {
    VIEWS=$(gql 'query($p: ID!) { node(id: $p) { ... on ProjectV2 { views(first: 50) { nodes { id name layout filter
          groupByFields(first: 5) { nodes { ... on ProjectV2FieldCommon { name } } }
          verticalGroupByFields(first: 5) { nodes { ... on ProjectV2FieldCommon { name } } }
          fields(first: 50) { nodes { ... on ProjectV2FieldCommon { id name } } } } } } } }' \
        --arg p "$PID" | jqb -c '.data.node.views.nodes')
}
read_views
# field_ids <name>...: a JSON array of the fields' ids, in the order named;
# FIELD_IDS_QUIET=1 skips the warning for a name the board lacks
field_ids() {
    local ids=() name id
    for name in "$@"; do
        id=$(field_id "$name")
        if [[ -n $id ]]; then
            ids+=("$id")
        elif [[ -z ${FIELD_IDS_QUIET:-} ]]; then
            echo "warning: no field $name to show in a view" >&2
        fi
    done
    jqb -cn '$ARGS.positional' --args "${ids[@]}"
}
# A copy made this run is no one's edit yet, so the fields just added go in its
# views: the swap's delete took Priority from each. A table shows every one
# added, and a board view Priority alone, as the contract's Views has them.
# GitHub shows the list in the order sent, and view.fields reads in field-ID
# order whatever the UI shows (2026-11-01), so a list built from that read would
# sort the columns by ID, and no read can keep a template's: the contract's
# order goes first, the view's other fields after it, and a todo says so.
if [[ $HOW == copied* ]] && ((${#ADDED_FIELDS[@]})); then
    # A contract field the board lacks is no fault here, so no warning.
    BOARD_ORDER_IDS=$(FIELD_IDS_QUIET=1 field_ids Title "${BOARD_FIELDS[@]}")
    TABLE_ORDER_IDS=$(FIELD_IDS_QUIET=1 field_ids "${TABLE_FIELDS[@]}")
    while IFS=$'\t' read -r view_id view_layout; do
        [[ -n $view_id ]] || continue
        if [[ $view_layout == BOARD_LAYOUT ]]; then
            ADD_IDS=$(field_ids Priority)
            ORDER_IDS=$BOARD_ORDER_IDS
        else
            ADD_IDS=$(field_ids "${ADDED_FIELDS[@]}")
            ORDER_IDS=$TABLE_ORDER_IDS
        fi
        SHOWN_IDS=$(jqb -c --arg v "$view_id" --argjson add "$ADD_IDS" --argjson order "$ORDER_IDS" \
            '([.[] | select(.id == $v) | .fields.nodes[].id] + $add) as $shown
             | [$order[] | select(. as $id | $shown | index($id))] + $shown
             | reduce .[] as $id ([]; if index($id) then . else . + [$id] end)' <<<"$VIEWS")
        gql 'mutation($v: ID!, $f: [ID!]) { updateProjectV2View(input: {viewId: $v, configuration: {visibleFieldIds: $f}}) { projectV2View { id } } }' \
            --arg v "$view_id" --argjson f "$SHOWN_IDS" >/dev/null
    done <<<"$(jqb -r '.[] | [.id, .layout] | @tsv' <<<"$VIEWS")"
    echo "showed ${ADDED_FIELDS[*]} in the copy's views" >&2
    TODO+=("the copy's views now list their columns in the contract's order, since no API reads a template's; drag back any column the template placed otherwise")
    read_views
fi
# Each view of views.json as this board wants it: a table view also shows the
# owner's issue fields the board carries.
WANT_VIEWS=$(jqb -c '[.[] | if .layout == "table" then .fields += ($ARGS.positional - .fields) else . end]' \
    --args "${EXTRA_TABLE_FIELDS[@]}" <<<"$VIEWS_JSON")
if [[ $OWNER_TYPE == Organization ]]; then
    REST_BASE="orgs/$OWNER/projectsV2/$NUM"
else
    # The user path takes the login: the numeric user_id its page names
    # answered 404 (2026-11-03).
    REST_BASE="users/$OWNER/projectsV2/$NUM"
fi
rest() { gh api -H "X-GitHub-Api-Version: $REST_VERSION" "$@"; }
# REST's fields, by the integer IDs its views take; read only when a view is
# to be made. It lists no Created, Updated or Closed.
REST_FIELDS=""
load_rest_fields() {
    [[ -n $REST_FIELDS ]] ||
        REST_FIELDS=$(rest "$REST_BASE/fields?per_page=100" | jqb -c '[.[] | {id, name}]')
}
# create_view <spec view>: by REST, which sets the filter, the grouping and a
# board's columns, then by GraphQL with every field where REST refused one.
create_view() {
    local want=$1 name body new_id unsent names
    name=$(jqb -r .name <<<"$want")
    load_rest_fields
    body=$(jqb -c --argjson r "$REST_FIELDS" '
        def ids($names): [$names[] as $n | $r[] | select(.name == $n) | .id];
        {name, layout, visible_fields: ids(.fields)}
        + (if .filter then {filter} else {} end)
        + (if .group_by then {group_by: ids([.group_by])} else {} end)
        + (if .columns then {vertical_group_by: ids([.columns])} else {} end)' <<<"$want")
    if [[ $(jqb -r --argjson b "$body" '(.group_by and $b.group_by == []) or (.columns and $b.vertical_group_by == [])' <<<"$want") == true ]]; then
        TODO+=("the view $name wants a grouping or columns by a field the board lacks; made without, so delete it and rerun once the board has the field")
    fi
    if ! new_id=$(printf '%s' "$body" | rest --method POST "$REST_BASE/views" --input - | jqb -r '.node_id // empty') ||
        [[ -z $new_id ]]; then
        echo "error: could not create the view $name on $URL; rerun once the cause is fixed" >&2
        exit 1
    fi
    echo "created the view $name" >&2
    unsent=$(jqb -r --argjson r "$REST_FIELDS" '[.fields[] | select(. as $n | [$r[].name] | index($n) | not)] | join(", ")' <<<"$want")
    if [[ -n $unsent ]]; then
        mapfile -t names <<<"$(jqb -r '.fields[]' <<<"$want")"
        gql 'mutation($v: ID!, $f: [ID!]) { updateProjectV2View(input: {viewId: $v, configuration: {visibleFieldIds: $f}}) { projectV2View { id } } }' \
            --arg v "$new_id" --argjson f "$(field_ids "${names[@]}")" >/dev/null
        echo "showed $unsent in the view $name" >&2
    fi
}
# A view of the spec's name is read, never set: a todo only where it differs.
# Its fields are compared as a set, since view.fields reads in field-ID order.
CREATED=0
while IFS= read -r want; do
    [[ -n $want ]] || continue
    name=$(jqb -r .name <<<"$want")
    count=$(jqb -r --arg n "$name" '[.[] | select(.name == $n)] | length' <<<"$VIEWS")
    if ((count > 1)); then
        TODO+=("$count views are named $name; delete all but one, since views.json names each once")
    elif ((count == 1)); then
        DIFF=$(jqb -r --arg n "$name" --argjson w "$want" '
            [.[] | select(.name == $n)][0] as $v
            | [$v.fields.nodes[]?.name] as $have
            | ([$v.groupByFields.nodes[]?.name] | join(", ")) as $group
            | ([$v.verticalGroupByFields.nodes[]?.name] | join(", ")) as $columns
            | ([$w.fields[] | select(. as $f | $have | index($f) | not)] | join(", ")) as $missing
            | ([$have[] | select(. as $f | $w.fields | index($f) | not)] | join(", ")) as $extra
            | def none: if . == "" then "nothing" else . end;
            [ if $v.layout != ($w.layout | ascii_upcase) + "_LAYOUT"
                then "is a \($v.layout | sub("_LAYOUT$"; "") | ascii_downcase), not a \($w.layout)" else empty end,
              if ($v.filter // "") != ($w.filter // "")
                then "filters \"\($v.filter // "")\", not \"\($w.filter // "")\"" else empty end,
              if $group != ($w.group_by // "")
                then "groups by \($group | none), not \($w.group_by // "" | none)" else empty end,
              if $w.columns and $columns != $w.columns
                then "has columns by \($columns | none), not \($w.columns)" else empty end,
              if $missing != "" then "lacks \($missing)" else empty end,
              if $extra != "" then "also shows \($extra)" else empty end ]
            | join("; ")' <<<"$VIEWS")
        [[ -z $DIFF ]] || TODO+=("the view $name $DIFF; left as found, since views.json has it otherwise")
    else
        create_view "$want"
        CREATED=1
    fi
done <<<"$(jqb -c '.[]' <<<"$WANT_VIEWS")"
if ((CREATED)); then read_views; fi
# A view the spec does not name: View 1 on a board this run built is GitHub's
# default, no one's yet, and goes; any other is someone's, and is reported.
OTHER_VIEWS=$(jqb -c --argjson w "$WANT_VIEWS" '[.[] | select(.name as $n | [$w[].name] | index($n) | not)]' <<<"$VIEWS")
if ((BUILT)); then
    while IFS= read -r view_id; do
        [[ -n $view_id ]] || continue
        gql 'mutation($v: ID!) { deleteProjectV2View(input: {viewId: $v}) { clientMutationId } }' --arg v "$view_id" >/dev/null
        echo "deleted View 1, GitHub's default" >&2
    done <<<"$(jqb -r '.[] | select(.name == "View 1") | .id' <<<"$OTHER_VIEWS")"
    OTHER_VIEWS=$(jqb -c '[.[] | select(.name != "View 1")]' <<<"$OTHER_VIEWS")
fi
OTHER_NAMES=$(jqb -r '[.[].name] | join(", ")' <<<"$OTHER_VIEWS")
[[ -z $OTHER_NAMES ]] ||
    TODO+=("the views $OTHER_NAMES are not in views.json; delete each that an older contract made")

# --- labels, in the repo: created where missing, never --force'd
HAVE_LABELS=$(gh label list --repo "$REPO" --search "needs:" --json name -L 200 | jqb -r '.[].name')
for need in "${NEEDS_LABELS[@]}"; do
    if ! grep -qixF "needs:$need" <<<"$HAVE_LABELS"; then
        gh label create "needs:$need" --repo "$REPO" --color c5def5 \
            --description "The brief needs: $need" >/dev/null
        echo "created label needs:$need" >&2
    fi
done

# --- workflows, read against the contract: name and enabled are all
# GraphQL gives, so a target or a filter goes unchecked. Where a pull request
# rule guards the default branch the repo lands that way, and Pull request
# linked to issue may rightly be on, so the contract asks nothing of it.
DEFAULT_BRANCH=$(jqb -r '.defaultBranchRef.name // empty' <<<"$REPO_READ")
if [[ -n $DEFAULT_BRANCH ]]; then
    # A failed read keeps the contract's off, which only reports: no write
    # hangs on it. A plan without rules answers here with an error too, and a
    # network or permission failure must not read as no rule, so it says so.
    if ! BRANCH_RULES=$(gh api "repos/$REPO/rules/branches/$DEFAULT_BRANCH" 2>/dev/null); then
        BRANCH_RULES='[]'
        TODO+=("could not read $DEFAULT_BRANCH's rules, so Pull request linked to issue was judged as off; a plan without rules answers so, and anything else wants a rerun")
    fi
    if [[ $(jqb -r 'any(.[]; .type == "pull_request")' <<<"$BRANCH_RULES") == true ]]; then
        WANT_OFF=("${WANT_OFF[@]/Pull request linked to issue/}")
    fi
fi
FLOWS=$(gql 'query($p: ID!) { node(id: $p) { ... on ProjectV2 { workflows(first: 30) { nodes { name enabled } } } } }' \
    --arg p "$PID" | jqb -c '.data.node.workflows.nodes')
for flow in "${WANT_ON[@]}"; do
    [[ $(jqb -r --arg n "$flow" '[.[] | select(.name == $n and .enabled)] | length' <<<"$FLOWS") != 0 ]] ||
        TODO+=("turn on $flow, as references/board-contract.md sets it")
done
for flow in "${WANT_OFF[@]}"; do
    [[ -n $flow ]] || continue
    [[ $(jqb -r --arg n "$flow" '[.[] | select(.name == $n and .enabled)] | length' <<<"$FLOWS") == 0 ]] ||
        TODO+=("turn off $flow")
done
# Auto-add to project is listed with the rest, but neither its repo nor its
# filter is, so on it still asks for a look, and off or absent asks for it.
if [[ $(jqb -r '[.[] | select(.name == "Auto-add to project" and .enabled)] | length' <<<"$FLOWS") != 0 ]]; then
    TODO+=("auto-add: on; only the browser reads its repo and filter, so check it covers $REPO with is:issue is:open")
else
    TODO+=("auto-add, unless a workflow already covers $REPO: Auto-add to project, $REPO, is:issue is:open")
fi

printf 'account: %s\n' "$ME"
printf 'project: %s (%s %s, number %s)\n' "$URL" "$OWNER_TYPE" "$OWNER" "$NUM"
printf 'path: %s\n' "$HOW"
printf 'linked: %s\n' "$REPO"
printf 'todo: %s\n' "${TODO[@]}"
