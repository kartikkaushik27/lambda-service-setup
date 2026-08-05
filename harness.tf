# Harness platform setup for the delivery pipeline.
#
# The project and the AWS/GitHub connectors are assumed to exist already -
# they are platform plumbing owned outside this stack, referenced here by
# identifier (see variables.tf). This configuration only creates what is
# specific to delivering this function.

# ---------------------------------------------------------------------------
# Credentials.
#
# Still managed here rather than assumed, because these are short-lived STS
# credentials: refreshing them is `tofu apply`, and the pipeline immediately
# has live credentials again. Swap to an OIDC-based connector and this whole
# block goes away.
# ---------------------------------------------------------------------------

resource "harness_platform_secret_text" "aws_access_key_id" {
  identifier                = "aws_access_key_id"
  name                      = "aws_access_key_id"
  org_id                    = var.harness_org_id
  project_id                = var.harness_project_id
  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = var.aws_access_key_id
}

resource "harness_platform_secret_text" "aws_secret_access_key" {
  identifier                = "aws_secret_access_key"
  name                      = "aws_secret_access_key"
  org_id                    = var.harness_org_id
  project_id                = var.harness_project_id
  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = var.aws_secret_access_key
}

resource "harness_platform_secret_text" "aws_session_token" {
  identifier                = "aws_session_token"
  name                      = "aws_session_token"
  org_id                    = var.harness_org_id
  project_id                = var.harness_project_id
  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = var.aws_session_token
}

resource "harness_platform_secret_text" "github_pat" {
  identifier                = "github_pat"
  name                      = "github_pat"
  org_id                    = var.harness_org_id
  project_id                = var.harness_project_id
  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = var.github_token
}

# The OpenTofu the pipeline runs manages Harness resources itself, so it needs
# platform credentials of its own.
resource "harness_platform_secret_text" "harness_pat" {
  identifier                = "harness_platform_pat"
  name                      = "harness_platform_pat"
  org_id                    = var.harness_org_id
  project_id                = var.harness_project_id
  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = var.harness_platform_api_key
}

# ---------------------------------------------------------------------------
# Deployment target for the native AWS Lambda deploy step. A Deployment stage
# cannot run without an environment and an infrastructure definition.
#
# This is the same module iacm/main.tf uses for every self-service project's
# own (environment, region) deployment targets - see modules/environment.
# ---------------------------------------------------------------------------

module "environment" {
  source = "./modules/environment"

  org_id     = var.harness_org_id
  project_id = var.harness_project_id

  environment_identifier = var.environment
  environment_name       = var.environment
  environment_type       = var.harness_environment_type

  infra_identifier = "lambda_infra"
  infra_name       = "lambda-infra"

  aws_connector_id = var.aws_connector_id
  aws_region       = var.aws_region
}

# ---------------------------------------------------------------------------
# IACM: everything an OpenTofu run needs to authenticate, defined once and
# attached to workspaces by reference.
#
# All of it is injected as environment variables because both providers read
# them natively - AWS_* for the AWS provider, HARNESS_* for the Harness
# provider - so the configuration in iacm/ declares no credential variables
# and cannot leak one into a plan file.
#
# The workspace `connector` block is not usable here: it forwards only the AWS
# key pair and drops the session token, which fails with STS credentials.
# ---------------------------------------------------------------------------

resource "harness_platform_infra_variable_set" "credentials" {
  identifier  = "iacm_credentials"
  name        = "IACM Credentials"
  org_id      = var.harness_org_id
  project_id  = var.harness_project_id
  description = "AWS and Harness credentials shared by IACM workspaces in this project."

  environment_variable {
    key        = "AWS_ACCESS_KEY_ID"
    value      = harness_platform_secret_text.aws_access_key_id.identifier
    value_type = "secret"
  }

  environment_variable {
    key        = "AWS_SECRET_ACCESS_KEY"
    value      = harness_platform_secret_text.aws_secret_access_key.identifier
    value_type = "secret"
  }

  environment_variable {
    key        = "AWS_SESSION_TOKEN"
    value      = harness_platform_secret_text.aws_session_token.identifier
    value_type = "secret"
  }

  environment_variable {
    key        = "HARNESS_PLATFORM_API_KEY"
    value      = harness_platform_secret_text.harness_pat.identifier
    value_type = "secret"
  }

  # Resolved by Harness itself at every pipeline execution rather than passed
  # as a static value, so this can never drift from the account the IACM
  # stage is actually running in.
  environment_variable {
    key        = "HARNESS_ACCOUNT_ID"
    value      = "<+account.identifier>"
    value_type = "string"
  }

  environment_variable {
    key        = "AWS_DEFAULT_REGION"
    value      = var.aws_region
    value_type = "string"
  }
}

# Non-secret inputs come from environments/lambda-service-poc.tfvars (rendered
# above) plus the three variables below - the exact same mechanism the
# environment-creation pipeline uses for every self-service workspace it
# creates (environment_pipeline.tf), so there is exactly one way this works.
resource "harness_platform_workspace" "this" {
  identifier  = "lambda_iacm_workspace"
  name        = "Lambda IACM Workspace"
  description = "Creates the Lambda function and its Harness service."
  org_id      = var.harness_org_id
  project_id  = var.harness_project_id

  provisioner_type    = "opentofu"
  provisioner_version = var.provisioner_version

  repository           = "https://github.com/${var.github_owner}/${var.github_repo_name}"
  repository_branch    = var.github_branch
  repository_path      = "iacm"
  repository_connector = var.github_connector_id

  cost_estimation_enabled = var.cost_estimation_enabled

  variable_sets = [harness_platform_infra_variable_set.credentials.identifier]

  terraform_variable_file {
    repository           = "https://github.com/${var.github_owner}/${var.github_repo_name}"
    repository_branch    = var.github_branch
    repository_connector = var.github_connector_id
    repository_path      = "environments/${local.project_name}.tfvars"
  }

  terraform_variable {
    key        = "region"
    value      = var.aws_region
    value_type = "string"
  }

  terraform_variable {
    key        = "environment_name"
    value      = var.environment
    value_type = "string"
  }

  terraform_variable {
    key        = "manage_environment"
    value      = "false"
    value_type = "string"
  }

  depends_on = [local_file.project_tfvars]
}
