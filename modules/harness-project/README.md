# harness-project

Project-scoped Harness platform setup: the project itself, the secrets every
downstream component authenticates with, and the AWS and GitHub connectors
built on top of those secrets.

Applied once from the root configuration. Everything else in this repository
(pipeline, IACM workspace, service) references the identifiers this module
outputs.

## Usage

```hcl
module "harness_project" {
  source = "./modules/harness-project"

  org_id       = "default"
  project_id   = "lambda_service_poc"
  project_name = "Lambda Service POC"

  aws_region       = "us-east-1"
  github_owner     = "my-org"
  github_repo_name = "lambda-service-setup"

  aws_access_key_id        = var.aws_access_key_id
  aws_secret_access_key    = var.aws_secret_access_key
  aws_session_token        = var.aws_session_token
  github_token             = var.github_token
  harness_platform_api_key = var.harness_platform_api_key
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `org_id` / `project_id` / `project_name` | string | – | Harness scope and naming |
| `project_color` | string | `#0063F7` | UI colour |
| `project_tags` | list(string) | `[]` | Harness tags (`key:value`) |
| `secret_manager_identifier` | string | `harnessSecretManager` | Where secrets are stored |
| `aws_region` | string | – | AWS connector default region |
| `aws_connector_identifier` / `aws_connector_name` | string | `aws_lambda_connector` / `AWS Lambda Connector` | AWS connector naming |
| `github_connector_identifier` / `github_connector_name` | string | `github_connector` / `GitHub Connector` | GitHub connector naming |
| `github_owner` / `github_repo_name` | string | – | Repository the connector is scoped to |
| `aws_access_key_id`, `aws_secret_access_key`, `aws_session_token`, `github_token`, `harness_platform_api_key` | string (sensitive) | – | Credentials to store as secrets |

## Outputs

`project_id`, `aws_connector_id`, `github_connector_id`, `secret_ids`.

## Notes

The AWS connector uses `manual` credentials including a session token, so it
works with short-lived STS credentials. The GitHub connector sets
`execute_on_delegate = false` so connectivity is validated by the Harness
control plane - this project needs no delegate.

The Harness API key is stored as a secret because the OpenTofu run inside the
IACM stage manages Harness resources itself and needs platform credentials of
its own.
