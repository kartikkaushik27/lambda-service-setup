# CI -> IACM -> Verify pipeline.
#
# The YAML lives in templates/pipeline.yaml.tftpl rather than in a heredoc so
# it stays readable as YAML - indentation mistakes surface in the file itself
# instead of inside an HCL string.
#
# Every stage runs on Harness Cloud, so the pipeline needs no delegate.

locals {
  pipeline_yaml = templatefile("${path.module}/templates/pipeline.yaml.tftpl", {
    pipeline_name       = var.pipeline_name
    pipeline_identifier = var.pipeline_identifier
    org_id              = var.org_id
    project_id          = var.project_id

    github_connector_id = var.github_connector_id
    github_repo_name    = var.github_repo_name

    function_name         = var.function_name
    artifact_bucket       = var.artifact_bucket
    artifact_key          = var.artifact_key
    artifact_build_prefix = var.artifact_build_prefix
    aws_region            = var.aws_region

    workspace_id = var.workspace_id

    service_id         = var.service_id
    artifact_source_id = var.artifact_source_id
    environment_id     = var.environment_id
    infrastructure_id  = var.infrastructure_id

    ci_image     = var.ci_image
    step_timeout = var.step_timeout

    aws_access_key_id_secret     = var.credential_secret_ids.aws_access_key_id
    aws_secret_access_key_secret = var.credential_secret_ids.aws_secret_access_key
    aws_session_token_secret     = var.credential_secret_ids.aws_session_token
  })
}

resource "harness_platform_pipeline" "this" {
  identifier = var.pipeline_identifier
  name       = var.pipeline_name
  org_id     = var.org_id
  project_id = var.project_id
  yaml       = local.pipeline_yaml
}
