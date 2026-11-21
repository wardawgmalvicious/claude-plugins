#!/usr/bin/env python3
"""What handoff work is open in every repo on this machine, in one view.

    uv run --no-project <skill>/scripts/handoff-status.py          # every repo beside this one
    uv run --no-project <skill>/scripts/handoff-status.py ROOT...  # a parent, or one repo
    uv run --no-project <skill>/scripts/handoff-status.py --check  # exit 1 on any finding
    uv run --no-project <skill>/scripts/handoff-status.py . --check --no-inbox   # one repo's briefs
    uv run --no-project <skill>/scripts/handoff-status.py . --json # the view as JSON, for a skill

<skill> is the triage-inbox skill's folder wherever it is installed, at user
scope or in a plugin, so any repo can run the view and wire the check as a
pre-commit hook without naming the repo the skill comes from. With no ROOT
it sweeps two levels above the working directory's repo, its main
checkout's when run from a linked worktree, where the repos sit as
<root>/<group>/<repo>; the working directory decides, never this file's
location, which inside a skill folder is no repo's (2026-10-24).
--no-project keeps uv from syncing the Python project of the repo it runs in.

Each repo keeps its own handoff index and the inbox keeps one directory per
repo, so answering "what is open, anywhere" meant opening every index and
listing every inbox directory by hand. Nothing aggregated them, and work got
lost between them: on 2026-09-18 an estate repo's index was found to have
answered two open questions in this repo's own queue two days earlier, and
nobody had read it. This sweeps them all and prints one section per repo
that has anything, in each index's own order.

Everything is DERIVED -- no state is kept here.
A brief states its own state in frontmatter, or an index states it:

  Frontmatter  a brief opening with `---` carries its state, and no index
            row is needed: the authoring repo's queue since 2026-09-27, when a
            hand-kept table proved to be what made two sessions collide.
            The grammar is a strict YAML subset, `key: value` or
            `key: [a, b]`, so this stays stdlib and GitHub renders it:
              status       open | deferred
              priority     1 | 2 | 3, buckets with no order inside one
              needs        [user, tenant, ...]; empty means a session can act
              blocked-by   [brief.md, 62, ...], each a file beside this one
                           or an issue's number, bare, since YAML reads
                           ` #<n>` as a comment; an issue blocks until the
                           board's read shows it closed
              parent       62, optional: the issue its issue is a
                           sub-issue of, once provision-board files it
              reopen-when  the trigger, required when deferred
              written      YYYY-MM-DD, the tiebreak within a bucket
              work-model   haiku | sonnet | opus | fable, optional: the
                           model the writer recommends working it on
              work-effort  low | medium | high | xhigh | max, optional
              platform     [fabric, claude, ...], optional: what the work
                           touches, each lowercase kebab
            Such briefs print grouped -- ready, needs you, a group for
            each other need, named for it (needs desktop, needs tenant),
            blocked, deferred -- by bucket, then oldest first, and one is
            "in flight" while a git worktree is named after it:
              held    a live session's lock, or a lock naming no pid
              merged  its branch committed, and the main checkout's HEAD
                      holds that: landed, its deployed-payload check to run
              parked  neither: unlanded work, or none begun, left there
            A lock whose pid is gone, a crashed session's, adds "lock
            stale", and prune-branches proposes the unlock.
  Rows      every table row or list item in a README.md under docs/handoffs/
            whose FIRST element is a link to a brief. Links elsewhere in a
            row, and links in prose, are not rows.
  State     the row's first **bold** span, which is where every index here
            puts it; failing that, the heading the row sits under.
  Touched   the date of the last commit to touch the brief, from one
            `git log` per repo (a spawn costs ~0.4 s here, so never one per
            file). `uncommitted` when no commit has touched it.
  Inbox     handoff-inbox/<repo>/ in the home directory, or under --inbox,
            keyed on the repo directory's name,
            which is what the inbox README tells a writer to use: from a
            linked worktree, its main checkout's. The age is read from the
            note's date prefix.
  Board     a GitHub project linked to the repo that carries the board
            contract, provision-board's references/board-contract.md: Status
            with Open, Deferred, In flight and Done, Priority with High,
            Medium and Low, an organization's own or the project's, which
            read as P1 to P3 and Urgent as P0, or a board's older P1 to P3,
            and a Reopen-when text field. A project short of Priority alone
            prints `board: not read`, not silence. Each open issue of the repo on it
            joins the queue as a brief does, its fields for frontmatter:
            Status Deferred for deferred, a `needs:<value>` label for each
            need, an open issue blocking it for blocked-by, its creation for
            written, and In flight for the claim, which the board holds where
            a brief's worktree does. A sub-issue prints under its parent
            where both are listed; a parent with open sub-issues is blocked,
            since a parent tracks and its sub-issues hold the work, and one
            whose sub-issues are all closed is flagged to close, and a
            Deferred one with a blank Reopen-when, as a card dragged there
            keeps, is flagged on its line, since --check never reads a
            board to make it a finding. The open
            issues are read 100 to a page, up to ISSUE_PAGES pages, and a
            note says when there were more. An issue whose body opens by naming a
            brief file, "Mirrors" or "Filed from", is left out while that
            file exists, since the file is the source until the queue's
            cutover to the board (2026-10-27). Any other open issue with no
            item on the board prints as `off board: #<n> <title>`, outside
            every group, since auto-add takes no issue filed before the board
            and silence read as no such issue (2026-10-30). It is no finding,
            as --check reads no board, and a card archived, or an issue on
            more than the ten projects the query reads, reads as off it too.
            The project titled "Backlog
            template" is no board, and where two carry the contract
            neither is read. One spawn per repo, side by side, reads its
            remote and git user.name; then per account, as the gh wrapper
            picks one from user.name, `gh auth token --user` and two GraphQL
            queries, each on stdin: a native gh.exe otherwise answers as the
            keyring's active account. A repo off GitHub or with no such
            project reads its files alone, as a queue audit-repo scaffolds in
            a client repo does, and a failed read says why on stderr and does
            the same. --check never reads a board, since lint-briefs runs it
            offline and in CI. A repo whose board holds no open issue yet
            still lists, its board line alone, though the summary counts it
            as no repo with work: dropped whole, a board provisioned that day
            read as `"repos": []`, which file-issue took for no board
            (2026-11-02).

A brief is any .md under docs/handoffs/ other than a README.md or an
instruction file, a CLAUDE.md or AGENTS.md, other than anything under
templates/ or examples/, which are reference material rather than work,
and other than DECLINED.md at the tree's root: the ledger of learnings
declined at inbox triage, a record and never a queue row.

Findings, which --check turns into exit 1:

  unindexed   a brief with no frontmatter that no index row links to --
              invisible to the one file a session is told to read first
  dangling    a row whose brief is gone -- spent but never struck
  frontmatter a value missing, unknown, or one a real YAML parser would
              misread, such as one opening with a backtick
  blocker     a blocked-by naming a brief that is gone: the landing that
              deleted it should have deleted the name too
  loose       a note in the inbox root, addressed to no repo
  orphan      an inbox directory matching no repo swept, e.g. a misspelling

--no-inbox skips the last two and the inbox listing, which lets pre-commit
check one repo's briefs without calling every other repo's inbox an orphan.

A date or position in a brief's FILENAME is reported but is not a finding:
it breaks the common core's stable-filename rule, but a repo's own convention
outranks that core, so this says so and leaves it there.

--json prints the same view as one JSON document instead of the tables, for
a reader that would otherwise scrape columns (report-backlog, 2026-10-23):
each repo with work or a board, its briefs in print order with their frontmatter keys
in snake case, its index rows, inbox notes and findings, then the inbox
root's loose notes and orphan directories. A brief's group is one of
GROUPS: "needs something else" stays one group there, its needs list
saying what the tables split it by. Every path is relative to its repo.
--check sets the exit code as it does without.
A board's issue joins the briefs with `#<number>` for its path, adding its
title, url, assignees and board_status, its sub_issues, {total,
completed} or null, and ready_to_close, and each repo's board is null, or
its number, title and url with a note saying what was not read. Every
entry carries parent: `#<number>`, `<owner>/<name>#<number>` for another
repo's issue, or null. An issue off the board is in neither briefs nor
findings, whose readers take it for queue work or a commit's blocker, but
in the repo's off_board, each with its `#<number>` path, title and url.
Each repo's counts tallies what the rest prints, so no reader counts rows by
hand and miscounts them (2026-11-02, 48 and 49 against 50): briefs, groups
(one count per GROUPS entry, zero included), needs (the "needs something
else" briefs by the heading the tables print them under), in_flight, off_board,
notes and findings.

--no-board reads files alone; --board-answer FILE, for tests, reads each
repo's GitHub answer from a JSON object keyed `owner/name` instead, a node
holding projectsV2 and issues as the queries ask for them, or a string for
the error that stands in for one; a later page of issues is keyed
`owner/name@<endCursor>`.

Stdlib only. Reads other repos and GitHub, and never writes to either.
"""

from __future__ import annotations

import argparse
import ctypes
import datetime as dt
import io
import json
import os
import pathlib
import re
import subprocess
import sys
from collections.abc import Callable, Sequence
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from string import Template
from typing import Union

INBOX = pathlib.Path.home() / "handoff-inbox"


def display_path(path: pathlib.Path) -> str:
    """A folder as a reader types it: from ~ under the home directory.

    absolute(), not resolve(), so a junction or symlink inbox prints as the
    path given, not its target.
    """
    try:
        return "~/" + path.absolute().relative_to(pathlib.Path.home().absolute()).as_posix()
    except ValueError:
        return path.as_posix()


HANDOFFS = pathlib.PurePosixPath("docs/handoffs")
REFERENCE_DIRS = {"templates", "examples"}
# An index, and the instruction files a directory may keep for its readers.
NOT_BRIEFS = {"readme.md", "claude.md", "agents.md"}
# Kept at the tree's root only, so a brief of the same name under execute/
# is still a brief.
LEDGERS = {"declined.md"}

# A row is a table row or list item that OPENS with a link to a .md file.
ROW_LINK = re.compile(
    r"^\s*(?:\||[-*]|\d+\.)\s*\[[^\]]*\]\(([^)\s#]+\.md)(?:#[^)]*)?\)")
BOLD = re.compile(r"\*\*(.+?)\*\*")
HEADING = re.compile(r"^#{1,6}\s+(.*)")
DATED_NAME = re.compile(r"^(\d{4}-\d{2}-\d{2}|\d{1,3})[-_]")
NOTE_DATE = re.compile(r"^(\d{4}-\d{2}-\d{2})-")
STATE_WIDTH = 46

FM_KEYS = ("status", "priority", "needs", "blocked-by", "reopen-when", "written",
           "work-model", "work-effort", "platform", "parent")
# An issue's number, as parent and a blocked-by item take one.
ISSUE_NUMBER = re.compile(r"[1-9][0-9]*")
FM_LISTS = {"needs", "blocked-by", "platform"}
FM_LINE = re.compile(r"^([a-z][a-z-]*):[ \t]*(.*?)[ \t]*$")
STATUSES = ("open", "deferred")
PRIORITIES = ("1", "2", "3")
# Aliases, never dated IDs, which freeze on one release once the next ships;
# the levels are the CLI's --effort values. Omitted, a session's defaults.
WORK_MODELS = ("haiku", "sonnet", "opus", "fable")
WORK_EFFORTS = ("low", "medium", "high", "xhigh", "max")
# A platform:* value's shape, as provision-board's references/board-contract.md
# gives it, and brief-bodies.py's PLATFORM; no set is fixed, since a repo's
# platform:* labels are its list.
PLATFORM = re.compile(r"[a-z0-9]+(-[a-z0-9]+)*")
# A plain YAML scalar may not open with an indicator, nor hold ": " or " #".
YAML_INDICATORS = tuple("`@&*!|>%{}[],#?'\"")
GROUPS = ("ready", "needs you", "needs something else", "blocked", "deferred")
# Claude Code locks the worktree a session holds as
# "claude session <name> (pid <n>)" (the prune-branches skill).
LOCK_PID = re.compile(r"\(pid (\d+)\)")
PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
STILL_ACTIVE = 259
ERROR_ACCESS_DENIED = 5

# What makes a linked project a queue board: provision-board's
# references/board-contract.md. A field's options are those it must offer, bar
# Priority, whose older levels, PRIORITY_NAMES's keys, may stand in; None is a
# text field.
CONTRACT = {"Status": {"Open", "Deferred", "In flight", "Done"},
            "Priority": {"High", "Medium", "Low"}, "Reopen-when": None}
# A board's Priority offers Urgent, High, Medium and Low: a project field, or,
# where its owner, an organization or a user, defines one, an issue field, which
# a board lists as a single select with no options and a card holds in its own
# fragment. A brief stays 1 to 3 whichever it is, read here as P1 to P3, and
# Urgent is a person's, so no filing writes it. A board not yet moved keeps P1
# to P3 as its options.
PRIORITY_NAMES = {"P1": "High", "P2": "Medium", "P3": "Low"}
PRIORITY_READ = {name: level for level, name in PRIORITY_NAMES.items()} | {"Urgent": "P0"}
BOARD_TEMPLATE = "Backlog template"
NEEDS_LABEL = "needs:"
# The opening of a body provision-board filed from a brief, or the pilot mirrored.
MIRROR = re.compile(r"(?:Mirrors|Filed from) \[`(docs/handoffs/[^`]+\.md)`\]")
GITHUB_REMOTE = re.compile(r"github\.com[:/]([^/\s]+)/([^/\s]+?)(?:\.git)?/?$")
GH_TIMEOUT = 30
ISSUE_PAGE = 100
ISSUE_PAGES = 20  # 2,000 open issues a repo, past which a note says more were left
REPOS_PER_QUERY = 10
REMOTE_WORKERS = 8  # git spawns, one per swept repo
ACCOUNT_WORKERS = 4  # one gh token and its queries per account
# One alias per repo, so one query asks for every repo an account holds.
PROJECTS = Template("""
  $alias: repository(owner: $owner, name: $name) {
    projectsV2(first: 20) { nodes { id number title url closed
      fields(first: 50) { nodes {
        ... on ProjectV2FieldCommon { name }
        ... on ProjectV2SingleSelectField { options { name } } } } } } }""")
ISSUES = Template("""
  $alias: repository(owner: $owner, name: $name) {
    issues(states: OPEN, first: $page, after: $after,
           orderBy: {field: CREATED_AT, direction: DESC}) {
      pageInfo { hasNextPage endCursor }
      nodes { number title url body createdAt updatedAt
        labels(first: 20) { nodes { name } }
        assignees(first: 10) { nodes { login } }
        blockedBy(first: 20) { nodes { number state repository { nameWithOwner } } }
        parent { number url repository { nameWithOwner } }
        subIssuesSummary { total completed }
        projectItems(first: 10, includeArchived: false) { nodes {
          project { id }
          fieldValues(first: 20) { nodes {
            ... on ProjectV2ItemFieldSingleSelectValue {
              name field { ... on ProjectV2FieldCommon { name } } }
            ... on ProjectV2ItemFieldTextValue {
              text field { ... on ProjectV2FieldCommon { name } } }
            ... on ProjectV2ItemIssueFieldValue {
              field { ... on ProjectV2FieldCommon { name } }
              issueFieldValue { ... on IssueFieldSingleSelectValue { name } } } } } } } } } }""")

for _stream in (sys.stdout, sys.stderr):
    if isinstance(_stream, io.TextIOWrapper):
        _stream.reconfigure(encoding="utf-8", errors="replace")


@dataclass
class Row:
    index: pathlib.Path
    target: pathlib.Path
    state: str


class Queued:
    """What a brief and a board's issue share: frontmatter's keys, and where they place it."""
    meta: dict[str, str | list[str]]

    def get(self, key: str) -> str:
        value = self.meta.get(key, "")
        return value if isinstance(value, str) else ""

    def items(self, key: str) -> list[str]:
        value = self.meta.get(key, [])
        return value if isinstance(value, list) else []

    @property
    def blockers(self) -> list[str]:
        return []

    @property
    def parent(self) -> str:
        """The issue this is a sub-issue of, `#<n>`, or "" for none."""
        return ""

    @property
    def open_subs(self) -> int:
        """Sub-issues still open; a parent with any is held blocked."""
        return 0

    @property
    def tiebreak(self) -> str:
        return ""

    @property
    def group(self) -> str:
        # A parent tracks and its sub-issues hold the work, so it waits on them.
        if self.get("status") == "deferred":
            return "deferred"
        if self.blockers or self.open_subs:
            return "blocked"
        return needs_group(self.items("needs"))

    @property
    def sort_key(self) -> tuple[str, str, str]:
        return (self.get("priority") or "9", self.get("written"), self.tiebreak)


@dataclass
class Brief(Queued):
    """A brief that states its own state in frontmatter."""
    path: pathlib.Path
    meta: dict[str, str | list[str]]
    problems: list[tuple[str, str]] = field(default_factory=list)
    # The repo's open issues, once a board's read lists them; None until then,
    # when an issue named in blocked-by is taken to block.
    open_issues: set[int] | None = None

    @property
    def name(self) -> str:
        return self.path.name

    @property
    def tiebreak(self) -> str:
        return self.path.name

    @property
    def source(self) -> tuple[int, str]:
        return (0, self.path.parent.as_posix())

    @property
    def blockers(self) -> list[str]:
        found = []
        for item in self.items("blocked-by"):
            if ISSUE_NUMBER.fullmatch(item):
                if self.open_issues is None or int(item) in self.open_issues:
                    found.append(f"#{item}")
            elif (self.path.parent / item).is_file():
                found.append(item)
        return found

    @property
    def parent(self) -> str:
        """Frontmatter's parent as `#<n>`, or "" for none or one validate() reports."""
        return f"#{self.get('parent')}" if ISSUE_NUMBER.fullmatch(self.get("parent")) else ""

    def claim(self, report: RepoReport) -> str | None:
        return report.worktrees.get(self.path.stem)


@dataclass
class Issue(Queued):
    """An open issue on the repo's board, its fields read into frontmatter's keys."""
    number: int
    title: str
    url: str
    meta: dict[str, str | list[str]]
    blocked_by: list[str]
    touched: str
    board_status: str
    assignees: list[str]
    parent_ref: str = ""  # `#<n>`, or `<owner>/<name>#<n>` in another repo
    parent_url: str = ""
    sub_total: int = 0
    sub_completed: int = 0

    @property
    def name(self) -> str:
        return f"#{self.number}"

    @property
    def parent(self) -> str:
        """The parent GitHub links, as parent_ref names it."""
        return self.parent_ref

    @property
    def open_subs(self) -> int:
        """Sub-issues GitHub counts as not completed."""
        return self.sub_total - self.sub_completed

    @property
    def ready_to_close(self) -> bool:
        """Every sub-issue closed, so the parent, which holds no work of its own, can close."""
        return bool(self.sub_total) and not self.open_subs

    @property
    def tiebreak(self) -> str:
        return f"{self.number:09d}"  # padded, so 9 sorts before 10

    @property
    def source(self) -> tuple[int, str]:
        return (1, "")

    @property
    def blockers(self) -> list[str]:
        return self.blocked_by

    def claim(self, report: RepoReport) -> str | None:
        if self.board_status != "In flight":
            return None
        return "board" + (f": {', '.join(self.assignees)}" if self.assignees else "")


# What a queue lists, for a helper that reads a member only one kind has: Queued
# is their shared base and declares no name, title, path or claim. Union, not
# `|`, which a module-level line evaluates and Python 3.9 cannot: uv run
# --no-project takes whichever interpreter it finds, in other repos too.
Listed = Union[Brief, Issue]


@dataclass
class OffBoard:
    """An open issue the repo's board holds no item for: named, and no queue work."""
    number: int
    title: str
    url: str


@dataclass
class Board:
    """The linked project a repo's queue issues sit on."""
    number: int
    title: str
    url: str


class BoardError(Exception):
    """Why an account's boards went unread, said once, its repos reading files alone."""


def needs_group(needs: list[str]) -> str:
    """The group a list of needs puts work in, as frontmatter's needs does."""
    if "user" in needs:
        return "needs you"
    return "needs something else" if needs else "ready"


@dataclass
class RepoReport:
    repo: pathlib.Path
    name: str = ""  # the main checkout's directory, which keys the inbox
    rows: list[Row] = field(default_factory=list)
    briefs: list[pathlib.Path] = field(default_factory=list)
    stated: list[Brief] = field(default_factory=list)
    worktrees: dict[str, str] = field(default_factory=dict)  # name -> how it holds
    touched: dict[str, str] = field(default_factory=dict)
    notes: list[pathlib.Path] = field(default_factory=list)
    inbox: pathlib.Path | None = None  # the folder the notes were read from
    board: Board | None = None
    board_note: str = ""
    issues: list[Issue] = field(default_factory=list)
    off_board: list[OffBoard] = field(default_factory=list)

    def unread_board(self, note: str) -> None:
        """Drop everything a board read set, so a repo read before a failure keeps none of it.

        That is the board, its issues, those off the board, and each brief's open-issue
        list, so a blocked-by issue number blocks again instead of reading as closed.

        Args:
            note: Why the board went unread, printed in its place.
        """
        self.board, self.issues, self.off_board = None, [], []
        self.board_note = note
        for brief in self.stated:
            brief.open_issues = None

    @property
    def stated_paths(self) -> set[pathlib.Path]:
        return {brief.path for brief in self.stated}

    @property
    def unindexed(self) -> list[pathlib.Path]:
        linked = {row.target for row in self.rows} | self.stated_paths
        return [b for b in self.briefs if b not in linked]

    @property
    def problems(self) -> list[tuple[Brief, str, str]]:
        return [(b, kind, text) for b in self.stated for kind, text in b.problems]

    @property
    def dangling(self) -> list[Row]:
        return [row for row in self.rows if not row.target.exists()]

    @property
    def empty(self) -> bool:
        """Whether the repo holds no handoff work, which the summary's count reads."""
        return not (self.rows or self.briefs or self.notes or self.issues or self.off_board
                    or self.board_note)

    @property
    def shown(self) -> bool:
        """Whether the view lists the repo: any work, or a board read with nothing on it yet.

        A second predicate, not a widened `empty`, so a new board's repo is listed
        without the summary calling it one with handoff work.
        """
        return not self.empty or self.board is not None


def find_repos(roots: list[pathlib.Path]) -> list[pathlib.Path]:
    """Return each root that is a repo, else repos up to two levels below it.

    Two levels because repos often sit under a grouping directory
    (<root>/<group>/<repo>), where a sweep one level deep would find
    none of them from the root.
    """
    found: list[pathlib.Path] = []
    for root in roots:
        root = root.resolve()
        if not root.is_dir():
            print(f"not a directory, skipped: {root}", file=sys.stderr)
            continue
        if (root / ".git").exists():
            found.append(root)
            continue
        for child in sorted(root.iterdir()):
            if not child.is_dir() or child.name.startswith("."):
                continue
            if (child / ".git").exists():
                found.append(child)
                continue
            found += sorted(g for g in child.iterdir()
                            if g.is_dir() and (g / ".git").exists())
    return found


def is_reference(path: pathlib.Path, tree: pathlib.Path) -> bool:
    return bool(REFERENCE_DIRS & set(path.relative_to(tree).parts[:-1]))


def is_ledger(path: pathlib.Path, tree: pathlib.Path) -> bool:
    return path.parent == tree and path.name.lower() in LEDGERS


def is_brief(path: pathlib.Path, tree: pathlib.Path) -> bool:
    return (path.suffix == ".md" and path.name.lower() not in NOT_BRIEFS
            and not is_reference(path, tree) and not is_ledger(path, tree))


def yaml_misread(value: str) -> str:
    """What makes a plain YAML scalar misread a value, or "" when nothing does.

    The finding says which case it met: one message once served all four and
    blamed the opening, so a colon mid-value sent the reader to a fine start.
    """
    if value.startswith("- "):
        return "it opens with '- '"
    if value.startswith(YAML_INDICATORS):
        return f"it opens with {value[0]!r}"
    if ": " in value:
        return "it holds ': '"
    if " #" in value:
        return "it holds ' #'"
    return ""


def read_frontmatter(path: pathlib.Path) -> Brief | None:
    """Parse a brief's frontmatter, or return None when it has none."""
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    if not lines or lines[0].rstrip() != "---":
        return None
    brief = Brief(path, {})
    end = next((i for i in range(1, len(lines)) if lines[i].rstrip() == "---"), None)
    if end is None:
        brief.problems.append(("frontmatter", "opens with --- and never closes"))
        return brief
    for number, line in enumerate(lines[1:end], start=2):
        if not line.strip():
            continue
        match = FM_LINE.match(line)
        if not match:
            brief.problems.append(("frontmatter", f"line {number} is not `key: value`"))
            continue
        key, raw = match.groups()
        if key not in FM_KEYS:
            brief.problems.append(("frontmatter", f"unknown key `{key}`"))
        elif key in brief.meta:
            brief.problems.append(("frontmatter", f"`{key}` is given twice"))
        elif key in FM_LISTS:
            if not (raw.startswith("[") and raw.endswith("]")):
                brief.problems.append(("frontmatter", f"`{key}` is not a list, [a, b]"))
                continue
            items = [item.strip() for item in raw[1:-1].split(",") if item.strip()]
            for item in items:
                if why := yaml_misread(item):
                    brief.problems.append(
                        ("frontmatter",
                         f"`{key}` item {item!r} would not parse as plain YAML: {why}"))
            brief.meta[key] = items
        else:
            if why := yaml_misread(raw):
                brief.problems.append(
                    ("frontmatter", f"`{key}` would not parse as plain YAML: {why}"))
            brief.meta[key] = raw
    validate(brief)
    return brief


def validate(brief: Brief) -> None:
    status = brief.get("status")
    if status not in STATUSES:
        brief.problems.append(("frontmatter", f"status is {status or 'missing'}; "
                                              "want open or deferred"))
    if brief.get("priority") not in PRIORITIES:
        brief.problems.append(("frontmatter", f"priority is {brief.get('priority') or 'missing'}; "
                                              "want 1, 2 or 3"))
    try:
        dt.date.fromisoformat(brief.get("written"))
    except ValueError:
        brief.problems.append(("frontmatter", "written is not a YYYY-MM-DD date"))
    if status == "deferred" and not brief.get("reopen-when"):
        brief.problems.append(("frontmatter", "a deferred brief needs reopen-when"))
    for key, allowed in (("work-model", WORK_MODELS), ("work-effort", WORK_EFFORTS)):
        if key in brief.meta and brief.get(key) not in allowed:
            brief.problems.append(("frontmatter", f"{key} is {brief.get(key) or 'empty'}; "
                                                  f"want {', '.join(allowed)}"))
    for name in brief.items("platform"):
        if not PLATFORM.fullmatch(name):
            brief.problems.append(("frontmatter", f"platform {name} is not lowercase kebab, "
                                                  "as power-bi"))
    if "parent" in brief.meta and not ISSUE_NUMBER.fullmatch(brief.get("parent")):
        brief.problems.append(("frontmatter", f"parent is {brief.get('parent') or 'empty'}; "
                                              "want an issue's number, bare"))
    for name in brief.items("blocked-by"):
        if not ISSUE_NUMBER.fullmatch(name) and not (brief.path.parent / name).is_file():
            brief.problems.append(("blocker", f"blocked-by names {name}, which does not exist"))


@dataclass
class Worktree:
    """One entry of `git worktree list --porcelain`."""
    name: str
    head: str = ""
    branch: str = ""  # refs/heads/<name>; empty when detached
    lock: str | None = None  # the lock's reason, "" when it gives none


def git_lines(repo: pathlib.Path, *args: str) -> list[str]:
    result = subprocess.run(
        ["git", "-C", str(repo), *args],
        capture_output=True, text=True, encoding="utf-8", errors="replace")
    return result.stdout.splitlines()


def read_worktrees(repo: pathlib.Path) -> list[Worktree]:
    """Every worktree of the repo, the main checkout first."""
    trees: list[Worktree] = []
    for line in git_lines(repo, "worktree", "list", "--porcelain"):
        key, _, value = line.partition(" ")
        if key == "worktree":
            trees.append(Worktree(pathlib.PurePath(value).name))
        elif trees and key == "HEAD":
            trees[-1].head = value
        elif trees and key == "branch":
            trees[-1].branch = value
        elif trees and key == "locked":
            trees[-1].lock = value
    return trees


def main_checkout(repo: pathlib.Path) -> pathlib.Path:
    """The repo's main checkout: the repo itself, unless it is a linked worktree.

    Only a worktree's .git is a file, and only then is git asked, since a
    spawn costs ~0.4 s here.
    """
    if not (repo / ".git").is_file():
        return repo
    for line in git_lines(repo, "worktree", "list", "--porcelain"):
        key, _, value = line.partition(" ")
        if key == "worktree":
            return pathlib.Path(value)
    return repo


def repo_name(repo: pathlib.Path) -> str:
    """The name the inbox keys a repo on: its main checkout's directory.

    A linked worktree's own directory is named for the worktree, so from one
    the sweep once read the repo's notes as an orphan directory and counted
    none (2026-09-30).
    """
    return main_checkout(repo).name


def pid_alive(pid: int) -> bool:
    """Whether a process is running, asked without signalling it.

    Never os.kill(pid, 0) on Windows, where every signal but the two console
    events is TerminateProcess: the probe would end the session it asks about.
    """
    if sys.platform != "win32":
        try:
            os.kill(pid, 0)
        except ProcessLookupError:
            return False
        except PermissionError:
            return True
        return True
    from ctypes import wintypes
    if pid > 0xFFFFFFFF:
        return False
    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel32.OpenProcess.argtypes = (wintypes.DWORD, wintypes.BOOL, wintypes.DWORD)
    kernel32.OpenProcess.restype = wintypes.HANDLE
    kernel32.GetExitCodeProcess.argtypes = (wintypes.HANDLE, ctypes.POINTER(wintypes.DWORD))
    kernel32.CloseHandle.argtypes = (wintypes.HANDLE,)
    handle = kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pid)
    if not handle:
        # Another account's process refuses the query, and exists all the same.
        return ctypes.get_last_error() == ERROR_ACCESS_DENIED
    try:
        code = wintypes.DWORD()
        return (bool(kernel32.GetExitCodeProcess(handle, ctypes.byref(code)))
                and code.value == STILL_ACTIVE)
    finally:
        kernel32.CloseHandle(handle)


def worktree_claims(repo: pathlib.Path, stems: set[str]) -> dict[str, str]:
    """How each worktree named after a brief holds it: held, merged or parked.

    Ancestry alone cannot say merged: a branch that never committed is an
    ancestor of the main checkout's HEAD too. So its oldest reflog entry, the
    commit it was created at, must also differ from its tip, and a branch
    whose reflog is gone reads parked. Two spawns for every unheld claim
    together, none for a held one.
    """
    trees = read_worktrees(repo)
    if not trees:
        return {}
    main, claims = trees[0], [t for t in trees[1:] if t.name in stems]
    states: dict[str, str] = {}
    unheld: list[Worktree] = []
    for tree in claims:
        pid = LOCK_PID.search(tree.lock or "")
        if tree.lock is not None and (not pid or pid_alive(int(pid.group(1)))):
            states[tree.name] = "held"
        else:
            unheld.append(tree)
    refs = [t.branch for t in unheld if t.branch]
    landed: set[str] = set()
    if refs:
        merged = set(git_lines(repo, "branch", "--merged", main.head, "--format=%(refname)"))
        created: dict[str, tuple[int, str]] = {}
        for line in git_lines(repo, "log", "-g", "--format=%gD %H", *refs):
            selector, _, sha = line.partition(" ")
            ref, _, index = selector.rpartition("@{")
            if not index.rstrip("}").isdigit():
                continue  # a date-form selector: no creation point, so parked
            number = int(index.rstrip("}"))
            if number >= created.get(ref, (-1, ""))[0]:
                created[ref] = (number, sha)
        landed = {t.branch for t in unheld if t.branch in merged
                  and t.branch in created and created[t.branch][1] != t.head}
    for tree in unheld:
        state = "merged" if tree.branch in landed else "parked"
        states[tree.name] = state + (", lock stale" if tree.lock is not None else "")
    return states


def read_rows(index: pathlib.Path, tree: pathlib.Path) -> list[Row]:
    rows: list[Row] = []
    heading = ""
    text = index.read_text(encoding="utf-8", errors="replace")
    for line in text.splitlines():
        if match := HEADING.match(line):
            heading = match.group(1).strip()
            continue
        match = ROW_LINK.match(line)
        if not match:
            continue
        target = (index.parent / match.group(1)).resolve()
        if not target.is_relative_to(tree) or not is_brief(target, tree):
            continue
        bold = BOLD.search(line[match.end():])
        state = bold.group(1) if bold else heading or "(no state)"
        rows.append(Row(index, target, state.strip().rstrip(".:;,")))
    return rows


def last_touched(repo: pathlib.Path) -> dict[str, str]:
    """Map each path under docs/handoffs to the date of its latest commit."""
    result = subprocess.run(
        ["git", "-C", str(repo), "log", "--format=%x00%cs", "--name-only",
         "--", str(HANDOFFS)],
        capture_output=True, text=True, encoding="utf-8", errors="replace")
    touched: dict[str, str] = {}
    date = ""
    for line in result.stdout.splitlines():
        if line.startswith("\x00"):
            date = line[1:]
        elif line.strip():
            touched.setdefault(line.strip(), date)
    return touched


def scan(repo: pathlib.Path, inbox_root: pathlib.Path | None) -> RepoReport:
    report = RepoReport(repo, repo_name(repo))
    tree = (repo / HANDOFFS).resolve()
    if tree.is_dir():
        for path in sorted(tree.rglob("*.md")):
            if path.name.lower() == "readme.md" and not is_reference(path, tree):
                report.rows += read_rows(path, tree)
            elif is_brief(path, tree):
                report.briefs.append(path)
                if (brief := read_frontmatter(path)) is not None:
                    report.stated.append(brief)
        if report.briefs or report.rows:
            report.touched = last_touched(repo)
        if report.stated:
            report.worktrees = worktree_claims(repo, {b.path.stem for b in report.stated})
    inbox = inbox_root / report.name if inbox_root else None
    report.inbox = inbox
    if inbox and inbox.is_dir():
        report.notes = sorted(n for n in inbox.iterdir()
                              if n.is_file() and n.name.lower() != "readme.md")
    return report


def github_remote(repo: pathlib.Path) -> tuple[str, str] | None:
    """The repo's `owner/name` on GitHub and its git user.name, or None off GitHub.

    One spawn for both: user.name comes from the includeIf for the repo's
    root, which only git resolves, and the last value given wins, as in git.
    """
    values: dict[str, str] = {}
    for line in git_lines(repo, "config", "--get-regexp", r"^(remote\.origin\.url|user\.name)$"):
        key, _, value = line.partition(" ")
        values[key] = value
    match = GITHUB_REMOTE.search(values.get("remote.origin.url", ""))
    if not match:
        return None
    return f"{match.group(1)}/{match.group(2)}", values.get("user.name", "")


def first_line(raw: bytes) -> str:
    return next(iter(raw.decode("utf-8", "replace").strip().splitlines()), "")


def gh_token(account: str) -> str:
    """The keyring's token for an account, so gh answers as it and not the active one."""
    if not account:
        raise BoardError("no git user.name to pick a gh account by")
    # A token already in the environment would answer for every account.
    env = {k: v for k, v in os.environ.items() if k not in ("GH_TOKEN", "GITHUB_TOKEN")}
    try:
        result = subprocess.run(["gh", "auth", "token", "--user", account],
                                capture_output=True, timeout=GH_TIMEOUT, env=env)
    except FileNotFoundError:
        raise BoardError("gh is not on PATH") from None
    except OSError as error:  # a refused start: Defender's ASR, or no executable
        raise BoardError(f"gh could not run: {error}") from None
    except subprocess.TimeoutExpired:
        raise BoardError(f"gh auth token gave no answer in {GH_TIMEOUT} s") from None
    token = result.stdout.decode("utf-8", "replace").strip()
    if result.returncode or not token:
        raise BoardError(first_line(result.stderr) or f"no gh account {account} in the keyring")
    return token


def ask_github(token: str, parts: dict[str, str]) -> dict[str, dict | str]:
    """Run one query of aliased parts as the token's account.

    Returns each alias's repository node, or the error standing in for it.
    The query goes on stdin: argv is one Windows command line, and visible.
    """
    query = "query {" + "".join(parts.values()) + "\n}"
    try:
        result = subprocess.run(["gh", "api", "graphql", "-F", "query=@-"],
                                input=query.encode("utf-8"), capture_output=True,
                                timeout=GH_TIMEOUT, env={**os.environ, "GH_TOKEN": token})
    except FileNotFoundError:
        raise BoardError("gh is not on PATH") from None
    except OSError as error:
        raise BoardError(f"gh could not run: {error}") from None
    except subprocess.TimeoutExpired:
        raise BoardError(f"GitHub gave no answer in {GH_TIMEOUT} s") from None
    try:
        answer = json.loads(result.stdout.decode("utf-8", "replace") or "null")
    except json.JSONDecodeError:
        answer = None
    if not isinstance(answer, dict):
        raise BoardError(first_line(result.stderr) or f"gh api exited {result.returncode}")
    # gh exits 1 on any error, yet the other aliases' data still stands.
    data = answer.get("data") or {}
    errors: dict[str | None, str] = {}
    for error in answer.get("errors") or []:
        # The scope error runs to four sentences and a URL; its point is one scope.
        message = ("its gh token lacks the read:project scope"
                   if error.get("type") == "INSUFFICIENT_SCOPES"
                   else error.get("message", "an error"))
        errors.setdefault((error.get("path") or [None])[0], message)
    if not data and errors:
        raise BoardError(next(iter(errors.values())))
    return {alias: data.get(alias) or errors.get(alias) or "GitHub returned nothing"
            for alias in parts}


def fetch(keys: list[str], template: Template, token: str, answer: dict | None,
          cursors: dict[str, str] | None = None) -> dict[str, dict | str]:
    """Each `owner/name`'s repository node, or the error standing in for it.

    REPOS_PER_QUERY repos to a query: ISSUES asks for ~26,000 nodes a repo,
    and GitHub refuses a query past 500,000. A repo in cursors is asked for
    the page after its cursor.
    """
    cursors = cursors or {}
    if answer is not None:
        return {key: answer.get(f"{key}@{cursors[key]}" if key in cursors else key,
                                "no answer for it in --board-answer") for key in keys}
    nodes: dict[str, dict | str] = {}
    for start in range(0, len(keys), REPOS_PER_QUERY):
        parts, aliases = {}, {}
        for number, key in enumerate(keys[start:start + REPOS_PER_QUERY]):
            owner, name = key.split("/", 1)
            aliases[f"r{number}"] = key
            parts[f"r{number}"] = template.substitute(
                alias=f"r{number}", owner=json.dumps(owner), name=json.dumps(name),
                page=ISSUE_PAGE, after=json.dumps(cursors.get(key)))
        nodes |= {aliases[alias]: node for alias, node in ask_github(token, parts).items()}
    return nodes


def carries_contract(project: dict) -> bool:
    """Whether a linked project is a queue board: open, not the template, the contract's fields."""
    return board_candidate(project) and not contract_gaps(project)


def board_candidate(project: dict) -> bool:
    """Whether a linked project may be the board at all: open, and not the template."""
    return not project.get("closed") and project.get("title") != BOARD_TEMPLATE


def contract_gaps(project: dict) -> set[str]:
    """The contract's fields a project lacks, or offers short of an option."""
    listed = {f["name"]: f for f in project["fields"]["nodes"] if f and f.get("name")}
    fields = {name: {o["name"] for o in f.get("options") or []} for name, f in listed.items()}

    def priority_stands_in(name: str) -> bool:
        return name == "Priority" and (issue_backed(listed[name])
                                       or set(PRIORITY_NAMES) <= fields[name])

    return {name for name, options in CONTRACT.items()
            if name not in fields
            or not (options is None or options <= fields[name] or priority_stands_in(name))}


def short_of_priority(project: dict) -> bool:
    """Whether Priority alone keeps a project from being the board: worth saying, not silence."""
    return board_candidate(project) and contract_gaps(project) == {"Priority"}


def issue_backed(field: dict) -> bool:
    """Whether a board's field is an issue field: `options` empty, a key a text field lacks."""
    return field.get("options") == []


def card_values(nodes: list[dict | None]) -> dict[str, str]:
    """A card's values by field name, an issue field's Priority as its P level."""
    values: dict[str, str] = {}
    for value in nodes:
        value = value or {}
        if name := (value.get("field") or {}).get("name"):
            values[name] = (value.get("name") or value.get("text")
                            or (value.get("issueFieldValue") or {}).get("name") or "")
    if "Priority" in values:
        values["Priority"] = PRIORITY_READ.get(values["Priority"], values["Priority"])
    return values


def local_date(stamp: str) -> str:
    """A GitHub timestamp, in UTC, as the local date, where a day's last hours fall."""
    try:
        return dt.datetime.fromisoformat(stamp.replace("Z", "+00:00")).astimezone().date().isoformat()
    except ValueError:
        return stamp[:10]


def board_issue(node: dict, board_id: str, repo: pathlib.Path,
                key: str) -> Issue | OffBoard | None:
    """An open issue as the queue holds it, as one the board lacks, or None.

    Mirroring a brief file that exists, it defers to the file, which the view
    already lists, on the board or off it: that is the None.
    """
    if (match := MIRROR.match(node.get("body") or "")) and (repo / match.group(1)).is_file():
        return None
    item = next((i for i in node["projectItems"]["nodes"]
                 if i and i["project"]["id"] == board_id), None)
    if item is None:
        return OffBoard(number=node["number"], title=node["title"], url=node["url"])
    values = card_values(item["fieldValues"]["nodes"])
    status = values.get("Status", "")
    blockers = []
    for blocker in node["blockedBy"]["nodes"]:
        if not blocker or blocker["state"] != "OPEN":
            continue
        where = blocker["repository"]["nameWithOwner"]
        prefix = "" if where.lower() == key.lower() else where
        blockers.append(f"{prefix}#{blocker['number']}")
    parent = node.get("parent") or {}
    if parent:
        where = parent["repository"]["nameWithOwner"]
        parent_ref = ("" if where.lower() == key.lower() else where) + f"#{parent['number']}"
    else:
        parent_ref = ""
    subs = node.get("subIssuesSummary") or {}
    return Issue(
        number=node["number"], title=node["title"], url=node["url"],
        meta={"status": "deferred" if status == "Deferred" else "open",
              "priority": values.get("Priority", "").removeprefix("P"),
              "needs": [label["name"][len(NEEDS_LABEL):] for label in node["labels"]["nodes"]
                        if label["name"].startswith(NEEDS_LABEL)],
              "reopen-when": values.get("Reopen-when", ""),
              "written": local_date(node["createdAt"]),
              "work-model": values.get("Work model", ""),
              "work-effort": values.get("Work effort", "")},
        blocked_by=blockers, touched=local_date(node["updatedAt"]), board_status=status,
        assignees=[a["login"] for a in node["assignees"]["nodes"] if a],
        parent_ref=parent_ref, parent_url=parent.get("url", ""),
        sub_total=subs.get("total") or 0, sub_completed=subs.get("completed") or 0)


def read_account(members: list[tuple[RepoReport, str]], token: str,
                 answer: dict | None) -> None:
    """Read the boards of every repo one account holds: projects first, then issues.

    Two checkouts of one remote are asked about once, and each gets the answer.
    """
    projects = fetch(list(dict.fromkeys(key for _, key in members)), PROJECTS, token, answer)
    boards: dict[str, tuple[dict, list[RepoReport]]] = {}
    for report, key in members:
        node = projects[key]
        if isinstance(node, str):
            report.board_note = f"not read: {node}"
            continue
        linked = [p for p in node["projectsV2"]["nodes"] if p]
        found = [p for p in linked if carries_contract(p)]
        short = [str(p["number"]) for p in linked if short_of_priority(p)]
        if len(found) > 1:
            numbers = ", ".join(str(p["number"]) for p in found)
            report.board_note = f"not read: projects {numbers} each carry the contract"
        elif found:
            boards.setdefault(key, (found[0], []))[1].append(report)
        elif short:
            report.board_note = (f"not read: project {', '.join(short)} has no Priority offering "
                                 "P1 to P3 or High, Medium and Low")
    if not boards:
        return
    # Page by page, every repo still paging asked in one query, so a sub-issue
    # older than the newest 100 is still read beside its parent.
    listed: dict[str, list[dict]] = {key: [] for key in boards}
    failed: dict[str, str] = {}
    cursors: dict[str, str] = {}
    pending = list(boards)
    for _ in range(ISSUE_PAGES):
        pages = fetch(pending, ISSUES, token, answer, cursors)
        pending = []
        for key, node in pages.items():
            if isinstance(node, str):
                failed[key] = node
                continue
            connection = node["issues"]
            listed[key] += [n for n in connection["nodes"] if n]
            if connection["pageInfo"]["hasNextPage"]:
                cursors[key] = connection["pageInfo"].get("endCursor")
                pending.append(key)
        if not pending:
            break
    for key, (project, reports) in boards.items():
        for report in reports:
            report.board = Board(project["number"], project["title"], project["url"])
            if key in failed and not listed[key]:
                report.board_note = f"issues not read: {failed[key]}"
                continue
            read = [board_issue(n, project["id"], report.repo, key) for n in listed[key]]
            report.issues = [issue for issue in read if isinstance(issue, Issue)]
            report.off_board = [issue for issue in read if isinstance(issue, OffBoard)]
            if key in failed:
                report.board_note = (f"open issues past the newest {len(listed[key])} "
                                     f"not read: {failed[key]}")
            elif key in pending:
                report.board_note = (f"the newest {len(listed[key])} open issues read, of more: "
                                     "an older one on the board is not listed")
            else:
                # Read whole, the list says which issue a brief's blocked-by names is open.
                numbers = {n["number"] for n in listed[key]}
                for brief in report.stated:
                    brief.open_issues = numbers


def read_boards(reports: list[RepoReport], answer: dict | None) -> None:
    """Join each repo's open board issues to its report, as its briefs are joined.

    The spawns run side by side, as each would cost ~0.4 s in turn here.
    """
    with ThreadPoolExecutor(max_workers=REMOTE_WORKERS) as pool:
        remotes = list(pool.map(lambda r: github_remote(r.repo), reports))
    accounts: dict[str, list[tuple[RepoReport, str]]] = {}
    for report, remote in zip(reports, remotes):
        if remote:
            accounts.setdefault(remote[1], []).append((report, remote[0]))

    def read(account: str, members: list[tuple[RepoReport, str]]) -> None:
        try:
            read_account(members, "" if answer is not None else gh_token(account), answer)
        except (BoardError, KeyError, TypeError) as error:
            why = (error if isinstance(error, BoardError)
                   else f"an answer shaped unlike the query ({error!r})")
            # A repo read before the failure would print a board and its refusal both.
            for report, _ in members:
                report.unread_board(f"not read: {why}")
            print(f"note: no board read as {account or 'no account'}: {why}", file=sys.stderr)

    with ThreadPoolExecutor(max_workers=ACCOUNT_WORKERS) as pool:
        list(pool.map(lambda item: read(*item), accounts.items()))


def age_days(note: pathlib.Path, today: dt.date) -> int | None:
    """Days since the date a note's name opens with, or None when it has none."""
    match = NOTE_DATE.match(note.name)
    if not match:
        return None
    try:
        return (today - dt.date.fromisoformat(match.group(1))).days
    except ValueError:
        return None


def age(note: pathlib.Path, today: dt.date) -> str:
    days = age_days(note, today)
    return "undated" if days is None else f"{days}d"


def shorten(text: str, width: int = STATE_WIDTH) -> str:
    return text if len(text) <= width else text[:width - 3] + "..."


def work(brief: Queued) -> str:
    """The model and effort a brief's writer recommends working it at."""
    model, effort = brief.get("work-model"), brief.get("work-effort")
    text = " ".join(part for part in (model and f"on {model}", effort and f"at {effort}")
                    if part)
    return f"  {text}" if text else ""


def detail(item: Listed, report: RepoReport, nested: bool = False) -> str:
    """What a brief or issue is waiting on, and whether a worktree or the board claims it."""
    parts = []
    if claim := item.claim(report):
        parts.append(f"in flight ({claim})")
    if isinstance(item, Issue) and item.board_status == "Done":
        parts.append("Done on the board, yet open")
    if item.parent and not nested:
        parts.append(f"sub-issue of {item.parent}")
    if item.group in ("needs you", "needs something else"):
        parts.append("needs " + ", ".join(item.items("needs")))
    elif item.group == "blocked":
        if item.blockers:
            parts.append("blocked by " + ", ".join(item.blockers))
        if isinstance(item, Issue) and item.open_subs:
            parts.append(f"{item.open_subs} of {item.sub_total} sub-issues open")
    elif item.group == "deferred":
        if trigger := item.get("reopen-when").strip():
            parts.append("reopen when " + shorten(trigger, 64))
        elif isinstance(item, Issue):
            # A card dragged to Deferred keeps a blank field, and no finding
            # covers a board, so the line says it (2026-10-29).
            parts.append(f"no reopen-when: update-issue {item.number} defer")
        else:
            parts.append("no reopen-when")
    if isinstance(item, Issue) and item.ready_to_close:
        parts.append(f"all {item.sub_total} sub-issues closed: close it")
    return "".join(f"  {part}" for part in parts)


def print_groups(items: Sequence[Listed], report: RepoReport,
                 when: Callable[[Listed], str]) -> None:
    """A queue's briefs or issues under their group headings, by priority then age.

    A sub-issue prints under its parent where both are listed, indented a
    step, its own group said by its detail, whatever group the parent is in.
    """
    urls = {i.url for i in items if isinstance(i, Issue)}
    children: dict[str, list[Listed]] = {}
    top: list[Listed] = []
    for item in items:
        if isinstance(item, Issue) and item.parent_url in urls and item.parent_url != item.url:
            children.setdefault(item.parent_url, []).append(item)
        else:
            top.append(item)

    def line(item: Listed, depth: int) -> None:
        width = STATE_WIDTH - 2 * depth
        # A filename is an address, so only an issue's title is cut.
        label = (item.name if isinstance(item, Brief)
                 else shorten(f"{item.name} {item.title}", width))
        print(f"      {'  ' * depth}P{item.get('priority') or '?'}  {label:<{width}}  "
              f"written {item.get('written') or '?':<10}  "
              f"touched {when(item)}{work(item)}{detail(item, report, depth > 0)}")
        if isinstance(item, Issue):
            for child in sorted(children.get(item.url, []),
                                key=lambda i: (GROUPS.index(i.group), i.sort_key)):
                line(child, depth + 1)

    for group in GROUPS:
        members = sorted((i for i in top if i.group == group), key=lambda i: i.sort_key)
        for heading, listed in by_need(group, members):
            print(f"    {heading}")
            for item in listed:
                line(item, 0)


def by_need(group: str, members: list[Listed]) -> list[tuple[str, list[Listed]]]:
    """Each heading a group's briefs print under, in order, with its briefs.

    Every need but the user's heads a group of its own, named for it, so the
    briefs one sitting can clear print together: under one heading for them
    all, four Desktop briefs printed with a tenant one between them
    (2026-10-15).
    """
    if group != "needs something else":
        return [(group, members)] if members else []
    split: dict[str, list[Listed]] = {}
    for brief in members:
        split.setdefault("needs " + ", ".join(brief.items("needs")), []).append(brief)
    return sorted(split.items(), key=lambda item: item[0])


def print_report(report: RepoReport, today: dt.date) -> None:
    repo = report.repo
    stated = report.stated_paths

    def rel(path: pathlib.Path) -> str:
        return path.relative_to(repo).as_posix()

    def touched(path: pathlib.Path) -> str:
        return report.touched.get(rel(path), "uncommitted")

    def when(item: Listed) -> str:
        return item.touched if isinstance(item, Issue) else touched(item.path)

    print(f"== {report.name} ==  {repo.as_posix()}")
    for index in dict.fromkeys(row.index for row in report.rows):
        listed = [r for r in report.rows
                  if r.index == index and r.target.exists() and r.target not in stated]
        if not listed:
            continue
        print(f"  index: {rel(index)}")
        for row in listed:
            dated = "   (dated filename)" if DATED_NAME.match(row.target.name) else ""
            print(f"    {shorten(row.state):<{STATE_WIDTH}}  {touched(row.target)}  "
                  f"{row.target.name}{dated}")
    if any(b not in stated for b in report.briefs) and not report.rows:
        print("  index: none")
    for directory in dict.fromkeys(b.path.parent for b in report.stated):
        print(f"  queue: {rel(directory)}/  (each brief's own frontmatter)")
        print_groups([b for b in report.stated if b.path.parent == directory], report, when)
    if report.board:
        print(f"  board: {report.board.title}, project {report.board.number}  "
              f"(each open issue's fields)")
        print_groups(report.issues, report, when)
    for issue in report.off_board:
        label = shorten(f"#{issue.number} {issue.title}")
        print(f"  off board: {label}")
    if report.board_note:
        print(f"  board: {report.board_note}")
    for row in report.dangling:
        print(f"  ! dangling   {rel(row.index)} links {row.target.name}, "
              f"which does not exist")
    for brief in report.unindexed:
        print(f"  ! unindexed  {rel(brief)}   touched {touched(brief)}")
    for brief, kind, text in report.problems:
        print(f"  ! {kind:<11} {rel(brief.path)}: {text}")
    if report.notes and report.inbox:
        print(f"  inbox: {len(report.notes)} note(s) in {display_path(report.inbox)}/")
        for note in report.notes:
            print(f"    {age(note, today):>8}  {note.name}")
    print()


def report_json(report: RepoReport, today: dt.date) -> dict:
    """One repo's view as plain data: what print_report prints, unformatted."""
    repo = report.repo
    stated = report.stated_paths

    def rel(path: pathlib.Path) -> str:
        return path.relative_to(repo).as_posix()

    def touched(path: pathlib.Path) -> str:
        return report.touched.get(rel(path), "uncommitted")

    def entry(item: Listed) -> dict:
        issue = isinstance(item, Issue)
        data = {
            "path": item.name if issue else rel(item.path),
            "group": item.group,
            "status": item.get("status"),
            "priority": item.get("priority"),
            "needs": item.items("needs"),
            "blocked_by": item.blockers,
            "reopen_when": item.get("reopen-when") or None,
            "written": item.get("written"),
            "touched": item.touched if issue else touched(item.path),
            "work_model": item.get("work-model") or None,
            "work_effort": item.get("work-effort") or None,
            "in_flight": item.claim(report),
            "parent": item.parent or None,
        }
        if issue:
            data.update(title=item.title, url=item.url, assignees=item.assignees,
                        board_status=item.board_status or None,
                        sub_issues=({"total": item.sub_total, "completed": item.sub_completed}
                                    if item.sub_total else None),
                        ready_to_close=item.ready_to_close)
        return data

    queued = sorted([*report.stated, *report.issues],
                    key=lambda i: (GROUPS.index(i.group), i.source, i.sort_key))
    board = None
    if report.board or report.board_note:
        board = {"number": report.board and report.board.number,
                 "title": report.board and report.board.title,
                 "url": report.board and report.board.url,
                 "note": report.board_note or None}
    rows = [r for r in report.rows if r.target.exists() and r.target not in stated]
    findings = [{"kind": "dangling", "path": rel(row.index),
                 "text": f"links {row.target.name}, which does not exist"}
                for row in report.dangling]
    findings += [{"kind": "unindexed", "path": rel(brief),
                  "text": "no frontmatter, and no index row links it"}
                 for brief in report.unindexed]
    findings += [{"kind": kind, "path": rel(brief.path), "text": text}
                 for brief, kind, text in report.problems]
    split = {heading: len(members)
             for heading, members in by_need("needs something else",
                                             [i for i in queued
                                              if i.group == "needs something else"])}
    counts = {
        "briefs": len(queued),
        "groups": {group: sum(1 for i in queued if i.group == group) for group in GROUPS},
        "needs": split,
        "in_flight": sum(1 for i in queued if i.claim(report)),
        "off_board": len(report.off_board),
        "notes": len(report.notes),
        "findings": len(findings),
    }
    return {
        "name": report.name,
        "path": repo.as_posix(),
        "board": board,
        "counts": counts,
        "briefs": [entry(item) for item in queued],
        "off_board": [{"path": f"#{issue.number}", "title": issue.title, "url": issue.url}
                      for issue in report.off_board],
        "rows": [{"index": rel(row.index), "path": rel(row.target), "state": row.state,
                  "touched": touched(row.target),
                  "dated_name": bool(DATED_NAME.match(row.target.name))} for row in rows],
        "notes": [{"name": note.name, "age_days": age_days(note, today)}
                  for note in report.notes],
        "findings": findings,
    }


def inbox_findings(names: set[str],
                   inbox: pathlib.Path) -> tuple[list[str], list[str]]:
    """Return (loose notes, orphan directories) in the inbox root."""
    if not inbox.is_dir():
        return [], []
    loose = sorted(p.name for p in inbox.iterdir()
                   if p.is_file() and p.name.lower() != "readme.md")
    orphans = sorted(p.name for p in inbox.iterdir()
                     if p.is_dir() and p.name not in names)
    return loose, orphans


def default_root() -> pathlib.Path | None:
    """Two above the working directory's main checkout, or None outside a repo.

    The working directory's, never this file's: inside a skill folder,
    two above this file is the skills directory, and the sweep found no
    repo there (2026-10-24). Two above a linked worktree is the main
    checkout's .claude/, where the sweep found only the worktrees, and read
    every other repo's inbox as an orphan (2026-10-17).
    """
    top = git_lines(pathlib.Path.cwd(), "rev-parse", "--show-toplevel")
    if not top:
        return None
    return main_checkout(pathlib.Path(top[0])).parents[1]


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Show open handoff briefs and inbox notes across every repo.")
    ap.add_argument("roots", nargs="*", type=pathlib.Path,
                    help="repos, or parents of repos (default: two levels above the "
                         "working directory's repo)")
    ap.add_argument("--inbox", type=pathlib.Path, default=INBOX,
                    help="inbox directory (default: handoff-inbox in the home "
                         "directory); for tests")
    ap.add_argument("--check", action="store_true",
                    help="exit 1 on any finding: unindexed, dangling, frontmatter, "
                         "blocker, loose or orphan")
    ap.add_argument("--no-inbox", action="store_true",
                    help="skip the inbox, its notes and its loose and orphan findings")
    ap.add_argument("--json", action="store_true",
                    help="print the view as one JSON document instead of the tables")
    ap.add_argument("--no-board", action="store_true",
                    help="read no GitHub board, only the files; --check never reads one")
    ap.add_argument("--board-answer", type=pathlib.Path,
                    help="read each repo's board from this JSON instead of GitHub; for tests")
    args = ap.parse_args()

    roots = args.roots
    if not roots:
        root = default_root()
        if root is None:
            print("error: the working directory is in no git repo; name the roots to sweep",
                  file=sys.stderr)
            return 2
        roots = [root]
    today = dt.date.today()
    repos = find_repos(roots)
    inbox = None if args.no_inbox else args.inbox
    reports = [scan(r, inbox) for r in repos]
    if not (args.check or args.no_board):
        answer = None
        if args.board_answer:
            answer = json.loads(args.board_answer.read_text(encoding="utf-8"))
        read_boards(reports, answer)
    names = {r.name for r in reports}
    loose, orphans = inbox_findings(names, inbox) if inbox else ([], [])
    findings = (sum(len(r.unindexed) + len(r.dangling) + len(r.problems) for r in reports)
                + len(loose) + len(orphans))

    if args.json:
        print(json.dumps({
            "swept": len(repos),
            "repos": [report_json(r, today) for r in reports if r.shown],
            "inbox": None if inbox is None else {"loose": loose, "orphans": orphans},
        }, indent=2, ensure_ascii=False))
        return 1 if args.check and findings else 0

    for report in reports:
        if report.shown:
            print_report(report, today)

    where = display_path(inbox) if inbox else ""
    for name in loose:
        print(f"! loose note in {where}/: {name} -- addressed to no repo")
    for name in orphans:
        print(f"! orphan inbox directory {where}/{name}/ -- "
              f"no repo of that name was swept")

    open_rows = sum(1 for r in reports for row in r.rows
                    if row.target.exists() and row.target not in r.stated_paths)
    stated = sum(len(r.stated) for r in reports)
    issues = sum(len(r.issues) for r in reports)
    off_board = sum(len(r.off_board) for r in reports)
    unindexed = sum(len(r.unindexed) for r in reports)
    dangling = sum(len(r.dangling) for r in reports)
    problems = sum(len(r.problems) for r in reports)
    notes = sum(len(r.notes) for r in reports)
    active = sum(not r.empty for r in reports)
    print(f"{len(repos)} repos swept, {active} with handoff work: "
          f"{open_rows} indexed brief(s), {stated} with frontmatter, {issues} board issue(s), "
          f"{off_board} off the board, {unindexed} unindexed, "
          f"{dangling} dangling row(s), {problems} frontmatter finding(s), "
          f"{notes} inbox note(s), {len(loose)} loose, {len(orphans)} orphan director(ies)")

    return 1 if args.check and findings else 0


if __name__ == "__main__":
    sys.exit(main())
