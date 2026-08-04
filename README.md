# lambda-service-setup

OpenTofu configuration that provisions:

1. **AWS prerequisites** for an AWS Lambda function: an IAM execution role, an
   S3 bucket, and a zipped deployment package uploaded to it.
2. A **Harness project** (`lambda_service_poc`) fully wired for Harness's
   **native AWS Lambda deployment type** - an AWS connector, a GitHub
   connector, a Service (`serviceDefinition.type: AwsLambda`), an
   Environment + Infrastructure Definition, and a single-stage Pipeline.

Running the resulting Harness pipeline (`Deploy Lambda`) is what actually
creates/updates the Lambda function in AWS - via Harness's built-in
`AwsLambdaDeploy` step, not a Terraform `aws_lambda_function` resource.

## Architecture

```
lambda-src/index.js              -> zipped and uploaded to S3 (aws.tf)
harness/function-definition.json -> Lambda "CreateFunction" manifest, read by
                                     the Harness Service via a GitHub connector
*.tf                              -> creates the GitHub repo, AWS IAM role/S3
                                     bucket, and every Harness resource below
```

Harness resources created (org `default`, project `lambda_service_poc`):

- Secrets: `aws_access_key_id`, `aws_secret_access_key`, `aws_session_token`, `github_pat`
- Connectors: `aws_lambda_connector` (AWS, manual/session-token auth), `github_connector`
- Service: `lambda_service` (type `AwsLambda`)
- Environment: `dev` (PreProduction) + Infrastructure Definition `lambda_infra`
- Pipeline: `deploy_lambda_pipeline`, one stage (`deploy_lambda`), deployment type `AwsLambda`

## Variables

See [`variables.tf`](variables.tf) for the full list and defaults. The ones
you're most likely to change:

| Variable | Default | Purpose |
|---|---|---|
| `function_name` | `lambda-service-poc` | Lambda function name; also seeds the IAM role and S3 bucket names |
| `runtime` | `nodejs20.x` | Lambda runtime |
| `handler` | `index.handler` | Lambda handler |
| `memory_size` | `128` | MB |
| `timeout` | `10` | seconds |
| `lambda_environment_variables` | `{}` | Lambda env vars |
| `aws_region` | `us-east-1` | Region for IAM/S3/Lambda |
| `harness_org_id` / `harness_project_id` | `default` / `lambda_service_poc` | Where Harness resources live |
| `github_owner` / `github_repo_name` / `github_branch` | `kartikkaushik27` / `lambda-service-setup` / `main` | Where this repo/manifest lives |

Sensitive inputs (never put these in a committed file - export as `TF_VAR_*`):

- `aws_access_key_id`, `aws_secret_access_key`, `aws_session_token` - AWS STS session credentials
- `harness_platform_api_key` - Harness Personal Access Token
- `github_token` - GitHub Personal Access Token

## Usage

```bash
# 1. Export sensitive credentials (see creds.txt locally - never commit it)
export TF_VAR_aws_access_key_id="..."
export TF_VAR_aws_secret_access_key="..."
export TF_VAR_aws_session_token="..."
export TF_VAR_harness_platform_api_key="..."
export TF_VAR_github_token="..."

# 2. Provision everything
tofu init
tofu plan
tofu apply

# 3. Push this repo's code into the GitHub repo tofu just created
git init
git remote add origin https://github.com/<github_owner>/<github_repo_name>.git
git add .
git commit -m "Initial OpenTofu + Harness Lambda service setup"
git push -u origin main

# 4. Run the pipeline in Harness to create the Lambda function in AWS
#    (see the harness_pipeline_url output from `tofu apply`)
```

## Known limitation

The AWS credentials used here are a **temporary STS session token**. Both
`tofu apply` and any Harness pipeline run against the resulting AWS connector
will fail once that token expires. For anything beyond a POC, switch the
`aws_lambda_connector` to IAM-role or OIDC-based authentication instead of
manual access-key/session-token credentials.
