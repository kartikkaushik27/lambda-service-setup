# lambda

Creates the AWS Lambda function *shell* - the function, its runtime config,
and IAM role wiring - with a tiny inline placeholder as its initial code.

This module is called from `iacm/`, i.e. it runs inside the pipeline's IACM
stage on every execution - it is the "Create Lambda" half of that stage.

It deliberately does **not** manage the function's real code after creation
(`lifecycle.ignore_changes` on the code fields). Actual code deploys are
owned exclusively by the pipeline's native "Deploy Lambdas" (`AwsLambdaDeploy`)
stage, which publishes the CI-built S3 artifact. Splitting it this way avoids
Terraform and the native deploy step racing to update the same function's
code on every run.

## Usage

```hcl
module "lambda" {
  source = "../modules/lambda"

  function_name      = "my-function"
  execution_role_arn = "arn:aws:iam::123456789012:role/my-function-exec-role"
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
| `runtime` / `handler` | string | – | Runtime and entry point |
| `timeout` / `memory_size` | number | – | 1–900 s / 128–10240 MB |
| `architecture` | string | `x86_64` | `x86_64` or `arm64` |
| `environment_variables` | map(string) | `{}` | Runtime env vars |
| `publish_version` | bool | `true` | Publish an immutable version per change (native deploy step only) |
| `reserved_concurrent_executions` | number | `-1` | Reserved concurrency |
| `tracing_mode` | string | `PassThrough` | X-Ray mode |

## Outputs

`function_name`, `function_arn`, `qualified_arn`, `version`.

## Why the code is a placeholder

Terraform only needs *some* code to create the function with - real code
always comes from the native `AwsLambdaDeploy` step, which runs right after
this workspace applies. `lifecycle.ignore_changes` on the code-related
arguments means re-applying this workspace later (e.g. to change memory size)
never touches the function's live code.
