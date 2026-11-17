# Item types no skill owns: where their definitions are

Every item type whose spec folder has a `getDefinition`, at `a96c37a`
(2026-10-20), and that no skill in this payload owns. For an owned type,
`SKILL.md` § Definition APIs names the owner's file. Nothing below is
measured here: read the spec folder's `swagger.json`, `definitions.json`
and `examples/`, then the Learn page, and treat a first `getDefinition`
of a portal-made item as the ground truth.

Learn's
[item definition overview](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/item-definition-overview)
lists some of these pages and omits others, and lists Dataflow and KQL
Dashboard twice (read 2026-10-20). The rows marked *search* were found by
searching Learn for the type, not on that list.

| Item | Spec folder | Learn definition page |
| --- | --- | --- |
| Anomaly detector | [`anomalyDetector/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/anomalyDetector) | [Anomaly detector definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/anomalydetector-definition) (search) |
| Apache Airflow job | [`apacheAirflowJob/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/apacheAirflowJob) | none found; [REST API capabilities for Apache Airflow Jobs](https://learn.microsoft.com/fabric/data-factory/apache-airflow-jobs-api-capabilities) shows the parts (search) |
| API for GraphQL | [`graphQLApi/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/graphQLApi) | [API for GraphQL definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/graphql-api-definition) |
| Azure Databricks storage | [`azureDatabricksStorage/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/azureDatabricksStorage) | [Azure Databricks Storage definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/azure-databricks-storage-definition) |
| Copy job | [`copyJob/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/copyJob) | [Copy job definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/copyjob-definition) |
| Cosmos DB database | [`cosmosDbDatabase/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/cosmosDbDatabase) | [Cosmos DB Database definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/cosmosdb-database-definition) (search) |
| dbt job | [`dataBuildToolJob/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/dataBuildToolJob) | [dbt job definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/dbtjob-definition) |
| Digital twin builder | [`digitalTwinBuilder/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/digitalTwinBuilder) | [Digital twin builder definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/digital-twin-builder-definition) (search) |
| Digital twin builder flow | [`digitalTwinBuilderFlow/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/digitalTwinBuilderFlow) | [Digital twin builder flow definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/digital-twin-builder-flow-definition) (search) |
| Map | [`map/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/map) | [Map item definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/map-definition) (search) |
| Mirrored Azure Databricks catalog | [`mirroredAzureDatabricksCatalog/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/mirroredAzureDatabricksCatalog) | [Mirrored Azure Databricks Catalog definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/mirrored-azuredatabricks-unitycatalog-definition) |
| Mirrored catalog | [`mirroredCatalog/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/mirroredCatalog) | [Mirrored Catalog definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/mirrored-catalog-definition) |
| Mirrored database | [`mirroredDatabase/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/mirroredDatabase) | [Mirrored database definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/mirrored-database-definition) |
| Mounted Data Factory | [`mountedDataFactory/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/mountedDataFactory) | [Mounted Data Factory definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/mounted-data-factory-definition) |
| Org app | [`orgApp/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/orgApp) | [Org app definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/orgapp-definition) |
| Org app audience | [`orgAppAudience/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/orgAppAudience) | [Org app audience definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/orgappaudience-definition) |
| Paginated report | [`paginatedReport/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/paginatedReport) | [Paginated Report definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/paginatedreport-definition) |
| Plan | [`plan/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/plan) | [Plan definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/plan-definition) (search) |
| Policy set | [`policySet/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/policySet) | [PolicySet definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/policyset-definition) (search) |
| Snowflake database | [`snowflakeDatabase/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/snowflakeDatabase) | [Snowflake Database definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/snowflake-database-definition) |
| User data function | [`userDataFunction/`](https://github.com/microsoft/fabric-rest-api-specs/tree/main/userDataFunction) | [User Data Function definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/user-data-function-definition) (search) |

A spec folder with no `getDefinition` has no definition to index: ML
model, ML experiment, mirrored warehouse, warehouse snapshot, datamart and
dashboard among them (`a96c37a`). Plan, Cosmos DB and user data functions
each have a deferred skill brief; when one lands, its row moves to
`SKILL.md`'s index.

Re-list from a spec clone, not from this table:
`grep -l getDefinition */swagger.json` names every folder with a
definition, and the index in `SKILL.md` names the owned ones.
