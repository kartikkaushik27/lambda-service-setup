# ---------------------------------------------------------------------------
# Executed by the pipeline's IACM stage on every run - this is the deployment.
#
# Two modules, one per half of the stage: the AWS Lambda function, and the
# Harness service that represents it. Both are shared with the root
# configuration through ../modules, so there is one definition of each
# resource in the repository.
#
# Inputs come from config.auto.tfvars (rendered by the root configuration and
# loaded automatically), credentials from environment variables supplied by the
# workspace's credentials variable set. The workspace declares no variables.
# ---------------------------------------------------------------------------

module "lambda_function" {
  source = "../modules/lambda-function"

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

module "harness_lambda_service" {
  source = "../modules/harness-lambda-service"

  service_identifier = var.harness.service_identifier
  service_name       = var.function.name
  org_id             = var.harness.org_id
  project_id         = var.harness.project_id

  github_connector_id      = var.harness.github_connector_id
  github_branch            = var.harness.github_branch
  function_definition_path = var.harness.function_definition_path

  aws_connector_id           = var.harness.aws_connector_id
  aws_region                 = var.aws_region
  artifact_bucket            = var.artifact.bucket
  artifact_source_identifier = var.harness.artifact_source_identifier
  artifact_file_path         = var.artifact.service_file_path

  # The service describes a function that must already exist, so that a failed
  # function deployment never leaves a service pointing at nothing.
  depends_on = [module.lambda_function]
}
