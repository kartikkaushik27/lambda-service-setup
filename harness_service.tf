# Harness "native" AWS Lambda service: a built-in Harness deployment type
# (serviceDefinition.type = AwsLambda) rather than a custom script service.
# The function definition manifest lives in the GitHub repo this project
# creates (harness/function-definition.json, generated from
# templates/function-definition.json.tftpl below); the deployment package
# (zip) is pulled from the S3 bucket provisioned in aws.tf.
#
# NOTE: every field in a Harness AwsLambdaFunctionDefinition manifest must be
# camelCase (functionName, runtime, handler, role, timeout, memorySize) -
# Harness injects the deployment package (from the service's primary S3
# artifact source) automatically; do NOT add a code/S3Bucket/S3Key block.
# Values here are rendered as literals from the current variables.tf values.
# Whenever you change those variables, re-run `tofu apply` and push the
# regenerated harness/function-definition.json to git.

resource "local_file" "lambda_function_definition" {
  filename = "${path.module}/harness/function-definition.json"
  content = templatefile("${path.module}/templates/function-definition.json.tftpl", {
    function_name = var.function_name
    runtime       = var.runtime
    handler       = var.handler
    role_arn      = aws_iam_role.lambda_exec.arn
    timeout       = var.timeout
    memory_size   = var.memory_size
  })
}

locals {
  lambda_service_yaml = <<-YAML
    service:
      name: ${var.function_name}
      identifier: lambda_service
      orgIdentifier: ${var.harness_org_id}
      projectIdentifier: ${harness_platform_project.this.identifier}
      serviceDefinition:
        type: AwsLambda
        spec:
          manifests:
            - manifest:
                identifier: lambdaFunctionDefinition
                type: AwsLambdaFunctionDefinition
                spec:
                  store:
                    type: Github
                    spec:
                      connectorRef: ${harness_platform_connector_github.this.identifier}
                      gitFetchType: Branch
                      branch: ${var.github_branch}
                      paths:
                        - harness/function-definition.json
          artifacts:
            primary:
              primaryArtifactRef: awslambdaartifact
              sources:
                - identifier: awslambdaartifact
                  type: AmazonS3
                  spec:
                    connectorRef: ${harness_platform_connector_aws.this.identifier}
                    region: ${var.aws_region}
                    bucketName: ${aws_s3_bucket.lambda_artifacts.id}
                    filePath: ${aws_s3_object.lambda_package.key}
  YAML
}

resource "harness_platform_service" "this" {
  identifier = "lambda_service"
  name       = var.function_name
  org_id     = var.harness_org_id
  project_id = harness_platform_project.this.identifier
  yaml       = local.lambda_service_yaml

  depends_on = [
    harness_platform_connector_github.this,
    harness_platform_connector_aws.this,
    aws_s3_object.lambda_package,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    local_file.lambda_function_definition,
  ]
}
