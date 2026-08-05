# lambda-foundation

Long-lived AWS infrastructure that a Lambda function needs *before* any code
is deployed: an execution role, a bucket to publish deployment packages to,
and a log group with an explicit retention policy.

Applied once from the root configuration (not from the pipeline) because none
of it changes between deployments.

## Usage

```hcl
module "lambda_foundation" {
  source = "./modules/lambda-foundation"

  function_name        = "my-function"
  artifact_bucket_name = "my-function-artifacts-123456789012"
  log_retention_days   = 30
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `function_name` | string | – | Lambda function name; seeds the role and log group names |
| `artifact_bucket_name` | string | – | Globally unique artifact bucket name |
| `artifact_bucket_force_destroy` | bool | `false` | Permit deleting a non-empty bucket |
| `artifact_retention_days` | number | `90` | Expiry for superseded package versions |
| `log_retention_days` | number | `30` | CloudWatch Logs retention |
| `additional_policy_arns` | list(string) | `[]` | Extra managed policies for the execution role |
| `max_session_duration` | number | `3600` | Execution role max session duration |

## Outputs

`execution_role_arn`, `execution_role_name`, `artifact_bucket`,
`artifact_bucket_arn`, `log_group_name`.

## Notes

Bucket versioning is enabled deliberately. The CI stage always uploads to the
same S3 key, and the deployment stage keys off the object's `version_id` to
notice that the code changed, so each build stays individually addressable
and recoverable.
