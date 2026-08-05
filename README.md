# lambda-service-setup

OpenTofu configuration that provisions a **one-time** foundation plus a
self-contained **3-stage Harness pipeline** that does everything else:

```
CI (Build Artifact)  ->  IACM (Create Lambda and Service)  ->  CI (Test)
zip lambda-src/,          runs Terraform (iacm/*.tf) that        invokes the
upload to S3               creates the real aws_lambda_function   deployed function
                            + the Harness native AWS Lambda        and fails the
                            service, in one apply                  pipeline if the
                                                                    response isn't
                                                                    healthy
```

All three stages run on **Harness Cloud** (hosted runners) - no delegate is
required to run the pipeline.

## One-time setup (local `tofu apply`)

A small amount of infrastructure rarely changes, so it's provisioned once by
local OpenTofu rather than by the pipeline:

- An **IAM execution role** for the Lambda function (`aws.tf`)
- An **S3 bucket** that the CI stage uploads deployment packages into (`aws.tf`)
- The **GitHub repository**, Harness **project**, **secrets**, **connectors**,
  the **IACM workspace** definition, and the **pipeline** itself

Everything else - the actual `aws_lambda_function` and the Harness `Service`
entity - is created every time the pipeline runs, by the pipeline's IACM
stage (see [Architecture](#architecture) below).

## Architecture

```
lambda-src/index.js              -> zipped by the CI stage and uploaded to S3
harness/function-definition.json -> Lambda "CreateFunction" manifest, read by
                                     the Harness Service via a GitHub connector
iacm/*.tf                        -> Terraform run by the pipeline's IACM stage:
                                     creates aws_lambda_function + the Harness
                                     "lambda_service" service
*.tf (repo root)                 -> one-time setup: GitHub repo, AWS IAM
                                     role/S3 bucket, and every Harness
                                     resource below
```

Harness resources created (org `default`, project `lambda_service_poc`):

- Secrets: `aws_access_key_id`, `aws_secret_access_key`, `aws_session_token`, `github_pat`, `harness_platform_pat`
- Connectors: `aws_lambda_connector` (AWS, manual/session-token auth), `github_connector`
- IACM Workspace: `lambda_iacm_workspace` (OpenTofu, points at `iacm/` in this repo)
- Pipeline: `deploy_lambda_pipeline` ("Lambda CI-IACM-Test Pipeline"), 3 stages:
  1. `build_artifact` (CI) - zips `lambda-src/` and uploads it to S3
  2. `create_lambda_and_service` (IACM) - `init` / `plan` / `apply` against the workspace above
  3. `test_lambda_deployment` (CI) - `aws lambda invoke` + asserts `statusCode: 200`
- Service `lambda_service` (type `AwsLambda`) - created/updated by the IACM
  stage's Terraform run (`iacm/main.tf`), not by local `tofu apply`

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
- `harness_platform_api_key` - Harness Personal Access Token (also stored as the `harness_platform_pat` Harness secret, for the IACM stage's own `harness` provider)
- `github_token` - GitHub Personal Access Token

## Usage

```bash
# 1. Export sensitive credentials (see creds.txt locally - never commit it)
export TF_VAR_aws_access_key_id="..."
export TF_VAR_aws_secret_access_key="..."
export TF_VAR_aws_session_token="..."
export TF_VAR_harness_platform_api_key="..."
export TF_VAR_github_token="..."

# 2. Provision the one-time foundation (see "One-time setup" above)
tofu init
tofu plan
tofu apply

# 3. Push this repo's code (including iacm/) into the GitHub repo tofu just
#    created - the CI stage clones it, and the IACM workspace fetches iacm/
#    from it on every pipeline run.
git init
git remote add origin https://github.com/<github_owner>/<github_repo_name>.git
git add .
git commit -m "Initial OpenTofu + Harness Lambda pipeline setup"
git push -u origin main

# 4. Run the pipeline in Harness (see the harness_pipeline_url output from
#    `tofu apply`). Since the CI codebase build is a runtime input, trigger
#    it with a branch, e.g. via the API:
#      pipeline:
#        identifier: deploy_lambda_pipeline
#        properties:
#          ci:
#            codebase:
#              build:
#                type: branch
#                spec:
#                  branch: main
```

## Function definition manifest

`harness/function-definition.json` is generated by OpenTofu (see
[`templates/function-definition.json.tftpl`](templates/function-definition.json.tftpl))
and must be pushed to git any time you change `function_name`, `runtime`,
`handler`, `memory_size`, or `timeout`. Two important rules from Harness's
AWS Lambda deployment type:

- Every field in the function definition must be **camelCase**
  (`functionName`, `runtime`, `handler`, `role`, `timeout`, `memorySize`) -
  not the PascalCase used by the raw AWS `CreateFunction` API.
- Do **not** include a `code`/`S3Bucket`/`S3Key` block - Harness injects the
  deployment package automatically from the service's primary S3 artifact
  source at deploy time.

## The `iacm/` Terraform config

This is a **standalone** Terraform configuration - it is not a module of the
root config and has its own state, managed entirely by Harness IACM. The
pipeline's IACM stage runs `init` / `plan` / `apply` against it on every
execution:

- `data.aws_s3_object.lambda_zip` reads whichever object the CI stage most
  recently uploaded. Because the S3 bucket has **versioning enabled**, its
  `version_id` changes on every CI upload; passing that as
  `s3_object_version` is what makes Terraform detect a code change and
  update the Lambda function on each run (bucket/key never change).
- `aws_lambda_function.this` - the actual Lambda function ("Create Lambda").
- `harness_platform_service.this` - the Harness native `AwsLambda` service
  entity ("Create Service"), so the deployment stays visible in Harness too.

AWS credentials are injected as plain environment variables
(`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_SESSION_TOKEN`) on the
`harness_platform_workspace` resource rather than via the workspace's
built-in `connector` block - that block only forwards a static access
key/secret pair and drops the session token, which breaks STS-based
credentials like ours.

## Known limitation

The AWS credentials used here are a **temporary STS session token**. Both
`tofu apply` and the pipeline's CI/IACM stages will fail once that token
expires (typically within a day). For anything beyond a POC, switch to
IAM-role or OIDC-based authentication instead of manual access-key/session-
token credentials.
