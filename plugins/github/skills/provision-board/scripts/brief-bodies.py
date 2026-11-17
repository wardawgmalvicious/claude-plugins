"""Turn a queue's handoff briefs into issue bodies and a manifest, then count denylisted terms.

Each brief in <repo-root>/docs/handoffs/execute/ with frontmatter becomes
<out-dir>/<stem>.md, its body less the heading, opening with a line that
names the file, every relative link made absolute against --blob. The
manifest, <out-dir>/manifest.json, holds one row per brief: the issue's
title, Status, Priority, needs, platform, Reopen-when, blocked-by, Work
model and Work effort, the body's file name, relative to <out-dir>, and the body's
opening, which file-issues.sh matches on GitHub to find an issue already
filed from the brief.

LINKS. `parent: <n>` names the issue a brief's issue is a sub-issue of,
and each `blocked-by` item is an issue number or a brief's filename; a
number is bare, as `#62` would open a YAML comment. A row carries the
parent as a number and each blocker as {"issue": <n>} or {"file":
<name>, "opening": <its issue's opening>}, so file-issues.sh can find a
blocker's issue as it finds a brief's: a brief in this manifest by its
row's opening, any other by the "Filed from" line its file's issue
opens with, the file sitting beside the brief, or in docs/handoffs/
execute/ for a brief with no file. A value that is neither, or a file
that is in neither place, is an error.

BRIEFS WITH NO FILE. --brief PATH, given once or more, takes only those
files, from wherever they are, as briefs no file in the repo will stand
for: triage-inbox drafts one in its scratchpad and files it here where
the repo has a board. Their relative links resolve as if each sat in
docs/handoffs/execute/. Each body then opens "Filed as `<stem>`
("<title>") with no brief file", which names no path, so the queue view
never reads it as a mirror, and that opening is still what file-issues.sh
matches: the title in it keeps a new subject that reuses an old stem from
matching the old one's issue, and having its card overwritten. A
--brief with no frontmatter, no heading or a status --status leaves out
is an error, since the queue's glob would skip it in silence. Two of one
name are a usage error, since the second body would overwrite the first
in <out-dir>.

A --brief that is a file under <repo-root>/docs/handoffs/ is the
exception: the file stays the source, as a skill brief in
docs/handoffs/skills/ does, so its body opens "Filed from [`<path>`]"
as a queue brief's does, and its links and blocked-by files resolve from
its own folder. The queue view then reads its issue as a mirror while
the file exists.

AN ISSUE THAT ALREADY EXISTS. A --brief with no file that names `issue:
<n>` stands for that issue, which file-issue's board verb puts on the
board. Its frontmatter sets the card, and its heading and body are the
issue's own title and body, wrapped only so they can be counted:
<out-dir>/<stem>.md is that body unchanged, with no opening line and no
link rewritten, and the row carries "issue": <n> and an empty opening, so
file-issues.sh files no body and matches no opening. A blocker naming such
a brief by filename is written {"issue": <n>}. A brief with a file that
names an issue is an error, since its file would be the source.

PHRASE LABELS. file-issues.sh makes a needs:<value> or platform:<value>
label of each value the repo lacks, with no prompt. needs:user is the one
label provision-board.sh makes with the board; every other needs value is
a phrase, and every platform value is named the same way, since no set of
platforms is fixed: a repo's platform:* labels are its list. A platform
value must be lowercase kebab, as power-bi, so a case or a space cannot
make a second spelling. On exit 0 each distinct value prints as one line,
    phrase label: needs:<value>, made where the repo lacks it
    phrase label: platform:<value>, made where the repo lacks it
so the user's yes to file covers the labels. Nothing here reads the
repo, so a value it already holds as a label prints too. On exit 1 none
prints, since a value may hold a term the count found.

The denylist count runs on exactly what would be filed, every title,
body, Reopen-when text and label value, so nothing reaches an issue or
its card unchecked. It parses
~/.config/identity-denylist.txt as identity-guard does: each line
right-trimmed, blanks and `#` lines dropped, terms matched case-blind as
fixed strings, a `word: <term>` one only where no ASCII letter or digit
borders it, and a <repo-root> under an exempt: prefix not counted at
all, since a client's own repo carries its name; so an exempt repo's
issues are not checked for another client's name either. It prints
a count per file and never a term, since the terms are the names the
denylist exists to keep out of view, nor an exempt root. With no
denylist, or one with no term, it exits 2, since filing unchecked is the
leak the count exists for; --allow-no-denylist instead counts nothing
and says so on a `denylist:` line, as it does for an exempt root, for a
caller that puts that line in the question asking to file.

Usage:
    brief-bodies.py <repo-root> <out-dir> --blob <url> [--status open,deferred] [--allow-no-denylist]
    brief-bodies.py <repo-root> <out-dir> --blob <url> --brief <path> [--brief <path> ...]

--blob is the URL a repo path is appended to, such as
https://github.com/<owner>/<repo>/blob/main/. --status picks the briefs
filed, both by default.

Exit 0 written and clean, exempt, or with no denylist under
--allow-no-denylist, 1 a denylisted term in a title or body, a
work-model or work-effort outside the board's options, a platform not
lowercase kebab, an issue, parent or
blocked-by that names no issue or brief, or a --brief that
cannot be filed as it stands, 2 a usage error or no denylist to check
against. The files are written in every case, and are filed only on
exit 0.
"""

import argparse
import json
import os
import posixpath
import re
import sys
from datetime import date
from pathlib import Path

BRIEF_DIR = "docs/handoffs/execute"
HANDOFFS = "docs/handoffs"
DENYLIST = Path.home() / ".config" / "identity-denylist.txt"
LINK = re.compile(r"\]\(([^)\s]+)\)")
STATUS = {"open": "Open", "deferred": "Deferred"}
# The Work model and Work effort options, as references/board-contract.md
# lists them; a value outside them fails here, before anything is filed.
WORK = {
    "work-model": ("haiku", "sonnet", "opus", "fable"),
    "work-effort": ("low", "medium", "high", "xhigh", "max"),
}
# A platform:* value's shape, as references/board-contract.md gives it; no
# set is fixed, so a value of another shape fails here, as a second
# spelling of one the repo has.
PLATFORM = re.compile(r"[a-z0-9]+(-[a-z0-9]+)*")
# The needs:* labels provision-board.sh makes on every board's repo, its
# NEEDS_LABELS; any other needs value is a phrase, named as a new label.
STANDARD_NEEDS = ("user",)
# An issue number, as parent and a blocked-by item take one: bare, since
# YAML reads `#62` after a space as a comment.
ISSUE_NUMBER = re.compile(r"[1-9][0-9]*")
# A frontmatter line opening `issue:`, however spelled.
ISSUE_LINE = re.compile(r"^\s*issue\s*:", re.MULTILINE | re.IGNORECASE)


def parse_list(value: str) -> list[str]:
    """Read a frontmatter list, `[a, b]`, into its items."""
    inner = value.strip().removeprefix("[").removesuffix("]")
    return [item.strip() for item in inner.split(",") if item.strip()]


def print_phrase_labels(rows: list[dict]) -> None:
    """Name each needs phrase and platform as the label file-issues.sh will make of it.

    Distinct values as its `unique` takes them, exact; a standard need in
    another case is no phrase, since its label match is case-blind.
    """
    phrases = sorted(
        {need for row in rows for need in row["needs"] if need.lower() not in STANDARD_NEEDS}
    )
    for phrase in phrases:
        print(f"phrase label: needs:{phrase}, made where the repo lacks it")
    for platform in sorted({name for row in rows for name in row["platform"]}):
        print(f"phrase label: platform:{platform}, made where the repo lacks it")


def absolutize(blob: str, base: str, match: re.Match) -> str:
    """Rewrite one relative Markdown link target, from the folder base, to an absolute URL."""
    target = match.group(1)
    if re.match(r"^(https?:|mailto:|#)", target):
        return match.group(0)
    path, _, anchor = target.partition("#")
    resolved = posixpath.normpath(posixpath.join(base, path)).lstrip("/")
    return "](" + blob + resolved + ("#" + anchor if anchor else "") + ")"


def norm_path(path: str) -> str:
    """Normalise a path for prefix comparison, as identity-guard's norm_path does.

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


def word_pattern(term: str) -> re.Pattern:
    """Match a lowercased `word:` term where no ASCII letter or digit borders it.

    The boundary is identity-guard's `[^[:alnum:]]` under LC_ALL=C, so `_`,
    `-`, `.` and `/` bound a term and a CamelCase run does not.
    """
    return re.compile(rf"(?<![0-9a-z]){re.escape(term)}(?![0-9a-z])")


def read_denylist() -> tuple[list[str], list[re.Pattern], list[str]] | None:
    """Return the denylist's terms and `word:` terms, lowercased, and its exempt prefixes.

    The exempt prefixes are normalised. Returns None when there is no denylist.
    """
    if not DENYLIST.is_file():
        return None
    terms, words, exempt = [], [], []
    for line in DENYLIST.read_text(encoding="utf-8").splitlines():
        line = line.rstrip()
        if not line or line.startswith("#"):
            continue
        if line.lower().startswith("exempt:"):
            prefix = line.split(":", 1)[1].lstrip()
            if prefix:
                exempt.append(norm_path(prefix))
            continue
        # Indented, a word: line is one still, as the hook reads it.
        stripped = line.lstrip()
        if stripped.lower().startswith("word:"):
            word = stripped.split(":", 1)[1].lstrip()
            if word:
                words.append(word_pattern(word.lower()))
            continue
        terms.append(line.lower())
    return terms, words, exempt


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("repo_root", type=Path)
    parser.add_argument("out_dir", type=Path)
    parser.add_argument("--blob", required=True)
    parser.add_argument("--status", default="open,deferred")
    parser.add_argument("--brief", type=Path, action="append", default=[])
    parser.add_argument("--allow-no-denylist", action="store_true",
                        help="with no denylist terms, count nothing and exit 0 on a denylist: line")
    args = parser.parse_args()

    wanted = set(parse_list(args.status))
    if not wanted <= STATUS.keys():
        print(f"error: --status takes open and deferred, not {args.status}", file=sys.stderr)
        return 2
    blob = args.blob if args.blob.endswith("/") else args.blob + "/"
    # A body is written as <out-dir>/<stem>.md, which would be the brief
    # itself if it sat there.
    out = args.out_dir.resolve()
    if args.brief:
        if not args.repo_root.is_dir():
            print(f"error: no repo at {args.repo_root}", file=sys.stderr)
            return 2
        missing = [str(path) for path in args.brief if not path.is_file()]
        if missing:
            print(f"error: no brief file at {', '.join(missing)}", file=sys.stderr)
            return 2
        names = [path.name.lower() for path in args.brief]
        repeated = sorted({name for name in names if names.count(name) > 1})
        if repeated:
            print(
                f"error: --brief names {', '.join(repeated)} more than once; "
                "the later body would overwrite the earlier in <out-dir>",
                file=sys.stderr,
            )
            return 2
        if any(path.resolve().parent == out for path in args.brief):
            print(
                "error: a --brief sits in <out-dir>, where its body would overwrite it",
                file=sys.stderr,
            )
            return 2
        briefs = sorted(args.brief)
    else:
        brief_dir = args.repo_root / BRIEF_DIR
        if not brief_dir.is_dir():
            print(f"error: no {BRIEF_DIR} under {args.repo_root}", file=sys.stderr)
            return 2
        if brief_dir.resolve() == out:
            print(
                "error: <out-dir> is the queue, whose briefs its bodies would overwrite",
                file=sys.stderr,
            )
            return 2
        briefs = sorted(brief_dir.glob("*.md"))
    args.out_dir.mkdir(parents=True, exist_ok=True)

    rows = []
    invalid = 0
    unfiled = 0
    unlinked = 0
    # Each blocker named by file, its folder, the brief naming it and its
    # position there, resolved once every row's opening is known.
    by_file: list[tuple[dict, str, str, int]] = []

    def refuse(brief: Path, reason: str) -> None:
        """Count a --brief that cannot be filed as it stands, naming why."""
        nonlocal unfiled
        print(f"error: {brief.name}: {reason}", file=sys.stderr)
        unfiled += 1

    def unlink(name: str, reason: str) -> None:
        """Count a parent or blocked-by that names no issue or brief, naming why."""
        nonlocal unlinked
        print(f"error: {name}: {reason}", file=sys.stderr)
        unlinked += 1

    def in_repo(brief: Path) -> str | None:
        """The repo path of a --brief under docs/handoffs/, which stays its source; else None."""
        try:
            rel = brief.resolve().relative_to((args.repo_root / HANDOFFS).resolve())
        except ValueError:
            return None
        return f"{HANDOFFS}/{rel.as_posix()}"

    for brief in briefs:
        rel = in_repo(brief) if args.brief else f"{BRIEF_DIR}/{brief.name}"
        no_file = rel is None
        text = brief.read_bytes().decode("utf-8").replace("\r\n", "\n")
        if not text.startswith("---\n"):
            if args.brief:
                refuse(brief, "no frontmatter")
            continue
        front, _, body = text[4:].partition("\n---\n")
        meta = dict(line.split(": ", 1) for line in front.splitlines() if ": " in line)
        # The split above reads only `issue: <value>`. Any other spelling, read
        # as no key, would file the draft as a new issue, which cannot be unfiled.
        if "issue" not in meta and ISSUE_LINE.search(front):
            meta["issue"] = ""
        status = meta.get("status", "").strip()
        if status not in wanted:
            if args.brief:
                refuse(brief, f"status is {status or 'missing'}; --status takes {args.status}")
            continue
        heading, _, rest = body.lstrip("\n").partition("\n")
        if not heading.startswith("# "):
            if args.brief:
                refuse(brief, "opens with no '# ' heading")
            else:
                print(f"warning: {brief.name} opens with no '# ' heading; skipped", file=sys.stderr)
            continue
        # A brief with no file resolves its links as if it sat in the queue.
        base = BRIEF_DIR if no_file else posixpath.dirname(rel)
        if "issue" in meta and not no_file:
            refuse(brief, "names an issue, but a brief with a file is that file's own")
            continue
        # An error names a value by its position, never its text, which may
        # hold a denylisted term the count below has not checked yet.
        issue = meta.get("issue", "").strip()
        if "issue" in meta and not ISSUE_NUMBER.fullmatch(issue):
            unlink(brief.name, "issue is not an issue number, bare")
        existing = int(issue) if ISSUE_NUMBER.fullmatch(issue) else None
        parent = meta.get("parent", "").strip()
        if "parent" in meta and not ISSUE_NUMBER.fullmatch(parent):
            unlink(brief.name, "parent is not an issue number, bare")
        blocked_by = parse_list(meta.get("blocked-by", "[]"))
        blockers = []
        for position, item in enumerate(blocked_by, start=1):
            if ISSUE_NUMBER.fullmatch(item):
                blockers.append({"issue": int(item)})
            elif item.endswith(".md") and "/" not in item:
                blockers.append({"file": item})
                by_file.append((blockers[-1], base, brief.name, position))
            else:
                unlink(
                    brief.name,
                    f"blocked-by item {position} is neither an issue number nor a brief's filename",
                )
        # The title is the heading as written: raising its first letter
        # misspelled a lowercase name opening it, `triage-inbox's` filed as
        # `Triage-inbox's`, after the user had approved it lowercase.
        title = heading.removeprefix("# ").removeprefix("Handoff: ").strip()
        needs = parse_list(meta.get("needs", "[]"))
        for need in needs:
            # 50 is believed to be GitHub's cap on a label name, unverified
            # (2026-10-27); a longer one fails file-issues.sh before it files.
            if len(f"needs:{need}") > 50:
                print(
                    f"warning: {brief.name}: needs:{need} may be too long for a label",
                    file=sys.stderr,
                )
        work = {key: meta.get(key, "").strip() for key in WORK}
        # These name the key or the position, never the value, by the rule
        # above: the count has not read it yet.
        for key, value in work.items():
            if value and value not in WORK[key]:
                print(
                    f"error: {brief.name}: {key} is none of {', '.join(WORK[key])}",
                    file=sys.stderr,
                )
                invalid += 1
        platforms = parse_list(meta.get("platform", "[]"))
        for position, platform in enumerate(platforms, start=1):
            if not PLATFORM.fullmatch(platform):
                print(
                    f"error: {brief.name}: platform {position} is not lowercase kebab, "
                    "as power-bi",
                    file=sys.stderr,
                )
                invalid += 1
            # The same cap as a needs value's above.
            elif len(f"platform:{platform}") > 50:
                print(
                    f"warning: {brief.name}: platform {position} may be too long for a label",
                    file=sys.stderr,
                )
        # The same in every run, unlike the date after it, so file-issues.sh
        # can match it against the issues a run in another session filed.
        if no_file:
            opening = f'Filed as `{brief.stem}` ("{title}") with no brief file'
            lead = (
                f"{opening}, on {date.today().isoformat()}. "
                "This issue is the brief: edit it, not a file."
            )
        else:
            opening = f"Filed from [`{rel}`]"
            lead = (
                f"{opening}({blob}{rel}) on {date.today().isoformat()}. "
                "While that file exists it is the source: edit the file, not this issue."
            )
        issue_body = (
            lead + "\n\n" + LINK.sub(lambda m: absolutize(blob, base, m), rest.lstrip("\n"))
        )
        # An issue that exists keeps its own body, written here only to be counted.
        if existing:
            opening, issue_body = "", rest.lstrip("\n")
        body_name = f"{brief.stem}.md"
        (args.out_dir / body_name).write_bytes(issue_body.encode("utf-8"))
        rows.append(
            {
                "file": brief.name,
                "issue": existing,
                "title": title,
                "status": STATUS[status],
                "priority": "P" + meta.get("priority", "3").strip(),
                "needs": needs,
                "platform": platforms,
                "reopen_when": meta.get("reopen-when", "").strip(),
                # As written, for the denylist count; file-issues.sh reads blockers.
                "blocked_by": blocked_by,
                "parent": int(parent) if ISSUE_NUMBER.fullmatch(parent) else None,
                "blockers": blockers,
                "work_model": work["work-model"],
                "work_effort": work["work-effort"],
                "body": body_name,
                "opening": opening,
                "chars": len(issue_body),
            }
        )
    # A blocker in this manifest is found by its row's opening, as its
    # brief is; any other by the line its file's issue opens with.
    openings = {row["file"]: row["opening"] for row in rows}
    existing_issues = {row["file"]: row["issue"] for row in rows if row["issue"]}
    for blocker, base, name, position in by_file:
        if blocker["file"] == name:
            unlink(name, f"blocked-by item {position} names the brief itself")
        elif blocker["file"] in existing_issues:
            number = existing_issues[blocker["file"]]
            blocker.clear()
            blocker["issue"] = number
        elif blocker["file"] in openings:
            blocker["opening"] = openings[blocker["file"]]
        elif (args.repo_root / base / blocker["file"]).is_file():
            blocker["opening"] = f"Filed from [`{base}/{blocker['file']}`]"
        else:
            unlink(
                name, f"blocked-by item {position} is in neither this manifest nor {base}/"
            )
    manifest = args.out_dir / "manifest.json"
    manifest.write_bytes(json.dumps(rows, indent=2).encode("utf-8") + b"\n")
    longest = max((row["chars"] for row in rows), default=0)
    print(f"{len(rows)} briefs to {manifest}; longest body {longest} chars")
    if invalid:
        print(
            f"error: {invalid} work-model, work-effort or platform values "
            "outside the board's options or shape",
            file=sys.stderr,
        )
    if unfiled:
        print(f"error: {unfiled} briefs cannot be filed as they stand", file=sys.stderr)
    if unlinked:
        print(
            f"error: {unlinked} issue, parent or blocked-by values name no issue or brief",
            file=sys.stderr,
        )
    if invalid or unfiled or unlinked:
        return 1

    # The denylist is the user's own, so a machine may hold none. Filing
    # unchecked is the leak this count exists for, so that stops, exit 2,
    # unless the caller opts in: then the skip is said on stdout, where
    # provision-board reads it into the question that asks to file.
    def no_terms(line: str) -> int:
        """Stop, exit 2, with no term to count, unless --allow-no-denylist lets the caller pass."""
        if not args.allow_no_denylist:
            print(f"error: no denylist terms at {DENYLIST}, so nothing was checked",
                  file=sys.stderr)
            return 2
        print(line)
        print_phrase_labels(rows)
        return 0

    denylist = read_denylist()
    if denylist is None:
        return no_terms(f"denylist: none at {DENYLIST}, so no term was counted")
    terms, words, exempt = denylist
    root = norm_path(str(args.repo_root.resolve()))
    if any(root.startswith(prefix) for prefix in exempt):
        print("denylist: the repo root is under an exempt: line, so nothing was counted")
        print_phrase_labels(rows)
        return 0
    if not terms and not words:
        return no_terms(f"denylist: no terms at {DENYLIST}, so no term was counted")
    hits = 0
    for row in rows:
        body = (args.out_dir / row["body"]).read_text(encoding="utf-8")
        # A platform value becomes a label with no fixed list to stop it, so
        # it is counted as a needs phrase is.
        fields = [
            row["title"],
            body,
            row["reopen_when"],
            *row["needs"],
            *row["platform"],
            *row["blocked_by"],
        ]
        text = "\n".join(fields).lower()
        count = sum(text.count(term) for term in terms)
        count += sum(len(word.findall(text)) for word in words)
        if count:
            hits += 1
            print(f"{row['file']}: {count}")
    print(f"denylist: {len(terms) + len(words)} terms, {len(rows)} briefs, {hits} with hits")
    if hits:
        return 1
    print_phrase_labels(rows)
    return 0


sys.exit(main())
