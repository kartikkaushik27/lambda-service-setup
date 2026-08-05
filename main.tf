# ---------------------------------------------------------------------------
# Root configuration.
#
# Applied by hand (or from a bootstrap pipeline) and responsible only for
# long-lived scaffolding: the AWS foundation the function needs, the Harness
# project it is delivered from, and the pipeline that does the delivering.
#
# The function itself and its Harness service are deliberately NOT here - they
# are provisioned on every pipeline run by the OpenTofu in iacm/, so a
# deployment is a pipeline execution rather than someone's local apply.
# ---------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# Repository holding this configuration, the function source, and the OpenTofu
# the pipeline runs. Created empty (auto_init = false) so pushing the local
# working copy becomes the initial commit.
resource "github_repository" "this" {
  name        = var.github_repo_name
  description = "OpenTofu-managed AWS Lambda function + Harness native AWS Lambda service/pipeline setup"
  visibility  = "private"
  auto_init   = false

  has_issues   = true
  has_projects = false
  has_wiki     = false
}

# ---------------------------------------------------------------------------
# AWS foundation: execution role, artifact bucket, log group.
# ---------------------------------------------------------------------------

module "lambda_foundation" {
  source = "./modules/lambda-foundation"

  function_name        = var.function_name
  artifact_bucket_name = local.artifact_bucket_name

  artifact_bucket_force_destroy = var.artifact_bucket_force_destroy
  artifact_retention_days       = var.artifact_retention_days
  log_retention_days            = var.log_retention_days
  additional_policy_arns        = var.lambda_additional_policy_arns
}

# ---------------------------------------------------------------------------
# Harness project: secrets and connectors everything else authenticates with.
# ---------------------------------------------------------------------------

module "harness_project" {
  source = "./modules/harness-project"

  org_id       = var.harness_org_id
  project_id   = var.harness_project_id
  project_name = var.harness_project_name
  project_tags = ["purpose:lambda-poc", "environment:${var.environment}"]

  aws_region       = var.aws_region
  github_owner     = var.github_owner
  github_repo_name = var.github_repo_name

  aws_access_key_id        = var.aws_access_key_id
  aws_secret_access_key    = var.aws_secret_access_key
  aws_session_token        = var.aws_session_token
  github_token             = var.github_token
  harness_platform_api_key = var.harness_platform_api_key

  depends_on = [github_repository.this]
}

# ---------------------------------------------------------------------------
# Deployment target for the native AWS Lambda deploy step.
# ---------------------------------------------------------------------------

module "harness_lambda_environment" {
  source = "./modules/harness-lambda-environment"

  org_id     = var.harness_org_id
  project_id = module.harness_project.project_id

  environment_identifier = var.environment
  environment_name       = var.environment
  environment_type       = var.harness_environment_type

  aws_connector_id = module.harness_project.aws_connector_id
  aws_region       = var.aws_region
}

# ---------------------------------------------------------------------------
# IACM workspace the provisioning stage runs, plus the credentials variable
# set it authenticates with.
# ---------------------------------------------------------------------------

module "harness_iacm_workspace" {
  source = "./modules/harness-iacm-workspace"

  identifier = "lambda_iacm_workspace"
  name       = "Lambda IACM Workspace"
  org_id     = var.harness_org_id
  project_id = module.harness_project.project_id

  provisioner_version     = var.provisioner_version
  cost_estimation_enabled = var.cost_estimation_enabled

  repository           = "https://github.com/${var.github_owner}/${var.github_repo_name}"
  repository_branch    = var.github_branch
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

# ---------------------------------------------------------------------------
# Delivery pipeline: build -> provision -> verify.
# ---------------------------------------------------------------------------

module "harness_lambda_pipeline" {
  source = "./modules/harness-lambda-pipeline"

  org_id     = var.harness_org_id
  project_id = module.harness_project.project_id

  github_connector_id = module.harness_project.github_connector_id
  github_repo_name    = var.github_repo_name
  workspace_id        = module.harness_iacm_workspace.workspace_id

  function_name         = var.function_name
  artifact_bucket       = module.lambda_foundation.artifact_bucket
  artifact_key          = local.artifact_key
  artifact_build_prefix = local.artifact_build_prefix
  aws_region            = var.aws_region

  # The service is created by the IACM stage; the deploy stage references it
  # by identifier and supplies its runtime input.
  service_id         = local.service_identifier
  artifact_source_id = local.artifact_source_identifier
  environment_id     = module.harness_lambda_environment.environment_id
  infrastructure_id  = module.harness_lambda_environment.infrastructure_id

  ci_image     = var.ci_image
  step_timeout = var.step_timeout

  credential_secret_ids = {
    aws_access_key_id     = module.harness_project.secret_ids.aws_access_key_id
    aws_secret_access_key = module.harness_project.secret_ids.aws_secret_access_key
    aws_session_token     = module.harness_project.secret_ids.aws_session_token
  }
}
