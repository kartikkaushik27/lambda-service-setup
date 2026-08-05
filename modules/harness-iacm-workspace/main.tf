# ---------------------------------------------------------------------------
# Credentials variable set.
#
# Everything an IACM run needs in order to authenticate lives here, once, and
# is attached to workspaces by reference. Rotating a credential is a change to
# the underlying Harness secret - no workspace is touched - and any additional
# workspace inherits the same wiring by adding one identifier to its
# variable_sets list.
#
# All five values are injected as *environment* variables rather than Terraform
# variables, because both providers read them natively:
#   - the AWS provider reads AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY /
#     AWS_SESSION_TOKEN (the session token matters: the workspace `connector`
#     block only forwards the key pair and silently drops it, which breaks
#     short-lived STS credentials)
#   - the Harness provider reads HARNESS_ACCOUNT_ID / HARNESS_PLATFORM_API_KEY
# so `iacm/` declares no credential variables at all and cannot leak one into
# a plan file.
# ---------------------------------------------------------------------------

resource "harness_platform_infra_variable_set" "credentials" {
  identifier  = var.variable_set_identifier
  name        = var.variable_set_name
  org_id      = var.org_id
  project_id  = var.project_id
  description = "AWS and Harness credentials shared by IACM workspaces in this project."

  environment_variable {
    key        = "AWS_ACCESS_KEY_ID"
    value      = var.credential_secret_ids.aws_access_key_id
    value_type = "secret"
  }

  environment_variable {
    key        = "AWS_SECRET_ACCESS_KEY"
    value      = var.credential_secret_ids.aws_secret_access_key
    value_type = "secret"
  }

  environment_variable {
    key        = "AWS_SESSION_TOKEN"
    value      = var.credential_secret_ids.aws_session_token
    value_type = "secret"
  }

  environment_variable {
    key        = "HARNESS_PLATFORM_API_KEY"
    value      = var.credential_secret_ids.harness_platform_api_key
    value_type = "secret"
  }

  environment_variable {
    key        = "HARNESS_ACCOUNT_ID"
    value      = var.harness_account_id
    value_type = "string"
  }

  environment_variable {
    key        = "AWS_DEFAULT_REGION"
    value      = var.aws_region
    value_type = "string"
  }
}

# ---------------------------------------------------------------------------
# Workspace.
#
# Deliberately holds no terraform_variable blocks: the non-secret inputs of
# the configuration are committed alongside it as `config.auto.tfvars`, which
# OpenTofu loads automatically from the working directory. That keeps a single
# source of truth (the root variables.tf that renders it), makes every input
# reviewable in a pull request, and leaves the workspace itself describing
# only *where* to run.
# ---------------------------------------------------------------------------

resource "harness_platform_workspace" "this" {
  identifier  = var.identifier
  name        = var.name
  description = var.description
  org_id      = var.org_id
  project_id  = var.project_id

  provisioner_type    = var.provisioner_type
  provisioner_version = var.provisioner_version

  repository           = var.repository
  repository_branch    = var.repository_branch
  repository_path      = var.repository_path
  repository_connector = var.repository_connector

  cost_estimation_enabled = var.cost_estimation_enabled

  variable_sets = concat(
    [harness_platform_infra_variable_set.credentials.identifier],
    var.additional_variable_set_ids,
  )
}
