#!/usr/bin/env python3
"""Fill the house social-card template and render it to a 1280x640 PNG.

    uv run --no-project <skill>/scripts/render-card.py <spec.json> --out <dir>
    uv run --no-project <skill>/scripts/render-card.py <spec.json> --out <dir> --no-render
    uv run --no-project <skill>/scripts/render-card.py --html <card.html>
    uv run --no-project <skill>/scripts/render-card.py --check <card.png>

<skill> is the audit-repo skill's folder, wherever it is installed;
--no-project keeps uv from syncing the Python project of whatever
repo it runs in. The first form writes <dir>/social-preview.html and
<dir>/social-preview.png; --no-render stops after the HTML. --html renders a
filled card edited by hand to the PNG beside it, and --check runs only the
PNG checks below.

GitHub shows a repo's social preview wherever a link to it unfurls, and no
API uploads one (no GraphQL mutation names an image, and
UpdateRepositoryInput has no field for one: re-probed 2026-10-24), so the
card is made here and uploaded by hand. One template, assets/
card-template.html, serves every repo, so a user's repos share one look;
the angles the skill offers differ in words, never in design.

The spec is a JSON object, every key required:
  owner       the account or organization, set small above the name
  name        the repo's name
  accent      one character of the name whose first occurrence is coloured,
              the hyphen in most names; "" colours none
  tagline     a sentence or two; **words** between double asterisks are bold
  chips       a list of short labels, such as the top-level folders
  foot_left   the footer's left side, such as the licence
  foot_right  the footer's right side, one short line

Every value is HTML-escaped on the way in, so a name or tagline cannot put
markup into the page Edge renders. A name longer than 18 characters is set
smaller, since 18 monospace characters at 96px fill the card's width.

The renderer is headless Edge at its x86 path, where Windows 11 installs it
and the only msedge.exe on this machine (2026-10-24); no image model is
needed. A throwaway --user-data-dir keeps the render off the user's running
browser and its profile.

THE PNG IS CHECKED, NOT TRUSTED. A wrong --window-size or display scale
yields a correct-looking image at the wrong size, with no error, so a run
fails unless the PNG's IHDR says 1280x640 and the file is at most 1 MB,
GitHub's upload limit. Exit 0: written, and the PNG checked. Exit 1: the
PNG failed a check. Exit 2: nothing rendered, from a bad spec or argument,
no Edge, or an Edge that wrote no PNG.

Stdlib only.
"""

import argparse
import html
import json
import re
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

WIDTH, HEIGHT = 1280, 640
MAX_BYTES = 1_000_000  # GitHub's 1 MB, read as decimal so a card near it errs small
FULL_NAME_CHARS = 18  # monospace characters at 96px that fit the 1080px column
NAME_PX, MIN_NAME_PX = 96, 56
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
SPEC_KEYS = ("owner", "name", "accent", "tagline", "chips", "foot_left", "foot_right")
EDGE_PATHS = (
    Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"),
    Path(r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"),
)
TEMPLATE = Path(__file__).resolve().parent.parent / "assets" / "card-template.html"
BOLD = re.compile(r"\*\*(.+?)\*\*")
PLACEHOLDER = re.compile(r"\{\{(\w+)\}\}")


class CardError(Exception):
    """A spec, argument or render that leaves nothing to check: exit 2."""


def load_spec(path: Path) -> dict:
    """Read and validate the spec, naming the first key that is wrong."""
    try:
        spec = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise CardError(f"cannot read the spec {path}: {exc}") from exc
    if not isinstance(spec, dict):
        raise CardError("the spec must be a JSON object")
    missing = [key for key in SPEC_KEYS if key not in spec]
    if missing:
        raise CardError(f"the spec lacks {', '.join(missing)}")
    for key in SPEC_KEYS:
        if key == "chips":
            if not isinstance(spec[key], list) or not all(isinstance(c, str) for c in spec[key]):
                raise CardError("chips must be a list of strings")
        elif not isinstance(spec[key], str):
            raise CardError(f"{key} must be a string")
    if not spec["name"].strip():
        raise CardError("name is empty")
    if len(spec["accent"]) > 1:
        raise CardError("accent is one character, or empty")
    if spec["accent"] and spec["accent"] not in spec["name"]:
        raise CardError(f"accent {spec['accent']!r} is not in the name {spec['name']!r}")
    return spec


def name_html(name: str, accent: str) -> str:
    """The name, escaped, with the accent's first occurrence in a span."""
    if not accent:
        return html.escape(name)
    before, _, after = name.partition(accent)
    return (f'{html.escape(before)}<span class="accent">{html.escape(accent)}</span>'
            f"{html.escape(after)}")


def name_size(name: str) -> int:
    """96px, shrunk in proportion past 18 characters so the name stays on one line."""
    if len(name) <= FULL_NAME_CHARS:
        return NAME_PX
    return max(MIN_NAME_PX, NAME_PX * FULL_NAME_CHARS // len(name))


def tagline_html(tagline: str) -> str:
    """The tagline, escaped, then each **span** made bold."""
    return BOLD.sub(r"<b>\1</b>", html.escape(tagline))


def fill(spec: dict) -> str:
    """The template with every placeholder replaced, in one pass.

    One pass, so a value that happens to hold {{key}} text is never filled
    in turn; a placeholder the template has and no value fills is refused.
    """
    template = TEMPLATE.read_text(encoding="utf-8")
    values = {
        "name": html.escape(spec["name"]),
        "owner": html.escape(spec["owner"]),
        "name_html": name_html(spec["name"], spec["accent"]),
        "name_size": str(name_size(spec["name"])),
        "tagline_html": tagline_html(spec["tagline"]),
        "chips_html": "".join(f'<span class="chip">{html.escape(c)}</span>'
                              for c in spec["chips"]),
        "foot_left": html.escape(spec["foot_left"]),
        "foot_right": html.escape(spec["foot_right"]),
    }
    unfilled = sorted(set(PLACEHOLDER.findall(template)) - values.keys())
    if unfilled:
        raise CardError(f"the template has placeholders no value fills: {', '.join(unfilled)}")
    return PLACEHOLDER.sub(lambda match: values[match.group(1)], template)


def find_edge() -> Path:
    for path in EDGE_PATHS:
        if path.is_file():
            return path
    raise CardError("no msedge.exe at " + " or ".join(str(p) for p in EDGE_PATHS))


def render(page: Path, png: Path) -> None:
    """Screenshot the page with headless Edge; raise unless a PNG appears."""
    edge = find_edge()
    png.unlink(missing_ok=True)
    with tempfile.TemporaryDirectory(prefix="render-card-") as profile:
        args = [str(edge), "--headless=new", "--disable-gpu", "--hide-scrollbars",
                "--force-device-scale-factor=1", "--no-first-run",
                f"--user-data-dir={profile}", f"--window-size={WIDTH},{HEIGHT}",
                f"--screenshot={png.resolve()}", page.resolve().as_uri()]
        try:
            result = subprocess.run(args, capture_output=True, timeout=120)
        except subprocess.TimeoutExpired as exc:
            raise CardError("Edge did not finish within 120 s") from exc
    if not png.is_file():
        stderr = result.stderr.decode("utf-8", "replace").strip()
        raise CardError(f"Edge exited {result.returncode} and wrote no PNG: {stderr}")


def check(png: Path) -> list[str]:
    """Each way the PNG falls short of GitHub's card; empty when it passes."""
    data = png.read_bytes()
    if data[:8] != PNG_SIGNATURE or data[12:16] != b"IHDR":
        return [f"{png} is not a PNG"]
    width, height = struct.unpack(">II", data[16:24])
    problems = []
    if (width, height) != (WIDTH, HEIGHT):
        problems.append(f"{png} is {width}x{height}, not {WIDTH}x{HEIGHT}")
    if len(data) > MAX_BYTES:
        problems.append(f"{png} is {len(data):,} bytes, over GitHub's 1 MB")
    return problems


def main() -> int:
    ap = argparse.ArgumentParser(description="Fill and render the social-card template.")
    ap.add_argument("spec", nargs="?", type=Path, help="the card's spec, a JSON object")
    ap.add_argument("--out", type=Path, help="directory for social-preview.html and .png")
    ap.add_argument("--no-render", action="store_true", help="write the HTML only")
    ap.add_argument("--html", type=Path, help="render this filled card to the PNG beside it")
    ap.add_argument("--check", type=Path, help="check this PNG only")
    args = ap.parse_args()

    try:
        if args.check:
            if not args.check.is_file():
                raise CardError(f"no file at {args.check}")
            png = args.check
        elif args.html:
            if not args.html.is_file():
                raise CardError(f"no file at {args.html}")
            png = args.html.with_suffix(".png")
            render(args.html, png)
        else:
            if not args.spec or not args.out:
                raise CardError("pass a spec and --out, or --html, or --check")
            spec = load_spec(args.spec)
            args.out.mkdir(parents=True, exist_ok=True)
            page = args.out / "social-preview.html"
            page.write_bytes(fill(spec).encode("utf-8"))
            print(f"wrote {page}")
            if args.no_render:
                return 0
            png = args.out / "social-preview.png"
            render(page, png)
    except CardError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    problems = check(png)
    for problem in problems:
        print(f"FAIL  {problem}", file=sys.stderr)
    if problems:
        return 1
    print(f"ok    {png}: {WIDTH}x{HEIGHT}, {png.stat().st_size:,} bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
