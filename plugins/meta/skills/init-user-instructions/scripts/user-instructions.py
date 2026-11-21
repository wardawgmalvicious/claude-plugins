#!/usr/bin/env python3
"""Check the user-scope CLAUDE.md, and read this machine's sessions for evidence about it.

    uv run --no-project <skill>/scripts/user-instructions.py check
    uv run --no-project <skill>/scripts/user-instructions.py check --payload <config-source>
    uv run --no-project <skill>/scripts/user-instructions.py sessions --since 2026-10-08
    uv run --no-project <skill>/scripts/user-instructions.py sessions --limit 100
    uv run --no-project <skill>/scripts/user-instructions.py sessions \
        --signature '2026-10-25|is not recognized as a name of a cmdlet'
    uv run --no-project <skill>/scripts/user-instructions.py sessions \
        --signature '2026-10-25|is not recognized as a name of a cmdlet' --hits 1c05c503 7ac794d2
    uv run --no-project <skill>/scripts/user-instructions.py names <file of proposed lines>
    ... --json on check or sessions, for a session to parse

<skill> is the init-user-instructions skill's folder, wherever it is
installed; --no-project keeps uv from syncing the Python project of
whatever repo it runs in.

`check` reads claude/CLAUDE.md in the config source, the repo the user's
config is authored in, found as the git root of the working directory or
--payload, and else the deployed ~/.claude/CLAUDE.md alone, saying so.
It reports, a line each:

- the line count against MAX_LINES, read from whichever Python script in
  the config source's scripts folder sets it and names CLAUDE.md, where
  the number lives alone, so nothing here restates it, with that
  script's name; an unread cap says why: no config source, no such
  script, two that disagree, or one that would not open;
- every ~/ path in a code span that resolves nowhere, and for a
  ~/.claude/ one, a payload source that is gone;
- every skill named in a code span, its tree, and whether it is deployed
  at user scope, a junction whose SKILL.md resolves, since a pointer to a
  project-scope or pruned skill is dead in every other repo; with no
  config source only deployed names are known, so the line says that
  an undeployed one cannot be told from any other code span;
- every tool the "On `PATH`" sentence lists that this process cannot
  find, and every "Not installed" one it can; PowerShell modules are not
  checked, which would need pwsh;
- every dated line, oldest first, with its age, and the versions it names;
- every number of things, which editing-claude-md.md says goes stale and
  wants a command that derives it instead;
- each account's deployed copy against the source, byte for byte.

The paths and account labels it prints are masked by the denylist, as
`sessions` masks its labels. With no denylist, either says on stderr that
nothing was masked by name, and goes on.

`sessions` reads every account's transcripts through find-session.py,
imported from the sibling skill folder, which the meta group deploys
beside this one: its parse() gives each session's typed prompts and
config_dirs() every account's directory. From the prompts alone it
prints the newest --limit (40) of those that read as a correction or a
standing instruction, each masked first; --json carries the same cut,
with corrections_total and corrections_left_out beside it: token-shaped strings, credential assignments, GUIDs and
emails become [masked], and each term ~/.config/identity-denylist.txt
lists becomes [denylisted], as identity-guard matches them. A session
launched under an exempt: root is labelled `client`, never by its
folder, and every other label is masked too. Each --signature DATE|TEXT
counts the sessions where a Bash or PowerShell result holds TEXT and its
command does not, before DATE, spanning it and begun on or after it, over
every session on disk, whatever --since says. A Read of the rule file
holds the text with no failure, so only shell results count. A shell
result whose command only prints files (cat, head, tail, sed -n, grep,
awk, jq, git show, git diff, git log, gh's view, list and diff,
Get-Content, Select-String, alone, chained, or in a for loop over a word
list) holds it with no failure either, so a session whose only such
results are those counts apart, as `printed`, beside `with_it`, never
dropped: the two sum to the raw figure. A chain holding any other
program, such as `make && cat x`, is a real result, as is a repo's own
transcript reader, which no name tells from any other script.

`with_it` splits by the tool_result's is_error: a session with any such
result flagged is `flagged`, and the rest `unflagged`, which sum to it.
The flag is a proxy both ways: `cmd || true` or `cmd | head` fails unflagged,
and `cat rule.md; make` holds the text flagged whatever make's failure was.
So `flags` counts the flagged results among every shell result read, and
none flagged reads the split unmeasured, since a format that dropped the
key would read every hit `unflagged`. Each phase also lists its sessions'
ids, SESSION_ID_CHARS long, per count; an id names nothing.

--hits ID... prints each hit in the sessions whose id starts so, printed
ones too: tool, flagged or not, the command's first COMMAND_WORDS words and
the tell's first line in that result, SNIPPET_CHARS at most around the tell,
masked as prompts are, with no other result text, bar a tell spanning lines,
which prints the result around it. A command also has common credential forms masked, in a
flag, a variable or a header: a list of forms, so one it lacks prints, and a
hit's line is for the verdict alone, never quoted. An id no session read
matches says so, as a probe's or this session's does. Without --hits no
result is printed.

It also
counts the transcripts whose request records carry the claude.ai Account
block, a userPreferences tag, in the system prompt (.shape.system) or a
system-role message, never in the conversation, where a session that
searched for the tag holds it too.

A session counts whole: find-session.py keeps only its first and last
activity, so --since keeps a session active on or after the date, and a
signature's session is before, spanning or after by those two stamps,
each converted to this machine's local date. The reach is the oldest
transcript on disk, which cleanupPeriodDays bounds (30 days by default,
claude-directory docs, 2026-10-30), and is printed with each account's
setting. The session running this is left out, by CLAUDE_CODE_SESSION_ID,
and so are probes, as find-session.py decides; a transcript that cannot
be read, as one the retention sweep removes mid-run, is skipped and
counted.

The docs call the transcript format internal and liable to change in any
release. When it does, this fails rather than reporting nothing:
transcripts on disk but not one prompt read exits 2, and request records
missing reports the Account block unmeasured, never absent.

`names` counts the denylist's terms in a file of lines a run proposes,
before any reaches the repo, and prints line numbers, never a term.

Exits 0 when it ran with nothing to report, 1 when `check` found
something, `sessions` found no transcript or `names` found a term, 2 when
it could not run: no CLAUDE.md, a --payload that holds no payload, a
--limit under 1, --hits with no --signature or an id too short to tell,
find-session.py missing, no denylist for `names`, a request record of an
unexpected shape, the transcript format moved, or a file it reads would
not open or decode. No dependencies; its suite, in the repo this skill is
authored in, holds its negative cases.
"""

from __future__ import annotations

import argparse
import difflib
import importlib.util
import io
import json
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import date, datetime
from pathlib import Path
from types import ModuleType

DENYLIST = Path.home() / ".config" / "identity-denylist.txt"
SKILL_NAME = "init-user-instructions"
CODE_SPAN = re.compile(r"`([^`\n]+)`")
HOME_PATH = re.compile(r"~/[^\s`'\"(),;]+")
SKILL_TOKEN = re.compile(r"/?[a-z0-9][a-z0-9-]*")
SLASH_TOKEN = re.compile(r"/[a-z][a-z0-9-]*")
CAP_SETTING = re.compile(rb"^MAX_LINES\s*=\s*(\d+)", re.M)  # bytes: max_lines() says why
DATE = re.compile(r"\b(20\d\d-\d\d-\d\d)\b")
VERSION = re.compile(r"\b\d+\.\d+\.\d+\b")  # any release series, not only Claude Code's 2.1
COUNT = re.compile(
    r"\b\d[\d,]*\s+(?:of\s+\d[\d,]*\s+)?(?:skills?|rules?|hooks?|servers?|groups?|agents?|"
    r"plugins?|files?|sessions?|transcripts?|repos?|commands?|tools?|accounts?)\b",
    re.I,
)
# The tooling paragraph's anchors; moved, check says so rather than listing nothing.
ON_PATH, NOT_INSTALLED, MODULES = "On `PATH`", "Not installed", "PowerShell modules"
# Where a ~/.claude/ path's source sits in the payload, by its first segment.
PAYLOAD_DIRS = {"rules", "agents", "hooks", "mcp"}

MARKERS = re.compile(
    r"\b(?:don['’]?t|do not|stop|never|always|again|instead|wrong|not what|i said|i told you|"
    r"i asked|why did you|from now on|every time|remember|should have|shouldn['’]?t)\b"
    r"|^\s*no\b",
    re.I,
)
LONG_PROMPT = 2000  # past this a prompt is likely pasted text, whose imperatives are not the user's
SNIPPET_CHARS = 300  # how much of a masked prompt is printed
DEFAULT_LIMIT = 40  # how many prompts sessions prints, the newest; --limit raises it
SESSION_ID_CHARS = 8  # enough of a session id to tell sessions apart in one report
COMMAND_WORDS = 6  # how much of a hit's command --hits prints: the program, not its payload
# Per side of a tell. The final cut never nears the edge, so masking still sees whole terms, and
# mask() never meets an unbounded line: two TOKENS backtrack quadratically on a long run (14 s
# on 40,000 characters, 2026-11-01), which a prompt's cap keeps from them and a result's does not.
MASK_WINDOW_CHARS = SNIPPET_CHARS * 4
MASK_SPAN_CHARS = 2 * MASK_WINDOW_CHARS  # the most mask() is handed: a tell's window, or a command
MIN_HIT_ID_CHARS = 4  # a shorter prefix matches sessions by chance
# A credential given as a flag's value, which TOKENS' name=value forms miss: docker login -p x,
# mysql -pX, curl -u a:b, --client-secret x. Commands only, since it over-masks mkdir -p, harmless
# in a diagnostic; --token-file names a path, so a name must end the flag. The long form comes
# first, or -pass would read as -p with the value "ass" and leave its argument bare.
FLAG_SECRET = re.compile(
    r"(?i)(?<!\S)(?:--?[a-z-]*(?:password|passwd|passphrase|pass(?:in|out)?|pwd|token|secret|"
    r"bearer|credentials?|api-?key|key|user|auth)(?:=|\s+)"
    r"|-[pu](?:\s+|(?=[^\s-])))"
    r"(?:\"[^\"]*\"|'[^']*'|\S+)")
# A credential in a header, by its name, since an opaque value has no shape to match. One start
# per word, so a long hyphenated run cannot backtrack cubically.
HEADER_SECRET = re.compile(
    r"(?i)(?<![\w-])[\w-]*(?:authorization|key|token|secret|cookie)[\w-]*:\s*(?:\w+\s+)?"
    r"(?:[^\s'\"]*;\s+)*[^\s'\"]+")
# A credential in a variable, spaced as PowerShell writes it: PGPASSWORD=x, $env:TOKEN = 'x'.
# TOKENS' assignment form needs a non-alphanumeric before its name, so PGPASSWORD slips it. Space
# counts only on both sides of the =, so GH_TOKEN= gh, which clears it, keeps its program.
ASSIGN_SECRET = re.compile(
    r"(?i)\b\w*(?:pass|pwd|secret|token|key|credential|auth)\w*(?:=|\s+=\s+)"
    r"(?:\"[^\"]*\"|'[^']*'|\S+)"
    r"|\b(?:bearer|basic)\s+\S+")
COMMAND_SECRETS = (FLAG_SECRET, HEADER_SECRET, ASSIGN_SECRET)
TOKENS = [
    re.compile(r"\bgh[pousr]_[A-Za-z0-9]{20,}"),
    re.compile(r"\bgithub_pat_[A-Za-z0-9_]{20,}"),
    re.compile(r"\bsk-ant-[A-Za-z0-9_-]{10,}"),
    re.compile(r"\bsk-[A-Za-z0-9]{20,}"),
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(r"\bxox[abprs]-[A-Za-z0-9-]{10,}"),
    re.compile(r"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{4,}"),
    # An Entra client secret: three characters, a digit, Q~, then the rest.
    re.compile(r"(?<![A-Za-z0-9_.~-])[A-Za-z0-9_.-]{3}\dQ~[A-Za-z0-9_.~-]{30,}"),
    # A credential written as an assignment, quoted or not, after _ too (GH_TOKEN=,
    # "token": "..."): AccountKey=... The value's floor of 8 spares prose ("the token:
    # please rotate it").
    re.compile(
        r"(?i)(?<![A-Za-z0-9])(?:account_?key|shared_?access_?key|client_?secret|password|"
        r"passwd|pwd|api_?key|access_?key|secret_?key|token)[\"']?\s*[=:]\s*[\"']?"
        r"[^\s;,'\"]{8,}"
    ),
    re.compile(r"\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b"),
    # Credentials in a URL's userinfo, whatever the host: scheme://user:pass@localhost
    # Greedy to the token's last @, so a password holding / or @ is masked whole.
    re.compile(r"(?<=://)[^\s/:@]+:\S+(?=@)"),
    re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+"),
    # A long run holding a letter and a digit: a key or a hash, never a word.
    re.compile(r"(?=[A-Za-z0-9+=_-]*\d)(?=[A-Za-z0-9+=_-]*[A-Za-z])[A-Za-z0-9+=_-]{40,}"),
    # Base64 with / or +, such as an AWS secret key or a storage key: a digit, one of
    # the two, and both letter cases, which a lowercase path with a digit in it lacks
    # (one did, in a real prompt, 2026-10-30).
    re.compile(r"(?<![A-Za-z0-9/+])(?=[A-Za-z0-9/+]*\d)(?=[A-Za-z0-9/+]*[/+])"
               r"(?=[A-Za-z0-9/+]*[A-Z])(?=[A-Za-z0-9/+]*[a-z])[A-Za-z0-9/+]{40,}={0,2}"),
]
# A rule's tell is a command's failure, so only shell results count: a Read of the
# rule file, or a grep for the tell itself, would hold the text without the failure.
SHELLS = {"Bash", "PowerShell"}
# A command that only prints files holds the rule's text without the failure it describes.
PRINTERS = {"cat", "head", "tail", "grep", "awk", "jq", "get-content", "select-string"}
GIT_PRINTERS = {"show", "diff", "log"}
GH_PRINTERS = {"view", "list", "diff"}  # gh <noun> <verb>, as `gh issue view 12` reads an issue
# Each prints no file: it moves the directory, prints its own words, which a hit's command holds
# and its tell does not, or closes a for loop opened by a header only_prints_files() reads apart,
# as it does a segment of bare VAR=value assignments.
NEUTRAL = {"cd", "pushd", "set-location", "echo", "printf", "done"}
# Absent from PowerShell, where each fails with "is not recognized as a name of a cmdlet", as a
# VAR=value word does: so a PowerShell call holding one ran it and failed, and is real.
BASH_ONLY = {"awk", "printf", "for", "do", "done"}
BLOCK_TAG = "<userPreferences>"
REQUEST_SHAPE = '{"type":"api-request-shape"'
REQUEST_BLOB = '{"type":"api-request-blob"'
PHASES = ("before", "spanning", "after")
# Each count a signature keeps per phase. with_it is the raw real figure, flagged + unflagged.
TELL_KEYS = ("with_it", "flagged", "unflagged", "printed")


@dataclass
class ShellHit:
    """One shell result holding a tell, unmasked: what --hits prints once masked."""

    index: int  # the signature's
    tool: str
    flagged: bool  # the tool_result's is_error
    printed: bool  # its command only prints files
    command: str
    line: str  # a window around the tell: in its first line, or the whole result if it spans lines


@dataclass
class ScanResult:
    """What one pass over a transcript found in the records parse() skips."""

    hits: list[ShellHit] = field(default_factory=list)
    shell_results: int = 0
    flagged_results: int = 0
    has_requests: bool = False
    has_block: bool = False
    entrypoint: str = ""

    def tells(self) -> dict[str, set[int]]:
        """Each signature this session counts under, by key: a real hit outranks a printed one.

        A flagged real result makes the session flagged, whatever else it holds.
        """
        real = {hit.index for hit in self.hits if not hit.printed}
        flagged = {hit.index for hit in self.hits if hit.flagged and not hit.printed}
        return {"with_it": real, "flagged": flagged, "unflagged": real - flagged,
                "printed": {hit.index for hit in self.hits if hit.printed} - real}


# --- shared -------------------------------------------------------------------------------


def load_find_session() -> ModuleType | None:
    """find-session.py from the sibling skill folder, beside this one in the repo and deployed.

    Not resolved first: through a junction, Path(__file__) is the junction's
    path, and its siblings are junctions too.
    """
    path = Path(__file__).parent.parent.parent / "find-session" / "scripts" / "find-session.py"
    spec = importlib.util.spec_from_file_location("find_session", path)
    if spec is None or spec.loader is None or not path.is_file():
        print(f"error: no find-session.py at {path}; this skill reads transcripts through it",
              file=sys.stderr)
        return None
    module = importlib.util.module_from_spec(spec)
    sys.modules["find_session"] = module  # dataclasses look their module up here
    spec.loader.exec_module(module)
    return module


def is_date(text: str) -> bool:
    """Whether text is a real YYYY-MM-DD: the regex alone takes 2026-13-45."""
    if not DATE.fullmatch(text):
        return False
    try:
        date.fromisoformat(text)
    except ValueError:
        return False
    return True


def read_denylist() -> tuple[list[re.Pattern], list[str]]:
    """The denylist's terms as patterns and its exempt: prefixes, as identity-guard reads them.

    Each line right-trimmed, blanks and # lines dropped, a term matched
    case-blind as a fixed string, a `word:` term only where no ASCII letter
    or digit borders it, and an exempt: line a path prefix (brief-bodies.py
    carries the same reading). No file gives no terms; a file that will not
    decode raises, which main() turns into exit 2.
    """
    terms: list[re.Pattern] = []
    exempt: list[str] = []
    try:
        content = DENYLIST.read_text(encoding="utf-8")
    except FileNotFoundError:
        return terms, exempt
    for line in content.splitlines():
        line = line.rstrip()
        if not line or line.startswith("#"):
            continue
        if line.lower().startswith("exempt:"):
            prefix = line.split(":", 1)[1].strip()
            if prefix:
                exempt.append(norm_path(prefix))
            continue
        stripped = line.lstrip()
        if stripped.lower().startswith("word:"):
            word = stripped.split(":", 1)[1].strip()
            if word:
                terms.append(re.compile(rf"(?<![0-9a-z]){re.escape(word)}(?![0-9a-z])", re.I))
            continue
        terms.append(re.compile(re.escape(line), re.I))
    return terms, exempt


def norm_path(path: str) -> str:
    """A path for prefix comparison: ~ expanded, lower case, forward slashes, /c/ as c:."""
    path = os.path.expanduser(path).replace("\\", "/").lower()
    drive = re.match(r"^/([a-z])(/|$)", path)
    if drive:
        path = f"{drive.group(1)}:{path[2:]}"
    return path.rstrip("/") + "/"


def mask(text: str, denied: list[re.Pattern], tally: dict[str, int]) -> str:
    """Text with each denylisted term and each token-shaped string replaced, counted in tally."""
    for pattern in denied:
        text, replaced = pattern.subn("[denylisted]", text)
        tally["denylisted"] += replaced
    for pattern in TOKENS:
        text, replaced = pattern.subn("[masked]", text)
        tally["tokens"] += replaced
    return text


# --- check --------------------------------------------------------------------------------


def payload_root(given: str | None) -> Path | None:
    """The config source: the root holding claude/CLAUDE.md, whatever its scripts are named."""
    if given:
        root = Path(given)
    else:
        try:
            top = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                                 capture_output=True, text=True, check=True).stdout.strip()
        except (OSError, subprocess.CalledProcessError):
            return None
        root = Path(top)
    return root if (root / "claude" / "CLAUDE.md").is_file() else None


@dataclass
class Cap:
    """The CLAUDE.md cap and the scripts that set it, or why it went unread."""

    value: int | None = None
    scripts: list[str] = field(default_factory=list)
    unread: str = ""


def max_lines(payload: Path | None) -> Cap:
    """MAX_LINES as a script in the config source's scripts folder sets it for CLAUDE.md.

    Only a script whose text also names CLAUDE.md counts, so a log trimmer's
    MAX_LINES never caps the file. Each script is read as bytes: both names
    are ASCII, which a UTF-8 or cp1252 source holds alike, so none is skipped
    for its encoding. One that will not open leaves the cap unread, since it
    may set another value, and every unread cap says which cause left it so.
    """
    if payload is None:
        return Cap(unread="no config source")
    setters: dict[str, int] = {}
    passed_over: list[str] = []
    for script in sorted((payload / "scripts").glob("*.py")):
        if not script.is_file():
            continue
        try:
            data = script.read_bytes()
        except OSError as exc:
            return Cap(unread=f"{script.name} would not open ({type(exc).__name__}), "
                              "and may set it")
        setting = CAP_SETTING.search(data)
        if not setting:
            continue
        if b"CLAUDE.md" in data:
            setters[script.name] = int(setting.group(1))
        else:
            passed_over.append(script.name)
    values = set(setters.values())
    if len(values) == 1:
        return Cap(value=values.pop(), scripts=list(setters))
    if values:
        return Cap(unread="the scripts disagree: "
                   + ", ".join(f"{name} sets {value}" for name, value in setters.items()))
    unread = "no script in the scripts folder sets MAX_LINES and names CLAUDE.md"
    if passed_over:
        unread += f"; passed over, setting it without naming CLAUDE.md: {', '.join(passed_over)}"
    return Cap(unread=unread)


def code_spans(lines: list[str]) -> list[tuple[int, str]]:
    """Each code span's text, with its 1-based line number."""
    return [(number, span.group(1)) for number, line in enumerate(lines, 1)
            for span in CODE_SPAN.finditer(line)]


def payload_source(payload: Path, rest: str) -> Path | None:
    """Where the payload keeps what ~/<rest> deploys from, or None if nothing deploys it."""
    if not rest.startswith(".claude/"):
        return None
    under = rest[len(".claude/"):].rstrip("/")
    head, _, tail = under.partition("/")
    if under in ("CLAUDE.md", "settings.json") or head in PAYLOAD_DIRS:
        return payload / "claude" / under
    if head == "skills" and tail:
        skill, _, inner = tail.partition("/")
        homes = sorted((payload / "skills").glob(f"*/{skill}"))
        return (homes[0] / inner) if homes else payload / "skills" / "<group>" / tail
    return None


def line_report(lines: list[str], cap: Cap, denied: list[re.Pattern]) -> dict:
    """The line count against the cap, its scripts or why it went unread, and the headroom left.

    The scripts' names are masked as paths are: a file name can name a client.
    """
    return {"count": len(lines), "cap": cap.value,
            "cap_scripts": [mask_label(name, denied) for name in cap.scripts],
            "cap_unread": mask_label(cap.unread, denied) if cap.unread else None,
            "over": cap.value is not None and len(lines) > cap.value,
            "headroom": None if cap.value is None else cap.value - len(lines)}


def dead_pointers(lines: list[str], payload: Path | None,
                  denied: list[re.Pattern]) -> list[dict]:
    """Each ~/ path in a code span that resolves nowhere, or whose payload source is gone.

    The source is masked as drift_report masks its paths: it is absolute, so a
    config source under the profile folder names the user, and a client
    checkout's path may name the client.
    """
    dead = []
    for number, span in code_spans(lines):
        for match in HOME_PATH.finditer(span):
            path = match.group(0).rstrip(".:")
            if any(mark in path for mark in "<*$"):  # a placeholder, not a path
                continue
            rest = path[2:]
            deployed = (Path.home() / rest).exists()
            source = payload_source(payload, rest) if payload else None
            source_exists = None if source is None else source.exists()
            if not deployed or source_exists is False:
                dead.append({"line": number, "path": path, "deployed": deployed,
                             "source": None if source is None
                             else mask_label(str(source), denied),
                             "source_exists": source_exists})
    return dead


def skill_trees(payload: Path | None) -> dict[str, str]:
    """Each skill's name and its tree: skills/<group>, or project for .claude/skills."""
    trees: dict[str, str] = {}
    if payload is None:
        return trees
    for skill_md in sorted((payload / "skills").glob("*/*/SKILL.md")):
        trees[skill_md.parent.name] = f"skills/{skill_md.parent.parent.name}"
    for skill_md in sorted((payload / ".claude" / "skills").glob("*/SKILL.md")):
        trees.setdefault(skill_md.parent.name, "project")
    return trees


def skill_report(lines: list[str], payload: Path | None, own: Path) -> dict:
    """Each skill a code span names, its tree, and whether it is deployed at user scope.

    Deployed means a SKILL.md resolves under it: a junction whose target is
    gone is listed by a glob but serves nothing.
    """
    trees = skill_trees(payload)
    skills_dir = own / "skills"
    deployed = ({entry.name for entry in skills_dir.glob("*") if (entry / "SKILL.md").is_file()}
                if skills_dir.is_dir() else set())
    named: dict[str, dict] = {}
    unresolved: set[str] = set()
    for number, span in code_spans(lines):
        if not SKILL_TOKEN.fullmatch(span):
            continue
        skill = span.lstrip("/")
        if skill in trees or skill in deployed:
            entry = named.setdefault(skill, {"skill": skill, "tree": trees.get(skill),
                                             "deployed": skill in deployed, "lines": []})
            entry["lines"].append(number)
        elif SLASH_TOKEN.fullmatch(span):
            unresolved.add(span)
    listed = sorted(named.values(), key=lambda entry: entry["lines"][0])
    return {"named": listed,
            "dead_elsewhere": [entry["skill"] for entry in listed
                               if entry["tree"] == "project" or not entry["deployed"]],
            # With no payload, trees is empty: a skill not deployed is no skill here at all.
            "undeployed_unchecked": payload is None,
            "slash_unresolved": sorted(unresolved)}


def tool_lists(text: str) -> tuple[list[str], list[str]] | None:
    """The tools the "On `PATH`" sentence lists, and the "Not installed" ones; None if moved."""
    start = text.find(ON_PATH)
    stop = text.find(NOT_INSTALLED, start + 1) if start >= 0 else -1
    end = text.find(MODULES, stop + 1) if stop >= 0 else -1
    if min(start, stop, end) < 0:
        return None

    def commands_in(chunk: str) -> list[str]:
        return [span for span in CODE_SPAN.findall(chunk)
                if not any(mark in span for mark in "/~ $<") and not span.startswith("-")]

    return commands_in(text[start + len(ON_PATH):stop]), commands_in(text[stop:end])


def tool_report(text: str) -> dict | None:
    """Listed tools this process cannot find, and "not installed" ones it can; None if moved."""
    lists = tool_lists(text)
    if lists is None:
        return None
    on_path, not_installed = lists
    return {"listed": len(on_path),
            "missing": [tool for tool in on_path if not shutil.which(tool)],
            "not_installed_listed": not_installed,
            "found_anyway": [tool for tool in not_installed if shutil.which(tool)]}


def dated_lines(lines: list[str], today: date) -> list[dict]:
    """Every dated line, oldest first, with its newest real date's age and its versions.

    A typo such as 2026-10-32 never outranks a real date on its line, and a
    line of typos alone is reported with no age, not a crash.
    """
    dated = []
    for number, line in enumerate(lines, 1):
        stamps = DATE.findall(line)
        if not stamps:
            continue
        real = [stamp for stamp in stamps if is_date(stamp)]
        newest = max(real) if real else max(stamps)
        age = (today - date.fromisoformat(newest)).days if real else None
        dated.append({"line": number, "date": newest, "age_days": age,
                      "versions": VERSION.findall(line)})
    return sorted(dated, key=lambda entry: (entry["date"], entry["line"]))


def count_mentions(lines: list[str]) -> list[dict]:
    """Every number of things on a line: a count that wants a derivation command."""
    return [{"line": number, "text": match.group(0)} for number, line in enumerate(lines, 1)
            for match in COUNT.finditer(line)]


def drift_report(raw: bytes, lines: list[str], config_dirs: list[tuple[str, Path]],
                 denied: list[re.Pattern]) -> list[dict]:
    """Each account's deployed CLAUDE.md against the source: identical, differs or missing.

    The account label and the config path are masked like sessions' labels: a
    ~/.claude-<client> folder names the client, and this report reaches a model
    that may quote it into a public file.
    """
    drift = []
    for account, config_dir in config_dirs:
        target = config_dir / "CLAUDE.md"
        label = mask_label(account or str(config_dir), denied)
        shown = mask_label(str(target), denied)
        if not target.is_file():
            drift.append({"account": label, "path": shown, "state": "missing"})
            continue
        deployed = target.read_bytes()
        if deployed == raw:
            drift.append({"account": label, "path": shown, "state": "identical"})
            continue
        diff = list(difflib.unified_diff(
            deployed.decode("utf-8", "replace").splitlines(), lines, lineterm="", n=0))
        # The first two entries are the ---/+++ headers; a changed line may itself start with --.
        changed = sum(1 for diff_line in diff[2:] if diff_line.startswith(("+", "-")))
        drift.append({"account": label, "path": shown, "state": "differs",
                      "lines_changed": changed})
    return drift


def render_check(report: dict) -> None:
    """Print check's report a line per check, a clean one included."""
    where = ("the config source" if report["payload"]
             else "the deployed copy alone; no config source here")
    print(f"source     {report['source']} ({where})")
    counted = report["lines"]
    cap_text = (f", cap {counted['cap']} (MAX_LINES in {', '.join(counted['cap_scripts'])}), "
                f"headroom {counted['headroom']}"
                if counted["cap"] is not None
                else f", cap unread: {counted['cap_unread']}")
    print(f"lines      {counted['count']}{cap_text}")
    pointers = report["dead_pointers"]
    print(f"pointers   {len(pointers)} resolve nowhere")
    for pointer in pointers:
        source = (f", source {'yes' if pointer['source_exists'] else 'no'} at {pointer['source']}"
                  if pointer["source"] else "")
        print(f"    L{pointer['line']} {pointer['path']}: "
              f"deployed {'yes' if pointer['deployed'] else 'no'}{source}")
    skills = report["skills"]
    print(f"skills     {len(skills['named'])} named")
    for entry in skills["named"]:
        state = "deployed" if entry["deployed"] else "NOT deployed"
        print(f"    {entry['skill']}: {entry['tree'] or 'deployed only'}, {state} at user scope, "
              f"L{','.join(map(str, entry['lines']))}")
    if skills["undeployed_unchecked"]:
        print("           not checked: with no config source an undeployed skill "
              "cannot be told from any other code span, so none is listed")
    if skills["slash_unresolved"]:
        print(f"           unresolved, a built-in or no skill: "
              f"{', '.join(skills['slash_unresolved'])}")
    tools = report["tools"]
    if tools is None:
        print(f"tools      not found by their anchors "
              f"({ON_PATH!r}, {NOT_INSTALLED!r}, {MODULES!r})")
    else:
        print(f"tools      {tools['listed']} listed on PATH, missing from this process's PATH: "
              f"{', '.join(tools['missing']) or 'none'}; 'not installed' yet found: "
              f"{', '.join(tools['found_anyway']) or 'none'}; PowerShell modules not checked")
    print(f"dated      {len(report['dated'])} lines, oldest first:")
    for entry in report["dated"]:
        versions = f" [{', '.join(entry['versions'])}]" if entry["versions"] else ""
        age = entry["age_days"]
        if age is None:
            print(f"    L{entry['line']} {entry['date']} (not a real date){versions}")
            continue
        unit = "day" if age == 1 else "days"
        future = " (in the future)" if age < 0 else ""
        print(f"    L{entry['line']} {entry['date']} ({age} {unit}){future}{versions}")
    print(f"counts     {len(report['counts'])}")
    for mention in report["counts"]:
        print(f"    L{mention['line']} {mention['text']}")
    if not report["payload"]:
        print("drift      not checked: no config source")
        return
    print("drift      " + "; ".join(
        f"{entry['path']}: {entry['state']}"
        + (f", {entry['lines_changed']} lines" if "lines_changed" in entry else "")
        for entry in report["drift"]))


def check(args: argparse.Namespace, find_session: ModuleType) -> int:
    """Run every deterministic check on the user-scope CLAUDE.md; 1 when any finds something."""
    payload = payload_root(args.payload)
    if args.payload and payload is None:  # a mistyped path must not read as a clean audit
        print(f"error: --payload {args.payload!r} holds no claude/CLAUDE.md", file=sys.stderr)
        return 2
    config_dirs = find_session.config_dirs()
    own = config_dirs[0][1]
    denied = read_denylist()[0]
    if not denied:  # nothing names a client, so nothing can be masked by name: say so, go on
        print(f"warning: no denylist terms at {DENYLIST}, so no path is masked by name",
              file=sys.stderr)
    source = payload / "claude" / "CLAUDE.md" if payload else own / "CLAUDE.md"
    if not source.is_file():
        print(f"error: no CLAUDE.md at {mask_label(str(source), denied)}", file=sys.stderr)
        return 2
    raw = source.read_bytes()
    text = raw.decode("utf-8")
    lines = text.splitlines()
    report = {
        "source": mask_label(str(source), denied),
        "payload": mask_label(str(payload), denied) if payload else None,
        "lines": line_report(lines, max_lines(payload), denied),
        "dead_pointers": dead_pointers(lines, payload, denied),
        "skills": skill_report(lines, payload, own),
        "tools": tool_report(text),
        "dated": dated_lines(lines, date.today()),
        "counts": count_mentions(lines),
        "drift": drift_report(raw, lines, config_dirs, denied) if payload else [],
    }
    tools = report["tools"]
    finding = bool(report["lines"]["over"] or report["dead_pointers"]
                   or report["skills"]["dead_elsewhere"] or tools is None
                   or tools["missing"] or tools["found_anyway"]
                   or any(entry["state"] != "identical" for entry in report["drift"]))
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        render_check(report)
    return 1 if finding else 0


# --- sessions -----------------------------------------------------------------------------


def texts_in(content: object) -> list[str]:
    """The text of a content field: a string, or a list of strings and text blocks."""
    if isinstance(content, str):
        return [content]
    found: list[str] = []
    for block in content if isinstance(content, list) else []:
        if isinstance(block, str):
            found.append(block)
        elif isinstance(block, dict) and block.get("type") == "text":
            text = block.get("text", "")
            if not isinstance(text, str):  # the format moved: exit 2 from main(), never a pass
                raise ValueError(f"a text block holds {type(text).__name__}, not a string")
            found.append(text)
    return found


def block_in_request(line: str, record: dict) -> bool:
    """Whether a request record carries the Account block where the system prompt goes."""
    if line.startswith(REQUEST_SHAPE):
        shown = texts_in((record.get("shape") or {}).get("system"))
    elif line.startswith(REQUEST_BLOB) and (record.get("message") or {}).get("role") == "system":
        shown = texts_in((record.get("message") or {}).get("content"))
    else:
        return False
    return any(BLOCK_TAG in text for text in shown)


def request_has_block(line: str, path: Path) -> bool:
    """Whether a request record's line carries the Account block; a moved format raises."""
    try:
        record = json.loads(line)
    except ValueError:  # a line cut off mid-write
        return False
    try:
        return block_in_request(line, record)
    except AttributeError as exc:  # the format moved: fail, never report "absent"
        raise ValueError(f"a request record naming userPreferences has an unexpected "
                         f"shape ({exc})") from exc


def entrypoint_of(line: str) -> str:
    """The entrypoint a transcript line records, else empty."""
    try:
        return json.loads(line).get("entrypoint") or ""
    except (ValueError, AttributeError):
        return ""


def command_segments(command_line: str) -> list[str] | None:
    """The command line split at unquoted ; & | and newlines, or None when it runs a substitution.

    A $(, a backtick or a process substitution, <( or >(, may run any
    program, so the line is then real, never printed. Quotes are tracked so
    `grep "a && b" f` is one segment; a stray one only makes the line read
    as real, the count the script had before.
    """
    if any(mark in command_line for mark in ("$(", "`", "<(", ">(")):
        return None
    segments: list[str] = []
    current: list[str] = []
    quote = ""
    for char in command_line:
        if quote:
            if char == quote:
                quote = ""
        elif char in "'\"":
            quote = char
        elif char in ";&|\n":
            segments.append("".join(current))
            current = []
            continue
        current.append(char)
    segments.append("".join(current))
    return [segment.strip() for segment in segments if segment.strip()]


def git_subcommand(words: list[str]) -> str:
    """The subcommand of a split git command, past its global options, else empty."""
    at = 1
    while at < len(words) and words[at].startswith("-"):
        at += 2 if words[at] in ("-c", "-C") else 1  # these two take a value
    return words[at] if at < len(words) else ""


def only_prints_files(command_line: str, tool: str = "Bash") -> bool:
    """Whether a command line only prints files: every segment a printer or one printing no file.

    A segment printing no file moves the directory, echoes its own words,
    assigns a variable, as `f=x && sed -n 1p "$f"` does, or opens a for
    loop's word list or closes it; a loop body's `do` is dropped to reach
    its program. Through the PowerShell tool an assignment word or a
    BASH_ONLY program is a failed command, so the line is real.
    At least one segment must print, so `cd x` alone does not, and a chain
    holding any other program, `make && cat x`, does not either.
    """
    segments = command_segments(command_line)
    if not segments:
        return False
    printing = False
    for segment in segments:
        all_words = segment.casefold().split()
        # Leading VAR=value words are not Bash's program, so a segment of nothing else runs none.
        words = [word for word in all_words if not re.fullmatch(r"\w+=\S*", word)]
        if tool == "PowerShell" and (len(words) < len(all_words)
                                     or (words and words[0] in BASH_ONLY)):
            return False
        if words[:1] == ["do"]:
            words = words[1:]
        head = words[0] if words else ""
        if not words or head in NEUTRAL:
            continue
        if head == "for":
            # `for f in a b` runs nothing, a $( or <( refused above; `for ((` is arithmetic.
            if len(words) < 3 or words[2] != "in" or not re.fullmatch(r"\w+", words[1]):
                return False
        elif head in PRINTERS:
            printing = True
        elif head == "sed":
            flags = words[1:]
            if (any(re.fullmatch(r"-[a-z]*n[a-z]*", word) for word in flags)
                    and not any(word.startswith(("-i", "--in-place")) for word in flags)):
                printing = True
            else:
                return False
        elif head == "git":
            if git_subcommand(words) not in GIT_PRINTERS:
                return False
            printing = True
        elif head == "gh":
            if len(words) < 3 or words[2] not in GH_PRINTERS:
                return False
            printing = True
        else:
            return False
    return printing


def tell_at(text: str, tell: str) -> int:
    """Where the tell starts in collapsed text, or 0: found in text itself, since casefold() moves
    an index wherever it changes a length, as ß to ss does."""
    found = re.search(re.escape(" ".join(tell.split())), text, re.I)
    return found.start() if found else 0


def around_tell(text: str, tell: str) -> str:
    """Text, whitespace collapsed, cut to a window around the tell, so mask() meets a bounded line.

    Collapsed first, so the window counts what the final cut counts: over raw text a run of
    spaces brings the window's edge, and a term it splits, up to the tell.
    """
    text = " ".join(text.split())
    start = max(tell_at(text, tell) - MASK_WINDOW_CHARS, 0)
    return text[start:start + MASK_SPAN_CHARS]


def shell_signature_hits(line: str, folded: list[str], commands: dict[str, tuple[str, str, bool]],
                         found: ScanResult) -> None:
    """Add to found each signature a shell result on this line holds and its command lacks.

    Counts every shell result and every flagged one, tell or none, since no
    flag in a whole store means the split is unmeasured. commands maps a shell
    call's id to its tool, its command line and whether it only prints files,
    and is filled here as the calls go by.
    """
    if not ('"tool_result"' in line or '"tool_use"' in line):
        return
    try:
        record = json.loads(line)
    except ValueError:
        return
    message = record.get("message") if isinstance(record, dict) else None
    content = message.get("content") if isinstance(message, dict) else None
    for block in content if isinstance(content, list) else []:
        if not isinstance(block, dict):
            continue
        if block.get("type") == "tool_use" and block.get("name") in SHELLS:
            # The raw command line, not json.dumps of the input, whose escaping would
            # hide a tell holding \ or ", nor its description, which Claude writes.
            fields = block.get("input") if isinstance(block.get("input"), dict) else {}
            command_line = fields.get("command")
            command_line = command_line if isinstance(command_line, str) else ""
            tool = str(block.get("name"))
            commands[str(block.get("id"))] = (tool, command_line,
                                              only_prints_files(command_line, tool))
        elif block.get("type") == "tool_result" and str(block.get("tool_use_id")) in commands:
            tool, command_line, prints = commands[str(block.get("tool_use_id"))]
            flagged = block.get("is_error") is True
            found.shell_results += 1
            found.flagged_results += flagged
            result = "\n".join(texts_in(block.get("content")))
            folded_result, folded_command = result.casefold(), command_line.casefold()
            for index, tell in enumerate(folded):
                if tell in folded_result and tell not in folded_command:
                    # A tell across lines has no line of its own: around_tell windows the whole.
                    held = next((text for text in result.splitlines() if tell in text.casefold()),
                                result)
                    found.hits.append(ShellHit(index, tool, flagged, prints, command_line,
                                               around_tell(held, tell)))


def scan(path: Path, find_session: ModuleType,
         signatures: list[tuple[str, str]]) -> ScanResult:
    """One pass over the records parse() skips: tool results, request records, the entrypoint."""
    found = ScanResult()
    folded = [text.casefold() for _, text in signatures]
    # A shell call's id -> its tool, its command line and whether it only prints files.
    commands: dict[str, tuple[str, str, bool]] = {}
    with path.open(encoding="utf-8", errors="replace") as handle:
        for line in handle:
            if line.startswith(find_session.API_REQUEST):
                found.has_requests = True
                if not found.has_block and "userPreferences" in line:
                    found.has_block = request_has_block(line, path)
                continue
            if not found.entrypoint and '"entrypoint"' in line:
                found.entrypoint = entrypoint_of(line)
            if folded:
                shell_signature_hits(line, folded, commands, found)
    return found


def shown_hit(hit: ShellHit, session_id: str, phase: str, tell: str,
              denied: list[re.Pattern], tally: dict[str, int]) -> dict:
    """A hit as --hits prints it: masked first, then cut, so no cut can split a term or a token."""
    # Collapsed before the cut, as around_tell does, so a run of spaces brings no term up to it.
    collapsed = " ".join(hit.command.split())
    command = collapsed[:MASK_SPAN_CHARS]
    if len(collapsed) > MASK_SPAN_CHARS:  # the cut may sit inside a word, so it is dropped whole
        command = command.rsplit(" ", 1)[0]
    for pattern in COMMAND_SECRETS:
        command, replaced = pattern.subn("[masked]", command)
        tally["tokens"] += replaced
    words = mask(command, denied, tally).split()
    line = mask(hit.line, denied, tally)
    # A long line's tell may sit past the cut, so the cut is around it.
    start = max(tell_at(line, tell) - SNIPPET_CHARS // 2, 0)
    return {"session": session_id[:SESSION_ID_CHARS], "signature": tell, "phase": phase,
            "tool": hit.tool, "flagged": hit.flagged, "printed": hit.printed,
            "command": " ".join(words[:COMMAND_WORDS])[:SNIPPET_CHARS]
            + (" ..." if len(words) > COMMAND_WORDS else ""),
            "line": line[start:start + SNIPPET_CHARS]}


def local_date(stamp: str) -> str:
    """A transcript's UTC stamp as a date on this machine's clock, which the user's dates are in."""
    if not stamp:
        return ""
    try:
        return datetime.fromisoformat(stamp.replace("Z", "+00:00")).astimezone().date().isoformat()
    except (ValueError, OverflowError, OSError):  # an out-of-range stamp raises the last two
        return stamp[:10]  # the UTC date: unconverted, but never a crash


def mask_label(text: str, denied: list[re.Pattern]) -> str:
    """A repo or account label masked like a prompt, but kept out of the prompts' tally."""
    return mask(text, denied, {"tokens": 0, "denylisted": 0})


def retention(config_dirs: list[tuple[str, Path]], denied: list[re.Pattern]) -> dict[str, str]:
    """Each account's cleanupPeriodDays, its label masked and kept unique, 30 where unset."""
    settings = {}
    for position, (account, config_dir) in enumerate(config_dirs, 1):
        try:
            value = json.loads((config_dir / "settings.json").read_text(encoding="utf-8")) \
                .get("cleanupPeriodDays")
        except (OSError, ValueError, AttributeError):
            value = None
        label = mask_label(account or str(config_dir), denied)
        if label in settings:  # two labels masked alike would overwrite each other
            label = f"{label} ({position})"
        settings[label] = f"{value}" if value is not None else "30 (default)"
    return settings


def parse_signatures(raw_signatures: list[str]) -> list[tuple[str, str]] | None:
    """Each DATE|TEXT as (date, text), or None after saying which one is malformed."""
    signatures = []
    for raw in raw_signatures:
        when, separator, text = raw.partition("|")
        if not separator or not is_date(when) or not text:
            print(f"error: --signature takes DATE|TEXT, not {raw!r}", file=sys.stderr)
            return None
        signatures.append((when, text))
    return signatures


def render_sessions(report: dict) -> None:
    """Print sessions' report: reach, window, masking, the prompts, signatures, the block."""
    reach = report["reach"]
    print(f"reach      {reach['transcripts']} transcripts, oldest written "
          f"{reach['oldest_transcript']}; cleanupPeriodDays "
          + ", ".join(f"{label} {value}" for label, value in reach["cleanupPeriodDays"].items())
          + f"; {reach['probes_skipped']} probes left out, {reach['unreadable']} unreadable")
    since = reach["since"]
    print(f"window     {reach['sessions_in_window']} sessions"
          + (f" active on or after {since}, of {reach['sessions_on_disk']} on disk"
             if since else ", every one on disk"))
    masked = report["masked"]
    print(f"masked     {masked['tokens']} token-shaped, {masked['denylisted']} denylisted "
          f"({report['denylist_terms']} terms read); {report['long_prompts_skipped']} long "
          "prompts skipped as likely pastes")
    corrections = report["corrections"]
    print(f"prompts    {report['corrections_total']} read as a correction or a standing "
          f"instruction, from {report['correction_sessions']} sessions:")
    for entry in corrections:
        flag = " [ran this skill]" if entry["ran_skill"] else ""
        print(f"    {entry['last']} {entry['session']} {entry['where']}{flag}: {entry['text']}")
    left_out = report["corrections_total"] - len(corrections)
    if left_out:
        print(f"    ... {left_out} older left out; narrow with --since, or raise --limit")
    for signature in report["signatures"]:
        print(f"signature  {signature['text']!r} since {signature['date']}, "
              "every session on disk, whatever --since says: "
              + ", ".join(f"{signature[phase]['with_it']} of {signature[phase]['sessions']} {phase}"
                          for phase in PHASES))
        for key, label in (("flagged", "with it, a result flagged is_error"),
                           ("unflagged", "with it, none flagged"),
                           ("printed", "printed apart, a command that only prints files")):
            print(f"           {label}: "
                  + ", ".join(f"{signature[phase][key]} {phase}" for phase in PHASES))
        for phase in PHASES:
            for key in ("flagged", "unflagged", "printed"):
                if signature[phase][f"{key}_ids"]:
                    print(f"    {phase} {key}: {', '.join(signature[phase][f'{key}_ids'])}")
    flags = report["flags"]
    if flags is not None:
        print(f"flags      {flags['flagged_results']} of {flags['shell_results']} shell results "
              "flagged is_error"
              + ("" if flags["measured"]
                 else "; unmeasured: with none flagged, the format may have moved, "
                      "so `flagged` and `unflagged` mean nothing"))
    for asked in report["hits"]:
        if not asked["sessions"]:
            print(f"hits       {asked['id']}: no session read; a mistyped id, a probe or this one")
            continue
        print(f"hits       {asked['id']}: {len(asked['results'])} in "
              f"{asked['sessions']} session(s)")
        for hit in asked["results"]:
            kind = ("flagged" if hit["flagged"] else "unflagged") + (
                ", printed" if hit["printed"] else "")
            print(f"    {hit['session']} {hit['phase']} {hit['tool']}, {kind} "
                  f"[{hit['signature']}]: {hit['command']}")
            print(f"        {hit['line']}")
    block = report["account_block"]
    if block is None:
        print("account    unmeasured: no transcript holds request records")
        return
    print(f"account    the Account block in {block['with_block']} of "
          f"{block['transcripts_with_requests']} transcripts with request records: "
          + ", ".join(f"{entrypoint} {seen['with_block']}/{seen['transcripts']}"
                      for entrypoint, seen in block["by_entrypoint"].items()))


def sessions(args: argparse.Namespace, find_session: ModuleType) -> int:
    """Read every account's transcripts for corrections, rules' tells and the Account block."""
    signatures = parse_signatures(args.signature)
    if signatures is None:
        return 2
    if args.since and not is_date(args.since):
        print(f"error: --since takes YYYY-MM-DD, not {args.since!r}", file=sys.stderr)
        return 2
    if args.limit < 1:
        print(f"error: --limit takes a positive number, not {args.limit}", file=sys.stderr)
        return 2
    if args.hits and not signatures:
        print("error: --hits reads a --signature's tells, and none was given", file=sys.stderr)
        return 2
    args.hits = [asked.strip() for asked in args.hits]
    if any(len(asked) < MIN_HIT_ID_CHARS for asked in args.hits):
        print(f"error: --hits takes at least {MIN_HIT_ID_CHARS} characters of a session id",
              file=sys.stderr)
        return 2

    config_dirs = find_session.config_dirs()
    asking = os.environ.get("CLAUDE_CODE_SESSION_ID")
    paths = [path for _, config_dir in config_dirs
             for path in sorted((config_dir / "projects").glob("*/*.jsonl")) if path.stem != asking]
    if not paths:
        print("no transcripts under "
              + ", ".join(str(config_dir / "projects") for _, config_dir in config_dirs),
              file=sys.stderr)
        return 1
    denied, exempt = read_denylist()
    if not denied:  # nothing names an organization: mask the token shapes alone, and say so
        print(f"warning: no denylist terms at {DENYLIST}, so no prompt is masked by name "
              "and no session reads `client`", file=sys.stderr)
    temp_roots = find_session.temp_roots()
    tally = {"tokens": 0, "denylisted": 0}

    prompts_read = probes = unreadable = in_window = on_disk = long_skipped = 0
    shell_results = flagged_results = 0
    oldest: float | None = None
    corrections = []
    tell_counts = [{phase: {"sessions": 0, **{key: 0 for key in TELL_KEYS},
                            **{f"{key}_ids": [] for key in TELL_KEYS}} for phase in PHASES}
                   for _ in signatures]
    asked_hits = {asked: {"id": asked, "sessions": 0, "results": []} for asked in args.hits}
    requests_by: dict[str, list[int]] = {}  # entrypoint -> [transcripts, with the block]
    for path in paths:
        try:
            modified = path.stat().st_mtime
            session = find_session.parse(path, replies=False)
        except OSError:  # removed by the retention sweep mid-run, or locked
            unreadable += 1
            continue
        oldest = modified if oldest is None else min(oldest, modified)
        prompts = [text for kind, text in session.texts if kind == "prompt"]
        prompts_read += len(prompts)
        if find_session.is_probe(session, temp_roots):
            probes += 1
            continue
        try:
            found = scan(path, find_session, signatures)
        except OSError:
            unreadable += 1
            continue
        except ValueError as exc:  # the format moved: say which transcript, exit 2 from main()
            raise ValueError(f"{path.name}: {exc}") from exc
        on_disk += 1
        shell_results += found.shell_results
        flagged_results += found.flagged_results
        if found.has_requests:
            seen = requests_by.setdefault(found.entrypoint or "unknown", [0, 0])
            seen[0] += 1
            seen[1] += found.has_block
        first, last = local_date(session.first), local_date(session.last)
        phases = ["after" if first >= when else
                  "before" if last and last < when else "spanning" for when, _ in signatures]
        tells = found.tells()
        for index, phase in enumerate(phases):
            seen = tell_counts[index][phase]
            seen["sessions"] += 1
            for key, indexes in tells.items():
                if index in indexes:
                    seen[key] += 1
                    seen[f"{key}_ids"].append(session.session_id[:SESSION_ID_CHARS])
        for asked, entry in asked_hits.items():
            if session.session_id.casefold().startswith(asked.casefold()):
                entry["sessions"] += 1
                entry["results"] += [
                    shown_hit(hit, session.session_id, phases[hit.index],
                              signatures[hit.index][1], denied, tally)
                    for hit in found.hits]
        if args.since and last and last < args.since:
            continue
        in_window += 1
        cwd = norm_path(session.cwd) if session.cwd else ""
        where = ("client" if any(cwd.startswith(prefix) for prefix in exempt)
                 else mask_label(session.repo, denied))
        ran_skill = any(SKILL_NAME in text for text in prompts)
        for text in prompts:
            if text.startswith("<") or not MARKERS.search(text):
                continue
            if len(text) > LONG_PROMPT:
                long_skipped += 1
                continue
            # Collapsed first, so a term a line break splits is still one match.
            shown = mask(" ".join(text.split()), denied, tally)
            corrections.append({"session": session.session_id[:SESSION_ID_CHARS], "where": where,
                                "last": last, "ran_skill": ran_skill,
                                "text": shown[:SNIPPET_CHARS]})
    if not prompts_read:
        cause = ("every transcript was unreadable" if unreadable == len(paths)
                 else "the transcript format may have changed")
        print(f"error: read {len(paths) - unreadable} transcripts and found not one prompt; "
              f"{cause}", file=sys.stderr)
        return 2

    with_requests = sum(seen[0] for seen in requests_by.values())
    correction_sessions = len({entry["session"] for entry in corrections})
    corrections_total = len(corrections)
    # Newest first, and within a session (one date for all its prompts) the latest prompt first.
    corrections = [entry for _, entry in sorted(
        enumerate(corrections), key=lambda pair: (pair[1]["last"], pair[0]), reverse=True)]
    report = {
        "reach": {"oldest_transcript": date.fromtimestamp(oldest).isoformat() if oldest else None,
                  "transcripts": len(paths), "probes_skipped": probes, "unreadable": unreadable,
                  "cleanupPeriodDays": retention(config_dirs, denied),
                  "since": args.since, "sessions_in_window": in_window,
                  "sessions_on_disk": on_disk},
        "masked": tally, "denylist_terms": len(denied), "long_prompts_skipped": long_skipped,
        "corrections": corrections[:args.limit], "corrections_total": corrections_total,
        "corrections_left_out": max(corrections_total - args.limit, 0),
        "correction_sessions": correction_sessions,
        "signatures": [{"date": when, "text": text, **counts}
                       for (when, text), counts in zip(signatures, tell_counts)],
        "flags": None if not signatures else {
            "shell_results": shell_results, "flagged_results": flagged_results,
            "measured": flagged_results > 0},
        "hits": list(asked_hits.values()),
        "account_block": None if not with_requests else {
            "transcripts_with_requests": with_requests,
            "with_block": sum(seen[1] for seen in requests_by.values()),
            "by_entrypoint": {entrypoint: {"transcripts": seen[0], "with_block": seen[1]}
                              for entrypoint, seen in sorted(requests_by.items())}},
    }
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        render_sessions(report)
    return 0


# --- names --------------------------------------------------------------------------------


def names(args: argparse.Namespace) -> int:
    """Count the denylist's terms in a file of proposed lines, printing line numbers, no term."""
    denied, _ = read_denylist()
    if not denied:
        print(f"error: no denylist terms at {DENYLIST}, so nothing was checked", file=sys.stderr)
        return 2
    lines = Path(args.file).read_text(encoding="utf-8").splitlines()
    # Whitespace collapsed, as sessions collapses a prompt: a double-spaced term still counts.
    hits = {number for number, line in enumerate(lines, 1)
            if any(pattern.search(" ".join(line.split())) for pattern in denied)}
    # A term the file's hard wrap splits across two lines: report the line it starts on.
    for number in range(1, len(lines)):
        head = " ".join(lines[number - 1].split())
        joined = f"{head} {' '.join(lines[number].split())}"
        if any(match.start() < len(head) < match.end()
               for pattern in denied for match in pattern.finditer(joined)):
            hits.add(number)
    ordered = sorted(hits)
    print(f"denylist: {len(denied)} terms read, {len(ordered)} lines with a hit"
          + (f": L{', L'.join(map(str, ordered))}" if ordered else ""))
    return 1 if ordered else 0


def main(argv: list[str] | None = None) -> int:
    """Parse the command line and run one command, turning unreadable input into exit 2."""
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    commands = parser.add_subparsers(dest="command", required=True)
    check_parser = commands.add_parser("check",
                                       help="deterministic checks on the user-scope CLAUDE.md")
    check_parser.add_argument("--payload",
                              help="the config source checkout (default: the git root here)")
    check_parser.add_argument("--json", action="store_true")
    sessions_parser = commands.add_parser("sessions",
                                          help="evidence from this machine's transcripts")
    sessions_parser.add_argument("--since", help="only sessions active on or after YYYY-MM-DD")
    sessions_parser.add_argument("--limit", type=int, default=DEFAULT_LIMIT,
                                 help="print at most this many prompts, the newest "
                                      f"(default {DEFAULT_LIMIT})")
    sessions_parser.add_argument("--signature", action="append", default=[],
                                 help="DATE|TEXT: count sessions whose shell results hold TEXT; "
                                      "repeatable")
    sessions_parser.add_argument("--hits", action="extend", nargs="+", default=[], metavar="ID",
                                 help="print each session's hits by id or id prefix (4 characters "
                                      "at least), masked: "
                                      "tool, flag, the command's first words, the tell's line")
    sessions_parser.add_argument("--json", action="store_true")
    names_parser = commands.add_parser("names",
                                       help="count denylisted terms in a file of proposed lines")
    names_parser.add_argument("file")
    args = parser.parse_args(argv)
    if isinstance(sys.stdout, io.TextIOWrapper):
        # LF on Windows too: --json redirected to a file would otherwise be CRLF.
        sys.stdout.reconfigure(encoding="utf-8", errors="replace", newline="\n")
    # Exit 1 means a finding, so a file that cannot be read or decoded must not reach it.
    try:
        if args.command == "names":
            return names(args)
        find_session = load_find_session()
        if find_session is None:
            return 2
        if args.command == "check":
            return check(args, find_session)
        return sessions(args, find_session)
    except (OSError, ValueError) as exc:  # UnicodeDecodeError is a ValueError
        print(f"error: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
