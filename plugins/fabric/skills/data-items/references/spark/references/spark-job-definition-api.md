# Spark job definition: definition and REST

A Spark job definition's two definition formats and the REST operations it
has beyond the generic item set. Generic CRUD, `getDefinition` and
`updateDefinition`, long-running operations and pagination are
`rest-api`'s, § Definition APIs and § Long-Running Operations.

| | |
| --- | --- |
| REST `type` | `SparkJobDefinition`, under `/workspaces/{ws}/sparkJobDefinitions/{id}` |
| Git folder | `<display name>.SparkJobDefinition/` |
| Learn definition | [Spark Job definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/spark-job-definition) |
| Spec folder | [`sparkjobdefinition/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/sparkjobdefinition): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `a96c37a`, 2026-10-20: 11 operations |

## Definition

Two formats, `SparkJobDefinitionV1` and `SparkJobDefinitionV2`; the spec's
`getDefinition` takes either as its `format` query. They share one payload
and differ in how files arrive:

| Format | Parts |
| --- | --- |
| `SparkJobDefinitionV1` | `SparkJobDefinitionV1.json` |
| `SparkJobDefinitionV2` | `SparkJobDefinitionV1.json` (yes — the file name still says V1 in V2 format), plus `Main/<file>` and optional `Libs/<file>` |

`Main/` takes at most one file, `Libs/` any number; each is base64 inline,
as every part is (Learn, read 2026-10-20).

**A `.jar` is refused as an inline `Main/` or `Libs/` part**, `400
BadRequest`: point `executableFile` or `additionalLibraryUris` at an
external `abfss://` path for one. Learn's V2 tutorial says the format
supports ".py or .scala" files (read 2026-10-20); whether an `.R`
file uploads inline, as this skill earlier said, is unconfirmed. The JSON
schema includes `executableFile`, `defaultLakehouseArtifactId`,
`mainClass`, `additionalLakehouseIds`, `commandLineArguments`,
`additionalLibraryUris`, `language`, `environmentArtifactId`; Learn's
properties table also lists `retryPolicy`, a `SimpleRetry` with
`retryCount` and `intervalBetweenRetriesInSeconds`. Its properties are on
the definition page.

What an update does differs by format (Learn, read 2026-10-20,
unmeasured):

- **V1 updates property references only.** It uploads and deletes no file
  in OneLake, and the `Main/` and `Libs/` checks do not apply.
- **V2 updates references and manages the OneLake files**: inline parts
  upload, and a replaced or removed file is deleted from OneLake.
- **`executableFile` is replaced whole.** It is a bare file name, which
  needs a matching `Main/` part in V2, or an external `abfss://` path,
  which needs none.
- **In V2, an update that omits `executableFile` or sets it `null`
  permanently deletes the main file from OneLake.** Always send it to
  keep the file; in V1 the same only clears the reference. Once
  `additionalLibraryUris` has been set, even to `[]`, it cannot go back
  to `null`.

Learn's V2 tutorial reads parts with `POST .../items/{id}/getDefinitionParts?format=SparkJobDefinitionV2`
and then `GET /v1/operations/{operationId}`; the spec's swagger has no
`getDefinitionParts` path, only `getDefinition` with the `format` query
(read 2026-10-20, neither measured). Learn's older V1 tutorial uploads the
main file to OneLake with a storage token and then sets its URL by an
update; V2 replaces that with inline parts.

## Git is not the live definition

Unmeasured. Whether `defaultLakehouseArtifactId` and
`environmentArtifactId` differ between the Git folder and a live
`getDefinition`, as logical and runtime ids do for other items, has not
been read. `rest-api` § Definition APIs has what `.platform` holds
live.

## REST beyond the generic set

Under `https://api.fabric.microsoft.com/v1/workspaces/{ws}/sparkJobDefinitions/{id}/`.
Learn lists the run under *Background Jobs* and the sessions under *Livy
Sessions*. The table is the spec's, at the SHA
above, with *On Learn* and *Measured* filled in. The Livy listings are
measured in [spark-monitoring.md](spark-monitoring.md); the logs behind a
session are [spark-monitoring-apis.md](spark-monitoring-apis.md)'s.

| Method | Path tail | Does | Body | Flags | On Learn | Measured |
| --- | --- | --- | --- | --- | --- | --- |
| `POST` | `jobs/sparkjob/instances` | Run on-demand [Spark job definition](/fabric/data-engineering/run-spark-job-definition) job instance | `executionData` | LRO | yes | no |
| `GET` | `livySessions` | Returns a list of livy sessions from the specified item identifier | | | yes | 2026-08-17 |
| `GET` | `livySessions?beta=true` | Returns a list of livy sessions from the specified item identifier (beta) | | beta | yes | no |
| `GET` | `livySessions/{livyId}` | Returns properties of the specified livy session | | | yes | no |

`rest-api` § Job Execution has the generic
`jobs/instances?jobType=...` form of the run.

## Measured deltas, and where to look next

None measured for the definition. The `.R` claim above is the skill's
earlier statement, undated; the `.jar` refusal and the V2 deletion are
Learn's (read 2026-10-20).

When this file runs out, read the spec's `swagger.json` and the
operation's `examples/` file, then Learn. Re-read the spec from the SHA
above: its commits are weekly, "Updating swagger files".
