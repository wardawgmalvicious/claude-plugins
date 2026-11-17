#!/usr/bin/env python3
"""Report what a Claude Code session cost, by phase, by model and by subagent.

    uv run --no-project <skill>/scripts/measure-session-cost.py           # this session so far
    uv run --no-project <skill>/scripts/measure-session-cost.py 52c8d3dd  # by id or its start
    uv run --no-project <skill>/scripts/measure-session-cost.py --repo my-repo --last 3
    uv run --no-project <skill>/scripts/measure-session-cost.py --json 52c8d3dd

<skill> is the measure-session-cost skill's folder, wherever it is installed;
--no-project keeps uv from syncing the Python project of whatever repo it runs in.

Each API call's bill is its context, read from or written to the prompt cache, times
the number of calls, plus its output: a long session is dear because each call carries
everything before it, read or written, not because of what it outputs. So this reports,
per session, the calls and their context, average and peak, priced by part -- uncached
input, cache write, cache read, output -- per model; the context at the first call,
which the session paid before any work; each phase, split at a compaction and at a gap
over IDLE_GAP, the one-hour cache's life; each call that rewrote most of its context to
the cache, and why; the tools called and the size of what they returned; and each
subagent.

It reads <config>/projects/<project>/<id>.jsonl and each subagent's
<id>/subagents/agent-*.jsonl, with the agent's type and model from its .meta.json, in
every account's config directory, which find-session.py's config_dirs() lists. A
transcript Claude Code set aside, <id>.orphaned-<timestamp>-<suffix>.jsonl, is skipped.
The transcript format is internal and may change in any release: transcripts with
assistant records but no usage in them exit 2.

Claude Code writes one line per content block, each repeating its message's id and
usage, so a message is counted once. Prices are list prices per million tokens, in one
dated table below; a model, speed or usage shape the table does not price is counted
and reported as unpriced, never guessed. A compaction's own API call writes no
assistant record, so it is named, with the context it summarized, and not priced; nor
does an away summary's or a prompt suggestion's. Claude Code's own total, which holds
the first two's calls by the gap they leave, and a suggestion's by inference, is read
from the last cost-state record and printed beside this one: a session's
process writes one as it ends, each holding the session's total so far, so a session
still running has none to compare, and a missing or reshaped one fails nothing. One whose
hasUnknownModelCost is true, Claude Code having no price for a model it called, is noted
beside its total, which may then be off for that model's calls.

Exits 1 when no session matches. No dependencies; the script's suite, in the repo this
skill is authored in, holds each case.
"""

from __future__ import annotations

import argparse
import importlib.util
import io
import json
import math
import os
import sys
from collections import Counter
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import NamedTuple


class Price(NamedTuple):
    """USD per million tokens, for each part of a call."""

    uncached: float
    write_5m: float
    write_1h: float
    read: float
    output: float


# Anthropic's list prices, read from the pricing page on PRICES_AS_OF. Update the date
# with any row. A model absent here is reported unpriced, not guessed: a throwaway
# script that guessed ran about 1.7 times high (2026-11-05).
PRICES_AS_OF = "2026-11-15"
PRICES_SOURCE = "https://platform.claude.com/docs/en/about-claude/pricing"
PRICES = {
    "claude-fable-5-2": Price(8, 10, 16, 0.20, 40),
    "claude-mythos-5-2": Price(8, 10, 16, 0.20, 40),
    "claude-fable-5-1": Price(10, 12.50, 20, 0.25, 50),
    "claude-mythos-5-1": Price(10, 12.50, 20, 0.25, 50),
    "claude-fable-5": Price(10, 12.50, 20, 1, 50),
    "claude-opus-5-5": Price(4, 5, 8, 0.20, 20),
    "claude-sonnet-5-5": Price(2, 2.50, 4, 0.10, 10),
    "claude-sonnet-5": Price(2, 2.50, 4, 0.20, 10),
    "claude-haiku-5-5": Price(0.10, 0.125, 0.20, 0.01, 0.50),
}
# A call whose prompt -- input, cache reads and cache writes -- passes the threshold
# pays the second row, for that call alone.
LONG_PROMPT = {"claude-haiku-5-5": (100_000, Price(0.50, 0.625, 1, 0.05, 2.50))}
# usage.speed "fast": input and output from the page's fast-mode table, Fable 5.2 and
# Mythos 5.2 at $16 / $80 and Opus 5.5 at $8 / $40, with each model's caching
# multipliers on top.
FAST = {
    "claude-fable-5-2": Price(16, 20, 32, 0.40, 80),
    "claude-mythos-5-2": Price(16, 20, 32, 0.40, 80),
    "claude-opus-5-5": Price(8, 10, 16, 0.40, 40),
}
US_ONLY = 1.1  # usage.inference_geo "us": every category
WEB_SEARCH = 10 / 1000  # per search, on top of tokens

# Seconds: past this, the one-hour cache has expired. By default Claude Code asks for the
# hour for the main thread only on a subscription within plan usage; an API key, usage
# credits or a cloud provider get five minutes there, and subagents five minutes either
# way, unless promptCacheTtl or subagentPromptCacheTtl, or its CLAUDE_CODE_*_CACHE_TTL
# variable, sets one (Claude Code docs, prompt-caching#choose-the-ttl-yourself,
# 2026-11-05). On five minutes a shorter gap rewrites the cache too, and its rewrite
# reads as a miss mid-phase.
IDLE_GAP = 3600
REWRITE_SHARE = 0.5  # a call writing at least this share of its prompt to the cache...
REWRITE_MIN = 20_000  # ...and at least this many tokens rewrote it
SKIP_MODELS = {"<synthetic>"}  # Claude Code's own placeholder messages, never billed
# Request records (2.1.300+) carry no usage: skipped unparsed, as find-session.py does.
API_REQUEST = ('{"type":"api-request"', '{"type":"api-request-blob"',
               '{"type":"api-request-shape"')
SAME = 0.005  # USD: Claude Code's total and this one agree within half a cent
NO_RECORD = "no cost-state record"  # harness()'s note, and print_harness()'s cue
# harness()'s note beside a total, from the record's hasUnknownModelCost. Which model
# Claude Code could not price, and at what rate it counted it, is not recorded, so the
# note says "may".
UNKNOWN_MODEL = ("Claude Code had no price for a model it called (hasUnknownModelCost), "
                 "so its total may be off for that model's calls")


@dataclass
class Call:
    """One API call: one assistant message id, its usage counted once."""

    ts: str
    model: str
    uncached: int
    read: int
    write_5m: int
    write_1h: int
    output: int
    searches: int = 0
    speed: str = "standard"
    geo: str = ""
    split_known: bool = True  # usage.cache_creation present, or nothing written

    @property
    def write(self) -> int:
        """Tokens written to the cache, at either lifetime."""
        return self.write_5m + self.write_1h

    @property
    def prompt(self) -> int:
        """The call's whole context: uncached input, cache reads and cache writes."""
        return self.uncached + self.read + self.write


def price_of(call: Call) -> tuple[dict[str, float] | None, str]:
    """A call's cost by part, or None and why it is unpriced.

    Args:
        call: One API call's usage.

    Returns:
        USD per part -- input, write, read, output, search -- and "", or None and the
        reason the table cannot price the call.
    """
    if not call.split_known:
        return None, "cache write with no 5m/1h split"
    standard = call.speed in ("standard", "")
    table = FAST if call.speed == "fast" else PRICES if standard else {}
    row = table.get(call.model)
    if row is None:
        what = call.model if standard else f"{call.model} at speed {call.speed}"
        return None, f"no price for {what}"
    long_prompt = LONG_PROMPT.get(call.model)
    if long_prompt and call.speed != "fast" and call.prompt > long_prompt[0]:
        row = long_prompt[1]
    scale = (US_ONLY if call.geo == "us" else 1) / 1_000_000
    return {
        "input": call.uncached * row.uncached * scale,
        "write": (call.write_5m * row.write_5m + call.write_1h * row.write_1h) * scale,
        "read": call.read * row.read * scale,
        "output": call.output * row.output * scale,
        "search": call.searches * WEB_SEARCH,
    }, ""


@dataclass
class Transcript:
    """What one transcript file records: its calls, compactions, tools and agents."""

    path: Path
    calls: list[Call] = field(default_factory=list)
    compactions: list[tuple[str, dict]] = field(default_factory=list)  # (ts, compactMetadata)
    tool_calls: Counter = field(default_factory=Counter)  # tool name -> calls
    tool_chars: Counter = field(default_factory=Counter)  # tool name -> result characters
    agents: dict[str, str] = field(default_factory=dict)  # agent id -> its description
    assistant_records: int = 0  # every model's but SKIP_MODELS'
    away_summaries: int = 0  # system records of subtype away_summary
    cost_state: dict | None = None  # the last cost-state record
    calls_after_cost_state: int = 0  # calls read after it
    cwd: str = ""
    name: str = ""
    ai_title: str = ""
    first: str = ""
    last: str = ""


def result_chars(content: object) -> int:
    """The text a tool result put in context, in characters; images are not counted."""
    if isinstance(content, str):
        return len(content)
    if isinstance(content, list):
        return sum(len(block.get("text", "")) for block in content
                   if isinstance(block, dict) and block.get("type") == "text")
    return 0


def read_transcript(path: Path, seen: set[str] | None = None) -> Transcript:
    """Every API call, compaction and tool call in one transcript file.

    Args:
        path: A session's or a subagent's .jsonl.
        seen: Message ids already counted, shared across one session's files, so a
            message written to two files is counted once. Updated in place.

    Returns:
        The transcript's calls, in time order, and what else it records.
    """
    transcript = Transcript(path)
    seen = set() if seen is None else seen
    names: dict[str, str] = {}  # tool_use id -> tool name
    asked: dict[str, str] = {}  # tool_use id -> the description in its input
    with path.open(encoding="utf-8", errors="replace") as handle:
        for line in handle:
            if line.startswith(API_REQUEST):
                continue
            try:
                record = json.loads(line)
            except ValueError:
                continue
            if not isinstance(record, dict):
                continue
            kind = record.get("type")
            ts = record.get("timestamp")
            if isinstance(ts, str):
                transcript.first = transcript.first or ts
                transcript.last = max(transcript.last, ts)
            transcript.cwd = transcript.cwd or record.get("cwd") or ""
            if kind == "custom-title":
                transcript.name = record.get("customTitle") or transcript.name
            elif kind == "ai-title":
                transcript.ai_title = record.get("aiTitle") or transcript.ai_title
            elif kind == "system" and record.get("subtype") == "compact_boundary":
                transcript.compactions.append((ts or "", record.get("compactMetadata") or {}))
            elif kind == "system" and record.get("subtype") == "away_summary":
                transcript.away_summaries += 1
            elif kind == "cost-state":
                transcript.cost_state = record
                transcript.calls_after_cost_state = 0
            elif kind == "assistant":
                message = record.get("message") or {}
                for block in message.get("content") or []:
                    if not isinstance(block, dict) or block.get("type") != "tool_use":
                        continue
                    use_id = str(block.get("id") or "")
                    if use_id in names:
                        continue
                    names[use_id] = block.get("name") or "?"
                    transcript.tool_calls[names[use_id]] += 1
                    given = block.get("input")
                    description = given.get("description") if isinstance(given, dict) else None
                    if isinstance(description, str):
                        asked[use_id] = description
                model = message.get("model") or "?"
                # A placeholder is no call, so it is no record either: counted, a
                # session of placeholders alone would read as a changed format.
                if model in SKIP_MODELS:
                    continue
                transcript.assistant_records += 1
                usage = message.get("usage")
                message_id = str(message.get("id") or record.get("uuid") or "")
                if not isinstance(usage, dict) or message_id in seen:
                    continue
                seen.add(message_id)
                split = usage.get("cache_creation")
                written = usage.get("cache_creation_input_tokens") or 0
                if isinstance(split, dict):
                    written_5m = split.get("ephemeral_5m_input_tokens") or 0
                    written_1h = split.get("ephemeral_1h_input_tokens") or 0
                else:
                    written_5m, written_1h = written, 0
                server_tools = usage.get("server_tool_use") or {}
                transcript.calls.append(Call(
                    ts=ts or "", model=model, uncached=usage.get("input_tokens") or 0,
                    read=usage.get("cache_read_input_tokens") or 0,
                    write_5m=written_5m, write_1h=written_1h,
                    output=usage.get("output_tokens") or 0,
                    searches=server_tools.get("web_search_requests") or 0,
                    speed=usage.get("speed") or "standard",
                    geo=usage.get("inference_geo") or "",
                    split_known=isinstance(split, dict) or not written))
                transcript.calls_after_cost_state += 1
            elif kind == "user":
                content = (record.get("message") or {}).get("content")
                use_id = ""
                for block in content if isinstance(content, list) else []:
                    if isinstance(block, dict) and block.get("type") == "tool_result":
                        use_id = str(block.get("tool_use_id") or "")
                        tool = names.get(use_id, "?")
                        transcript.tool_chars[tool] += result_chars(block.get("content"))
                # An Agent call's result names its agent: its description, given or in the
                # call's input, or the forked skill it ran.
                result = record.get("toolUseResult")
                if isinstance(result, dict) and isinstance(result.get("agentId"), str):
                    skill = result.get("commandName")
                    transcript.agents[result["agentId"]] = (
                        result.get("description") or asked.get(use_id)
                        or (f"/{skill}" if skill else ""))
    transcript.calls.sort(key=lambda call: call.ts)
    return transcript


def config_dirs() -> list[tuple[str, Path]]:
    """Every account's config directory, through find-session.py's reader of the map.

    Its sibling in the meta group, deployed beside this one; loaded from its file, since
    a hyphen makes it un-importable by name. Not resolved, so a junction's path stands.

    Returns:
        Each account's name and directory, this account's first; only its own, with a
        warning, when find-session.py does not load.
    """
    finder = Path(__file__).parent.parent.parent / "find-session" / "scripts" / "find-session.py"
    try:
        spec = importlib.util.spec_from_file_location("find_session", finder)
        if spec is None or spec.loader is None:
            raise ImportError(f"no loader for {finder}")
        module = importlib.util.module_from_spec(spec)
        sys.modules["find_session"] = module  # dataclasses look their module up here
        spec.loader.exec_module(module)
        return module.config_dirs()
    # Running another file's code can raise anything, a SyntaxError or a TypeError from
    # an edit to it among them, and the documented fallback is this warning.
    except Exception as exc:
        own = Path(os.environ.get("CLAUDE_CONFIG_DIR") or Path.home() / ".claude")
        print(f"warning: find-session.py did not load ({exc}), so only {own} is read",
              file=sys.stderr)
        return [("", own)]


def repo_of(cwd: str) -> str:
    """The repo a working directory sits in, by its folder name, a worktree as its repo."""
    cwd = cwd.replace("\\", "/").rstrip("/").split("/.claude/worktrees/")[0]
    return cwd.rsplit("/", 1)[-1] or "?"


def cwd_of(path: Path) -> str:
    """The first cwd a transcript records, read no further than it; "" if it is gone."""
    try:
        with path.open(encoding="utf-8", errors="replace") as handle:
            for line in handle:
                if '"cwd"' not in line or line.startswith(API_REQUEST):
                    continue
                try:
                    record = json.loads(line)
                except ValueError:
                    continue
                if isinstance(record, dict) and isinstance(record.get("cwd"), str):
                    return record["cwd"]
    except OSError:  # deleted since the glob, by the retention sweep
        pass
    return ""


def pick(args: argparse.Namespace) -> list[tuple[Path, str]]:
    """The transcripts asked for, newest first.

    Args:
        args: The parsed command line: a session id, --repo with --last, or neither.

    Returns:
        Each session's transcript and its account's name, "" for this account's own.
    """
    found: list[tuple[float, Path, str]] = []
    for index, (account, config) in enumerate(config_dirs()):
        for path in (config / "projects").glob("*/*.jsonl"):
            # <id>.orphaned-<timestamp>-<suffix>.jsonl is a copy Claude Code set aside,
            # not a session: counted, it doubles every message of the one it copies.
            if "." in path.stem:
                continue
            try:
                mtime = path.stat().st_mtime
            except OSError:  # deleted since the glob, by the retention sweep
                continue
            found.append((mtime, path, account if index else ""))
    found.sort(key=lambda entry: entry[0], reverse=True)
    newest = [(path, account) for _, path, account in found]
    asking = os.environ.get("CLAUDE_CODE_SESSION_ID")
    if args.session:
        hits = [hit for hit in newest if hit[0].stem.startswith(args.session)]
        exact = [hit for hit in hits if hit[0].stem == args.session]
        if len(hits) > 1 and not exact:
            ids = ", ".join(hit[0].stem for hit in hits[:5])
            raise SystemExit(f"error: {len(hits)} sessions start {args.session}: {ids}; "
                             "give more of the id")
        return exact or hits
    if args.repo:
        chosen = []
        for path, account in newest:
            if path.stem != asking and repo_of(cwd_of(path)).lower() == args.repo.lower():
                chosen.append((path, account))
                if len(chosen) == args.last:
                    break
        return chosen
    if not asking:
        raise SystemExit("error: name a session id, or --repo <folder> with --last <n>; "
                         "CLAUDE_CODE_SESSION_ID is unset, so there is no current session")
    return [hit for hit in newest if hit[0].stem == asking]


def sum_costs(calls: list[Call]) -> tuple[dict[str, float], list[tuple[Call, str]]]:
    """The calls' cost by part, and each call left unpriced with why."""
    total = {"input": 0.0, "write": 0.0, "read": 0.0, "output": 0.0, "search": 0.0}
    unpriced = []
    for call in calls:
        cost, why = price_of(call)
        if cost is None:
            unpriced.append((call, why))
            continue
        for part, amount in cost.items():
            total[part] += amount
    return total, unpriced


def by_model(calls: list[Call]) -> list[dict]:
    """One row per model: its calls, their context, tokens and cost by part."""
    rows = []
    for model in sorted({call.model for call in calls}):
        mine = [call for call in calls if call.model == model]
        cost, unpriced = sum_costs(mine)
        rows.append({
            "model": model, "calls": len(mine),
            "avg_context": round(sum(call.prompt for call in mine) / len(mine)),
            "peak_context": max(call.prompt for call in mine),
            "tokens": {"input": sum(call.uncached for call in mine),
                       "write": sum(call.write for call in mine),
                       "read": sum(call.read for call in mine),
                       "output": sum(call.output for call in mine)},
            "cost": {part: round(amount, 6) for part, amount in cost.items()},
            "total": round(sum(cost.values()), 6),
            "unpriced_calls": len(unpriced),
        })
    return rows


def seconds_between(start: str, end: str) -> float:
    """The seconds from one ISO stamp to another; 0 when either does not parse."""
    try:
        return (datetime.fromisoformat(end.replace("Z", "+00:00"))
                - datetime.fromisoformat(start.replace("Z", "+00:00"))).total_seconds()
    except ValueError:
        return 0.0


def phases(transcript: Transcript) -> list[dict]:
    """The main thread's calls, split at each compaction and each gap over IDLE_GAP."""
    out: list[dict] = []
    pending = sorted(transcript.compactions, key=lambda boundary: boundary[0])
    prev = None
    for call in transcript.calls:
        why = ""
        while pending and pending[0][0] <= call.ts:  # every compaction since the last call
            meta = pending.pop(0)[1]
            why = (f"compacted ({meta.get('trigger', '?')}), "
                   f"{tokens(meta.get('preTokens'))} to {tokens(meta.get('postTokens'))}")
        if prev is not None and not why:
            gap = seconds_between(prev.ts, call.ts)
            if gap > IDLE_GAP:
                why = f"after {gap / 3600:.1f} h idle"
        if prev is None or why:
            out.append({"start": call.ts, "why": why or "start", "calls": []})
        out[-1]["calls"].append(call)
        prev = call
    for phase in out:
        calls = phase["calls"]
        cost, unpriced = sum_costs(calls)
        phase.update(first_context=calls[0].prompt,
                     peak_context=max(call.prompt for call in calls),
                     last_context=calls[-1].prompt, total=round(sum(cost.values()), 6),
                     unpriced_calls=len(unpriced))
    return out


def rewrites(transcript: Transcript, split: list[dict]) -> list[dict]:
    """Calls that wrote most of their context to the cache, each with its likeliest cause."""
    starts = {id(phase["calls"][0]): phase["why"] for phase in split}
    out = []
    prev = None
    for call in transcript.calls:
        if call.write >= REWRITE_MIN and call.write >= REWRITE_SHARE * call.prompt:
            why = starts.get(id(call), "")
            if why == "start":
                why = "the session's first call"
            elif why.startswith("compacted"):
                why = "after a compaction"
            elif why:
                why += ": the one-hour cache had expired"
            elif prev is not None and prev.model != call.model:
                why = f"model switched from {prev.model}: a cache serves only its own model"
            else:
                why = "cache miss mid-phase"
            cost, _ = price_of(call)
            out.append({"ts": call.ts, "model": call.model, "written": call.write,
                        "context": call.prompt,
                        "write_cost": round(cost["write"], 6) if cost else None, "why": why})
        prev = call
    return out


def tools_table(transcript: Transcript) -> list[dict]:
    """Each tool called, most called first, with the characters its results returned."""
    return [{"tool": name, "calls": count, "result_chars": transcript.tool_chars.get(name, 0)}
            for name, count in transcript.tool_calls.most_common()]


def usd(value: object) -> float | None:
    """A finite number of dollars, or None; json.loads reads NaN, and True is an int."""
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    try:
        number = float(value)
    except OverflowError:  # an int past a float's range, which json.loads keeps exact
        return None
    return round(number, 6) if math.isfinite(number) else None


def harness(transcript: Transcript) -> tuple[float | None, dict[str, float], str | None]:
    """Claude Code's own total, from the transcript's last cost-state record.

    The record's format is undocumented, so a missing or reshaped one is a note, never an
    error: the script's own total stands without it.

    Args:
        transcript: The session's main transcript.

    Returns:
        The total, None when there is none to compare; the cost per model the record
        gives; and a note: why there is no total, or, beside one, UNKNOWN_MODEL when the
        record's hasUnknownModelCost is true; else None.
    """
    record = transcript.cost_state
    if record is None:
        return None, {}, NO_RECORD
    total = usd(record.get("totalCostUSD"))
    if total is None:
        return None, {}, "no totalCostUSD in its cost-state record"
    if transcript.calls_after_cost_state:
        return None, {}, (f"{plural(transcript.calls_after_cost_state, 'call')} after its "
                          "last cost-state record")
    usage = record.get("modelUsage")
    models = {}
    for model, row in usage.items() if isinstance(usage, dict) else []:
        cost = usd(row.get("costUSD")) if isinstance(row, dict) else None
        if cost is not None:
            models[model] = cost
    # Only a JSON true counts: a reshaped flag is left unread, as a reshaped row is.
    note = UNKNOWN_MODEL if record.get("hasUnknownModelCost") is True else None
    return total, models, note


def measure(path: Path, account: str) -> dict:
    """One session's report, its subagents' transcripts read beside its own.

    Args:
        path: The session's transcript.
        account: The account whose config directory holds it, "" for this one's own.

    Returns:
        The report, as --json prints it, plus "_records" and "_calls", which main()
        checks and drops.
    """
    seen: set[str] = set()
    main_thread = read_transcript(path, seen)
    agents = []
    folder = path.with_suffix("") / "subagents"
    for agent_path in sorted(folder.rglob("agent-*.jsonl")) if folder.is_dir() else []:
        agent_transcript = read_transcript(agent_path, seen)
        try:
            meta = json.loads(agent_path.with_suffix(".meta.json").read_text(encoding="utf-8"))
        except (OSError, ValueError):
            meta = {}
        agent_id = agent_path.stem.removeprefix("agent-")
        agent_calls = agent_transcript.calls
        cost, unpriced = sum_costs(agent_calls)
        agents.append({
            "id": agent_id, "type": meta.get("agentType") or "?",
            "model": (meta.get("model")
                      or ", ".join(sorted({call.model for call in agent_calls})) or "?"),
            "description": main_thread.agents.get(agent_id, ""), "calls": len(agent_calls),
            "peak_context": max((call.prompt for call in agent_calls), default=0),
            "total": round(sum(cost.values()), 6), "unpriced_calls": len(unpriced),
            "by_model": by_model(agent_calls), "tools": tools_table(agent_transcript),
            "_transcript": agent_transcript,
        })
    split = phases(main_thread)
    main_cost, main_unpriced = sum_costs(main_thread.calls)
    unpriced = [why for _, why in main_unpriced]
    for agent in agents:
        unpriced += [why for _, why in sum_costs(agent["_transcript"].calls)[1]]
    main_total = sum(main_cost.values())
    agents_total = sum(agent["total"] for agent in agents)
    harness_total, harness_models, harness_note = harness(main_thread)
    records = main_thread.assistant_records + sum(
        agent["_transcript"].assistant_records for agent in agents)
    return {
        "session_id": path.stem, "repo": repo_of(main_thread.cwd), "cwd": main_thread.cwd,
        "title": main_thread.name or main_thread.ai_title, "first_active": main_thread.first,
        "last_active": main_thread.last, "config_dir": str(path.parent.parent.parent),
        "other_account": account or None,
        "prices_as_of": PRICES_AS_OF,
        "startup_context": main_thread.calls[0].prompt if main_thread.calls else 0,
        "main": {"calls": len(main_thread.calls), "total": round(main_total, 6),
                 "by_model": by_model(main_thread.calls), "tools": tools_table(main_thread)},
        "phases": [{key: value for key, value in phase.items() if key != "calls"}
                   | {"calls": len(phase["calls"])} for phase in split],
        "compactions": [{"ts": ts, "trigger": meta.get("trigger"),
                         "pre_tokens": meta.get("preTokens"),
                         "post_tokens": meta.get("postTokens")}
                        for ts, meta in main_thread.compactions],
        "away_summaries": main_thread.away_summaries,
        "rewrites": rewrites(main_thread, split),
        "subagents": [{key: value for key, value in agent.items() if key != "_transcript"}
                      for agent in agents],
        "subagents_total": round(agents_total, 6),
        "total": round(main_total + agents_total, 6),
        "harness_total": harness_total,
        "harness_by_model": harness_models,
        "harness_note": harness_note,
        "unpriced": dict(Counter(unpriced)),
        "_records": records,
        "_calls": len(main_thread.calls) + sum(len(agent["_transcript"].calls)
                                               for agent in agents),
    }


def tokens(count: object) -> str:
    """A token count as 12.3k, or "?" when it is not a number."""
    if not isinstance(count, (int, float)):
        return "?"
    return f"{count / 1000:.1f}k" if count >= 1000 else str(int(count))


def local_time(stamp: str, fmt: str = "%Y-%m-%d %H:%M") -> str:
    """A UTC stamp in local time; its first 16 characters when it does not parse."""
    try:
        return datetime.fromisoformat(stamp.replace("Z", "+00:00")).astimezone().strftime(fmt)
    except ValueError:
        return stamp[:16]


def money(amount: float) -> str:
    """USD to the cent."""
    return f"${amount:,.2f}"


def plural(count: int, noun: str) -> str:
    """The count and the noun, an s added for any count but 1."""
    return f"{count} {noun}" + ("" if count == 1 else "s")


def print_models(rows: list[dict], indent: str) -> None:
    """Print by_model()'s rows as a table."""
    print(f"{indent}{'model':<20}{'calls':>6}{'avg ctx':>9}{'peak ctx':>10}"
          f"{'input':>9}{'write':>9}{'read':>9}{'output':>9}{'total':>9}")
    for row in rows:
        cost = row["cost"]
        note = f"  ({row['unpriced_calls']} unpriced)" if row["unpriced_calls"] else ""
        if cost["search"]:
            note += f"  (with {money(cost['search'])} of web search)"
        print(f"{indent}{row['model']:<20}{row['calls']:>6}{tokens(row['avg_context']):>9}"
              f"{tokens(row['peak_context']):>10}{money(cost['input']):>9}"
              f"{money(cost['write']):>9}{money(cost['read']):>9}{money(cost['output']):>9}"
              f"{money(row['total']):>9}{note}")


def print_harness(session: dict) -> None:
    """Print Claude Code's own total beside the script's, and what the gap holds."""
    own = session["harness_total"]
    if own is None:
        why = session["harness_note"]
        if why == NO_RECORD:
            why += (", which a session's process writes as it ends: "
                    "a session still running has none")
        print(f"  Claude Code's own total: none to compare, {why}")
        return
    gap = own - session["total"]
    line = f"  Claude Code's own total, from cost-state: {money(own)}"
    # The note qualifies every reading of the gap, so it follows each.
    unknown = f"; {UNKNOWN_MODEL}" if session["harness_note"] == UNKNOWN_MODEL else ""
    if abs(gap) < SAME:
        print(f"{line}, the same{unknown}")
        return
    if gap < 0:
        print(f"{line}, {money(-gap)} below{unknown}")
        return
    compactions, away = len(session["compactions"]), session["away_summaries"]
    causes = ([plural(compactions, "compaction")] if compactions else []) + (
        [f"{away} away summar{'y' if away == 1 else 'ies'}"] if away else [])
    # A prompt suggestion writes no record at all, so it is named as possible, not counted.
    named = ", ".join(causes) + (" and " if causes else "") + "any prompt suggestions"
    unpriced = sum(session["unpriced"].values())
    also = f"; and {plural(unpriced, 'unpriced call')}" if unpriced else ""
    print(f"{line}, {money(gap)} above, for calls with no message record: "
          f"{named}{also}{unknown}")


def report(session: dict) -> None:
    """Print one session's report as text, in local time."""
    title = f"  {session['title']}" if session["title"] else ""
    print(f"{session['session_id']}  {session['repo']}{title}")
    print(f"  {local_time(session['first_active'])} to "
          f"{local_time(session['last_active'], '%Y-%m-%d %H:%M')}, local time")
    if session["other_account"]:
        print(f"  under the {session['other_account']} account's {session['config_dir']}")
    main_thread = session["main"]
    agents = (f"{plural(len(session['subagents']), 'subagent')} "
              f"{money(session['subagents_total'])}" if session["subagents"] else "no subagents")
    print(f"  total {money(session['total'])} at list prices of {session['prices_as_of']}: "
          f"main thread {money(main_thread['total'])} over "
          f"{plural(main_thread['calls'], 'call')}, {agents}")
    print_harness(session)
    if not main_thread["calls"]:
        print("  no API calls recorded")
        return
    print(f"  start-up: {tokens(session['startup_context'])} tokens of context at the first call")
    print_models(main_thread["by_model"], "  ")
    print("  phases:")
    for number, phase in enumerate(session["phases"], 1):
        why = "" if phase["why"] == "start" else f"  {phase['why']}"
        print(f"    {number}  {local_time(phase['start'], '%m-%d %H:%M')}  {phase['calls']} "
              f"calls, context {tokens(phase['first_context'])} to "
              f"{tokens(phase['last_context'])}, peak {tokens(phase['peak_context'])}, "
              f"{money(phase['total'])}{why}")
    if session["compactions"]:
        summarized = ", ".join(tokens(compaction["pre_tokens"])
                               for compaction in session["compactions"])
        print(f"  each compaction's own call writes no record, so is not priced: it read the "
              f"context it summarized ({summarized})")
    if session["rewrites"]:
        print(f"  rewrites (a call writing at least half its context, {tokens(REWRITE_MIN)} "
              f"or more, to the cache):")
        for rewrite in session["rewrites"]:
            cost = (money(rewrite["write_cost"]) if rewrite["write_cost"] is not None
                    else "unpriced")
            print(f"    {local_time(rewrite['ts'], '%m-%d %H:%M')}  "
                  f"{tokens(rewrite['written'])} written, {cost}  {rewrite['why']}")
    if main_thread["tools"]:
        print("  tools (main thread): calls, result text")
        for row in main_thread["tools"]:
            print(f"    {row['tool']:<24}{row['calls']:>5}{row['result_chars'] / 1024:>9.0f} KB")
    if session["subagents"]:
        print("  subagents:")
        for agent in sorted(session["subagents"], key=lambda agent: -agent["total"]):
            desc = f"  {agent['description'][:50]}" if agent["description"] else ""
            note = f" ({agent['unpriced_calls']} unpriced)" if agent["unpriced_calls"] else ""
            print(f"    {agent['id'][:8]}  {agent['type']:<16} {agent['model']:<18}"
                  f"{agent['calls']:>5} calls, peak {tokens(agent['peak_context'])}, "
                  f"{money(agent['total'])}{note}{desc}")
    if session["unpriced"]:
        whys = "; ".join(f"{plural(count, 'call')}, {why}"
                         for why, count in session["unpriced"].items())
        print(f"  unpriced, so left out of every total: {whys}")


def main(argv: list[str] | None = None) -> int:
    """Parse the command line, measure each session asked for, and print the reports.

    Returns:
        0 on a report; 1 when no session matches; 2 when assistant records carried no
        usage, as a changed transcript format would leave them.
    """
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("session", nargs="?", help="a session id, or the start of one")
    parser.add_argument("--repo", help="the newest sessions run in this repo (its folder name)")
    parser.add_argument("--last", type=int, default=1, help="how many, with --repo (default 1)")
    parser.add_argument("--json", action="store_true", help="print the report as JSON")
    args = parser.parse_args(argv)
    if args.session and args.repo:
        parser.error("give a session id or --repo, not both")
    if isinstance(sys.stdout, io.TextIOWrapper):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    if args.last < 1:
        parser.error("--last takes 1 or more")
    picked = pick(args)
    if not picked:
        what = (args.session if args.session
                else f"run in {args.repo}" if args.repo else os.environ["CLAUDE_CODE_SESSION_ID"])
        searched = ", ".join(str(config / "projects") for _, config in config_dirs())
        print(f"no session {what} under {searched}", file=sys.stderr)
        return 1
    sessions = [measure(path, account) for path, account in picked]
    if any(session["_records"] and not session["_calls"] for session in sessions):
        print("error: assistant records with no usage read from them; "
              "the transcript format may have changed", file=sys.stderr)
        return 2
    for session in sessions:
        session.pop("_records")
        session.pop("_calls")
    if args.json:
        print(json.dumps(sessions, ensure_ascii=False, indent=2))
    else:
        for index, session in enumerate(sessions):
            if index:
                print()
            report(session)
        print(f"\nprices: {PRICES_SOURCE}, read {PRICES_AS_OF}; times are local")
    return 0


if __name__ == "__main__":
    sys.exit(main())
