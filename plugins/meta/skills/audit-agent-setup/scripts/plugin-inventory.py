#!/usr/bin/env python3
"""List an account's plugins: what settings say of each, its stage, and what it declares.

    uv run --no-project <skill>/scripts/plugin-inventory.py                  # this session's account, this repo
    uv run --no-project <skill>/scripts/plugin-inventory.py --plugin typescript-lsp
    uv run --no-project <skill>/scripts/plugin-inventory.py --json          # for a session to parse

<skill> is the audit-agent-setup skill's folder, wherever it is installed;
--no-project keeps uv from syncing the Python project of whatever repo it
runs in.

Every run of the skill before this script wrote the same read by hand, and
three of them got it wrong: a loop that exited 1, a synced plugin looked up
by `synced/manifest.json` when the file is one level down, and synced
plugins named by the manifest, whose `name` is the folder's, a UUID for two
of three (2026-10-21). It reads files only: no `claude plugin` command, which
writes state, and nothing that connects. The one tool it asks anything of is
rustup, below, which starts no server.

The account is CLAUDE_CONFIG_DIR, else ~/.claude, and its plugins root
CLAUDE_CODE_PLUGIN_CACHE_DIR, else <config>/plugins (plugins loading
reference). For each plugin named in `enabledPlugins` or found on disk it
reports:

- what each settings file read says, and which one wins: local, then
  project, then user. Managed settings and --settings are not read, and
  either outranks all three, so the run says so.
- its stage. `installed` is a record in installed_plugins.json, whose
  installPath should exist; `cached, not installed` is a folder under
  cache/<marketplace>/<plugin>/ with no record, the work account's state
  for four plugins on 2026-10-21; a cache version holding `.orphaned_at`
  is counted apart. A `<name>@synced` plugin is a folder under
  synced/<bucket>/, mapped by its own .claude-plugin/plugin.json, whose
  `name` is the one enabledPlugins uses; a folder may be a UUID or the
  name itself, and a `<name>~g4` beside it is a second copy. A bucket is
  named `<orgId>_<id>`, and the account map's orgId for this config
  directory marks the account's own.
- its skills and commands as the listing names them, `<plugin>:<name>`,
  from the default skills/ and commands/ folders only.
- its MCP and language servers: a server's type and its url or command,
  its header and env keys, never their values. An LSP command is looked up
  on this shell's PATH, which may not be the one Claude Code spawns from,
  and never run, so a file found says only that a file of that name is
  there. A rustup proxy is the case it can tell apart: rustup puts one in
  ~/.cargo/bin whether or not the component is installed, and it is the
  same file as the rustup beside it, so `rustup which <command>` answers
  for the working directory's toolchain, with auto-install off so that a
  pinned toolchain it lacks downloads nothing (2026-11-01). The test is
  the file, not the folder: rustup says `unknown binary` of any name its
  toolchain lacks, so it would call a `cargo install`ed server missing.
  Only a rustup in a PATH folder is ever run: a file found anywhere else,
  the working directory or a path the plugin names, reads as found outside
  this shell's PATH.

--plugin <name> looks a plugin up in every known marketplace's
.claude-plugin/marketplace.json, the list of what can be installed: the
official clone listed 315 on 2026-10-21, of which its plugins/ folder held
43, the rest fetched from elsewhere. Exits 1 when the config directory is
missing, and 2 when a file it reads is there in a shape it does not know,
rather than report nothing; a settings file that does not parse is a
warning. No dependencies; the script's suite, in the repo this skill is
authored in, holds each case.
"""

from __future__ import annotations

import argparse
import io
import json
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

SOURCES = ("local", "project", "user")  # highest first, of those this reads
LIST_MAX = 6  # skills printed per plugin before "N more"
RUSTUP_TIMEOUT = 5  # seconds for `rustup which`, which reads its own files


class FormatChanged(Exception):
    """A file is there in a shape this script does not know."""


@dataclass
class Plugin:
    plugin_id: str
    enabled: dict[str, object] = field(default_factory=dict)  # source -> value
    records: list[dict] = field(default_factory=list)  # installed_plugins.json entries
    cached: list[str] = field(default_factory=list)  # cache version folders
    orphaned: list[str] = field(default_factory=list)  # of those, holding .orphaned_at
    synced: list[dict] = field(default_factory=list)  # {folder, bucket, own, marketplace}
    listed: str | None = None  # the marketplace that lists it, when one does
    folder: Path | None = None  # where its skills and servers were read
    skills: list[str] = field(default_factory=list)
    servers: list[dict] = field(default_factory=list)
    lsp: list[dict] = field(default_factory=list)

    @property
    def name(self) -> str:
        return self.plugin_id.rsplit("@", 1)[0]

    @property
    def market(self) -> str:
        return self.plugin_id.rsplit("@", 1)[1] if "@" in self.plugin_id else ""


def read_json(path: Path, what: str) -> object:
    """A JSON file's content, None when absent; a file that does not parse is a format change."""
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return None
    except (OSError, ValueError) as exc:
        raise FormatChanged(f"{path} ({what}) did not read: {exc}") from exc


def repo_root(given: str | None) -> Path | None:
    if given:
        return Path(given).resolve()
    try:
        top = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                             text=True, check=True).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return None
    return Path(top) if top else None


def same_dir(a: Path, b: Path) -> bool:
    """One folder however spelled, an 8.3 short name (USERNA~1) included."""
    return (os.path.normcase(os.path.realpath(a)).rstrip("\\/")
            == os.path.normcase(os.path.realpath(b)).rstrip("\\/"))


def own_org(config: Path) -> str | None:
    """The orgId the account map gives this config directory, if it gives one."""
    path = Path(os.environ.get("CLAUDE_ACCOUNTS_MAP")
                or Path.home() / ".config" / "claude-accounts.json")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None
    accounts = data.get("accounts") if isinstance(data, dict) else None
    for entry in (accounts.values() if isinstance(accounts, dict) else []):
        if (isinstance(entry, dict) and isinstance(entry.get("configDir"), str)
                and same_dir(Path(entry["configDir"]), config)):
            org = entry.get("orgId")
            return org if isinstance(org, str) and org else None
    return None


def enabled_plugins(files: dict[str, Path]) -> dict[str, dict[str, object]]:
    """Plugin id -> {source: value}, from each settings file that names it."""
    out: dict[str, dict[str, object]] = {}
    for source, path in files.items():
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except FileNotFoundError:
            continue
        except (OSError, ValueError) as exc:
            print(f"warning: {path} did not parse ({exc}); Claude Code may skip it too",
                  file=sys.stderr)
            continue
        found = data.get("enabledPlugins") if isinstance(data, dict) else None
        for plugin_id, value in (found.items() if isinstance(found, dict) else []):
            out.setdefault(plugin_id, {})[source] = value
    return out


def dirs(path: Path) -> list[Path]:
    """The folders in a folder, dot-named ones left out."""
    try:
        return sorted(p for p in path.iterdir() if p.is_dir() and not p.name.startswith("."))
    except OSError:
        return []


def installed(root: Path) -> dict[str, list[dict]]:
    data = read_json(root / "installed_plugins.json", "install records")
    if data is None:
        return {}
    found = data.get("plugins") if isinstance(data, dict) else None
    if not isinstance(found, dict) or not all(
            isinstance(v, list) and all(isinstance(r, dict) for r in v) for v in found.values()):
        raise FormatChanged(f"{root / 'installed_plugins.json'} holds no plugins map of record "
                            "lists")
    return found


def synced(root: Path, org: str | None) -> dict[str, list[dict]]:
    """Plugin name -> its synced folders, each mapped by its own plugin.json."""
    out: dict[str, list[dict]] = {}
    folders = 0
    for bucket in dirs(root / "synced"):
        own = bool(org) and bucket.name.split("_", 1)[0].casefold() == org.casefold()
        for folder in dirs(bucket):
            folders += 1
            manifest = read_json(folder / ".claude-plugin" / "plugin.json", "plugin manifest")
            if not isinstance(manifest, dict) or not isinstance(manifest.get("name"), str):
                print(f"warning: {folder} has no .claude-plugin/plugin.json naming it",
                      file=sys.stderr)
                continue
            meta = read_json(bucket / f"{folder.name}.meta.json", "synced plugin metadata")
            out.setdefault(manifest["name"], []).append({
                "folder": folder, "bucket": bucket.name, "own": own,
                "marketplace": meta.get("marketplace_name") if isinstance(meta, dict) else None,
            })
    if folders and not out:
        raise FormatChanged(f"{folders} folders under {root / 'synced'} and no "
                            ".claude-plugin/plugin.json naming any of them")
    return out


def marketplaces(root: Path) -> dict[str, dict]:
    """Marketplace name -> {source, location, entries by plugin name}."""
    known = read_json(root / "known_marketplaces.json", "known marketplaces") or {}
    if not isinstance(known, dict):
        raise FormatChanged(f"{root / 'known_marketplaces.json'} is no map of marketplaces")
    places = {name: (entry.get("source"), Path(entry["installLocation"]))
              for name, entry in known.items()
              if isinstance(entry, dict) and isinstance(entry.get("installLocation"), str)}
    for clone in dirs(root / "marketplaces"):
        places.setdefault(clone.name, (None, clone))
    out: dict[str, dict] = {}
    for name, (source, location) in sorted(places.items()):
        listing = read_json(location / ".claude-plugin" / "marketplace.json", "marketplace")
        entries: dict[str, dict] = {}
        if listing is not None:
            plugins = listing.get("plugins") if isinstance(listing, dict) else None
            if not isinstance(plugins, list):
                raise FormatChanged(f"{location} lists no plugins in "
                                    ".claude-plugin/marketplace.json")
            entries = {e["name"]: e for e in plugins
                       if isinstance(e, dict) and isinstance(e.get("name"), str)}
        out[name] = {"source": source, "location": location, "cloned": listing is not None,
                     "entries": entries}
    return out


def server_list(declared: object, folder: Path | None, default: str, wrapper: str) -> dict:
    """A plugin's servers: inline, from a path it names, or from its default file."""
    if isinstance(declared, str) or declared is None:
        name = declared if isinstance(declared, str) else default
        declared = read_json(folder / name, "server declarations") if folder else None
    if isinstance(declared, dict) and isinstance(declared.get(wrapper), dict):
        declared = declared[wrapper]
    return declared if isinstance(declared, dict) else {}


def mcp_rows(servers: dict) -> list[dict]:
    rows = []
    for name, s in sorted(servers.items()):
        if not isinstance(s, dict):
            continue
        kind = s.get("type") or ("stdio" if s.get("command") else "http")
        rows.append({"name": name, "type": kind,
                     "endpoint": s.get("url") if kind != "stdio" else s.get("command"),
                     "header_keys": sorted(s.get("headers") or {}),
                     "env_keys": sorted(s.get("env") or {}),
                     "headers_helper": bool(s.get("headersHelper"))})
    return rows


def binary_state(command: str) -> str:
    """What can be said of a server's command without starting it, as the report words it."""
    found = shutil.which(command)
    if found is None:
        return "not on this shell's PATH"
    path = Path(found)
    # which() also takes a path as given and, on Windows, tries the working directory first, and
    # either could be a rustup the plugin or the audited repo chose: never run one from there.
    if not any(entry and same_dir(path.parent, Path(entry))
               for entry in os.environ.get("PATH", "").split(os.pathsep)):
        return "found outside this shell's PATH, not run"
    rustup = path.with_name("rustup" + path.suffix)
    try:
        # rustup is the same file as itself, but `rustup which rustup` exits 1: no proxy.
        proxy = path.stem.casefold() != "rustup" and os.path.samefile(path, rustup)
    except OSError:  # no rustup beside it
        proxy = False
    if not proxy:
        return "found on this shell's PATH, not run"
    try:
        # No pipes: a timeout's kill leaves a grandchild holding one, and the wait would hang on it.
        done = subprocess.run([str(rustup), "which", path.stem], stdin=subprocess.DEVNULL,
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                              timeout=RUSTUP_TIMEOUT,
                              env={**os.environ, "RUSTUP_AUTO_INSTALL": "0"}, check=False)
    except (OSError, subprocess.TimeoutExpired):
        return "a rustup proxy on this shell's PATH, rustup did not answer"
    return ("a rustup proxy on this shell's PATH, "
            + ("installed" if done.returncode == 0 else "not installed, so it cannot run"))


def lsp_rows(servers: dict) -> list[dict]:
    rows = []
    for name, s in sorted(servers.items()):
        if isinstance(s, dict) and isinstance(s.get("command"), str):
            args = [a for a in s.get("args") or [] if isinstance(a, str)]
            rows.append({"name": name, "command": " ".join([s["command"], *args]),
                         "binary": binary_state(s["command"])})
    return rows


def describe(p: Plugin, folder: Path | None, entry: dict | None) -> None:
    """Fill in what a plugin declares, from its folder and its marketplace entry."""
    manifest = {}
    if folder is not None and folder.is_dir():
        p.folder = folder
        found = read_json(folder / ".claude-plugin" / "plugin.json", "plugin manifest")
        manifest = found if isinstance(found, dict) else {}
        p.skills = sorted({f"{p.name}:{d.name}" for d in dirs(folder / "skills")
                           if (d / "SKILL.md").is_file()}
                          | {f"{p.name}:{f.stem}" for f in (folder / "commands").glob("*.md")})
    entry = entry or {}
    mcp = server_list(manifest.get("mcpServers", entry.get("mcpServers")), p.folder,
                      ".mcp.json", "mcpServers")
    lsp = server_list(manifest.get("lspServers", entry.get("lspServers")), p.folder,
                      ".lsp.json", "lspServers")
    p.servers, p.lsp = mcp_rows(mcp), lsp_rows(lsp)


def newest(folder: Path, skip: list[str]) -> Path | None:
    live = [d for d in dirs(folder) if d.name not in skip]
    return max(live, key=lambda d: d.stat().st_mtime) if live else None


def gather(config: Path, root: Path, repo: Path | None) -> tuple[list[Plugin], dict]:
    files = {"user": config / "settings.json"}
    if repo is not None:
        files = {"local": repo / ".claude" / "settings.local.json",
                 "project": repo / ".claude" / "settings.json", **files}
    named = enabled_plugins(files)
    records = installed(root)
    copies = synced(root, own_org(config))
    markets = marketplaces(root)

    ids = list(named)
    ids += [i for i in records if i not in ids]
    for market in dirs(root / "cache"):
        ids += [f"{d.name}@{market.name}" for d in dirs(market) if f"{d.name}@{market.name}"
                not in ids]
    ids += [f"{n}@synced" for n in copies if f"{n}@synced" not in ids]

    plugins = []
    for plugin_id in ids:
        p = Plugin(plugin_id, enabled=named.get(plugin_id, {}))
        p.records = records.get(plugin_id, [])
        folder: Path | None = None
        if p.market == "synced":
            p.synced = copies.get(p.name, [])
            mine = [c for c in p.synced if c["own"]] or p.synced
            folder = mine[0]["folder"] if mine else None
        else:
            cache = root / "cache" / p.market / p.name
            p.cached = [d.name for d in dirs(cache)]
            p.orphaned = [v for v in p.cached if (cache / v / ".orphaned_at").exists()]
            paths = [Path(r["installPath"]) for r in p.records
                     if isinstance(r.get("installPath"), str)]
            folder = next((d for d in paths if d.is_dir()), None) or newest(cache, p.orphaned)
        entry = markets.get(p.market, {}).get("entries", {}).get(p.name)
        p.listed = p.market if entry else None
        describe(p, folder, entry)
        plugins.append(p)
    return plugins, markets


def winner(p: Plugin) -> tuple[str, object] | None:
    for source in SOURCES:
        if source in p.enabled:
            return source, p.enabled[source]
    return None


def stage(p: Plugin) -> str:
    if p.market == "synced":
        if not p.synced:
            return "no synced folder maps to it"
        where = "; ".join(f"{c['bucket'].split('_', 1)[0][:8]}/{c['folder'].name}"
                          + (" (this account's org)" if c["own"] else "") for c in p.synced)
        count = len(p.synced)
        return f"synced, {count} folder{'s' if count > 1 else ''}: {where}"
    parts = []
    if p.records:
        scopes = sorted({str(r.get("scope", "?")) for r in p.records})
        missing = [r for r in p.records if not (isinstance(r.get("installPath"), str)
                                                and Path(r["installPath"]).is_dir())]
        parts.append(f"installed at {', '.join(scopes)} scope"
                     + (f", {len(missing)} record's installPath missing" if missing else ""))
    elif p.cached and len(p.orphaned) < len(p.cached):
        parts.append("cached, not installed")
    elif p.cached:
        parts.append("cached, every version orphaned, not installed")
    else:
        parts.append("not fetched")
    if p.cached:
        parts.append(f"{len(p.cached)} cache version{'s' if len(p.cached) > 1 else ''}"
                     + (f", {len(p.orphaned)} orphaned" if p.orphaned else ""))
    parts.append(f"listed by {p.listed}" if p.listed else "no marketplace clone lists it")
    return "; ".join(parts)


def show_value(value: object) -> str:
    return json.dumps(value) if not isinstance(value, str) else value


def lookup(name: str, markets: dict) -> list[dict]:
    hits = []
    for market, m in markets.items():
        entry = m["entries"].get(name)
        if entry is None:
            continue
        source = entry.get("source")
        local = m["location"] / source if isinstance(source, str) else None
        p = Plugin(f"{name}@{market}")
        describe(p, local if local is not None and local.is_dir() else None, entry)
        hits.append({"plugin": p.plugin_id,
                     "source": source if isinstance(source, str) else (source or {}).get("source"),
                     "description": entry.get("description"),
                     "skills": p.skills, "mcp_servers": p.servers, "lsp_servers": p.lsp})
    return hits


def print_servers(p: Plugin) -> None:
    for s in p.servers:
        keys = [f"header keys {', '.join(s['header_keys'])}" if s["header_keys"] else "",
                f"env keys {', '.join(s['env_keys'])}" if s["env_keys"] else "",
                "a headersHelper" if s["headers_helper"] else ""]
        extra = "; ".join(k for k in keys if k)
        print(f"    mcp       {s['name']}: {s['type']} {s['endpoint']}"
              + (f" ({extra})" if extra else ""))
    for s in p.lsp:
        print(f"    lsp       {s['name']}: {s['command']}, {s['binary']}")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--config", help="the account's config directory "
                    "(default: CLAUDE_CONFIG_DIR, else ~/.claude)")
    ap.add_argument("--repo", help="the repo whose project and local settings to read "
                    "(default: the git root of the working directory; none outside one)")
    ap.add_argument("--plugin", action="append", default=[],
                    help="look this plugin up in every known marketplace; repeatable")
    ap.add_argument("--json", action="store_true", help="print the inventory as JSON")
    args = ap.parse_args(argv)
    if isinstance(sys.stdout, io.TextIOWrapper):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    from_env = os.environ.get("CLAUDE_CONFIG_DIR")
    config = Path(args.config or from_env or Path.home() / ".claude")
    if not config.is_dir():
        print(f"error: no config directory at {config}", file=sys.stderr)
        return 1
    root = Path(os.environ.get("CLAUDE_CODE_PLUGIN_CACHE_DIR") or config / "plugins")
    repo = repo_root(args.repo)
    try:
        plugins, markets = gather(config, root, repo)
        lookups = {name: lookup(name, markets) for name in args.plugin}
    except FormatChanged as exc:
        print(f"error: {exc}; the plugin file format may have changed", file=sys.stderr)
        return 2

    if args.json:
        print(json.dumps({
            "config": str(config), "plugins_root": str(root), "plugins_root_exists": root.is_dir(),
            "repo": str(repo) if repo else None,
            "plugins": [{
                "id": p.plugin_id, "enabled": p.enabled,
                "effective": dict(zip(("source", "value"), won)) if (won := winner(p)) else None,
                "stage": stage(p), "install_records": len(p.records),
                "cache_versions": p.cached, "orphaned_versions": p.orphaned,
                "synced_folders": [{"bucket": c["bucket"], "folder": c["folder"].name,
                                    "own_org": c["own"], "marketplace": c["marketplace"]}
                                   for c in p.synced],
                "listed_by": p.listed, "read_from": str(p.folder) if p.folder else None,
                "skills": p.skills, "mcp_servers": p.servers, "lsp_servers": p.lsp,
            } for p in plugins],
            "marketplaces": [{"name": n, "location": str(m["location"]), "cloned": m["cloned"],
                              "plugins": len(m["entries"])} for n, m in markets.items()],
            "lookups": lookups,
        }, ensure_ascii=False, indent=2))
        return 0

    how = "CLAUDE_CONFIG_DIR" if args.config is None and from_env else (
        "--config" if args.config else "CLAUDE_CONFIG_DIR unset, the default")
    print(f"account   {config}  ({how})")
    print(f"plugins   {root}" + ("" if root.is_dir() else "  (absent: no plugin fetched)"))
    print(f"repo      {repo or 'none: user settings only'}")
    print("Settings read: " + ", ".join(s for s in SOURCES if repo or s == "user")
          + ". Managed settings and --settings are not read and outrank them.\n")
    for p in plugins:
        print(p.plugin_id)
        win = winner(p)
        if win:
            others = [f"{s} {show_value(v)}" for s, v in p.enabled.items() if s != win[0]]
            print(f"    enabled   {show_value(win[1])}, from {win[0]}"
                  + (f" (over {', '.join(others)})" if others else ""))
        else:
            print("    enabled   named in no settings file read")
        print(f"    stage     {stage(p)}")
        if p.skills:
            more = len(p.skills) - LIST_MAX
            print("    skills    " + ", ".join(p.skills[:LIST_MAX])
                  + (f", {more} more" if more > 0 else ""))
        print_servers(p)
    if not plugins:
        print("No plugin named in settings or found on disk.")
    print()
    for name, m in markets.items():
        state = f"{len(m['entries'])} plugins listed" if m["cloned"] else "no clone on disk"
        print(f"marketplace {name}: {state}, at {m['location']}")
    for name, hits in lookups.items():
        if not hits:
            print(f"\n{name}: in no known marketplace's list")
        for hit in hits:
            p = Plugin(hit["plugin"], skills=hit["skills"], servers=hit["mcp_servers"],
                       lsp=hit["lsp_servers"])
            print(f"\n{hit['plugin']}: listed, source {hit['source']}")
            if p.skills:
                print("    skills    " + ", ".join(p.skills))
            print_servers(p)
    return 0


if __name__ == "__main__":
    sys.exit(main())
