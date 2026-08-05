# Build -> provision -> deploy -> verify.
#
# The YAML lives in templates/pipeline.yaml.tftpl rather than in a heredoc, so
# it stays readable as YAML and indentation mistakes surface in the file being
# edited. The rendered result is available as the pipeline_yaml output.

resource "harness_platform_pipeline" "this" {
  identifier = "deploy_lambda_pipeline"
  name       = "Lambda CI-IACM-Deploy Pipeline"
  org_id     = var.harness_org_id
  project_id = var.harness_project_id

  yaml = templatefile("${path.module}/templates/pipeline.yaml.tftpl", {
    pipeline_identifier = "deploy_lambda_pipeline"
    pipeline_name       = "Lambda CI-IACM-Deploy Pipeline"
    org_id              = var.harness_org_id
    project_id          = var.harness_project_id

    github_connector_id = var.github_connector_id
    github_repo_name    = var.github_repo_name

    function_name         = var.function_name
    artifact_bucket       = aws_s3_bucket.artifacts.id
    artifact_key          = local.artifact_key
    artifact_build_prefix = local.artifact_build_prefix
    aws_region            = var.aws_region
    aws_connector_id      = var.aws_connector_id

    workspace_id = harness_platform_workspace.this.identifier

    # Created by the IACM stage, referenced here by identifier.
    service_id         = local.service_identifier
    artifact_source_id = local.artifact_source_identifier

    environment_id    = module.environment.environment_id
    infrastructure_id = module.environment.infrastructure_id

    ci_image     = var.ci_image
    step_timeout = var.step_timeout

    aws_access_key_id_secret     = harness_platform_secret_text.aws_access_key_id.identifier
    aws_secret_access_key_secret = harness_platform_secret_text.aws_secret_access_key.identifier
    aws_session_token_secret     = harness_platform_secret_text.aws_session_token.identifier
  })
}
