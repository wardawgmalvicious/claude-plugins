# Variable library: definition and REST

A variable library's definition parts and their shapes, and how REST
reaches the active value set. It has no operation past the generic seven.
Generic CRUD, `getDefinition` and `updateDefinition`, long-running
operations and pagination are `rest-api`'s, § Definition APIs and
§ Long-Running Operations; reading the values from a notebook, a
pipeline, a shortcut or a schedule is [SKILL.md](../SKILL.md)'s.

| | |
| --- | --- |
| REST `type` | `VariableLibrary`, under `/workspaces/{ws}/variableLibraries/{id}` |
| Git folder | `<display name>.VariableLibrary/` |
| Learn definition | [Variable library definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/variable-library-definition) |
| Spec folder | [`variableLibrary/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/variableLibrary): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `a96c37a`, 2026-10-20: 7 operations, all generic |

## Definition

**Omit `format` entirely**: VariableLibrary does not support the field in
definition requests, and even `"format": null` may cause errors
(`rest-api` § Definition APIs). The parts:

| Path | Required | Holds |
| --- | --- | --- |
| `variables.json` | yes | variable names, types and default values |
| `settings.json` | yes | `valueSetsOrder`, an empty array when there are no value sets |
| `valueSets/<name>.json` | only with value sets | one value set's overrides of the defaults |
| `.platform` | no | the item's metadata, handled by the Git and REST layer |

Learn's property tables for each part are on its definition page, linked
above; the shapes below are the ones this skill's other sections rely on.

### variables.json

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/variableLibrary/definition/variables/1.0.0/schema.json",
  "variables": [
    { "name": "lakehouse_name", "type": "String", "value": "bronze_lakehouse" },
    { "name": "enable_logging", "type": "Boolean", "value": true },
    { "name": "target_warehouse", "type": "ItemReference",
      "value": { "itemId": "...", "workspaceId": "..." } }
  ]
}
```

A Boolean's `value` is a bare JSON `true` or `false`: Learn's definition
article types `value` as JSON, and an update from Git took a bare one
and `getDefinition` returned it bare (a client estate, 2026-10-13).
Whether a sync rejects a quoted `"true"` or coerces it is unverified.

### settings.json and value sets

`settings.json` is always present. `valueSetsOrder` is an empty array
when no value sets are used:

```json
{ "$schema": "...", "valueSetsOrder": [] }
```

When value sets are configured, list them in priority order:

```json
{ "$schema": "...", "valueSetsOrder": ["test", "prod"] }
```

Every entry in `valueSetsOrder` must have a matching file under
`valueSets/`:

```json
{
  "$schema": "...",
  "name": "dev",
  "variableOverrides": [
    { "name": "lakehouse_name", "value": "bronze_dev" },
    { "name": "enable_logging", "value": false }
  ]
}
```

An override takes its variable's JSON type, so a Boolean's is bare too,
though Learn's `VariableOverride` table types `value` as String: its
value-sets page says a value set holds values of each variable's own
type, and the same round trip carried a bare override.

Learn's definition page adds that `valueSetsOrder` may be empty or
partial, may not name a value set that does not exist, and that an update
with a partial or empty list appends the missing names alphabetically
(read 2026-10-20). Its definition example writes the value-set paths
`valueSet/valueSet1.json` where its parts table and the spec's examples
write `valueSets/`; this skill uses `valueSets/`, as a Git folder does.
What validation Git sync applies to the whole item is in SKILL.md's
*Git-sync validation*.

## Git is not the live definition

The **active value set is not in the definition**: Learn says it is
workspace state, so three workspaces can hold the same definition with a
different active set, and a first sync into a new workspace leaves
**Default** active (*Variable library CI/CD* and *Fabric CI/CD concepts
and best practices*, read 2026-10-20). Read or switch it by REST, below.
The spec's `getDefinition` description adds that a sensitivity label is
no part of its result. Whether `getDefinition` returns `.platform` with an all-zero
`logicalId` as it does for a KQL database (`rest-api` §
Definition APIs) is unmeasured for this item.

## REST beyond the generic set

None: the spec has seven operations (list, create, get, update, delete,
`getDefinition`, `updateDefinition`), and Learn's *Variable Library*
`Items` group lists the same seven (both read 2026-10-20), so there is no
table. One of the generic calls carries item-specific content:

- **The active value set** is `properties.activeValueSetName`, a required
  property of the item that **Get** returns and **Update** (`PATCH`)
  takes beside `displayName` and `description`. Learn's value-sets page
  points at the Update call for switching it. Unmeasured here, as is
  whether the name must already be in `valueSetsOrder`.
- **Reordering value sets** is not possible in the UI; Learn says to edit
  `settings.json` through Git or `updateDefinition`.

## Measured deltas, and where to look next

Nothing about the definition or REST has been measured against a tenant
except the bare Boolean above (2026-10-13).

**The spec and Learn disagree on `format`.** The spec's
`VariableLibraryPublicDefinition` describes `format` as "Supported
format: `VariableLibraryV1`", and one of its two create examples sends
it, while
Learn's definition page never mentions a format and its definition
example omits it (both read 2026-10-20). The rule stays *omit*, as
`rest-api` records; whether `VariableLibraryV1` is accepted is
unmeasured.

When this file runs out, read the spec's `swagger.json` and the
operation's `examples/` file, then Learn. Re-read the spec from the SHA
above: its commits are weekly, "Updating swagger files".
