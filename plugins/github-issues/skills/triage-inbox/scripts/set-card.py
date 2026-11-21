#!/usr/bin/env python3
"""Read or set one issue's card on its repo's handoff board.

    uv run --no-project <skill>/scripts/set-card.py REPO NUMBER    # read; writes nothing
    uv run --no-project <skill>/scripts/set-card.py REPO NUMBER --status "In flight" --assign
    uv run --no-project <skill>/scripts/set-card.py REPO NUMBER --status Deferred \\
        --reopen-when "<trigger>" --unassign --comment COMMENT_FILE
    uv run --no-project <skill>/scripts/set-card.py REPO NUMBER --status Open --comment COMMENT_FILE
    uv run --no-project <skill>/scripts/set-card.py REPO NUMBER --priority P1 \\
        --add-label needs:user --comment COMMENT_FILE
    uv run --no-project <skill>/scripts/set-card.py REPO NUMBER --work-model opus \\
        --work-effort blank
    uv run --no-project <skill>/scripts/set-card.py REPO NUMBER --close COMMENT_FILE
    uv run --no-project <skill>/scripts/set-card.py REPO NUMBER --close COMMENT_FILE \\
        --reason "not planned"                       # or --duplicate-of OTHER

<skill> is the triage-inbox skill's folder, as for handoff-status.py, and
REPO a checkout of the repo whose issue it is, `.` from its root.

The board is the one handoff-status.py reads: the project linked to the
repo that carries the contract in provision-board's
references/board-contract.md, never the template, and none where two carry
it. The account is the one the repo's git user.name picks, through that
account's own token, so gh never answers as the keyring's active account.
Both come from handoff-status.py, loaded from beside this file, so the
view and the writes cannot disagree on which board or which account.

WHY A SCRIPT. A Status write names the project, the item, the field and the
option by their IDs, four lookups a skill would otherwise spell out in prose
for every coordinator to get right by hand; lead-sessions claims an issue and
defers one through it, work-issue does both, and update-issue moves and
reprioritizes one, its Work model and Work effort too, without working
it, and update-issue's drop and
file-issue's close verb close one through it. It is one query to read and
one mutation to write, two with --comment and three for --close, run in
turn, all on stdin, since argv is one Windows command line and visible.

WHY THE COMMENT IS HERE. A move a person reads later says why, and the why
goes first, so a failed comment leaves the card as it was. Each skill that
moved a card ran that pair by hand, gh issue comment then this script, kept
together by "a change to either is made in both" lines in three places;
--comment makes each move one command (2026-11-14).

The writes are the claim, its release, the Priority, Work model and Work
effort and the needs:* labels, never the landing, bar --close for an issue
with nothing left to land or one dropped:

  --status       Open, Deferred or In flight. Done is closing the issue, which
                 a push carrying `Closes #N` does and the board's Item closed
                 workflow moves, so it is refused here.
  --close        COMMENT_FILE, on the user's word, for an issue with nothing
                 left to land, as work-issue's re-measure finds one, or one
                 dropped, as update-issue's drop and file-issue's close verb
                 take one. It posts the file as a comment, then, while the
                 issue is still open, removes every needs:* label and clears
                 Reopen-when, then closes it, each step only once the one
                 before it went through: a failed comment writes nothing, so
                 the trigger it records is never cleared unrecorded. A drop
                 clears them too: half the issues closed as not planned still
                 carried needs:user on 2026-11-12, 5 of 10. The comment
                 comes from a file, never argv, as update-issue's does. The
                 board's Item closed workflow sets Done, on any close, as after
                 a landing's push. It goes alone, and refuses a card someone
                 holds, as a claim does.
  --reason       with --close: completed, the default, or "not planned", as gh
                 spells them; duplicate goes with --duplicate-of.
  --duplicate-of OTHER, with --close: the issue in this repo that this one
                 duplicates, closed as DUPLICATE with closeIssue's
                 duplicateIssueId, as `gh issue close --duplicate-of` does.
  --reopen-when  the Deferred card's trigger: required with Deferred, as
                 lint-briefs requires it of a deferred brief, and refused with
                 any other Status.
  --priority     P1, P2 or P3, the card's Priority as High, Medium or Low, which
                 filing set and a reprioritize changes; it touches no claim, so
                 another's assignee does not stop it. On a board holding its
                 owner's own Priority, an issue field, it writes to the issue.
                 Urgent reads as P0, never written. A board not yet moved
                 off P1 to P3 takes the level itself.
  --work-model   haiku, sonnet, opus or fable, and --work-effort low, medium,
                 high, xhigh or max: the card's Work model and Work effort,
                 the writer's advice on how a session works the issue, which
                 filing set from a draft's work-model and work-effort. Either
                 takes blank, which clears the field, as a tracking parent
                 takes neither (2026-11-17). Like --priority they touch no claim. A
                 board lacking the field or the option is refused, naming
                 provision-board, which adds both; carries_contract checks
                 neither, so a board without them is still the board.
  --assign       adds the acting account as an assignee, so the claim holds
                 across machines and people, where a worktree claims only on
                 its own machine; --unassign removes it.
  --add-label    a needs:* label, repeatable, which the repo must hold
                 already: one it lacks is made to provision-board's contract
                 first, by gh label create, and refused here. --remove-label
                 takes one off, and is left out where the issue lacks it, a
                 write left with nothing to send refused. Any other label is
                 refused: the card's labels are its needs.
  --comment      COMMENT_FILE, posted as a comment before any other write,
                 which runs only once it went through, as --close's does. It
                 goes with any of the writes above and with none alone, and
                 never with --close, which takes its own. The file opens with
                 the move, as `Deferred: …` does.

Refused, exit 1, before anything is written: a repo with no GitHub origin or
no board, an issue that is closed or not on the board, a mirror, an issue
whose body opens by naming a brief file that still exists, since the file is
the source until the queue's cutover to the board, a duplicate of an issue
the repo does not have, and a claim, In flight, or a close, on a card
already In flight or assigned to anyone but the acting account alone, who
may claim it again to resume.

Refused too, before GitHub is asked: a comment or a Reopen-when holding a
term of the identity denylist, $IDENTITY_DENYLIST, else
~/.config/identity-denylist.txt, parsed as identity-guard and
provision-board's brief-bodies.py parse it: blanks and # lines dropped,
terms case-blind fixed strings, a `word: <term>` one only where no ASCII
letter or digit borders it, and a REPO under an exempt: prefix not checked
at all. identity-guard scans a gh issue comment's --body-file, but never
sees the gh this script runs, so a move's comment would otherwise reach
GitHub unscanned (the user's call, 2026-11-14). The refusal names the file,
or the --reopen-when text, and a count, never the term. With no denylist,
stderr says so and the write goes on, as the hook does.

After a write the card is read again and printed as GitHub then holds it,
even when the mutation failed part way, since its fields run in turn with no
rollback; a failure, or any value written that reads otherwise, exits 1 and
says how the card reads: what the board shows is the claim, not what was
sent. A close holds once the issue reads closed for the reason asked, and
a duplicate's duplicate_of names the issue asked, with no needs:* label and
Reopen-when blank; Done is the workflow's to set, so it is not waited for.

stdout is the card as one JSON object: acting_as, repo, number, title, url,
state, state_reason, GitHub's own (COMPLETED, NOT_PLANNED, DUPLICATE,
REOPENED or null), duplicate_of, the number a duplicate names or null,
board, item, status, priority, work_model, work_effort, each "" where blank,
reopen_when, assignees, needs, the issue's needs:* labels, and mirrors, the
brief file a mirror names or null.
stderr says what was written, a comment by the URL GitHub gave it, and on a
failure after the comment posted, the read back's included, that URL and to
rerun without --comment, or for --close to finish the close by hand.

--answer FILE, for tests, reads the query's answer from a JSON file instead
of GitHub, its `data` object; --dry-run prints each mutation instead of
sending it, and is implied by --answer, so a test never writes.

Stdlib only.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import pathlib
import re
import subprocess
import sys
from string import Template

# Which board, which account, and what a board is, are decided where the
# view reads them. Put in sys.modules before it runs, as importlib's recipe
# does: a dataclass in a module missing from there fails on its annotations.
_spec = importlib.util.spec_from_file_location(
    "handoff_status", pathlib.Path(__file__).with_name("handoff-status.py"))
if _spec is None or _spec.loader is None:
    sys.exit("error: handoff-status.py beside this script cannot be loaded as a module")
handoff_status = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = handoff_status
_spec.loader.exec_module(handoff_status)

BoardError = handoff_status.BoardError
SETTABLE = ("Open", "Deferred", "In flight")
PRIORITIES = tuple(sorted(handoff_status.PRIORITY_NAMES))
# Each work field by its argument's name: the board's field, its mutation's
# alias, and the options the board contract gives it, read where the view
# checks a brief's.
WORK_FIELDS = {"work_model": ("Work model", "model", handoff_status.WORK_MODELS),
               "work_effort": ("Work effort", "effort", handoff_status.WORK_EFFORTS)}
BLANK = "blank"  # a work field's value that clears it
# A close's reason as gh spells it, and as closeIssue's stateReason takes it.
REASONS = {"completed": "COMPLETED", "not planned": "NOT_PLANNED", "duplicate": "DUPLICATE"}
# The issue a duplicate names, read beside the card only for --duplicate-of.
DUPLICATE = Template("dup: issue(number: $number) { id number }")
# Each label --add-label names, read beside the card by its place in the list.
LABEL = Template("label$index: label(name: $name) { id name }")
NEEDS = "needs:"
READ = Template("""query {
  viewer { login id }
  repo: repository(owner: $owner, name: $name) {
    issueFields(first: 25) { nodes {
      ... on IssueFieldSingleSelect { id name options { id name } } } }
    projectsV2(first: 20) { nodes { id number title url closed
      fields(first: 50) { nodes {
        ... on ProjectV2FieldCommon { id name }
        ... on ProjectV2SingleSelectField { options { id name } } } } } }
    $duplicate
    $labels
    issue(number: $number) { id number title url state stateReason body
      duplicateOf { number }
      assignees(first: 10) { nodes { login id } }
      labels(first: 50) { nodes { id name } }
      projectItems(first: 10, includeArchived: false) { nodes { id project { id }
        fieldValues(first: 20) { nodes {
          ... on ProjectV2ItemFieldSingleSelectValue {
            name field { ... on ProjectV2FieldCommon { name } } }
          ... on ProjectV2ItemFieldTextValue {
            text field { ... on ProjectV2FieldCommon { name } } }
          ... on ProjectV2ItemIssueFieldValue {
            field { ... on ProjectV2FieldCommon { name } }
            issueFieldValue { ... on IssueFieldSingleSelectValue { name } } } } } } } } }
}""")


def graphql(token: str, document: str) -> dict:
    """Send one query or mutation as the token's account; its `data`, or BoardError.

    A partial answer is an error here, where the view keeps the rest: one
    card is read or written, so any part missing leaves nothing to stand on.
    """
    try:
        result = subprocess.run(["gh", "api", "graphql", "-F", "query=@-"],
                                input=document.encode("utf-8"), capture_output=True,
                                timeout=handoff_status.GH_TIMEOUT,
                                env={**os.environ, "GH_TOKEN": token})
    except FileNotFoundError:
        raise BoardError("gh is not on PATH") from None
    except OSError as error:
        raise BoardError(f"gh could not run: {error}") from None
    except subprocess.TimeoutExpired:
        raise BoardError(f"GitHub gave no answer in {handoff_status.GH_TIMEOUT} s") from None
    try:
        answer = json.loads(result.stdout.decode("utf-8", "replace") or "null")
    except json.JSONDecodeError:
        answer = None
    if not isinstance(answer, dict):
        raise BoardError(handoff_status.first_line(result.stderr)
                         or f"gh api exited {result.returncode}")
    if errors := answer.get("errors"):
        error = errors[0]
        raise BoardError("its gh token lacks the project scope"
                         if error.get("type") == "INSUFFICIENT_SCOPES"
                         else error.get("message", "an error"))
    return answer.get("data") or {}


def norm_path(path: str) -> str:
    """Normalise a path for prefix comparison, as brief-bodies.py and identity-guard do.

    Lower-case, forward slashes, `/c/...` folded to `c:/...`, one trailing
    slash. A path carrying `~` is resolved first, where the guard runs
    `cygpath -l`, so an 8.3 short name compares equal to its long form.
    """
    if "~" in path:
        path = os.path.realpath(path)
    path = path.replace("\\", "/").lower()
    drive = re.match(r"^/([a-z])(/|$)", path)
    if drive:
        path = f"{drive.group(1)}:{path[2:]}"
    return path.removesuffix("/") + "/"


def denylist_hits(repo: pathlib.Path, texts: list[tuple[str, str]]) -> list[str]:
    """Each text holding a denylisted term, as `<what>: <count>`; never the term.

    texts pairs what names each text, a file's path or the --reopen-when
    text, with the text. Nothing is checked, and nothing returned, with no
    denylist, which stderr says, or for a repo under an exempt: prefix.
    """
    path = pathlib.Path(os.environ.get("IDENTITY_DENYLIST")
                        or pathlib.Path.home() / ".config" / "identity-denylist.txt")
    if not path.is_file():
        print(f"note: no denylist at {path}, so the text written is not checked",
              file=sys.stderr)
        return []
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError) as error:
        raise BoardError(f"the denylist at {path} cannot be read ({error}), so nothing "
                         "was written") from None
    terms, words, exempt = [], [], []
    for line in lines:
        line = line.rstrip()
        if not line or line.startswith("#"):
            continue
        if line.lower().startswith("exempt:"):
            if prefix := line.split(":", 1)[1].lstrip():
                exempt.append(norm_path(prefix))
            continue
        # Indented, a word: line is one still, as the hook reads it. Its
        # boundary is the hook's [^[:alnum:]] under LC_ALL=C.
        stripped = line.lstrip()
        if stripped.lower().startswith("word:"):
            if word := stripped.split(":", 1)[1].lstrip():
                words.append(re.compile(rf"(?<![0-9a-z]){re.escape(word.lower())}(?![0-9a-z])"))
            continue
        terms.append(line.lower())
    root = norm_path(str(repo))
    if any(root.startswith(prefix) for prefix in exempt):
        return []
    hits = []
    for what, text in texts:
        lowered = text.lower()
        count = sum(lowered.count(term) for term in terms)
        count += sum(len(word.findall(lowered)) for word in words)
        if count:
            hits.append(f"{what}: {count}")
    return hits


def find_card(data: dict, repo: pathlib.Path, key: str) -> dict:
    """The card as the script reports it, with the IDs a write needs kept apart."""
    node, issue = data.get("repo") or {}, (data.get("repo") or {}).get("issue")
    if not issue:
        raise BoardError(f"no issue #{data.get('number')} in {key}")
    boards = [p for p in node["projectsV2"]["nodes"] if p and handoff_status.carries_contract(p)]
    if not boards:
        raise BoardError(f"{key} has no linked project carrying the board contract")
    if len(boards) > 1:
        numbers = ", ".join(str(p["number"]) for p in boards)
        raise BoardError(f"projects {numbers} each carry the contract, so neither is the board")
    board = boards[0]
    item = next((i for i in issue["projectItems"]["nodes"]
                 if i and i["project"]["id"] == board["id"]), None)
    values = handoff_status.card_values((item or {}).get("fieldValues", {}).get("nodes", []))
    match = handoff_status.MIRROR.match(issue.get("body") or "")
    mirrors = match.group(1) if match and (repo / match.group(1)).is_file() else None
    fields = {f["name"]: f for f in board["fields"]["nodes"] if f and f.get("name")}
    needs = {label["name"]: label["id"] for label in issue["labels"]["nodes"]
             if label and label["name"].startswith("needs:")}
    return {
        "card": {
            "acting_as": data["viewer"]["login"], "repo": key, "number": issue["number"],
            "title": issue["title"], "url": issue["url"], "state": issue["state"],
            "state_reason": issue.get("stateReason"),
            "duplicate_of": (issue.get("duplicateOf") or {}).get("number"),
            "board": board["number"], "item": item["id"] if item else None,
            "status": values.get("Status", ""), "priority": values.get("Priority", ""),
            "work_model": values.get("Work model", ""),
            "work_effort": values.get("Work effort", ""),
            "reopen_when": values.get("Reopen-when", ""),
            "assignees": [a["login"] for a in issue["assignees"]["nodes"] if a],
            "needs": list(needs), "mirrors": mirrors},
        "ids": {"viewer": data["viewer"]["id"], "issue": issue["id"], "project": board["id"],
                "fields": fields, "needs": needs,
                "issue_fields": ((node.get("issueFields") or {}).get("nodes") or []),
                "duplicate": (node.get("dup") or {}).get("id")}}


def issue_priority(found: dict, priority: str) -> str:
    """The write of the owner's Priority, an issue field: on the issue, not the card."""
    ids, quote = found["ids"], json.dumps
    field = next((f for f in ids["issue_fields"] if f and f.get("name") == "Priority"), None)
    if field is None:
        raise BoardError("the board's Priority lists no options and the repo has no such issue "
                         "field")
    wanted = handoff_status.PRIORITY_NAMES[priority]
    option = next((o["id"] for o in field["options"] if o["name"] == wanted), None)
    if option is None:
        raise BoardError(f"the owner's Priority has no option {wanted}, for {priority}")
    return (f"priority: setIssueFieldValue(input: {{issueId: {quote(ids['issue'])}, "
            f"issueFields: [{{fieldId: {quote(field['id'])}, "
            f"singleSelectOptionId: {quote(option)}}}]}}) {{ clientMutationId }}")


def clear_value(found: dict, alias: str, field_id: str) -> str:
    """One field's clear on the card, as a mutation field under its alias."""
    quote, ids = json.dumps, found["ids"]
    return (f"{alias}: clearProjectV2ItemFieldValue(input: {{"
            f"projectId: {quote(ids['project'])}, itemId: {quote(found['card']['item'])}, "
            f"fieldId: {quote(field_id)}}}) {{ projectV2Item {{ id }} }}")


def mutation(found: dict, status: str | None, reopen_when: str | None, priority: str | None,
             work: dict[str, str], assign: bool, unassign: bool, add_labels: list[str],
             remove_labels: list[str]) -> str | None:
    """The one mutation that makes the card read as asked, or None with nothing to send.

    work maps a work field's argument name to the option to set, "" to clear
    it. add_labels and remove_labels are label IDs, already found.
    """
    ids, item = found["ids"], found["card"]["item"]
    quote = json.dumps  # a JSON string is a GraphQL string literal

    def set_value(alias: str, field: str, value: str) -> str:
        return (f"{alias}: updateProjectV2ItemFieldValue(input: {{"
                f"projectId: {quote(ids['project'])}, itemId: {quote(item)}, "
                f"fieldId: {quote(ids['fields'][field]['id'])}, value: {{{value}}}}}) "
                "{ projectV2Item { id } }")

    parts = []
    if status:
        option = next(o["id"] for o in ids["fields"]["Status"]["options"] if o["name"] == status)
        parts.append(set_value("status", "Status", f"singleSelectOptionId: {quote(option)}"))
    if reopen_when is not None:
        parts.append(set_value("reopen", "Reopen-when", f"text: {quote(reopen_when)}"))
    if priority and handoff_status.issue_backed(ids["fields"]["Priority"]):
        parts.append(issue_priority(found, priority))
    elif priority:
        # carries_contract has held the field to one spelling or the other. The name
        # comes first where it offers both, as file-issues.sh takes it; a board not
        # yet moved off P1 to P3 still names the level itself.
        options = ids["fields"]["Priority"]["options"]
        names = (handoff_status.PRIORITY_NAMES[priority], priority)
        option = next(o["id"] for name in names for o in options if o["name"] == name)
        parts.append(set_value("priority", "Priority", f"singleSelectOptionId: {quote(option)}"))
    for attr, value in work.items():
        field, alias, _ = WORK_FIELDS[attr]
        board = found["card"]["board"]
        if (listed := ids["fields"].get(field)) is None:
            raise BoardError(f"board {board} has no {field} field: provision-board adds it")
        if not value:
            parts.append(clear_value(found, alias, listed["id"]))
            continue
        option = next((o["id"] for o in listed.get("options") or [] if o["name"] == value), None)
        if option is None:
            raise BoardError(f"board {board}'s {field} has no option {value}: "
                             "provision-board adds it")
        parts.append(set_value(alias, field, f"singleSelectOptionId: {quote(option)}"))
    if assign or unassign:
        verb = "addAssigneesToAssignable" if assign else "removeAssigneesFromAssignable"
        parts.append(f"assign: {verb}(input: {{assignableId: {quote(ids['issue'])}, "
                     f"assigneeIds: [{quote(ids['viewer'])}]}}) {{ clientMutationId }}")
    for alias, verb, labels in (("add", "addLabelsToLabelable", add_labels),
                                ("remove", "removeLabelsFromLabelable", remove_labels)):
        if labels:
            parts.append(f"{alias}: {verb}(input: {{labelableId: {quote(ids['issue'])}, "
                         f"labelIds: [{', '.join(quote(label) for label in labels)}]}}) "
                         "{ clientMutationId }")
    return "mutation {\n  " + "\n  ".join(parts) + "\n}" if parts else None


def comment_step(found: dict, comment: str) -> tuple[str, str]:
    """The comment's mutation, named, sent before any other: --comment's and --close's."""
    # Unescaped past ASCII, so the body carries no \u surrogate pair for a
    # parser to misread; a JSON string is a GraphQL string literal either way.
    return ("the comment",
            f"mutation {{\n  comment: addComment(input: {{subjectId: "
            f"{json.dumps(found['ids']['issue'])}, "
            f"body: {json.dumps(comment, ensure_ascii=False)}}}) "
            "{ commentEdge { node { url } } }\n}")


def comment_url(answer: dict) -> str:
    """The posted comment's URL from addComment's answer, or "" where it holds none."""
    edge = (answer.get("comment") or {}).get("commentEdge") or {}
    return (edge.get("node") or {}).get("url") or ""


def note_posted(posted: bool, url: str, args: argparse.Namespace) -> None:
    """Name a comment that posted before the run failed, so no rerun posts it twice.

    A move's comment rides on --comment, so its rerun drops that flag; --close's
    is its own argument, so a rerun of it always posts again, and the close is
    finished by hand instead.
    """
    if not posted:
        return
    rerun = ("rerun without --comment" if args.comment
             else "a rerun of --close posts it again: finish the close by hand")
    print(f"note: the comment posted, {url or 'its URL not returned'}; {rerun}",
          file=sys.stderr)


def close_steps(found: dict, comment: str, reason: str) -> list[tuple[str, str]]:
    """The close's mutations, named, in the order they run: comment, clear, close.

    Each is its own mutation, sent only once the one before it went through:
    a mutation's fields run on past a failed one, so one document would
    clear the trigger and close the issue under a comment that never posted.
    The clear runs while the issue is open, where every other write runs,
    and is left out when there is nothing to clear. The close names its
    reason, and a duplicate the issue it duplicates, already found.
    """
    ids, card, quote = found["ids"], found["card"], json.dumps
    issue = quote(ids["issue"])
    steps = [comment_step(found, comment)]
    clear = []
    if ids["needs"]:
        labels = ", ".join(quote(label) for label in ids["needs"].values())
        clear.append(f"labels: removeLabelsFromLabelable(input: {{labelableId: {issue}, "
                     f"labelIds: [{labels}]}}) {{ clientMutationId }}")
    if card["reopen_when"]:
        clear.append(clear_value(found, "reopen", ids["fields"]["Reopen-when"]["id"]))
    if clear:
        steps.append(("the clear", "mutation {\n  " + "\n  ".join(clear) + "\n}"))
    duplicate = (f", duplicateIssueId: {quote(ids['duplicate'])}"
                 if reason == "DUPLICATE" else "")
    steps.append(("the close",
                  f"mutation {{\n  close: closeIssue(input: {{issueId: {issue}, "
                  f"stateReason: {reason}{duplicate}}}) {{ issue {{ state }} }}\n}}"))
    return steps


def refusal(card: dict, status: str | None, closing: bool = False) -> str | None:
    """Why no write may touch this card, or None.

    A claim on a card someone else holds, In flight or assigned to another,
    is refused, or two sessions would each read In flight back and go on;
    the acting account alone on it may claim it again, to resume. A close
    is refused there too: the issue is that session's to land or release.
    """
    if card["state"] != "OPEN":
        return f"#{card['number']} is {card['state'].lower()}"
    if card["item"] is None:
        return (f"#{card['number']} is not on board {card['board']}: "
                "file-issue's board verb puts an existing issue on it")
    if card["mirrors"]:
        return (f"#{card['number']} mirrors {card['mirrors']}, which is the source until the "
                "cutover: work the brief file")
    held = card["assignees"] != [card["acting_as"]] and (
        card["assignees"] or card["status"] == "In flight")
    if (status == "In flight" or closing) and held:
        owners = ", ".join(card["assignees"]) or "no assignee"
        return f"#{card['number']} is already claimed: {card['status']}, {owners}"
    return None


def misread(card: dict, args: argparse.Namespace) -> list[str]:
    """Each value the card does not hold as the write asked."""
    wrong = []
    if args.status and card["status"] != args.status:
        wrong.append(f"Status {card['status'] or 'blank'}")
    if args.reopen_when is not None and card["reopen_when"] != args.reopen_when:
        wrong.append(f"Reopen-when {card['reopen_when'] or 'blank'}")
    if args.priority and card["priority"] != args.priority:
        wrong.append(f"Priority {card['priority'] or 'blank'}")
    for attr, (field, _, _) in WORK_FIELDS.items():
        wanted = getattr(args, attr)
        if wanted is not None and card[attr] != ("" if wanted == BLANK else wanted):
            wrong.append(f"{field} {card[attr] or 'blank'}")
    if args.assign and card["acting_as"] not in card["assignees"]:
        wrong.append(f"{card['acting_as']} not assigned")
    if args.unassign and card["acting_as"] in card["assignees"]:
        wrong.append(f"{card['acting_as']} still assigned")
    have = {name.lower() for name in card["needs"]}
    wrong += [f"{name} not on" for name in args.add_label if name.lower() not in have]
    wrong += [f"{name} still on" for name in args.remove_label if name.lower() in have]
    if args.close:
        if card["state"] != "CLOSED":
            wrong.append(f"still {card['state'].lower()}")
        elif card["state_reason"] != REASONS[args.reason]:
            wrong.append(f"closed as {card['state_reason'] or 'no reason'}")
        if args.duplicate_of and card["duplicate_of"] != args.duplicate_of:
            wrong.append(f"duplicate of {card['duplicate_of'] or 'nothing'}")
        if card["needs"]:
            wrong.append(f"{', '.join(card['needs'])} still on")
        if card["reopen_when"]:
            wrong.append(f"Reopen-when {card['reopen_when']}")
    return wrong


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("repo", type=pathlib.Path)
    parser.add_argument("number", type=int)
    parser.add_argument("--status", choices=SETTABLE)
    parser.add_argument("--reopen-when")
    parser.add_argument("--priority", choices=PRIORITIES)
    for attr, (_, _, options) in WORK_FIELDS.items():
        parser.add_argument(f"--{attr.replace('_', '-')}", choices=(*options, BLANK))
    claim = parser.add_mutually_exclusive_group()
    claim.add_argument("--assign", action="store_true")
    claim.add_argument("--unassign", action="store_true")
    parser.add_argument("--add-label", action="append", default=[], metavar="needs:VALUE")
    parser.add_argument("--remove-label", action="append", default=[], metavar="needs:VALUE")
    parser.add_argument("--comment", type=pathlib.Path, metavar="COMMENT_FILE")
    parser.add_argument("--close", type=pathlib.Path, metavar="COMMENT_FILE")
    parser.add_argument("--reason", choices=tuple(REASONS))
    parser.add_argument("--duplicate-of", type=int, metavar="OTHER")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--answer", type=pathlib.Path)
    args = parser.parse_args()

    def read_comment(flag: str, path: pathlib.Path) -> str:
        try:
            text = path.read_text(encoding="utf-8").strip()
        except (OSError, UnicodeDecodeError) as error:
            parser.error(f"{flag} cannot read its comment file: {error}")
        if not text:
            parser.error(f"{flag} needs its comment: the file is empty")
        return text

    comment = ""
    args.add_label = [name.strip() for name in args.add_label]
    args.remove_label = [name.strip() for name in args.remove_label]
    for flag, names in (("--add-label", args.add_label), ("--remove-label", args.remove_label)):
        for name in names:
            if not name.startswith(NEEDS) or not name[len(NEEDS):].strip():
                parser.error(f"{flag} takes a needs:* label, not {name or 'a blank'}")
    if both := {n.lower() for n in args.add_label} & {n.lower() for n in args.remove_label}:
        parser.error(f"{', '.join(sorted(both))} cannot be both added and removed")
    card_writes = bool(args.status or args.priority or args.work_model or args.work_effort
                       or args.assign or args.unassign or args.add_label or args.remove_label)
    if args.comment:
        if args.close:
            parser.error("--comment never goes with --close, which posts its own")
        if not card_writes:
            parser.error("--comment goes with a write it records, never alone")
        comment = read_comment("--comment", args.comment)
    if (args.reason or args.duplicate_of is not None) and not args.close:
        parser.error("--reason and --duplicate-of go with --close")
    if args.duplicate_of is not None:
        if args.reason not in (None, "duplicate"):
            parser.error(f"--duplicate-of closes as a duplicate, not as {args.reason}")
        if args.duplicate_of == args.number:
            parser.error(f"#{args.number} cannot be its own duplicate")
        args.reason = "duplicate"
    elif args.reason == "duplicate":
        parser.error("--reason duplicate needs --duplicate-of, the issue it duplicates")
    args.reason = args.reason or "completed"
    if args.close:
        if card_writes or args.reopen_when is not None:
            parser.error("--close goes alone: it clears the card itself")
        comment = read_comment("--close", args.close)
    if (args.status == "Deferred") != (args.reopen_when is not None):
        parser.error("--reopen-when goes with --status Deferred, and only with it")
    if args.reopen_when is not None:
        args.reopen_when = args.reopen_when.strip()
        if not args.reopen_when:
            parser.error("--reopen-when needs its trigger")
    writes = card_writes or bool(args.close)

    repo = args.repo.resolve()
    posted, url = False, ""
    try:
        # Each text this run would send, checked before GitHub is asked.
        texts = [(str(args.comment or args.close), comment)] if comment else []
        if args.reopen_when:
            texts.append(("the --reopen-when text", args.reopen_when))
        if texts and (hits := denylist_hits(repo, texts)):
            raise BoardError(f"a denylisted term in {'; '.join(hits)}, so nothing was written: "
                             "reword it by kind")
        remote = handoff_status.github_remote(repo)
        if not remote:
            raise BoardError(f"{repo} has no GitHub origin")
        key, account = remote
        owner, name = key.split("/", 1)
        duplicate = (DUPLICATE.substitute(number=args.duplicate_of)
                     if args.duplicate_of is not None else "")
        labels = "\n    ".join(LABEL.substitute(index=index, name=json.dumps(label))
                               for index, label in enumerate(args.add_label))
        query = READ.substitute(owner=json.dumps(owner), name=json.dumps(name),
                                number=args.number, duplicate=duplicate, labels=labels)
        if args.answer:
            token = ""
            data = json.loads(args.answer.read_text(encoding="utf-8"))
        else:
            token = handoff_status.gh_token(account)
            data = graphql(token, query)
        data = {**data, "number": args.number}
        found = find_card(data, repo, key)
        card = found["card"]
        print(f"acting as {card['acting_as']}", file=sys.stderr)
        if not writes:
            print(json.dumps(card, indent=2))
            return 0
        if why := refusal(card, args.status, closing=bool(args.close)):
            raise BoardError(why)
        if args.duplicate_of is not None and not found["ids"]["duplicate"]:
            raise BoardError(f"no issue #{args.duplicate_of} in {key} for "
                             f"#{args.number} to duplicate")
        if args.close:
            steps = close_steps(found, comment, REASONS[args.reason])
        else:
            add_ids = []
            for index, label in enumerate(args.add_label):
                if not (found_label := data["repo"].get(f"label{index}") or {}).get("id"):
                    raise BoardError(f"no label {label} in {key}: make it to the board "
                                     "contract first, by gh label create")
                add_ids.append(found_label["id"])
            held = {name.lower(): label_id for name, label_id in found["ids"]["needs"].items()}
            remove_ids = [held[name.lower()] for name in args.remove_label if name.lower() in held]
            # A clear of a field already blank is left out, as a remove of a
            # label the issue lacks is: absent names each, for the refusal.
            absent = [name for name in args.remove_label if name.lower() not in held]
            work = {}
            for attr, (field, _, _) in WORK_FIELDS.items():
                if (wanted := getattr(args, attr)) is None:
                    continue
                if wanted != BLANK:
                    work[attr] = wanted
                elif card[attr]:
                    work[attr] = ""
                else:
                    absent.append(f"a {field}")
            write = mutation(found, args.status, args.reopen_when, args.priority, work,
                             args.assign, args.unassign, add_ids, remove_ids)
            if write is None:
                raise BoardError(f"#{args.number} carries none of "
                                 f"{', '.join(absent)}, so nothing was written")
            steps = [comment_step(found, comment)] if comment else []
            steps.append(("the write", write))
        if args.dry_run or args.answer:
            print("\n".join(document for _, document in steps))
            return 0
        # A mutation's fields run in turn with no rollback, so a failure part way
        # may leave some written: the card is read back either way, and printed.
        before, failed = card, None
        for step, document in steps:
            try:
                answer = graphql(token, document)
            except BoardError as error:
                failed = f"{step} failed ({error})"
                break
            if step == "the comment":
                posted, url = True, comment_url(answer)
        card = find_card({**graphql(token, query), "number": args.number}, repo, key)["card"]
    except BoardError as error:
        print(f"error: {error}", file=sys.stderr)
        note_posted(posted, url, args)
        return 1
    except (KeyError, TypeError) as error:
        print(f"error: an answer shaped unlike the query ({error!r})", file=sys.stderr)
        note_posted(posted, url, args)
        return 1
    print(json.dumps(card, indent=2))
    if failed or (wrong := misread(card, args)):
        why = failed or "the write did not hold"
        owners = ", ".join(card["assignees"]) or "none"
        reads = (f"Status {card['status'] or 'blank'}, Priority {card['priority'] or 'blank'}, "
                 f"Reopen-when {card['reopen_when'] or 'blank'}, assignees {owners}")
        if args.work_model or args.work_effort:
            reads += (f", Work model {card['work_model'] or 'blank'}, "
                      f"Work effort {card['work_effort'] or 'blank'}")
        if args.close or args.add_label or args.remove_label:
            reads += f", labels {', '.join(card['needs']) or 'no needs:*'}"
        if args.close:
            reads += f", {card['state'].lower()}"
        print(f"error: {why}; the card reads {reads}", file=sys.stderr)
        note_posted(posted, url, args)
        if not failed:
            print(f"error: not as asked: {'; '.join(wrong)}", file=sys.stderr)
        return 1
    commented = f"commented {url}".rstrip()
    if args.close:
        done = [commented]
        done += [f"removed {', '.join(before['needs'])}"] if before["needs"] else []
        done += ["cleared Reopen-when"] if before["reopen_when"] else []
        closed = (f"a duplicate of #{args.duplicate_of}" if args.duplicate_of is not None
                  else args.reason)
        print(f"#{card['number']}: {', '.join(done)}, closed as {closed}; the board's "
              "Item closed workflow sets Done", file=sys.stderr)
        return 0
    done = [f"Status {args.status}"] if args.status else []
    done += ["Reopen-when"] if args.reopen_when is not None else []
    done += [f"Priority {args.priority}"] if args.priority else []
    for attr, (field, _, _) in WORK_FIELDS.items():
        if (wanted := getattr(args, attr)) == BLANK:
            done += [f"{field} cleared"] if before[attr] else []
        elif wanted:
            done.append(f"{field} {wanted}")
    done += [f"{'assigned' if args.assign else 'unassigned'} {card['acting_as']}"] \
        if args.assign or args.unassign else []
    done += [f"{name} added" for name in args.add_label]
    done += [f"{name} removed" for name in before["needs"]
             if name.lower() in {label.lower() for label in args.remove_label}]
    print(f"#{card['number']}: {commented + ', ' if comment else ''}wrote {', '.join(done)}",
          file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
