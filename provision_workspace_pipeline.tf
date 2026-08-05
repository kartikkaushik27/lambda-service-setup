# A generic, reusable pipeline: init/plan/apply against whatever workspace
# it's given at runtime.
#
# IACM stages otherwise need to know their workspace at pipeline-authoring
# time, which the per-project self-service workspaces created by the
# environment-creation pipeline (environment_pipeline.tf) can't offer - they
# don't exist yet when that pipeline is written. This pipeline exists so that
# script can provision each one it creates, by calling this pipeline's
# execute API once per workspace id instead.

resource "harness_platform_pipeline" "provision_workspace" {
  identifier = "provision_iacm_workspace"
  name       = "Provision IACM Workspace"
  org_id     = var.harness_org_id
  project_id = var.harness_project_id

  yaml = templatefile("${path.module}/templates/provision-workspace-pipeline.yaml.tftpl", {
    pipeline_identifier = "provision_iacm_workspace"
    pipeline_name       = "Provision IACM Workspace"
    org_id              = var.harness_org_id
    project_id          = var.harness_project_id
    step_timeout        = var.step_timeout
  })
}
