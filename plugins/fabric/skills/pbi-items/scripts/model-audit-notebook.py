# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "jupyter",
# META     "jupyter_kernel_name": "python3.12"
# META   },
# META   "dependencies": {}
# META }

# MARKDOWN ********************

# # Semantic model audit: the notebook tier
# Gathers what only semantic link reaches, for the pbi-items skill's model audit: storage
# mode per partition, each relationship with the rows that find no match across it, Best
# Practice Analyzer, Model Memory Analyzer and, with READ_DATA, the checks that read table data.
# It changes nothing in the model. The result is one JSON string, the notebook's exit value,
# which the Job Scheduler API hands back: run-model-audit.py renders the parameters below into
# this source, creates the notebook, runs it and deletes it. Plain Python kernel: no Spark, no
# lakehouse. Every call through TOM needs ReadWrite on the model; a section whose call fails is
# reported under "errors" and the rest still run.

# PARAMETERS CELL ********************

# The semantic model's name or ID.
DATASET = ""
# The model's workspace, name or ID; blank = this notebook's workspace.
WORKSPACE = ""
# True - also read table data, for duplicate and missing keys against the data, relationships
# the model lacks, and functional dependencies inside each table. Billed to the capacity as
# interactive queries, and held in this notebook's memory, 16 GB by default.
READ_DATA = False
# Rows read per table when READ_DATA. A table that fills the cap is named under "capped"; a
# relationship whose one side is capped is not checked, since its missing keys could be rows
# the cap left out.
MAX_ROWS = 1000000
# Longest list kept per section, so the exit value stays small.
TOP_N = 50

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# CELL ********************

# ruff: noqa: E402 - a notebook imports after its parameters cell
import json
import time
from collections.abc import Callable
from typing import Any

import pandas as pd
import sempy.fabric as fabric
from sempy.relationships import find_relationships, list_relationship_violations

if not DATASET:
    raise ValueError("DATASET is blank: set it to the semantic model's name or ID")
workspace = WORKSPACE or None
result: dict[str, Any] = {"dataset": DATASET, "workspace": WORKSPACE, "readData": READ_DATA,
                          "maxRows": MAX_ROWS, "topN": TOP_N, "sections": {}, "errors": {},
                          "seconds": {}}


def records(df: pd.DataFrame, limit: int | None = None) -> dict[str, Any]:
    """A DataFrame as column names and rows of values, cut to limit, with its full row count."""
    kept = df if limit is None else df.head(limit)
    rows = json.loads(kept.to_json(orient="values", date_format="iso", default_handler=str))
    return {"rows": len(df), "columns": [str(name) for name in df.columns], "data": rows}


def brief(exc: Exception) -> str:
    """An exception's first line and the lines naming inner exceptions, without stack frames."""
    lines = f"{type(exc).__name__}: {exc}".splitlines()
    kept = lines[:1] + [line.strip() for line in lines[1:] if "Exception:" in line][:4]
    return " | ".join(kept)[:1000]


def section(name: str, gather: Callable[[], Any]) -> None:
    """Run one section into result, recording its error rather than ending the run."""
    started = time.monotonic()
    try:
        result["sections"][name] = gather()
    # Each section stands behind a different gate (TOM, XMLA, the data itself), so one failing
    # must not lose the others; the error is the finding.
    except Exception as exc:
        result["errors"][name] = brief(exc)
    result["seconds"][name] = round(time.monotonic() - started, 1)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# MARKDOWN ********************

# ## Metadata and engine statistics
# `calculate_missing_rows` counts, on the server, the rows on each relationship's many side
# that find no row on its one side: the rows a limited relationship drops without a word.

# CELL ********************

relationships = pd.DataFrame()


def gather_relationships() -> dict[str, Any]:
    global relationships
    relationships = fabric.list_relationships(DATASET, extended=True,
                                              calculate_missing_rows=True, workspace=workspace)
    return records(relationships, 500)


def gather_bpa() -> dict[str, Any]:
    df = fabric.run_model_bpa(DATASET, workspace=workspace, export="none",
                              return_dataframe=True)
    summary = {"rows": len(df)}
    if {"Category", "Rule Name"} <= set(df.columns):
        keys = [column for column in ("Category", "Rule Name", "Severity") if column in df.columns]
        counts = df.groupby(keys, dropna=False).size().reset_index(name="Count")
        summary["byRule"] = records(counts.sort_values("Count", ascending=False))
    summary["sample"] = records(df, TOP_N)
    return summary


def gather_memory() -> dict[str, Any]:
    # The signature allows export=None, but the function asserts one of its three formats
    # (2026-10-23); "html" only displays, where "table" and "zip" need a lakehouse.
    frames = fabric.model_memory_analyzer(DATASET, workspace=workspace, export="html",
                                          return_dataframe=True)
    kept = {}
    for name, df in frames.items():
        if name == "Columns":
            sizes = [column for column in df.columns if "size" in str(column).lower()]
            if sizes:
                df = df.sort_values(sizes[0], ascending=False)
        kept[name] = records(df, TOP_N)
    return kept


section("partitions", lambda: records(fabric.list_partitions(DATASET, workspace=workspace), 500))
section("relationships", gather_relationships)
section("bpa", gather_bpa)
section("memory", gather_memory)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# MARKDOWN ********************

# ## Checks that read table data (READ_DATA)
# From the semantic link tutorials: `list_relationship_violations` joins the tables as the
# model's relationships say and reports missing keys and broken multiplicity;
# `find_relationships` proposes relationships the model lacks; `find_dependencies` finds
# columns that determine others inside one table, a dimension held inside a wider table.

# CELL ********************

tables: dict[str, Any] = {}
capped: list[str] = []
unread: dict[str, str] = {}


def gather_tables() -> dict[str, Any]:
    # XMLA first, the default; it refused a Direct Lake table whose text held a 0x02 control
    # character, "an invalid character" to its XML reader, where REST may not (2026-10-23).
    read = {}
    for name in fabric.list_tables(DATASET, workspace=workspace)["Name"]:
        for mode in ("xmla", "rest"):
            try:
                df = fabric.read_table(DATASET, name, num_rows=MAX_ROWS, mode=mode,
                                       workspace=workspace)
            # A table that one mode cannot read is a finding, and the next mode may read it.
            except Exception as exc:
                unread[name] = f"{unread.get(name, '')}{mode}: {brief(exc)}; "
                continue
            tables[name] = df
            read[name] = {"rows": len(df), "mode": mode}
            if len(df) >= MAX_ROWS:
                capped.append(name)
            break
    if not tables:
        raise RuntimeError(f"no table could be read: {json.dumps(unread)[:1500]}")
    return {"read": read, "capped": capped, "unread": unread}


def gather_violations() -> dict[str, Any]:
    if relationships.empty:
        raise RuntimeError("no relationships to check: the relationships section returned none")
    unchecked = (relationships["To Table"].isin(capped + list(unread))
                 | relationships["From Table"].isin(list(unread)))
    not_checked = records(relationships[unchecked], 200)
    if unchecked.all():
        return {"violations": None, "notChecked": not_checked}
    found = list_relationship_violations(tables, relationships[~unchecked],
                                         missing_key_errors="ignore")
    return {"violations": records(found, 200), "notChecked": not_checked}


def gather_candidates() -> dict[str, Any]:
    # The thresholds the semantic model relationships tutorial uses to recover every one.
    found = find_relationships(tables, exclude=relationships, name_similarity_threshold=0.7,
                               coverage_threshold=0.7)
    return records(found, TOP_N)


def gather_dependencies() -> dict[str, Any]:
    found = {}
    for name, df in tables.items():
        if name not in capped and len(df.columns) >= 3:
            deps = df.find_dependencies()
            if len(deps):
                found[name] = records(deps, TOP_N)
    return found


if READ_DATA:
    section("tables", gather_tables)
    if "tables" not in result["errors"]:
        section("violations", gather_violations)
        section("candidates", gather_candidates)
        section("dependencies", gather_dependencies)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# CELL ********************

payload = json.dumps(result, default=str, separators=(",", ":"))
print(f"{len(payload):,} characters; sections {sorted(result['sections'])}; "
      f"errors {sorted(result['errors'])}")
notebookutils.notebook.exit(payload)  # noqa: F821 - a Fabric notebook built-in

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }
