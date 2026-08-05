# ---------------------------------------------------------------------------
# This configuration owns the scaffolding: AWS infrastructure the function
# needs (aws.tf), Harness platform wiring for delivery (harness.tf), and the
# pipeline (pipeline.tf).
#
# It does NOT create the Lambda function or the Harness service. Those are the
# two modules under modules/, applied by the pipeline's IACM stage from iacm/,
# so a deployment is a pipeline execution rather than someone's local apply.
#
# The Harness project and the AWS/GitHub connectors are assumed to exist -
# they are referenced by identifier from variables.tf.
# ---------------------------------------------------------------------------

locals {
  # Applied to every AWS resource via the provider's default_tags, and passed
  # to the IACM configuration so pipeline-created resources match.
  common_tags = merge(
    {
      Application = var.function_name
      Environment = var.environment
      Owner       = var.owner
      ManagedBy   = "OpenTofu"
      Repository  = "${var.github_owner}/${var.github_repo_name}"
    },
    var.additional_tags,
  )

  artifact_bucket_name = "${var.function_name}-artifacts-${data.aws_caller_identity.current.account_id}"

  # Stable key the OpenTofu run deploys the function from. The bucket is
  # versioned, so this single key still carries the history of every build.
  artifact_key = "${var.function_name}/lambda.zip"

  # Immutable per-build packages, as <build number>.zip. The deploy stage hands
  # one of these to the service by name.
  artifact_build_prefix = "${var.function_name}/builds"

  # The service is created by the IACM stage, but the pipeline references it,
  # so the identifiers are fixed here and shared with iacm/ through the
  # generated tfvars below.
  service_identifier         = "lambda_service"
  artifact_source_identifier = "lambda_artifact"

  function_definition_path = "harness/function-definition.json"
}

# Repository holding this configuration, the function source, and the OpenTofu
# the pipeline runs.
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
# Files rendered into the repository and committed alongside it. Both are read
# by the pipeline, so generating them keeps variables.tf the only place a value
# is defined, and any change to them is a reviewable diff.
# ---------------------------------------------------------------------------

# The function definition manifest the native deploy step applies.
#
# Every field must be camelCase (functionName, memorySize, ...) and the
# manifest must not carry a code/S3Bucket/S3Key block - Harness injects the
# package from the service's artifact source.
#
# The tags matter beyond housekeeping: Harness reconciles the function's tags
# to this manifest and untags anything missing from it, so omitting them would
# have the deploy stage strip the tags the OpenTofu run just applied.
resource "local_file" "lambda_function_definition" {
  filename        = "${path.module}/${local.function_definition_path}"
  file_permission = "0644"

  content = templatefile("${path.module}/templates/function-definition.json.tftpl", {
    function_name = var.function_name
    runtime       = var.runtime
    handler       = var.handler
    role_arn      = aws_iam_role.lambda_exec.arn
    timeout       = var.timeout
    memory_size   = var.memory_size
    tags          = jsonencode(local.common_tags)
  })
}

# Non-secret inputs for the OpenTofu the IACM stage runs. Named *.auto.tfvars
# so OpenTofu loads it automatically from iacm/, which is what lets the
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
    execution_role_arn    = aws_iam_role.lambda_exec.arn
    environment_variables = jsonencode(var.lambda_environment_variables)

    artifact_bucket = aws_s3_bucket.artifacts.id
    artifact_key    = local.artifact_key

    harness_org_id             = var.harness_org_id
    harness_project_id         = var.harness_project_id
    github_connector_id        = var.github_connector_id
    github_branch              = var.github_branch
    function_definition_path   = local.function_definition_path
    service_identifier         = local.service_identifier
    artifact_source_identifier = local.artifact_source_identifier

    tags = local.common_tags
  })
}
