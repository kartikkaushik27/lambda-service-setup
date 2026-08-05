# Renders the AWS Lambda function-definition manifest that's checked into
# the GitHub repo (harness/function-definition.json). This is one-time,
# static content (function name/runtime/handler/role never change per
# deployment) so it's generated here by local `tofu apply` rather than by
# the pipeline. The Harness *service* itself (serviceDefinition.type =
# AwsLambda, referencing this manifest + the S3 artifact) is now created by
# the IACM workspace's Terraform run (see iacm/main.tf) instead of here -
# that's the "Create Lambda and Service" step of the CI -> IACM -> Test
# pipeline (see harness_pipeline.tf).
#
# NOTE: every field in a Harness AwsLambdaFunctionDefinition manifest must be
# camelCase (functionName, runtime, handler, role, timeout, memorySize) -
# Harness injects the deployment package (from the service's primary S3
# artifact source) automatically; do NOT add a code/S3Bucket/S3Key block.

resource "local_file" "lambda_function_definition" {
  filename        = "${path.module}/harness/function-definition.json"
  file_permission = "0644"
  content = templatefile("${path.module}/templates/function-definition.json.tftpl", {
    function_name = var.function_name
    runtime       = var.runtime
    handler       = var.handler
    role_arn      = aws_iam_role.lambda_exec.arn
    timeout       = var.timeout
    memory_size   = var.memory_size
  })
}
