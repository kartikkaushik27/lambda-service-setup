# Harness-managed secrets backing the AWS and GitHub connectors below.
# Values are supplied via sensitive TF variables (TF_VAR_* env vars) and are
# encrypted at rest by Harness's built-in secret manager.

resource "harness_platform_secret_text" "aws_access_key_id" {
  identifier                = "aws_access_key_id"
  name                      = "aws_access_key_id"
  org_id                    = var.harness_org_id
  project_id                = harness_platform_project.this.identifier
  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = var.aws_access_key_id
}

resource "harness_platform_secret_text" "aws_secret_access_key" {
  identifier                = "aws_secret_access_key"
  name                      = "aws_secret_access_key"
  org_id                    = var.harness_org_id
  project_id                = harness_platform_project.this.identifier
  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = var.aws_secret_access_key
}

resource "harness_platform_secret_text" "aws_session_token" {
  identifier                = "aws_session_token"
  name                      = "aws_session_token"
  org_id                    = var.harness_org_id
  project_id                = harness_platform_project.this.identifier
  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = var.aws_session_token
}

resource "harness_platform_secret_text" "github_pat" {
  identifier                = "github_pat"
  name                      = "github_pat"
  org_id                    = var.harness_org_id
  project_id                = harness_platform_project.this.identifier
  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = var.github_token
}
