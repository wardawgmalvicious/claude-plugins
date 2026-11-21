# Event Schema Set: definition and REST

An event schema set's definition shape and its REST surface. Generic CRUD,
`getDefinition` and `updateDefinition`, long-running operations and
pagination are `rest-api`'s, § Definition APIs and § Long-Running
Operations. Which edits mint a version, and the item's byte format, are
[event-schema-set.md](../event-schema-set.md)'s §6 and §8; the Git-side
scripts are [editing-from-git.md](editing-from-git.md)'s.

| | |
| --- | --- |
| REST `type` | `EventSchemaSet`, under `/workspaces/{ws}/eventSchemaSets/{id}` |
| Git folder | `<display name>.EventSchemaSet/` |
| Learn definition | [EventSchemaSet definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/eventschemaset-definition) |
| Spec folder | [`eventSchemaSet/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/eventSchemaSet): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `a96c37a`, 2026-10-20: 7 operations, all generic |

## Definition

One part, and no `format` value on either source: Learn's page lists none,
and the spec types `format` as a free string and omits it from its
examples. A `getDefinition` response carries no `format` (measured
2026-11-17, the spec's examples).

| Path | Required | Holds |
| --- | --- | --- |
| `EventSchemaSetDefinition.json` | yes | `eventTypes[]` and `schemas[]`, each schema with its `versions[]` of Avro text |
| `.platform` | no | the item's metadata; `getDefinition` always returns it, and `updateDefinition` reads it only with `?updateMetadata=true` (Learn's item definition overview) |

**The spec's examples name the part `EventSchemaSetV1.json`** (create and
`getDefinition`, read 2026-10-20), where Learn's page and every Git folder
seen say `EventSchemaSetDefinition.json`. **A live `getDefinition` names
it `EventSchemaSetDefinition.json`** (measured 2026-11-17, the spec's
examples), so the spec's name is a placeholder; the examples' payloads
are truncated, so they say nothing of the content.

### Anatomy

Learn's property tables are on its definition page; this is what the file
adds, as measured.

| Object | Fields Learn documents | What the file adds |
| --- | --- | --- |
| root | `eventTypes`, `schemas` | `name`, the item's display name |
| `eventTypes[]` | `id`, `description`, `eventTypeCategory`, `format`, `envelopeMetadata`, `schemaUrl` or `schema`, `schemaFormat`, `protocol`, `protocolOptions` | `schema` in place of `schemaUrl` after a portal **Update** (`event-schema-set.md` §6) |
| `schemas[]` | `id`, `description`, `format`, `versions` | nothing |
| `versions[]` | `id`, `description`, `format`, `schema` | `ancestor`, and newest-first order (`event-schema-set.md` §8) |

The values the file held at every commit on 2026-09-30, as in Learn's
example:

- An event type's `format` is `CloudEvents/1.0`. Its `envelopeMetadata`
  requires string `id`, `type`, `source` and `specversion`, and
  `type.value` repeats the event type's `id`.
- `schemaFormat`, a schema's `format` and a version's `format` are all
  `Avro/1.12.0`.
- Creating a schema, by upload or in the visual builder, writes
  `"schemaUrl": "#/schemas/<id>"`; the generated event type and its
  schema share that `id`.
- `eventTypeCategory`, `protocol`, `protocolOptions` and the optional
  `description` on `schemas[]` and `versions[]` never appeared.
  Learn's page allows `EventType` or `BusinessEventType` for
  `eventTypeCategory` (read 2026-10-20).

`schemaUrl` and an inline `schema` are mutually exclusive (Learn), and
the file respects that: an event type carries one or the other.

## Git is not the live definition

**A live `getDefinition`'s definition part holds what the Git folder
holds** (observed 2026-11-17, Fabric REST, one set read twice, the
second after a portal **Update** minted a version). It had `versions[]`
newest first, each with its `ancestor`, and the inline `schema` that the
Update left on the event type, byte-identical to the new head. Its bytes
were CRLF with no final newline and no BOM. **Its `.platform` does
not**: LF, but with `logicalId` all zeros where Git holds the item's
logical id, as `rest-api` § Definition APIs records for other items, so
normalize it before a diff. `updateDefinition` was never run against
one (`event-schema-set.md` §10), so whether it mints is unknown.

## REST beyond the generic set

None. The spec holds no operation past the generic seven at the
SHA above, and Learn's *Event Schema Set Items* group lists the same seven
(read 2026-10-20): create, delete, get, get definition, list, update, and
update definition. Four item-specific details, all read, none run:

- **`DELETE` takes `?hardDelete=true`**, which "permanently deletes" the
  item; left out, the item is soft-deleted "if the item type supports it".
  It is in the spec and on Learn's Delete page, which lists
  `UnsupportedItemType` among the errors (read 2026-10-20). Whether an
  event schema set supports soft delete is unmeasured.
- **Create takes `description` up to 256 characters** (spec). That is the
  item's, not an event type's, whose cap is `event-schema-set.md` §4's.
- **A `GET` returns `properties.oneLakeRootPath`** (spec).
- **Learn's Delete page carries a Preview note and lists User as the only
  supported identity, with service principals and managed identities
  "No"** (read 2026-10-20, that page only; the others' identity tables were
  not read). `event-schema-set.md` §10 records the schema registry as GA
  (What's New, September 2026), so the two disagree on status.

Learn's *Create Business events and manage data access with REST APIs*
creates a schema set by REST, polling a `202`, then enables data access
security with a Storage-audience token and replaces the data access roles.
That is Business events work, not covered here and not run.

## Measured deltas, and where to look next

- **`getDefinition`'s part is `EventSchemaSetDefinition.json`, with no
  `format`** (2026-11-17), against the spec's examples, above.

No other REST call is measured. The measured behaviour of the
item is in `event-schema-set.md`: versioning by route (§6), the
description stores (§4), and bytes (§8).

When this file runs out, read the spec's `swagger.json` and the
operation's `examples/` file, then Learn. Re-read the spec from the SHA
above: its commits are weekly, "Updating swagger files".

## MCP

None. Learn's Fabric MCP servers list (read 2026-10-20) names no server
for event schema sets; its local Real-Time Intelligence server names
Eventhouse, Eventstreams, Activator, maps and Azure Data Explorer
resources.
