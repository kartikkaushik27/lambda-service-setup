# harness-lambda-pipeline

The three-stage delivery pipeline:

1. **Build Artifact** (CI) - packages `lambda-src/` and publishes `lambda.zip`
   to the artifact bucket, tagged with the build number and commit SHA.
2. **Create Lambda and Service** (IACM) - runs `init`, `plan` and `apply` on
   the workspace, which provisions the Lambda function and the Harness service.
3. **Verify Deployment** (CI) - invokes the function and fails the pipeline
   unless it responds successfully, so a green run means a live function.

Every stage runs on Harness Cloud, so no delegate is required.

## Usage

```hcl
module "harness_lambda_pipeline" {
  source = "./modules/harness-lambda-pipeline"

  org_id     = "default"
  project_id = module.harness_project.project_id

  github_connector_id = module.harness_project.github_connector_id
  github_repo_name    = "lambda-service-setup"
  workspace_id        = module.harness_iacm_workspace.workspace_id

  function_name   = "my-function"
  artifact_bucket = module.lambda_foundation.artifact_bucket
  artifact_key    = "my-function/lambda.zip"
  aws_region      = "us-east-1"

  credential_secret_ids = {
    aws_access_key_id     = module.harness_project.secret_ids.aws_access_key_id
    aws_secret_access_key = module.harness_project.secret_ids.aws_secret_access_key
    aws_session_token     = module.harness_project.secret_ids.aws_session_token
  }
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `pipeline_identifier` / `pipeline_name` | string | `deploy_lambda_pipeline` / `Lambda CI-IACM-Test Pipeline` | Pipeline identity |
| `org_id` / `project_id` | string | – | Harness scope |
| `github_connector_id` / `github_repo_name` | string | – | Codebase the CI stages clone |
| `workspace_id` | string | – | IACM workspace the deployment stage runs |
| `function_name` | string | – | Function built and verified |
| `artifact_bucket` / `artifact_key` | string | – | Where the package is published |
| `aws_region` | string | – | Region of the function and bucket |
| `ci_image` | string | `alpine:3.19` | Image the CI steps run in |
| `step_timeout` | string | `10m` | Per-step timeout |
| `credential_secret_ids` | object | – | Harness secrets the CI steps read AWS credentials from |

## Outputs

`pipeline_id`, `pipeline_yaml`.

## Where the YAML lives

`templates/pipeline.yaml.tftpl`. Keeping it in a real YAML file rather than an
HCL heredoc means indentation errors show up in the file being edited, and the
rendered result is available as the `pipeline_yaml` output for review before
applying.
