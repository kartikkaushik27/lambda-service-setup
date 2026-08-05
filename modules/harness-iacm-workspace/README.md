# harness-iacm-workspace

An IACM workspace plus the credentials variable set it authenticates with.

## Usage

```hcl
module "harness_iacm_workspace" {
  source = "./modules/harness-iacm-workspace"

  identifier = "lambda_iacm_workspace"
  name       = "Lambda IACM Workspace"
  org_id     = "default"
  project_id = module.harness_project.project_id

  repository           = "https://github.com/my-org/lambda-service-setup"
  repository_branch    = "main"
  repository_path      = "iacm"
  repository_connector = module.harness_project.github_connector_id

  harness_account_id = var.harness_account_id
  aws_region         = var.aws_region

  credential_secret_ids = {
    aws_access_key_id        = module.harness_project.secret_ids.aws_access_key_id
    aws_secret_access_key    = module.harness_project.secret_ids.aws_secret_access_key
    aws_session_token        = module.harness_project.secret_ids.aws_session_token
    harness_platform_api_key = module.harness_project.secret_ids.harness_pat
  }
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `identifier` / `name` / `description` | string | – | Workspace identity |
| `org_id` / `project_id` | string | – | Harness scope |
| `provisioner_type` | string | `opentofu` | `opentofu`, `terraform` or `terragrunt` |
| `provisioner_version` | string | `latest` | Pin an exact provisioner version, or track latest |
| `repository`, `repository_branch`, `repository_path`, `repository_connector` | string | – | Where the configuration lives |
| `cost_estimation_enabled` | bool | `true` | Cost estimates alongside plans |
| `harness_account_id` / `aws_region` | string | – | Exported as `HARNESS_ACCOUNT_ID` / `AWS_DEFAULT_REGION` |
| `variable_set_identifier` / `variable_set_name` | string | `iacm_credentials` / `IACM Credentials` | Variable set identity |
| `credential_secret_ids` | object | – | Identifiers of existing Harness secrets |
| `additional_variable_set_ids` | list(string) | `[]` | Extra variable sets to attach |

## Outputs

`workspace_id`, `credentials_variable_set_id`.

## Why the workspace declares no variables

Two decisions keep it that way:

**Credentials go in a variable set as environment variables.** Both providers
read them natively - the AWS provider takes `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY` and `AWS_SESSION_TOKEN`, and the Harness provider
takes `HARNESS_ACCOUNT_ID` and `HARNESS_PLATFORM_API_KEY`. The configuration
therefore declares no credential variables and cannot leak one into a plan
file. Note that the workspace `connector` block is *not* usable here: it
forwards only the AWS key pair and drops the session token, which fails with
short-lived STS credentials.

**Non-secret inputs are committed as `config.auto.tfvars`,** which OpenTofu
loads automatically from its working directory. The root configuration renders
that file, so values stay defined once, and any change to them shows up in a
pull request diff instead of in a workspace's UI settings.
