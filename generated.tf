# ---------------------------------------------------------------------------
# Files rendered into the repository by this configuration and committed
# alongside it. Both are inputs to the pipeline, so generating them here keeps
# variables.tf the only place a value is defined - and any change to them is a
# reviewable diff in a pull request.
# ---------------------------------------------------------------------------

# The AWS Lambda function definition manifest the Harness service reads at
# deploy time.
#
# Every field must be camelCase (functionName, memorySize, ...), and the
# manifest must NOT carry a code/S3Bucket/S3Key block: Harness injects the
# deployment package from the service's artifact source itself.
#
# The tags matter beyond housekeeping. Harness reconciles the function's tags
# to whatever this manifest declares - it will untag anything missing from it -
# so omitting them would have the deploy stage strip the tags the OpenTofu
# apply had just set, and the two stages would fight on every run. Both sides
# read the same local.common_tags, so they agree.
resource "local_file" "lambda_function_definition" {
  filename        = "${path.module}/${local.function_definition_path}"
  file_permission = "0644"

  content = templatefile("${path.module}/templates/function-definition.json.tftpl", {
    function_name = var.function_name
    runtime       = var.runtime
    handler       = var.handler
    role_arn      = module.lambda_foundation.execution_role_arn
    timeout       = var.timeout
    memory_size   = var.memory_size
    tags          = jsonencode(local.common_tags)
  })
}

# Non-secret inputs for the OpenTofu the IACM stage runs. Named *.auto.tfvars
# so OpenTofu loads it automatically from iacm/, which is what lets the IACM
# workspace itself declare no variables at all.
resource "local_file" "iacm_config" {
  filename        = "${path.module}/iacm/config.auto.tfvars"
  file_permission = "0644"

  content = templatefile("${path.module}/templates/config.auto.tfvars.tftpl", {
    aws_region = var.aws_region

    function_name         = var.function_name
    runtime               = var.runtime
    handler               = var.handler
    timeout               = var.timeout
    memory_size           = var.memory_size
    architecture          = var.lambda_architecture
    publish_version       = var.lambda_publish_version
    execution_role_arn    = module.lambda_foundation.execution_role_arn
    environment_variables = jsonencode(var.lambda_environment_variables)

    artifact_bucket            = module.lambda_foundation.artifact_bucket
    artifact_key               = local.artifact_key
    service_artifact_file_path = var.service_artifact_file_path

    harness_org_id             = var.harness_org_id
    harness_project_id         = module.harness_project.project_id
    aws_connector_id           = module.harness_project.aws_connector_id
    github_connector_id        = module.harness_project.github_connector_id
    github_branch              = var.github_branch
    function_definition_path   = local.function_definition_path
    service_identifier         = local.service_identifier
    artifact_source_identifier = local.artifact_source_identifier

    tags = local.common_tags
  })
}
