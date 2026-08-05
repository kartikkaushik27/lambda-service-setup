# AWS Lambda delivery with OpenTofu and Harness

Provisions an AWS Lambda function and delivers it through a Harness pipeline
that builds the package, applies OpenTofu to deploy it, and then proves the
deployment works by invoking the function.

Everything - AWS infrastructure, the Harness project, connectors, secrets, the
IACM workspace, the pipeline, and the service - is defined as code in this
repository.

## Pipeline

```
 ┌─────────────────┐  ┌──────────────────────────┐  ┌──────────────────┐  ┌───────────────────┐
 │ Build Artifact  │  │ Create Lambda and Service│  │ Deploy with      │  │ Verify Deployment │
 │      (CI)       │─▶│          (IACM)          │─▶│ Harness          │─▶│       (CI)        │
 │                 │  │                          │  │ (Deployment)     │  │                   │
 │ zip lambda-src/ │  │ tofu init / plan / apply  │  │ AwsLambdaDeploy  │  │ invoke function,  │
 │ publish to S3   │  │ → aws_lambda_function     │  │ through the      │  │ assert on the     │
 │ export build key│  │ → harness_platform_service│  │ managed service  │  │ response          │
 └─────────────────┘  └──────────────────────────┘  └──────────────────┘  └───────────────────┘
```

Stages 1, 2 and 4 run on Harness Cloud. Stage 3 is a Deployment stage, so it
runs on a **delegate** - one must be healthy for the pipeline to pass.

The two deployment stages are deliberate, not redundant: stage 2 provisions the
function as infrastructure, and stage 3 releases a specific build through
Harness so the deployment is tracked, attributable and rollback-capable.

### How a build reaches the deploy stage

The service does not hard-code which package it deploys. Its artifact
`filePath` is left as a runtime input, and the pipeline supplies it:

1. Stage 1 publishes the package to an immutable per-build key,
   `<function>/builds/<build number>.zip`, and exports that key as the step
   output variable `ARTIFACT_KEY`. It also copies it to the stable key that
   stage 2's OpenTofu reads.
2. Stage 3 passes that output into the service's runtime input as
   `serviceInputs`, so the release names the exact package this run built:

```yaml
filePath: <+pipeline.stages.build_artifact.spec.execution.steps.package_and_publish.output.outputVariables.ARTIFACT_KEY>
```

Set `service_artifact_file_path` to a literal key instead of `"<+input>"` to
pin the service to one package.

## Who owns what

The split is deliberate: **the root configuration owns scaffolding, the
pipeline owns deployments.**

| | Root configuration (`tofu apply`, occasional) | `iacm/` (pipeline, every run) |
|---|---|---|
| AWS | IAM execution role, artifact bucket, log group | the Lambda function |
| Harness | project, secrets, connectors, environment, infrastructure, IACM workspace, pipeline | the AwsLambda service |

Nothing about a deployment requires a local apply. Conversely, nothing
long-lived is re-provisioned on every build.

## Layout

```
.
├── main.tf                 wires the modules together
├── variables.tf            single source of truth for every input
├── locals.tf               naming and tagging
├── generated.tf            files rendered into the repo (see below)
├── moved.tf                state moves from the pre-module layout
├── outputs.tf
├── providers.tf            AWS / Harness / GitHub providers, default tags
├── versions.tf
├── backend.tf.example      remote state, for when local state stops being enough
│
├── modules/
│   ├── lambda-foundation/       IAM role, artifact bucket, log group
│   ├── lambda-function/         the aws_lambda_function
│   ├── harness-lambda-service/  the Harness AwsLambda service
│   ├── harness-project/         project, secrets, connectors
│   ├── harness-lambda-environment/ environment + AwsLambda infrastructure
│   ├── harness-iacm-workspace/  workspace + credentials variable set
│   └── harness-lambda-pipeline/ the four-stage delivery pipeline
│
├── iacm/                   the deployment, run by the IACM stage
│   ├── main.tf             calls ../modules/lambda-function and
│   │                       ../modules/harness-lambda-service
│   ├── variables.tf        five grouped inputs, no credentials
│   ├── moved.tf            state moves for the workspace's own state
│   └── config.auto.tfvars  GENERATED - do not edit
│
├── lambda-src/             function source, packaged by the CI stage
├── harness/                GENERATED function definition manifest
└── templates/              templates for the generated files
```

The two modules under `iacm/` are the same modules the root configuration
would use, so each resource is defined exactly once in the repository.

## Why the IACM workspace has no variables

The workspace previously carried sixteen `terraform_variable` blocks and three
environment variables. It now carries none, through two changes:

**Credentials live in a Harness variable set** and are injected as environment
variables that both providers read natively - `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` for AWS and `HARNESS_ACCOUNT_ID`,
`HARNESS_PLATFORM_API_KEY` for Harness. The configuration in `iacm/` therefore
declares no credential variables and cannot leak one into a plan file. Rotating
a credential means updating one Harness secret; adding a second workspace means
attaching the same variable set.

Note that the workspace `connector` block does not work for this: it forwards
only the AWS key pair and drops the session token, which fails with
short-lived STS credentials.

**Non-secret inputs are generated into `iacm/config.auto.tfvars`** by the root
apply and committed. OpenTofu loads `*.auto.tfvars` automatically from its
working directory, so the values arrive without any workspace configuration -
defined once in the root `variables.tf`, and visible as a diff in a pull
request rather than as a field in a UI.

What is left in `iacm/variables.tf` is five inputs, grouped into objects
(`function`, `artifact`, `harness`, plus `aws_region` and `tags`) so adding a
setting does not mean adding another loose variable.

## Generated files

Both are committed, because the pipeline reads them from the repository:

| File | Rendered from | Consumed by |
|---|---|---|
| `harness/function-definition.json` | `templates/function-definition.json.tftpl` | the Harness service manifest |
| `iacm/config.auto.tfvars` | `templates/config.auto.tfvars.tftpl` | the IACM stage's OpenTofu run |

Do not edit them by hand - the next root apply overwrites them. Change
`variables.tf` instead.

## Usage

### One-time setup

```bash
export TF_VAR_aws_access_key_id="..."
export TF_VAR_aws_secret_access_key="..."
export TF_VAR_aws_session_token="..."
export TF_VAR_github_token="..."
export TF_VAR_harness_platform_api_key="..."

tofu init
tofu apply
```

Then commit and push, so the pipeline can read the repository:

```bash
git add -A && git commit -m "Provision Lambda delivery stack" && git push
```

### Deploying

Run the pipeline - the URL is in the `harness_pipeline_url` output. Each run
packages the current `lambda-src/`, applies `iacm/`, and verifies the result.

Changing the function's runtime, memory, timeout or environment variables is a
change to the root `variables.tf` followed by `tofu apply` (which re-renders
`iacm/config.auto.tfvars`), a commit, and a pipeline run.

## Production considerations

Already handled:

- **Secrets** never appear in configuration or state input: they arrive as
  `TF_VAR_*` at the root and as environment variables inside IACM runs.
- **Tagging** is applied through the provider's `default_tags`, so every
  resource is tagged in both the root and IACM configurations. The same tags
  are rendered into the function definition manifest, because Harness
  reconciles the function's tags to that manifest and untags anything missing
  from it - without them the deploy stage would strip the tags the provisioning
  stage had just applied.
- **Artifact history**: bucket versioning is enabled and superseded packages
  expire on a schedule, so any earlier build stays deployable.
- **Log retention** is declared rather than left at Lambda's unbounded default.
- **Immutable function versions** are published on each code change.
- **Encryption and access**: the artifact bucket is encrypted (SSE-S3) with
  public access fully blocked, and `force_destroy` defaults to off.
- **Input validation** on runtime, memory, timeout, retention and durations
  fails fast at plan time rather than mid-apply at the AWS API.
- **Version pinning**: providers are pinned to a minor series and
  `.terraform.lock.hcl` is committed.
- **Verification**: a deployment is not considered successful until the
  function has been invoked and its response asserted on.
- **Traceable releases**: each build is published under an immutable key and
  deployed by name through Harness, with `AwsLambdaRollback` configured as the
  stage's rollback step.
- **Cost estimation** is enabled on the IACM workspace, so a plan shows the
  cost impact of the change alongside it.

Worth doing before real production use:

- **Remote state** for the root configuration - see `backend.tf.example`.
  (`iacm/` state is already remote: the IACM workspace owns it.)
- **Long-lived credentials**: this stack uses short-lived STS credentials that
  expire, which is why they are re-exported for each apply. In a permanent
  setup, use an IAM role assumed by a Harness AWS connector with OIDC instead
  of storing keys as secrets.
- **Approval before apply** in the IACM stage, so a plan is reviewed before it
  reaches production.
- **Pin `provisioner_version`** once you have confirmed which OpenTofu
  versions your Harness account offers.
- **Least-privilege IAM**: the execution role gets `AWSLambdaBasicExecutionRole`
  and nothing else; add what the function actually needs through
  `lambda_additional_policy_arns`.

## Inputs

See `variables.tf` for the full list with descriptions, and
`terraform.tfvars.example` for a populated starting point. Each module also
documents its own interface in `modules/<name>/README.md`.

## Outputs

| Output | Description |
|---|---|
| `harness_pipeline_url` | Link to the pipeline |
| `github_repository_url` | Repository holding this configuration |
| `lambda_execution_role_arn` | Role the function runs as |
| `artifact_bucket` / `artifact_key` | Where packages are published |
| `log_group_name` | Log group for the function |
| `harness_project_id` | Harness project |
| `harness_environment_id` / `harness_infrastructure_id` | Target of the native deploy stage |
| `iacm_workspace_id` | Workspace the provisioning stage runs |
| `iacm_credentials_variable_set_id` | Variable set reusable by other workspaces |
