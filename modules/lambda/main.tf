# Terraform only creates the function *shell* here - a placeholder package
# just so aws_lambda_function has something to create with. Real code is
# owned exclusively by the pipeline's native "Deploy Lambdas" (AwsLambdaDeploy)
# stage, which publishes the actual CI-built artifact from S3 after this
# workspace applies. The lifecycle block below is what enforces that split:
# without it, every apply would re-read the artifact and push a competing
# code update at the same time the native deploy step is doing the same
# thing, which is what caused CodeSHA256/"update in progress" races when
# many lambdas deployed concurrently.
data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/.placeholder/${var.function_name}.zip"

  source {
    content  = "exports.handler = async () => ({ statusCode: 200, body: \"placeholder - awaiting first deploy\" });"
    filename = "index.js"
  }
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

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

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

  # Freezes whatever code is currently live (placeholder on first create,
  # or a real CI artifact on every apply after the native deploy step has
  # run at least once) so re-applying this workspace never reverts or
  # collides with it - the s3_* attributes are listed too since functions
  # created before this change still have them set in state.
  lifecycle {
    ignore_changes = [filename, source_code_hash, publish, s3_bucket, s3_key, s3_object_version]
  }
}
