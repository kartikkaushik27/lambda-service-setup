# The "separate pipeline" for self-service projects: on a push to
# dev/test/stage/prod that touches environments/**, create or update one
# IACM workspace per (project file, region that branch owns), then provision
# every one of them.
#
# One shared pipeline, not one per branch - see environment-triggers.tf for
# how the four branches feed it.

resource "harness_platform_pipeline" "create_environment_workspaces" {
  identifier = "create_environment_workspaces"
  name       = "Create Environment Workspaces"
  org_id     = var.harness_org_id
  project_id = var.harness_project_id

  yaml = templatefile("${path.module}/templates/environment-pipeline.yaml.tftpl", {
    pipeline_identifier = "create_environment_workspaces"
    pipeline_name       = "Create Environment Workspaces"
    org_id              = var.harness_org_id
    project_id          = var.harness_project_id

    github_connector_id = var.github_connector_id
    github_repo_name    = var.github_repo_name
    repo_url            = "https://github.com/${var.github_owner}/${var.github_repo_name}"

    ci_image     = var.ci_image
    step_timeout = var.step_timeout

    harness_pat_secret = harness_platform_secret_text.harness_pat.identifier

    provision_pipeline_id   = harness_platform_pipeline.provision_workspace.identifier
    provision_timeout       = var.environment_pipeline_provision_timeout
    provision_poll_interval = var.environment_pipeline_poll_interval_seconds
    provision_poll_attempts = var.environment_pipeline_poll_attempts
  })
}
