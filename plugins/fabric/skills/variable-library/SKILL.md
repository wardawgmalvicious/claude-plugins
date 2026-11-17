---
name: variable-library
description: "Use for a Microsoft Fabric Variable Library (`.VariableLibrary`, `/variableLibraries`), config-as-code that parameterizes notebooks and pipelines per environment, in Git or by REST, `fab` or a script. Covers definition parts (variables.json, settings.json, valueSets/{name}.json; omit `format`), variable types (String, Boolean, Number, Integer, DateTime, Guid, ItemReference, ConnectionReference), notebook reads by `notebookutils.variableLibrary.getLibrary('Lib').Var` (NOT `.get('lib','var')`) or `get(\"$(/**/Lib/Var)\")`, runtime limits (same workspace, no SPN, active value set), the ItemReference kernel shape (`.value()` AttributeErrors), the `bool('false')` → True trap, the pipeline `libraryVariables` block (three keys, no `libraryId`), its type mapping (Number unsupported, references → Object), Expression-object wrapping and the runtime-ID rule."
when_to_use: "Use before a Read, edit or REST call on an item of type VariableLibrary, or when Git sync fails `InvalidContent (ValueMismatch)`."
# model: inherit  # any model: value blocks Copilot slash invocation
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Fabric Variable Library

Config-as-code for parameterizing notebooks and pipelines per environment. Stored as a Fabric item with definition parts under source control; consumed at runtime via `notebookutils.variableLibrary` (notebooks) or the `libraryVariables` block (pipelines). An **Eventstream** is a third consumer (preview): its source connections and destination items take `ConnectionReference` and `ItemReference` variables, held in its definition as `$(/**/Lib/Var)` (`rti-items`, `references/eventstream/references/eventstream-api.md`). The runtime limits below are the notebook and pipeline ones; Learn does not say they reach an eventstream.

An item's definition and REST calls have a file of their own. Read it
first for its job; past it, the REST spec's folder, then Learn, by `microsoft-learn-mcp`, or with no server, `curl -sL -H 'Accept: text/markdown' <page URL>` (undocumented, read 2026-11-07):

| The job | Read first |
| --- | --- |
| The definition parts (omit `format`), the `variables.json`, `settings.json` and value-set shapes, the active value set by REST | [references/variable-library-api.md](references/variable-library-api.md) |

A live page that contradicts a line here wins: say so, act on the page,
and route the fix by `capture-learning`, bar a dated measured line that
names the page it overrules and the call that measured it, which a page
changed since its date sends back to re-measure. An observed claim is cited
or marked pending a doc check, and stands, marked observed, only where no
page covers it.

## Definition parts

The parts, and why `format` is omitted entirely:
[references/variable-library-api.md](references/variable-library-api.md)
§ Definition.

## Supported variable types

| Type | Tier | Description |
|---|---|---|
| `String` | Basic | Text |
| `Boolean` | Basic | JSON `true` / `false`, never quoted |
| `Number` | Basic | Floating-point. **Not supported in pipelines** |
| `Integer` | Basic | Whole numbers |
| `DateTime` | Basic | ISO 8601 |
| `Guid` | Basic | GUID |
| `ItemReference` | Advanced | Fabric item binding (`{itemId, workspaceId}`) |
| `ConnectionReference` | Advanced | External connection (Snowflake, Azure SQL, …) by ID, so items reference it without embedded credentials; exposes `.connectionId` |

## variables.json

Its shape, and a Boolean's bare `value`:
[references/variable-library-api.md](references/variable-library-api.md)
§ variables.json.

## settings.json + Value Sets

`valueSetsOrder` and the `valueSets/<name>.json` overrides:
[references/variable-library-api.md](references/variable-library-api.md)
§ settings.json and value sets.

## Git-sync validation (`InvalidContent`)

Importing a Variable Library from Git validates the whole item; a failure surfaces on the workspace sync as `InvalidContent (first issue: ValueMismatch)` / "Item content cannot be used". Two verified causes (2026-08-06):

1. **A value-set override names a variable that doesn't exist** — when renaming a variable in `variables.json`, propagate the rename to **every** `valueSets/*.json`, including value sets populated by someone else.
2. **An empty `value`** — the library rejects `""` for any variable or override. For not-yet-supplied values use a sentinel (e.g. `FILL-ME`) and make consumers treat it as unset.

Also enforced: override value type must match the variable's declared type, and the item must stay under 1 MB.

## Notebook consumption

Use `getLibrary()` + dot notation:

```python
lib = notebookutils.variableLibrary.getLibrary("MyConfig")
name = lib.lakehouse_name        # String
flag = lib.enable_logging        # Boolean: typed, by Learn

# Holds for a bool and for a string "true" / "false" alike
if str(flag).lower() == "true":
    ...
```

Learn says values come back typed, and tests a Boolean with a bare
`if debug_mode:` (read 2026-10-13); no run here has confirmed it, in
either kernel. Hence the test above: `flag.lower()` raises
`AttributeError` on a real bool, and `bool(flag)` turns the string
`"false"` true.

**Wrong patterns** (cause runtime failure or silent bugs):

```python
notebookutils.variableLibrary.get("MyConfig", "lakehouse_name")   # ❌ signature does not exist
bool(flag)                                                         # ❌ "false" → True
```

The **reference-path form** of `get()` does exist and auto-types the value — the `/**/` prefix is required and names are case-sensitive:

```python
notebookutils.variableLibrary.get("$(/**/MyConfig/lakehouse_name)")   # ✅
```

**Runtime limits** (all verified 2026-08-06): same-workspace libraries only; **no SPN support** — scheduled / service-principal runs must receive values as notebook parameters instead; always resolves the workspace's **active value set**. Works in the pure-Python (non-Spark) kernel.

**ItemReference shape differs by kernel.** The pure-Python kernel returns a plain dict-like object — `.get("itemId")` is already the GUID string; the documented `.get("itemId").value()` accessor (Spark surface) raises `AttributeError: 'str' object has no attribute 'value'` there. Accept both:

```python
ref = notebookutils.variableLibrary.get("$(/**/MyConfig/target_warehouse)")
item_id = ref.get("itemId")
if callable(getattr(item_id, "value", None)):
    item_id = item_id.value()
```

### Blank-parameter + lazy resolution pattern

Ship the notebook's parameters cell blank and resolve blanks from the workspace's Variable Library at run time. Interactive runs — including branched-out workspaces — pick up their own workspace's config with zero edits; pipeline runs pass every parameter explicitly and never touch the API, which sidesteps the no-SPN limit by design:

```python
# parameters cell:  WAREHOUSE = ""   # pipeline overrides with an explicit value

def vl_lookup(name: str):
    try:
        return notebookutils.variableLibrary.get(f"$(/**/MyConfig/{name})")
    except Exception as exc:
        raise RuntimeError(f"Variable Library lookup failed for '{name}' — is the library in "
                           "this workspace, and does this runtime support variableLibrary?") from exc

WAREHOUSE = WAREHOUSE or vl_lookup("WarehouseConnectionString")
```

## Pipeline consumption

Pipelines consume Variable Library values via a `libraryVariables` block, **sibling to** `activities` (not nested):

```json
{
  "properties": {
    "activities": [{
      "name": "Run ETL",
      "type": "TridentNotebook",
      "typeProperties": {
        "notebookId": {
          "value": "@pipeline().libraryVariables.notebook_id",
          "type": "Expression"
        }
      }
    }],
    "libraryVariables": {
      "notebook_id": {
        "libraryName": "MyConfig",
        "variableName": "notebook_id",
        "type": "String"
      }
    }
  }
}
```

Each entry needs exactly **three** keys — `libraryName`, `variableName`,
`type`. There is **no `libraryId`**: every entry in live Git-synced
pipelines carries these three and nothing else (36 entries across two
pipelines, checked 2026-09-02), and no Microsoft Learn page mentions
such a field. The object key (`notebook_id` above) is the local alias
the expression uses; `variableName` is the name in the library, and the
two need not match.

### Pipeline type mapping

Pipeline type names DIFFER from Variable Library type names. Map carefully:

| Variable Library Type | Pipeline Type |
|---|---|
| Boolean | **Bool** |
| Integer | **Int** |
| String | **String** |
| DateTime | **String** |
| Guid | **String** |
| Number | **unsupported in pipelines** |
| ItemReference | **Object** |
| ConnectionReference | **Object** |

The two advanced types are `Object`, not `String`, because the whole
point of them is property access — `.itemId`, `.workspaceId`,
`.connectionId` — which a string cannot carry:

```json
"notebookId": { "value": "@pipeline().libraryVariables.NotebookRef.itemId",
                "type": "Expression" }
```

`Object` is confirmed against live Git-synced pipelines (2026-09-02);
Learn documents the dotted property access but not the type name.
**`Number` has no pipeline representation at all** — Learn's
known-limitations list is explicit that Number types aren't supported in
pipelines, so a Number variable cannot be consumed from one. Use
`Integer`, or `String` and cast.

Dynamic references must be wrapped in Expression objects: `{"value": "@pipeline().libraryVariables.x", "type": "Expression"}`. Bare strings are treated as literals — not resolved.

## Lakehouse shortcut consumption

**No Lakehouse file brings this skill in**: a `paths:` glob on
`shortcuts.metadata.json` was tried and reverted on 2026-09-01 (see the
note at the end of this section), and the skill has had none at all
since 2026-11-10.
Read this when you are already here for a Variable Library.

A OneLake shortcut can bind its **target** to a variable, so one shortcut resolves to a different item per environment. In Git this lands in `<Name>.Lakehouse/shortcuts.metadata.json` — an array of shortcut objects, where the reference-path form replaces the `itemReference` value:

```json
{
  "name": "ue_Holidays_v2",
  "path": "/Tables/bronze",
  "target": {
    "type": "OneLake",
    "oneLake": {
      "path": "Tables/ue_Holidays_v2",
      "itemReference": "$(/**/MyConfig/ItemReferenceOperation)"
    }
  }
}
```

The backing variable must be type **`ItemReference`**, whose value is a `{"workspaceId", "itemId"}` GUID pair — not a lakehouse name. The Runtime ID rule below applies unchanged.

Two constraints worth knowing before designing around this:

- **Variable libraries are the only supported assignment method.** Shortcut variables cannot be assigned via REST API; the portal's *Manage shortcut → Edit target* pane is the assignment surface, and Git is where the result is read back.
- The reference is **static** — it points at one item and does not re-resolve across environments by itself. Per-stage behaviour comes from value sets, each pointing at a different item.

Whether shortcuts reach Git at all is controlled by `alm.settings.json` in the same folder, which carries an `Enabled`/`Disabled` state per target type (`Shortcuts.OneLake`, `Shortcuts.AdlsGen2`, `Shortcuts.Dataverse`, `Shortcuts.AmazonS3`, and four more) plus `DataAccessRoles`. A shortcut whose target type is `Disabled` there will not sync — check it before debugging a shortcut that "vanished" on deploy.

**Why no glob on `shortcuts.metadata.json`.** Binding a shortcut target to
a variable is one *option*, not what a shortcuts file is. Most shortcuts
carry a plain `workspaceId`/`itemId` pair and have nothing to do with
Variable Library, so a `**/*.Lakehouse/shortcuts.metadata.json` glob would
pull this skill into every Lakehouse regardless — the same over-broad shape
as the bare `**/.platform` that had to be narrowed out of
`pbip`, since folded into `pbi-items`. The discriminator is `$(...)` *inside* the file,
where no glob can see it. Tried and reverted 2026-09-01.

## Schedule consumption

A job schedule's on/off can follow a **Boolean** variable, through the
*Edit schedule* pane's *Controller*. Learn documents it only on
*Schedule a user data function*, and its supported-items list names no
schedule (both read 2026-10-14), yet a pipeline's pane has it too (a
client estate, 2026-10-13). A pipeline's `.schedules` entry then holds
the reference in place of `enabled` (`data-items`'
`references/data-pipeline/data-pipeline.md` § 7), so
switching a schedule per environment is a value-set edit, with no CI
step rewriting `enabled`. Default the variable to `false`: a first sync
or a deploy to an empty stage leaves **Default** active (Learn's
*Variable library CI/CD*), so a new workspace leaves the schedule off
until a value set that turns it on is made active.

**A flip takes effect when the schedule next reads the variable**, which
List Item Schedules gives as
`enabledDetail.nextResolveVariableReferenceDateTime` (`rest-api`).
One Cron schedule at a 15-minute interval, each change made once (the
same estate, 2026-10-13):

| Change | Took effect |
| --- | --- |
| The override, edited in the portal | within 2 minutes, before the next read |
| The override, by an update from Git | at the next read, about 12 minutes on |
| A binding, synced over an unbound schedule | first read 20 to 40 minutes after the schedule's `createdDateTime` |
| A binding, deployed to a stage that never held the item | read within 82 seconds, the next 15 minutes after creation |

Reads came 15 and 16 minutes apart, so whether they follow the
schedule's interval or a fixed timer is unknown. A schedule that is off
still reads, and turns back on at the first read after its value does.
Saving a binding moved the run times off their old grid, as turning the
schedule back on did. A deploy carries the binding, not an on/off
state: the target resolves it against its own active value set, which a
deploy leaves alone (Learn). Unread: a value that arrives by deployment
(probably waiting for a read too), a flip in a deploy's target, a target
whose value set turns the schedule on, a redeploy over a schedule the
target holds, and a service principal deploying.

## Runtime ID rule (cross-reference)

`ItemReference` variable values are passed **verbatim** to consumers — they are NOT resolved against `.platform` `logicalId`. Always store the **runtime item ID** (the GUID from the Fabric portal URL or `GET /v1/workspaces/{wsId}/items` response). See rest-api skill for the runtime-vs-logicalId distinction — using the wrong one is a leading cause of `PowerBIEntityNotFound` from pipelines.

## Gotchas

| Issue | Resolution |
|---|---|
| `.get("lib", "var")` fails at runtime | Use `getLibrary("lib").var`, or `get()` with one reference path, `"$(/**/lib/var)"` |
| `bool("false")` → `True`, or `'bool' object has no attribute 'lower'` | Test `str(flag).lower() == "true"`, which holds whether a Boolean arrives typed or as a string |
| Definition rejected — `format` field | Omit `format` entirely — VariableLibrary does not support it |
| Pipeline variable wrong type | Map correctly: Boolean→Bool, Integer→Int, DateTime/Guid→String, Item/ConnectionReference→**Object**. `Number` has no pipeline type — switch the variable to Integer or String |
| Pipeline expression treated as literal | Wrap in `{"value": "...", "type": "Expression"}` |
| Pipeline variable not resolving | Check `libraryName` + `variableName` and the Expression wrapper. There is no `libraryId` — adding one is not the fix |
| `.itemId` / `.connectionId` unresolved on a library variable | Entry declared `"type": "String"`; advanced types must be `"type": "Object"` |
| Value Sets ignored | Add `valueSetsOrder` array to `settings.json` |
| Value Set validation error | Create matching file under `valueSets/` for every entry in `valueSetsOrder` |
| `PowerBIEntityNotFound` from `ItemReference` | Stored a `.platform` `logicalId` instead of the runtime item ID |
| Git sync fails `InvalidContent (ValueMismatch)` | Rename propagated to `variables.json` but not every `valueSets/*.json`, or an empty `value` — the library rejects `""`; use a `FILL-ME` sentinel |
| `AttributeError: 'str' object has no attribute 'value'` on ItemReference | Pure-Python kernel returns dict-like — `.get("itemId")` is already the GUID; only call `.value()` when it exists |
| Lookup fails under SPN / scheduled run | `notebookutils.variableLibrary` has no SPN support — pass values as notebook parameters from the pipeline |
| A schedule bound to a variable hasn't switched after its value changed through Git | It switches at its next read of the variable, which `enabledDetail.nextResolveVariableReferenceDateTime` gives; see *Schedule consumption* |

## Reference

- Microsoft Learn: [What is a variable library? (overview + supported items)](https://learn.microsoft.com/fabric/cicd/variable-library/variable-library-overview)
- Microsoft Learn: [NotebookUtils variable library utilities for Fabric](https://learn.microsoft.com/fabric/data-engineering/notebookutils/notebookutils-variable-library)
- Microsoft Learn: [Variable library integration with pipelines](https://learn.microsoft.com/fabric/data-factory/variable-library-integration-with-data-pipelines)
- Comprehensive MS Learn link bundle (concept / variable types / value sets / per-consumer integration / REST / ADF migration): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- rest-api skill — definition envelope, runtime ID vs logicalId, `?updateMetadata=true` flag
- data-items skill, its Spark reference — `notebookutils.runtime.context` (sibling API to `notebookutils.variableLibrary`)
