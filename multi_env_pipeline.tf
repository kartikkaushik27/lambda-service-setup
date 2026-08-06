# Single pipeline for the self-service, multi-project, multi-region flow:
#
#   Create Workspaces (scripted - the only step with no native equivalent)
#     -> Create Lambda and Service   (native IACMTerraformPlugin, repeated per workspace)
#     -> Deploy Lambdas              (native AwsLambdaDeploy,      repeated per lambda)
#     -> Validate Lambdas            (scripted invoke+assert,      repeated per lambda)
#
# Driven entirely by environments/*.tfvars - see templates/multi-env-pipeline.yaml.tftpl
# for the full flow and README.md for the branch/region mapping.

resource "harness_platform_pipeline" "multi_env" {
  identifier = "lambda_multi_env_pipeline"
  name       = "Lambda Multi-Environment Pipeline"
  org_id     = var.harness_org_id
  project_id = var.harness_project_id

  yaml = templatefile("${path.module}/templates/multi-env-pipeline.yaml.tftpl", {
    pipeline_identifier = "lambda_multi_env_pipeline"
    pipeline_name       = "Lambda Multi-Environment Pipeline"
    org_id              = var.harness_org_id
    project_id          = var.harness_project_id

    github_connector_id = var.github_connector_id
    github_repo_name    = var.github_repo_name
    repo_url            = "https://github.com/${var.github_owner}/${var.github_repo_name}"

    credentials_variable_set = harness_platform_infra_variable_set.credentials.identifier
    harness_pat_secret       = harness_platform_secret_text.harness_pat.identifier

    # environments/<project_name>.tfvars for the original project, pinned to
    # its own dedicated pipeline (pipeline.tf) - this pipeline must skip it.
    legacy_project_name = local.project_name

    ci_image               = var.ci_image
    workspace_step_timeout = var.multi_env_workspace_step_timeout
    iacm_step_timeout      = var.multi_env_iacm_step_timeout
    max_concurrency        = var.multi_env_max_concurrency
    deploy_max_concurrency = var.multi_env_deploy_max_concurrency
    iacm_max_concurrency   = var.multi_env_iacm_max_concurrency

    aws_access_key_id_secret     = harness_platform_secret_text.aws_access_key_id.identifier
    aws_secret_access_key_secret = harness_platform_secret_text.aws_secret_access_key.identifier
    aws_session_token_secret     = harness_platform_secret_text.aws_session_token.identifier
  })
}

# ---------------------------------------------------------------------------
# Triggers: one per branch. dev owns us-east-1 only; test/stage/prod each own
# us-east-1 and us-west-1 - the pipeline script itself decides which regions
# a branch owns (templates/multi-env-pipeline.yaml.tftpl), this only decides
# which branch push starts it.
# ---------------------------------------------------------------------------

locals {
  multi_env_branches = ["dev", "test", "stage", "prod"]
}

resource "harness_platform_triggers" "multi_env" {
  for_each = toset(local.multi_env_branches)

  identifier = "lambda_multi_env_${each.value}_trigger"
  name       = "Lambda Multi-Env - ${each.value}"
  org_id     = var.harness_org_id
  project_id = var.harness_project_id
  target_id  = harness_platform_pipeline.multi_env.identifier

  yaml = templatefile("${path.module}/templates/multi-env-trigger.yaml.tftpl", {
    trigger_identifier  = "lambda_multi_env_${each.value}_trigger"
    trigger_name        = "Lambda Multi-Env - ${each.value}"
    pipeline_id         = harness_platform_pipeline.multi_env.identifier
    pipeline_name       = harness_platform_pipeline.multi_env.name
    org_id              = var.harness_org_id
    project_id          = var.harness_project_id
    branch              = each.value
    github_connector_id = var.github_connector_id
    github_repo_name    = var.github_repo_name
  })
}
