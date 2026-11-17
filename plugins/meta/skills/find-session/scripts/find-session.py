#!/usr/bin/env python3
"""Find a past Claude Code session by what was said in it.

    uv run --no-project <skill>/scripts/find-session.py rename session  # every term, anywhere
    uv run --no-project <skill>/scripts/find-session.py --repo my-repo winget
    uv run --no-project <skill>/scripts/find-session.py --days 3 --limit 5 worktree
    uv run --no-project <skill>/scripts/find-session.py --json pbir     # for a session to parse

<skill> is the find-session skill's folder, wherever it is installed;
--no-project keeps uv from syncing the Python project of whatever repo it
runs in.

A session matches when every term appears in it, ignoring case: in its
name, a prompt you typed, or a compaction summary of what it did; --replies
adds Claude's own text. The tightest match comes first, then the newest,
each with the passage that matched best and the command that resumes it.

Names alone are a weak index, which is why this sits beside the
name-session hook: Claude Code titles a session from its first prompt and
never again, so the session where naming sessions was first explored
(2026-09-30) was titled "CONTRIBUTING.md for repo", and only its prompts
said what it had become.

It searches every account's config directory, since a login is one: the
session's own, CLAUDE_CONFIG_DIR or else ~/.claude, then each other that
the account map names, CLAUDE_ACCOUNTS_MAP or else
~/.config/claude-accounts.json, where the user keeps one; with none,
only the first is read. A match found under another
account's directory says so, since `claude --resume` finds it only from a
launch under that directory, which its folder gives it.

It reads <config>/projects/*/*.jsonl itself,
though the docs call that format internal and liable to change in any
release. The Agent SDK's get_session_messages() was the supported route
and was measured first: it returns only the chain since the last
compaction, and for one long session it lacked 31 of the 50 prompts typed
(2026-10-06) -- the sessions most worth finding. When the format does
change, this fails rather than reporting nothing: transcripts on disk but
not one prompt read from them exits 2.

It reaches back only as far as transcripts are kept, so the summary line
names the day the oldest one on disk was last written: `cleanupPeriodDays`
is the most that can be, and on 2026-10-06 the store held 7 days against a
setting of 15, because a lower value had been set for a while first.
That date bounds a transcript's last write, not its
session's last activity: Claude Code writes title and state records after
a session's last prompt, so on 2026-10-06 one last prompted 2026-09-24 was
found while the oldest transcript read as written 2026-09-29.

The session running the search is left out, by CLAUDE_CODE_SESSION_ID,
which Claude Code sets in its shells, since its own prompt holds the
terms. Probe sessions -- cwd in the temp folder, or named "probe: ..." --
are left out unless --probes. Exits 1 when nothing matches. No
dependencies; the script's suite, in the repo this skill is authored in,
holds each case.
"""

from __future__ import annotations

import argparse
import io
import json
import os
import re
import sys
import tempfile
import time
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

REMINDER = re.compile(r"<system-reminder>.*?</system-reminder>", re.S)
COMMAND_NAME = re.compile(r"<command-name>([^<]*)</command-name>")
COMMAND_ARGS = re.compile(r"<command-args>(.*?)</command-args>", re.S)
CONTINUED = "This session is being continued from a previous conversation"
KIND_ORDER = {"name": 0, "prompt": 1, "summary": 2, "reply": 3}
# Request records (2.1.300+), a third of a transcript's bytes, carry nothing parse() reads
# that the session's other records lack: skipped unparsed, by the prefix they open with
# (measured 2026-10-22, 2.1.308).
API_REQUEST = ('{"type":"api-request"', '{"type":"api-request-blob"',
               '{"type":"api-request-shape"')


@dataclass
class Session:
    session_id: str
    path: Path
    cwd: str = ""
    branch: str = ""
    first: str = ""
    last: str = ""
    name: str = ""
    ai_title: str = ""
    texts: list[tuple[str, str]] = field(default_factory=list)  # (kind, text)
    account: str = ""  # set only for a directory other than this session's own

    @property
    def title(self) -> str:
        if self.name or self.ai_title:
            return self.name or self.ai_title
        prompts = [t for k, t in self.texts if k == "prompt"]
        return " ".join(prompts[0].split())[:60] if prompts else "(untitled)"

    @property
    def repo(self) -> str:
        cwd = self.cwd.replace("\\", "/").rstrip("/")
        cwd = cwd.split("/.claude/worktrees/")[0]
        return cwd.rsplit("/", 1)[-1] or "?"


def texts_of(content: object) -> list[str]:
    """The text blocks of a message's content, which is a string or a list of blocks."""
    if isinstance(content, str):
        return [content]
    if isinstance(content, list):
        return [b.get("text", "") for b in content
                if isinstance(b, dict) and b.get("type") == "text"]
    return []


def typed(text: str) -> str:
    """A user record's text as typed: reminders dropped, a slash command spelled out."""
    text = REMINDER.sub("", text).strip()
    name = COMMAND_NAME.search(text)
    if name:
        args = COMMAND_ARGS.search(text)
        return f"{name.group(1)} {args.group(1).strip() if args else ''}".strip()
    return text


def parse(path: Path, replies: bool) -> Session:
    s = Session(path.stem, path)
    with path.open(encoding="utf-8", errors="replace") as fh:
        for line in fh:
            if line.startswith(API_REQUEST):
                continue
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            if not isinstance(rec, dict):
                continue
            kind = rec.get("type")
            ts = rec.get("timestamp")
            if isinstance(ts, str):
                s.first = s.first or ts
                s.last = max(s.last, ts)
            s.cwd = s.cwd or rec.get("cwd") or ""
            s.branch = rec.get("gitBranch") or s.branch
            if kind == "custom-title":
                s.name = rec.get("customTitle") or s.name
            elif kind == "ai-title":
                s.ai_title = rec.get("aiTitle") or s.ai_title
            elif kind == "user" and not rec.get("isMeta"):
                for t in texts_of((rec.get("message") or {}).get("content")):
                    t = typed(t)
                    if not t or t.startswith("<local-command-"):
                        continue
                    summary = rec.get("isCompactSummary") or t.startswith(CONTINUED)
                    s.texts.append(("summary" if summary else "prompt", t))
            elif kind == "assistant" and replies:
                for t in texts_of((rec.get("message") or {}).get("content")):
                    if t.strip():
                        s.texts.append(("reply", t))
    return s


def same_dir(a: Path, b: Path) -> bool:
    return (os.path.normcase(os.path.abspath(a)).rstrip("\\/")
            == os.path.normcase(os.path.abspath(b)).rstrip("\\/"))


def config_dirs() -> list[tuple[str, Path]]:
    """Every config directory to search, as (account, directory), this session's own first.

    The own one's account is "" unless the map names it. No map adds no
    directory; one that does not read, or of another version, adds none and
    says so on stderr, as the map's contract asks of a reader.
    """
    own = Path(os.environ.get("CLAUDE_CONFIG_DIR") or Path.home() / ".claude")
    dirs = [("", own)]
    path = Path(os.environ.get("CLAUDE_ACCOUNTS_MAP")
                or Path.home() / ".config" / "claude-accounts.json")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return dirs
    except (OSError, ValueError) as exc:
        print(f"warning: {path} did not read ({exc}), so only {own} is searched",
              file=sys.stderr)
        return dirs
    if not isinstance(data, dict) or data.get("version") != 1:
        print(f"warning: {path} is no version 1 account map, so only {own} is searched",
              file=sys.stderr)
        return dirs
    accounts = data.get("accounts")
    for name, entry in (accounts.items() if isinstance(accounts, dict) else []):
        found = entry.get("configDir") if isinstance(entry, dict) else None
        if not isinstance(found, str) or not found:
            continue
        if same_dir(Path(found), own):
            dirs[0] = (name, own)
        elif not any(same_dir(Path(found), d) for _, d in dirs):
            dirs.append((name, Path(found)))
    return dirs


def long_path(path: str) -> str:
    if os.name != "nt":
        return path
    import ctypes

    buf = ctypes.create_unicode_buffer(32768)
    n = ctypes.windll.kernel32.GetLongPathNameW(path, buf, len(buf))
    return buf.value if 0 < n < len(buf) else path


def temp_roots() -> list[str]:
    local = os.environ.get("LOCALAPPDATA")
    candidates = [tempfile.gettempdir(), os.environ.get("TEMP", ""),
                  os.path.join(local, "Temp") if local else ""]
    return sorted({os.path.normcase(long_path(c)).rstrip("\\/") for c in candidates if c})


def is_probe(s: Session, roots: list[str]) -> bool:
    if s.name.lower().startswith("probe:"):
        return True
    cwd = os.path.normcase(long_path(s.cwd)) if s.cwd else ""
    return any(cwd == r or cwd.startswith(r + os.sep) for r in roots)


def best_passage(s: Session, terms: list[str]) -> tuple[str, str, int]:
    """The passage holding the most terms, preferring a name, then a prompt.

    Returns its kind, its text, and the match's tier: KIND_ORDER's rank when
    that one passage holds every term, or 4 when only the session as a whole
    does, which a long compaction summary makes common and weak.
    """
    candidates = [("name", s.name), ("name", s.ai_title)] + s.texts
    kind, text, score = "", "", 0
    for k, t in sorted(candidates, key=lambda c: KIND_ORDER[c[0]]):
        n = sum(term in t.lower() for term in terms)
        if n > score:
            kind, text, score = k, t, n
    return kind, text, KIND_ORDER[kind] if score == len(terms) else 4


def snippet(text: str, terms: list[str], width: int = 110) -> str:
    flat = " ".join(text.split())
    low = flat.lower()
    hits = [low.find(t) for t in terms if t in low]
    start = max(0, min(hits) - 30) if hits else 0
    piece = flat[start:start + width]
    return ("…" if start else "") + piece + ("…" if start + width < len(flat) else "")


def local_time(stamp: str) -> str:
    try:
        when = datetime.fromisoformat(stamp.replace("Z", "+00:00"))
    except ValueError:
        return stamp[:16]
    return when.astimezone().strftime("%Y-%m-%d %H:%M")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("terms", nargs="+", help="words that must all appear in the session")
    ap.add_argument("--repo", help="only sessions run in this repo (its folder name)")
    ap.add_argument("--days", type=float, help="only sessions active in the last N days")
    ap.add_argument("--limit", type=int, default=10, help="most matches to show (default 10)")
    ap.add_argument("--replies", action="store_true", help="search Claude's replies too")
    ap.add_argument("--probes", action="store_true", help="include probe sessions")
    ap.add_argument("--json", action="store_true", help="print the matches as JSON")
    args = ap.parse_args(argv)
    if isinstance(sys.stdout, io.TextIOWrapper):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    dirs = config_dirs()
    asking = os.environ.get("CLAUDE_CODE_SESSION_ID")  # holds the terms in its own prompt
    elsewhere: dict[Path, str] = {}  # transcript -> its account, outside the own directory
    paths = []
    for i, (account, config) in enumerate(dirs):
        for p in sorted((config / "projects").glob("*/*.jsonl")):
            if p.stem != asking:
                paths.append(p)
                if i:
                    elsewhere[p] = account
    if not paths:
        where = ", ".join(str(d / "projects") for _, d in dirs)
        print(f"no transcripts under {where}", file=sys.stderr)
        return 1
    oldest = min(p.stat().st_mtime for p in paths)
    if args.days is not None:
        cutoff = time.time() - args.days * 86400
        paths = [p for p in paths if p.stat().st_mtime >= cutoff]

    terms = [t.lower() for t in args.terms]
    roots = temp_roots()
    read = 0
    matches: list[Session] = []
    for path in paths:
        s = parse(path, args.replies)
        s.account = elsewhere.get(path, "")
        read += sum(k == "prompt" for k, _ in s.texts)
        if not args.probes and is_probe(s, roots):
            continue
        if args.repo and s.repo.lower() != args.repo.lower():
            continue
        haystack = "\n".join([s.name, s.ai_title] + [t for _, t in s.texts]).lower()
        if all(t in haystack for t in terms):
            matches.append(s)
    if paths and not read:
        print(f"error: read {len(paths)} transcripts and found not one prompt; "
              "the transcript format may have changed", file=sys.stderr)
        return 2

    # Tightest match first -- every term in a name, then in one prompt, one
    # summary, one reply, then only across the session -- newest first within.
    ranked = sorted(((best_passage(s, terms), s) for s in matches),
                    key=lambda m: m[1].last, reverse=True)
    ranked.sort(key=lambda m: m[0][2])
    shown = ranked[:args.limit]
    if args.json:
        out = []
        for (kind, text, tier), s in shown:
            out.append({
                "session_id": s.session_id, "title": s.title, "name": s.name,
                "ai_title": s.ai_title, "repo": s.repo, "cwd": s.cwd, "branch": s.branch,
                "first_active": s.first, "last_active": s.last,
                "match": {"kind": kind, "every_term": tier < 4,
                          "text": snippet(text, terms, 300)},
                "resume": f"claude --resume {s.session_id}",
                "config_dir": str(s.path.parent.parent.parent),
                "other_account": s.account or None,
            })
        print(json.dumps(out, ensure_ascii=False, indent=2))
    else:
        for (kind, text, tier), s in shown:
            where = kind if tier < 4 else f"{kind}, some terms; the rest elsewhere"
            print(f"{local_time(s.last)}  {s.repo}  {s.title}")
            print(f"    {where}: {snippet(text, terms)}")
            print(f"    claude --resume {s.session_id}")
            if s.account:
                print(f"    under the {s.account} account's {s.path.parent.parent.parent}: "
                      f"resume it from {s.cwd or 'its folder'}")
        more = f", first {len(shown)} shown" if len(matches) > len(shown) else ""
        reach = datetime.fromtimestamp(oldest).strftime("%Y-%m-%d")
        print(f"{len(matches)} of {len(paths)} sessions matched{more}; "
              f"oldest transcript written {reach}; times are local")
    return 0 if matches else 1


if __name__ == "__main__":
    sys.exit(main())
