# Environment: definition and REST

An environment's definition parts and the staging, publish and library
operations it has beyond the generic item set. Generic CRUD,
`getDefinition` and `updateDefinition`, long-running operations and
pagination are `rest-api`'s, § Definition APIs and § Long-Running
Operations.

| | |
| --- | --- |
| REST `type` | `Environment`, under `/workspaces/{ws}/environments/{id}` |
| Git folder | `<display name>.Environment/` |
| Learn definition | [Environment definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/environment-definition) |
| Spec folder | [`environment/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/environment): `swagger.json`, `definitions.json`, `examples/` |
| Spec read | `6f817cb`, 2026-11-07: 31 operations |

## Definition

Default format (omit `format` or set to `null`); Learn's example sends the
string `"format": "null"` (read 2026-10-20, unmeasured). Every part is
optional. Key parts:

| Part path | Content |
| --- | --- |
| `Libraries/PublicLibraries/environment.yml` | Conda / pip dependencies |
| `Setting/Sparkcompute.yml` | Pool config: `driver_cores`, `driver_memory`, `executor_cores`, `executor_memory`, `dynamic_executor_allocation` (`min_executors` / `max_executors`), `runtime_version` |
| `Libraries/CustomLibraries/<name>.{jar\|py\|whl\|tar.gz}` | Custom user uploads — JAR + Python + wheel + R archive all supported here (unlike SparkJobDefinition V2 `Main`/`Libs`) |
| `.platform` | the item's metadata; `getDefinition` always returns it, and `updateDefinition` reads it only with `?updateMetadata=true` |

The field tables for `environment.yml` and `Sparkcompute.yml` are on
Learn's definition page; it lists more settings than the row above,
among them `enable_native_execution_engine`, `instance_pool_id` and
`spark_conf` (read 2026-10-20).

A custom live pool attaches to an environment, but its configuration
doesn't travel in these parts: Learn says live pools can't be managed via
environment public APIs or CI/CD, so a deploy carries the environment and
not its pool. Set the pool up in the portal in each workspace. The spec's
`staging/sparkcompute` update does carry `customLivePoolSupport` and
`customLivePoolSettings` in its non-beta form (below, read 2026-10-20,
unmeasured), which sits against that sentence; test one before relying on
either.

## Git is not the live definition

Unmeasured. `Sparkcompute.yml` names the pool by `instance_pool_id`, a
runtime id; whether a Git folder holds the same or a logical one has not
been read. `rest-api` § Definition APIs has what `.platform` holds
live.

## REST beyond the generic set

Under `https://api.fabric.microsoft.com/v1/workspaces/{ws}/environments/{id}/`.
The `staging/` paths read and change the draft, and the paths without it
read the published state; publish and cancel are the operations between
them. Learn's groups: *Items* (publish and cancel), *Staging*,
*Published* and *Pool Activations*, which only reads a custom live
pool's activation history and sets nothing (read 2026-11-07). The
publish log, `staging/publish/log`, needs write permission on the
environment, not read, and truncates the driver's stdout at 50 MB
with the marker `--- LOG TRUNCATED AT 50000000 BYTES ---` and the
header `x-ms-log-truncated` (Learn, read 2026-11-07). Most
operations exist twice in the spec, once `beta=true` and once `beta=false`,
and Learn lists both; the table keeps the spec's rows as they are. The
table is the spec's, at the SHA above, with *On
Learn* and *Measured* filled in. Nothing here is measured.

| Method | Path tail | Does | Body | Flags | On Learn | Measured |
| --- | --- | --- | --- | --- | --- | --- |
| `GET` | `staging/sparkcompute?beta=true` | Get environment staging spark compute | | beta | yes | no |
| `PATCH` | `staging/sparkcompute?beta=true` | Update environment staging spark compute. If you want to delete a spark property, set its value as null | `instancePool`, `driverCores`, `driverMemory`, `executorCores`, `executorMemory`, `dynamicExecutorAllocation`, `sparkProperties`, `runtimeVersion` | beta | yes | no |
| `GET` | `sparkcompute?beta=true` | Get environment spark compute | | beta | yes | no |
| `GET` | `staging/sparkcompute?beta=false` | Get environment staging spark compute | | | yes | no |
| `PATCH` | `staging/sparkcompute?beta=false` | Update environment staging spark compute. If you want to delete a spark property, set its value as null | `instancePool`, `driverCores`, `driverMemory`, `executorCores`, `executorMemory`, `dynamicExecutorAllocation`, `sparkProperties`, `runtimeVersion`, `customLivePoolSupport`, `customLivePoolSettings` | | yes | no |
| `GET` | `sparkcompute?beta=false` | Get environment spark compute | | | yes | no |
| `GET` | `staging/libraries?beta=false` | Get a list of libraries staged into environment | | | yes | no |
| `POST` | `staging/libraries` | Upload spark library into environment | | | yes | no |
| `DELETE` | `staging/libraries?libraryToDelete=` | Deletes a library from environment. It supports deleting one file at a time | | | yes | no |
| `GET` | `staging/libraries?beta=true` | Get environment staging libraries | | beta | yes | no |
| `POST` | `staging/libraries/{libraryName}` | Upload spark library into environment | | | yes | no |
| `DELETE` | `staging/libraries/{libraryName}` | Delete a custom library from environment. It supports deleting one file at a time. The supported file formats are .jar, .py, .whl, and .tar.gz | | | yes | no |
| `POST` | `staging/libraries/removeExternalLibrary` | Delete a spark external library from an environment | `name`, `version` | | yes | no |
| `POST` | `staging/libraries/importExternalLibraries` | Upload spark external libraries as an `environment.yml` file into environment. It overrides the list of existing external libraries in environment | | | yes | no |
| `GET` | `staging/libraries/exportExternalLibraries` | Export a set of external libraries saved in the environment in YML format | | | yes | no |
| `GET` | `libraries?beta=false` | Get environment published libraries | | | yes | no |
| `GET` | `libraries?beta=true` | Get environment published libraries | | beta | yes | no |
| `GET` | `libraries/exportExternalLibraries` | Export a set of external libraries published in the environment in `YML` format | | | yes | no |
| `POST` | `staging/publish?beta=false` | Trigger an environment publish operation | | LRO | yes | no |
| `POST` | `staging/publish?beta=true` | Trigger an environment publish operation | | beta | yes | no |
| `GET` | `staging/publish/log` | Get environment publish log | | | yes | no |
| `POST` | `staging/cancelPublish` | Trigger an environment publish cancellation | | | yes | no |
| `GET` | `poolActivations` | Lists pool activations for the specified environment | | | yes | no |
| `GET` | `poolActivations/{activationId}` | Gets properties of the specified pool activation | | | yes | no |

## Measured deltas, and where to look next

None measured. A custom live pool's settings are portal-only by Learn,
which the spec's `customLivePoolSettings` field disagrees with (above).

When this file runs out, read the spec's `swagger.json` and the
operation's `examples/` file, then Learn. Re-read the spec from the SHA
above: its commits are weekly, "Updating swagger files".
