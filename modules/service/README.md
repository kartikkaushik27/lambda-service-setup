# service

Creates the Harness native AWS Lambda service
(`serviceDefinition.type: AwsLambda`) for a function.

Called from `iacm/`, so it runs in the pipeline's IACM stage - the "create
service" half of that stage.

## The service does not know where its artifact lives

Every field of the artifact source is a **runtime input**:

```yaml
sources:
  - identifier: lambda_artifact
    type: AmazonS3
    spec:
      connectorRef: <+input>
      region: <+input>
      bucketName: <+input>
      filePath: <+input>
```

The stage that built the package supplies them at deploy time. Nothing about a
bucket, a path or a connector is stored on the service, so the same service
works whether the package is published to S3, JFrog or a registry - only the
publishing step and `artifact_source_type` change.

## Usage

```hcl
module "service" {
  source = "../modules/service"

  service_name        = "my-function"
  org_id              = "default"
  project_id          = "my_project"
  github_connector_id = "github_connector"
  github_branch       = "main"
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `service_identifier` | string | `lambda_service` | Harness service identifier |
| `service_name` | string | – | Display name |
| `org_id` / `project_id` | string | – | Harness scope |
| `github_connector_id` / `github_branch` | string | – | Where the manifest is fetched from |
| `function_definition_path` | string | `harness/function-definition.json` | Manifest path in the repo |
| `artifact_source_identifier` | string | `lambda_artifact` | Artifact source identifier |
| `artifact_source_type` | string | `AmazonS3` | Kind of artifact store |

## Outputs

`service_id`, `service_yaml`.

## Note on the manifest

Harness requires every field in an `AwsLambdaFunctionDefinition` manifest to be
camelCase (`functionName`, `memorySize`, …) and rejects a
`code`/`S3Bucket`/`S3Key` block, because it injects the package from the
artifact source. It also reconciles the function's **tags** to the manifest and
removes any that are missing from it, so the manifest the root configuration
generates includes them.
