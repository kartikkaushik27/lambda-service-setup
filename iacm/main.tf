# Executed by the pipeline's IACM stage on every run - this is the deployment.
#
# Two modules: one creates the Lambda function, one creates the Harness service
# for it.
#
# Inputs come from config.auto.tfvars, which the root configuration renders and
# OpenTofu loads automatically. Credentials come from environment variables
# supplied by the workspace's credentials variable set, so the workspace itself
# declares no variables.

module "lambda" {
  source = "../modules/lambda"

  function_name      = var.function.name
  description        = "Deployed by Harness IACM from ${lookup(var.tags, "Repository", "OpenTofu")}"
  execution_role_arn = var.function.execution_role_arn

  runtime      = var.function.runtime
  handler      = var.function.handler
  timeout      = var.function.timeout
  memory_size  = var.function.memory_size
  architecture = var.function.architecture

  environment_variables = var.function.environment_variables
  publish_version       = var.function.publish_version

  artifact_bucket = var.artifact.bucket
  artifact_key    = var.artifact.key
}

module "service" {
  source = "../modules/service"

  service_identifier = var.harness.service_identifier
  service_name       = var.function.name
  org_id             = var.harness.org_id
  project_id         = var.harness.project_id

  github_connector_id      = var.harness.github_connector_id
  github_branch            = var.harness.github_branch
  function_definition_path = var.harness.function_definition_path

  artifact_source_identifier = var.harness.artifact_source_identifier

  # The service describes a function that must already exist, so a failed
  # function deployment never leaves a service pointing at nothing.
  depends_on = [module.lambda]
}
