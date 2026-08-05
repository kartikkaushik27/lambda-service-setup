resource "harness_platform_project" "this" {
  identifier = var.project_id
  name       = var.project_name
  org_id     = var.org_id
  color      = var.project_color
  tags       = var.project_tags
}

# ---------------------------------------------------------------------------
# Secrets.
#
# Values arrive as sensitive variables (TF_VAR_* env vars) and are stored in
# the Harness built-in secret manager, so nothing downstream - connectors,
# pipeline steps, IACM runs - ever references a credential in plain text.
# ---------------------------------------------------------------------------

resource "harness_platform_secret_text" "aws_access_key_id" {
  identifier                = "aws_access_key_id"
  name                      = "aws_access_key_id"
  org_id                    = var.org_id
  project_id                = harness_platform_project.this.identifier
  secret_manager_identifier = var.secret_manager_identifier
  value_type                = "Inline"
  value                     = var.aws_access_key_id
}

resource "harness_platform_secret_text" "aws_secret_access_key" {
  identifier                = "aws_secret_access_key"
  name                      = "aws_secret_access_key"
  org_id                    = var.org_id
  project_id                = harness_platform_project.this.identifier
  secret_manager_identifier = var.secret_manager_identifier
  value_type                = "Inline"
  value                     = var.aws_secret_access_key
}

resource "harness_platform_secret_text" "aws_session_token" {
  identifier                = "aws_session_token"
  name                      = "aws_session_token"
  org_id                    = var.org_id
  project_id                = harness_platform_project.this.identifier
  secret_manager_identifier = var.secret_manager_identifier
  value_type                = "Inline"
  value                     = var.aws_session_token
}

resource "harness_platform_secret_text" "github_pat" {
  identifier                = "github_pat"
  name                      = "github_pat"
  org_id                    = var.org_id
  project_id                = harness_platform_project.this.identifier
  secret_manager_identifier = var.secret_manager_identifier
  value_type                = "Inline"
  value                     = var.github_token
}

# Consumed by the IACM stage: the OpenTofu it runs manages Harness resources
# itself, so it needs platform credentials of its own.
resource "harness_platform_secret_text" "harness_pat" {
  identifier                = "harness_platform_pat"
  name                      = "harness_platform_pat"
  org_id                    = var.org_id
  project_id                = harness_platform_project.this.identifier
  secret_manager_identifier = var.secret_manager_identifier
  value_type                = "Inline"
  value                     = var.harness_platform_api_key
}

# ---------------------------------------------------------------------------
# Connectors
# ---------------------------------------------------------------------------

resource "harness_platform_connector_aws" "this" {
  identifier = var.aws_connector_identifier
  name       = var.aws_connector_name
  org_id     = var.org_id
  project_id = harness_platform_project.this.identifier

  manual {
    access_key_ref    = harness_platform_secret_text.aws_access_key_id.identifier
    secret_key_ref    = harness_platform_secret_text.aws_secret_access_key.identifier
    session_token_ref = harness_platform_secret_text.aws_session_token.identifier
    region            = var.aws_region
  }
}

resource "harness_platform_connector_github" "this" {
  identifier      = var.github_connector_identifier
  name            = var.github_connector_name
  org_id          = var.org_id
  project_id      = harness_platform_project.this.identifier
  url             = "https://github.com/${var.github_owner}/${var.github_repo_name}"
  connection_type = "Repo"

  # Connectivity is checked by the Harness control plane rather than a
  # delegate, so this project needs no delegate of its own.
  execute_on_delegate = false

  credentials {
    http {
      username  = var.github_owner
      token_ref = harness_platform_secret_text.github_pat.identifier
    }
  }
}
