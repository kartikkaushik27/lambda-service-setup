# AWS Lambda + Harness, with OpenTofu

Deploys an AWS Lambda function through a Harness pipeline that builds the
package, provisions the function and its Harness service with OpenTofu,
deploys it with the native AWS Lambda step, and proves it works.

## What is assumed to exist

The Harness **project** and the **AWS and GitHub connectors** are platform
plumbing owned outside this stack. They are referenced by identifier and never
created or modified here:

| Variable | Default |
|---|---|
| `harness_project_id` | `lambda_service_poc` |
| `aws_connector_id` | `aws_lambda_connector` |
| `github_connector_id` | `github_connector` |

## Layout

```
aws.tf          IAM role, versioned artifact bucket, log group
harness.tf      credentials, environment + infrastructure, IACM workspace
pipeline.tf     the 4-stage pipeline (YAML in templates/)
main.tf         locals, repository, generated files
variables.tf    every input, in one place

modules/
  lambda/       creates the AWS Lambda function
  service/      creates the Harness AwsLambda service

iacm/           what the pipeline runs: those two modules
lambda-src/     function source
harness/        generated function definition manifest
```

Two modules, deliberately: **create lambda** and **create service**. Everything
else is one-time scaffolding and lives in flat root files.

## The pipeline

```
Build Artifact  ->  Create Lambda and Service  ->  Deploy with Harness  ->  Verify Deployment
    (CI)                     (IACM)                    (Deployment)              (CI)
```

1. **Build Artifact** – zips `lambda-src/` and publishes it twice: to an
   immutable per-build key (`<function>/builds/<build number>.zip`) and to a
   stable key. It then exports where the package landed as step outputs:
   `ARTIFACT_BUCKET`, `ARTIFACT_KEY`, `ARTIFACT_REGION`.
2. **Create Lambda and Service** – runs the OpenTofu in `iacm/`: the two
   modules. Cost estimation is on, so each plan shows its cost impact.
3. **Deploy with Harness** – the native `AwsLambdaDeploy` step against the
   service the previous stage reconciled, with `AwsLambdaRollback` wired to a
   stage rollback on failure. Runs on a delegate; the other stages run on
   Harness Cloud.
4. **Verify Deployment** – invokes the function and fails unless it returns
   `statusCode: 200` with no `FunctionError`.

## The service does not know where its artifact lives

Every field of the service's artifact source is a runtime input:

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

The deploy stage fills them from stage 1's outputs. No bucket, path or
connector is stored on the service, so publishing to JFrog or a container
registry instead means changing the build step and the source `type` - not the
service, and not any consumer of it.

## Running it

Credentials are passed as environment variables, never committed:

```bash
export TF_VAR_aws_access_key_id=...      # short-lived STS credentials
export TF_VAR_aws_secret_access_key=...
export TF_VAR_aws_session_token=...
export TF_VAR_harness_platform_api_key=...
export TF_VAR_github_token=...

tofu init
tofu apply
```

That creates the scaffolding and the pipeline. From then on, deployments are
pipeline executions - not local applies.

Because the AWS credentials are short-lived, re-running `tofu apply` is also how
the pipeline's credentials get refreshed. An OIDC-based AWS connector removes
that step entirely.

For anything beyond a single operator, move state off the local disk by adding
a `backend "s3"` block with DynamoDB locking.

## Where values come from

`variables.tf` is the only place a value is defined for the original,
dedicated project. Everything its pipeline needs is rendered from it into two
generated, committed files:

- `harness/function-definition.json` – the manifest the native deploy step
  applies.
- `environments/lambda-service-poc.tfvars` – non-secret inputs for its IACM
  workspace, linked as a Git variable file (so the workspace itself declares
  no variables).

Every other, self-service project instead owns a hand-written
`environments/<project>.tfvars` – see "Self-service multi-lambda projects"
below.

Credentials reach the IACM run only as environment variables, from a
credentials variable set attached to the workspace, so they cannot end up in a
plan file. The workspace's own `connector` option is unusable with STS
credentials: it forwards the key pair but drops the session token.

## Two things worth knowing

**Detecting new code.** The stable S3 key never changes, so the function module
reads the object's `version_id` and passes it as `s3_object_version`. Without
that, a plan would see identical bucket/key arguments and leave the function
untouched.

**Tags.** Harness reconciles the function's tags to the deploy manifest and
removes any that are missing from it. The generated manifest therefore includes
the same tags OpenTofu applies - otherwise the deploy stage would strip the tags
the provisioning stage had just set.
