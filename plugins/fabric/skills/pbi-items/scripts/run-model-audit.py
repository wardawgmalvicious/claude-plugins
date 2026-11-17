#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "azure-identity>=1.15",
#     "requests>=2.31",
# ]
# ///
"""Run the audit's notebook tier against one semantic model, from outside Fabric.

    uv run <dir>/run-model-audit.py run WORKSPACE MODEL --out audit.json
    uv run <dir>/run-model-audit.py run WORKSPACE MODEL --model-workspace OTHER --read-data
    uv run <dir>/run-model-audit.py render MODEL > notebook-content.py

<dir> is this script's folder. Semantic link runs only inside Fabric, so `run` writes the
parameters into model-audit-notebook.py, beside this script, creates it as a temporary notebook
in WORKSPACE, runs it through the Job Scheduler API, reads the JSON it returns as its exit
value, and deletes it, failed run or not, unless --keep. WORKSPACE needs a Fabric capacity and
the caller Contributor on it; MODEL is the semantic model's name or ID, in WORKSPACE unless
--model-workspace names another, and the notebook's calls through TOM need ReadWrite on it.
Workspaces are names or IDs. It signs in as the Azure CLI's account, and the notebook runs as
that account too: set AZURE_CONFIG_DIR first where tenants are kept apart.

The model is only read. The one write is the notebook item, which a Git-connected workspace
lists as an uncommitted change until it is deleted. --read-data adds the checks that read table
data, up to --max-rows rows per table, billed to the capacity as interactive queries.

`render` prints the notebook source with its parameters set and signs in to nothing: the
notebook to import by hand, or to read before a run. The JSON goes to --out, whose folder is
made before the notebook is, or stdout, which also takes it if --out cannot be written, and a
summary of it to stderr. Exit 0 when every section ran, 1 when one failed, the run did or
--out could not be written, 2 on a bad argument.
"""

from __future__ import annotations

import argparse
import base64
import io
import json
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, NoReturn

FABRIC_API = "https://api.fabric.microsoft.com/v1"
FABRIC_SCOPE = "https://api.fabric.microsoft.com/.default"
NOTEBOOK = Path(__file__).with_name("model-audit-notebook.py")
GUID = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", re.I)
TERMINAL = ("Completed", "Failed", "Cancelled", "Deduped")


class ApiError(RuntimeError):
    """A REST call that failed: the request, its status, and the start of the reply."""


def fail_usage(message: str) -> NoReturn:
    """Print a usage error and exit 2."""
    print(f"run-model-audit: {message}", file=sys.stderr)
    sys.exit(2)


def note(message: str) -> None:
    """Print progress to stderr, which keeps stdout for the JSON."""
    print(message, file=sys.stderr, flush=True)


def write_stdout(text: str) -> None:
    """Write text to stdout as UTF-8 bytes, so Windows turns no LF into CRLF on the way."""
    sys.stdout.flush()
    sys.stdout.buffer.write(text.encode("utf-8"))
    sys.stdout.buffer.flush()


class Api:
    """Fabric REST calls, signed in as the Azure CLI's account."""

    def __init__(self) -> None:
        from azure.identity import AzureCliCredential

        self.credential = AzureCliCredential(process_timeout=60)

    def headers(self) -> dict[str, str]:
        """A bearer header, from a token the credential refreshes as it nears expiry."""
        return {"Authorization": f"Bearer {self.credential.get_token(FABRIC_SCOPE).token}"}

    def send(self, method: str, url: str, body: dict | None = None) -> Any:
        """Send one request and return the reply as it came, raising on a 4xx or 5xx.

        Raises:
            ApiError: On a transport failure or a 4xx or 5xx reply.
        """
        import requests

        try:
            reply = requests.request(method, url, headers=self.headers(), json=body,
                                     timeout=300)
        except requests.RequestException as exc:
            raise ApiError(f"{method} {url}: {exc}") from exc
        if reply.status_code >= 400:
            raise ApiError(f"{method} {url}: {reply.status_code} {reply.text[:800]}")
        return reply

    def call(self, method: str, url: str, body: dict | None = None) -> Any:
        """Send one request, wait out a long-running operation, and return the JSON reply.

        Raises:
            ApiError: On a transport failure, a 4xx or 5xx reply, or an operation that fails.
        """
        reply = self.send(method, url, body)
        if reply.status_code == 202 and reply.headers.get("Location"):
            reply = self._finish(reply)
            if reply is None:
                return {}
        return reply.json() if reply.content else {}

    def pages(self, url: str, key: str = "value") -> list[dict]:
        """Every item of a paged list, following continuationUri."""
        found: list[dict] = []
        while url:
            page = self.call("GET", url)
            found.extend(page.get(key) or [])
            url = page.get("continuationUri") or ""
        return found

    def _finish(self, reply: Any) -> Any:
        """Poll a 202's operation to its end; return its result, or None if it has none."""
        import requests

        location = reply.headers["Location"]
        deadline = time.monotonic() + 600
        status = "Running"
        while status in ("NotStarted", "Running"):
            if time.monotonic() > deadline:
                raise ApiError(f"operation still {status} after ten minutes: {location}")
            time.sleep(int(reply.headers.get("Retry-After") or 2))
            reply = requests.get(location, headers=self.headers(), timeout=120)
            try:
                status = (reply.json() if reply.content else {}).get("status")
            except ValueError:
                status = None
        if status != "Succeeded":
            raise ApiError(f"operation {status}: {reply.text[:800]}")
        result = requests.get(location.rstrip("/") + "/result", headers=self.headers(),
                              timeout=120)
        return None if result.status_code >= 400 else result


def render(args: argparse.Namespace) -> str:
    """The notebook source with the run's values written into its parameters cell.

    Raises:
        RuntimeError: If the notebook no longer assigns each parameter exactly once.
    """
    source = NOTEBOOK.read_bytes().decode("utf-8")
    values = {"DATASET": args.model, "WORKSPACE": args.model_workspace or "",
              "READ_DATA": args.read_data, "MAX_ROWS": args.max_rows, "TOP_N": args.top}
    for name, value in values.items():
        pattern = re.compile(rf"^{name} = .*$", re.M)
        if len(pattern.findall(source)) != 1:
            raise RuntimeError(f"{NOTEBOOK.name} does not assign {name} exactly once")
        source = pattern.sub(lambda _match: f"{name} = {value!r}", source)
    return source


def resolve_workspace(api: Api, name_or_id: str) -> tuple[str, str]:
    """A workspace's ID and name, from either.

    Raises:
        ApiError: If no workspace, or more than one, answers to it.
    """
    if GUID.match(name_or_id):
        found = api.call("GET", f"{FABRIC_API}/workspaces/{name_or_id}")
        return found["id"], found.get("displayName") or name_or_id
    matches = [ws for ws in api.pages(f"{FABRIC_API}/workspaces")
               if ws.get("displayName") == name_or_id]
    if len(matches) != 1:
        raise ApiError(f"{len(matches)} workspaces this account can see are named {name_or_id!r}")
    return matches[0]["id"], name_or_id


def check_model(api: Api, workspace_id: str, model: str) -> str:
    """The model's name, after checking the workspace holds it, before a notebook is spent.

    Raises:
        ApiError: If the workspace holds no semantic model by that name or ID.
    """
    for item in api.pages(f"{FABRIC_API}/workspaces/{workspace_id}/semanticModels"):
        if model in (item.get("id"), item.get("displayName")):
            return item["displayName"]
    raise ApiError(f"no semantic model {model!r} in workspace {workspace_id}")


def summarize(result: dict) -> None:
    """Print each section's outcome and timing to stderr."""
    seconds = result.get("seconds") or {}
    for name, body in (result.get("sections") or {}).items():
        rows = body.get("rows") if isinstance(body, dict) else None
        size = f", {rows} rows" if isinstance(rows, int) else ""
        note(f"  {name}: ok{size} ({seconds.get(name, '?')} s)")
        if name == "tables":
            for table in (body.get("unread") or {}):
                note(f"    {table}: NOT READ, so not checked: see sections.tables.unread")
            for table in body.get("capped") or []:
                note(f"    {table}: capped at --max-rows")
    for name, error in (result.get("errors") or {}).items():
        note(f"  {name}: FAILED ({seconds.get(name, '?')} s): {error[:300]}")


def run(api: Api, args: argparse.Namespace) -> int:
    """Create the notebook, run it, read its exit value, and delete it."""
    source = render(args)
    workspace_id, workspace_name = resolve_workspace(api, args.workspace)
    model_workspace_id = workspace_id
    if args.model_workspace:
        model_workspace_id, _ = resolve_workspace(api, args.model_workspace)
    model_name = check_model(api, model_workspace_id, args.model)
    note(f"model {model_name!r}; notebook runs in {workspace_name!r}")

    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    body = {
        "displayName": f"tmp_model_audit_{stamp}",
        "type": "Notebook",
        "description": "Temporary: run-model-audit.py's read-only semantic model audit. "
                       "Deleted when its run ends; safe to delete if left behind.",
        "definition": {"format": "fabricGitSource", "parts": [{
            "path": "notebook-content.py", "payloadType": "InlineBase64",
            "payload": base64.b64encode(source.encode("utf-8")).decode("ascii")}]},
    }
    notebook = api.call("POST", f"{FABRIC_API}/workspaces/{workspace_id}/items", body)
    notebook_id = notebook["id"]
    note(f"created notebook {body['displayName']} ({notebook_id})")
    base = f"{FABRIC_API}/workspaces/{workspace_id}/notebooks/{notebook_id}/jobs/execute"
    job_id = ""
    job: dict | None = None
    try:
        reply = api.send("POST", f"{base}/instances?jobType=RunNotebook")
        job_id = reply.headers["Location"].split("?")[0].rstrip("/").rsplit("/", 1)[-1]
        job = wait(api, f"{base}/instances/{job_id}?beta=true", args.timeout * 60)
    finally:
        if job_id and job is None:
            cancel(api, workspace_id, notebook_id, job_id)
        if args.keep:
            note(f"kept notebook {body['displayName']} ({notebook_id})")
        else:
            delete(api, workspace_id, notebook_id, body["displayName"])

    if job.get("status") != "Completed":
        note(f"run {job.get('status')}: {json.dumps(job.get('failureReason'))[:1500]}")
        return 1
    # Measured under properties (2026-10-23 and 2026-11-05), though the notebook API page shows
    # exitValue at the top level; read either and record which.
    exit_value, found_at = job.get("exitValue"), "exitValue"
    if not exit_value:
        exit_value, found_at = (job.get("properties") or {}).get("exitValue"), "properties"
    if not exit_value:
        note("run Completed with no exitValue: the notebook ended before its last cell. "
             f"The job instance: {json.dumps(job)[:1500]}")
        return 1
    try:
        result = json.loads(exit_value)
    except ValueError:
        note(f"exitValue is not JSON ({len(exit_value):,} characters): {exit_value[:300]}")
        return 1
    result["run"] = {"workspace": workspace_name, "notebook": body["displayName"],
                     "jobInstanceId": job_id, "startTimeUtc": job.get("startTimeUtc"),
                     "endTimeUtc": job.get("endTimeUtc"), "exitValueAt": found_at,
                     "exitValueCharacters": len(exit_value)}
    text = json.dumps(result, indent=2, ensure_ascii=False) + "\n"
    wrote = True
    if args.out:
        try:
            args.out.write_bytes(text.encode("utf-8"))
        except OSError as exc:
            wrote = False
            note(f"could not write {args.out}: {exc}; the result follows on stdout")
            write_stdout(text)
        else:
            note(f"{len(exit_value):,}-character result written to {args.out}")
    else:
        write_stdout(text)
    summarize(result)
    return 1 if result.get("errors") or not wrote else 0


def wait(api: Api, url: str, limit: float) -> dict:
    """Poll a job instance until it ends, printing its status each minute.

    Raises:
        ApiError: If the job has not ended within limit seconds.
    """
    started = time.monotonic()
    shown = -60.0
    while True:
        job = api.call("GET", url)
        status = job.get("status")
        elapsed = time.monotonic() - started
        if status in TERMINAL:
            note(f"run {status} after {elapsed:.0f} s")
            return job
        if elapsed > limit:
            raise ApiError(f"run still {status} after {limit / 60:.0f} minutes")
        if elapsed - shown >= 60:
            note(f"run {status} ({elapsed:.0f} s)")
            shown = elapsed
        time.sleep(15)


def cancel(api: Api, workspace_id: str, notebook_id: str, job_id: str) -> None:
    """Cancel a run left going, so the notebook can be deleted under it."""
    url = f"{FABRIC_API}/workspaces/{workspace_id}/items/{notebook_id}/jobs/instances/{job_id}"
    try:
        api.send("POST", f"{url}/cancel")
        note(f"cancelled run {job_id}")
    except ApiError as exc:
        note(f"could not cancel run {job_id}: {exc}")


def delete(api: Api, workspace_id: str, notebook_id: str, name: str) -> None:
    """Delete the notebook, or say plainly that it is still there."""
    try:
        api.send("DELETE", f"{FABRIC_API}/workspaces/{workspace_id}/items/{notebook_id}")
        note(f"deleted notebook {name}")
    except ApiError as exc:
        note(f"NOT DELETED: notebook {name} ({notebook_id}) is still in the workspace: {exc}")


def main() -> int:
    """Parse the command line and run one command."""
    if isinstance(sys.stderr, io.TextIOWrapper):
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)
    for name, summary in (("run", "run the notebook tier and print its result"),
                          ("render", "print the notebook with its parameters set")):
        command = commands.add_parser(name, help=summary)
        if name == "run":
            command.add_argument("workspace", help="the workspace the notebook runs in")
        command.add_argument("model", help="the semantic model's name or ID")
        command.add_argument("--model-workspace",
                             help="the model's workspace, where it is not the notebook's")
        command.add_argument("--read-data", action="store_true",
                             help="add the checks that read table data")
        command.add_argument("--max-rows", type=int, default=1_000_000,
                             help="rows read per table with --read-data (default 1,000,000)")
        command.add_argument("--top", type=int, default=50,
                             help="longest list kept per section (default 50)")
        if name == "run":
            command.add_argument("--out", type=Path, help="write the JSON here, not stdout")
            command.add_argument("--keep", action="store_true",
                                 help="leave the notebook in the workspace after the run")
            command.add_argument("--timeout", type=int, default=30,
                                 help="minutes to wait for the run (default 30)")
    args = parser.parse_args()
    if not args.model or args.model != args.model.strip():
        fail_usage("the model name is blank or starts or ends with whitespace, and notebooks "
                   "fail to run against a model whose name ends with one")
    for option in ("max_rows", "top", "timeout"):
        if getattr(args, option, 1) < 1:
            fail_usage(f"--{option.replace('_', '-')} must be at least 1")
    if args.command == "render":
        write_stdout(render(args))
        return 0
    if args.out:
        # The result is written only after a run of up to --timeout minutes, so a path that
        # cannot take it fails here, before the notebook exists (a missing folder lost a
        # finished 515 s run, 2026-11-05).
        if args.out.is_dir():
            fail_usage(f"--out {args.out} is a folder: name a file")
        try:
            args.out.parent.mkdir(parents=True, exist_ok=True)
        except OSError as exc:
            fail_usage(f"--out's folder cannot be made: {exc}")
    try:
        return run(Api(), args)
    except ApiError as exc:
        print(f"run-model-audit: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
