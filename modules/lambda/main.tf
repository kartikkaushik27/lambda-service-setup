# Reads the deployment package the CI stage uploaded.
#
# The bucket has versioning enabled, so version_id changes on every upload
# even though the key is constant. Feeding it to s3_object_version below is
# what makes a plan detect new code - without it Terraform would see
# identical bucket/key arguments and leave the function untouched.
data "aws_s3_object" "artifact" {
  bucket = var.artifact_bucket
  key    = var.artifact_key
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  role          = var.execution_role_arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size
  architectures = [var.architecture]

  s3_bucket         = var.artifact_bucket
  s3_key            = var.artifact_key
  s3_object_version = data.aws_s3_object.artifact.version_id

  # Publishes an immutable numbered version per code change, so a previous
  # build can be re-pointed to without rebuilding it.
  publish = var.publish_version

  reserved_concurrent_executions = var.reserved_concurrent_executions

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []

    content {
      variables = var.environment_variables
    }
  }

  tracing_config {
    mode = var.tracing_mode
  }
}
