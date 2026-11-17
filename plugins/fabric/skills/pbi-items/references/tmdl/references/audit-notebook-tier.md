# Notebook tier: running semantic link from outside Fabric

How the third evidence tier in [audit.md](audit.md) §2 is run:
what the two bundled scripts do, what each section of their result
answers, and what it costs. The skill's [SKILL.md](../../../SKILL.md)
names the command, in its § 4. The
`sempy.fabric` signatures and permission gates are in
[audit-reference.md](audit-reference.md) §4; this file does not repeat
them.

## 1. Shape

Semantic link runs only inside Fabric, so the work is split in two:

- `model-audit-notebook.py` is a Fabric notebook in Git source format,
  Python kernel, no Spark and no lakehouse. It reads the model, changes
  nothing, and returns one JSON string as its **exit value**.
- `run-model-audit.py` writes the run's parameters into that source,
  creates it as a temporary notebook, runs it through the Job Scheduler
  API, reads the exit value and deletes the notebook, failed run or not.
  `--keep` leaves it; `render` prints the source and signs in to nothing,
  for importing it by hand.

The parameters are written into the source, not passed to the run. The
notebook API page no longer documents a notebook's parameter body, and
the Run On Demand Item Job reference says its `parameters` property "is
not broadly supported" (both read 2026-10-23). A notebook created fresh
for each run needs neither.

The exit value comes back from **Get Item Job Instance** on the
notebook path with `?beta=true`:
`/workspaces/{ws}/notebooks/{nb}/jobs/execute/instances/{job}?beta=true`.
**It arrives as `properties.exitValue`**, not the top-level `exitValue`
the notebook API page shows: four runs on 2026-10-23 found it there, as
Learn's business-events page had, after a first run reading only the
top level reported none. The driver reads both and records which under
`run.exitValueAt`. A 23,112-character exit value came back whole.

A run spent about 70 seconds `NotStarted` while the Python session
started, then 20 seconds on a three-table model's metadata sections, or
about four minutes with `--read-data` over a 530,000-row table
(2026-10-23).

## 2. Sections of the result

Each section runs on its own, so one gate failing does not lose the
rest: its error lands under `errors`, and the script exits 1.

| Section | Call | Serves |
| --- | --- | --- |
| `partitions` | `list_partitions` | §1 storage mode, as bound |
| `relationships` | `list_relationships(extended=True, calculate_missing_rows=True)` | checks 4–7, and 21: missing rows counted on the server |
| `bpa` | `run_model_bpa(export="none", return_dataframe=True)` | check 19, as counts per rule plus a sample |
| `memory` | `model_memory_analyzer(export=None, return_dataframe=True)` | checks 17 and 18; `Columns` sorted by size |
| `tables` | `read_table(num_rows=MAX_ROWS)` per table | `--read-data` only: the input to the three below |
| `violations` | `sempy.relationships.list_relationship_violations` | check 21 against the data: missing keys and broken multiplicity |
| `candidates` | `find_relationships(exclude=<the model's>)` | check 22 |
| `dependencies` | `FabricDataFrame.find_dependencies()` per table | check 23 |

**A table that fills `--max-rows` is listed under `capped`**, and a
relationship whose one side is capped goes to `notChecked`, not
`violations`: its "missing" keys could be rows the cap left out. A
capped table is also skipped by `dependencies`. `--top` bounds every
other list.

**A table neither reader can read is listed under `unread`**, with each
reader's error, and every relationship touching it goes to `notChecked`.
`read_table` tries XMLA, then REST. On 2026-10-23 one Direct Lake table
defeated both: XMLA's XML reader refused a `0x02` control character in
its text, "an invalid character", and REST mode failed in semantic link's
own parsing of a timestamp with no fractional seconds. **The XMLA error
is a finding**: a text column holds a control character, which other
XMLA clients will trip on too. The REST error is semantic link's, not
the data's.

## 3. The checks that read data

All three come from the semantic link tutorials and run only with
`--read-data`, which reads every table into the notebook's memory, 16 GB
on the default Python notebook, and bills the capacity as interactive
queries.

- **Check 21, rows that miss across a relationship.** The sharpest
  silent failures in `audit.md` §4 are rows that vanish: a limited
  relationship joins `INNER`, assume-RI understates, and a duplicate on a
  Direct Lake one side fails the query. The server-side count needs no
  `--read-data`; `list_relationship_violations` adds which keys and
  duplicate keys on the one side ("one of seven values in
  `Fact[Product Key]` isn't present in `Product[Product Key]`, and the
  missing key is `50`", in the relationships tutorial).
- **Check 22, relationships the model lacks.** `find_relationships`
  proposes joins from column names and value coverage. This is the
  evidence check 9 asks for before a disconnected table is flagged. The
  thresholds are the relationships tutorial's, 0.7 for name similarity
  and 0.7 for coverage, which recovered every relationship in its
  sample. A candidate is a hypothesis: the same tutorial shows Power BI
  autodetecting two relationships that were semantically wrong.
- **Check 23, functional dependencies inside a table.** A column that
  determines others, `ProductKey` → `Category`, is a dimension held
  inside a wider table: the "star → one wide table" defect of
  `audit.md` §3, and the proof that collapsing a snowflake loses nothing.
  The default threshold is a conditional entropy of 0.01; a dependency
  that holds only approximately shows where the data breaks it, as the
  dependencies tutorial's `City` → `Region` did.

## 4. Costs and gates

- **The run workspace** needs a Fabric capacity and the caller
  **Contributor** there, to create the notebook. The model's workspace
  is `--model-workspace`, the run workspace by default.
- **The notebook runs as the caller**, the Azure CLI's account: a REST
  run is an interactive run, under the user's security context (Learn,
  how to use notebooks).
- **A Git-connected workspace lists the notebook as an uncommitted
  change** until it is deleted. Commit nothing from the workspace while
  a run is in flight.
- `--timeout`, 30 minutes by default, cancels the run before deleting
  the notebook.

## 5. What a failure looks like

| Symptom | Meaning |
| --- | --- |
| exit 2 before any sign-in | a bad argument, including a model name ending in whitespace, which notebooks fail on |
| `N workspaces this account can see are named …` | the name is wrong, or the account is in the wrong tenant: check `AZURE_CONFIG_DIR` |
| `run Failed:` with a `failureReason` | the notebook raised outside a section: read the reason, or rerun with `--keep` and open the run |
| `run Completed with no exitValue` | the notebook ended before its last cell |
| `<section>: FAILED` | that section's gate: usually ReadWrite on the model for a TOM call |
| `<table>: NOT READ, so not checked` | `--read-data` could not read that table (§2); the data checks ran on the rest |
| `NOT DELETED: notebook …` | the notebook is still in the workspace: delete it by the ID printed |

## 6. Left for later

Not drilled here, and candidates for routing out of this skill rather
than more sections in it: `semantic-link-labs` (the Delta Analyzer for
check 20, and its Direct Lake helpers), `evaluate_measure`,
`get_model_calc_dependencies`, which could make check 2 exact, and the
Great Expectations tutorial.

## 7. Sources

- [Discover relationships in a semantic model using semantic link](https://learn.microsoft.com/fabric/data-science/tutorial-power-bi-relationships)
- [Analyze functional dependencies in a semantic model](https://learn.microsoft.com/fabric/data-science/tutorial-power-bi-dependencies)
- [Discover relationships in the Synthea dataset](https://learn.microsoft.com/fabric/data-science/tutorial-relationships-detection)
- [Explore and validate relationships in semantic models and dataframes](https://learn.microsoft.com/fabric/data-science/semantic-link-validate-relationship)
- [Detect, explore, and validate functional dependencies](https://learn.microsoft.com/fabric/data-science/semantic-link-validate-data)
- [Manage and execute notebooks in Fabric with APIs](https://learn.microsoft.com/fabric/data-engineering/notebook-public-api)
  — the exit value.
- [Use Python experience in notebooks](https://learn.microsoft.com/fabric/data-engineering/using-python-experience-on-notebook)
  — semantic link native, 2 vCores and 16 GB by default.
- [Notebook definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/notebook-definition)
  — the `fabricGitSource` part.
- [Job Scheduler: Run On Demand Item Job](https://learn.microsoft.com/rest/api/fabric/core/job-scheduler/run-on-demand-item-job)
