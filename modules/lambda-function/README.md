# lambda-function

Creates or updates the AWS Lambda function itself from a deployment package
already sitting in S3.

This module is called from `iacm/`, i.e. it runs inside the pipeline's IACM
stage on every execution - it is the "Create Lambda" half of that stage.

## Usage

```hcl
module "lambda_function" {
  source = "../modules/lambda-function"

  function_name      = "my-function"
  execution_role_arn = "arn:aws:iam::123456789012:role/my-function-exec-role"
  artifact_bucket    = "my-function-artifacts-123456789012"
  artifact_key       = "my-function/lambda.zip"
  runtime            = "nodejs20.x"
  handler            = "index.handler"
  timeout            = 10
  memory_size        = 128
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `function_name` | string | – | Function name |
| `description` | string | `Managed by OpenTofu via Harness IACM` | Console description |
| `execution_role_arn` | string | – | Runtime IAM role |
| `artifact_bucket` / `artifact_key` | string | – | Where the CI stage published the zip |
| `runtime` / `handler` | string | – | Runtime and entry point |
| `timeout` / `memory_size` | number | – | 1–900 s / 128–10240 MB |
| `architecture` | string | `x86_64` | `x86_64` or `arm64` |
| `environment_variables` | map(string) | `{}` | Runtime env vars |
| `publish_version` | bool | `true` | Publish an immutable version per change |
| `reserved_concurrent_executions` | number | `-1` | Reserved concurrency |
| `tracing_mode` | string | `PassThrough` | X-Ray mode |

## Outputs

`function_name`, `function_arn`, `qualified_arn`, `version`,
`artifact_version_id`.

## How code changes are detected

The S3 key is constant across builds, so the module reads the object's
`version_id` (bucket versioning must be enabled) and passes it as
`s3_object_version`. That value changes on every CI upload, which is what
causes a plan to update the function code.
