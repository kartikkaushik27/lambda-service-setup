# Reads whichever object the pipeline's CI stage most recently uploaded.
# Since the S3 bucket has versioning enabled, `version_id` changes on every
# CI upload - passing it as s3_object_version below is what makes Terraform
# detect a code change and update the Lambda function on each pipeline run
# (the bucket/key themselves never change).
data "aws_s3_object" "lambda_zip" {
  bucket = var.s3_bucket
  key    = var.s3_key
}

# ---------------------------------------------------------------------------
# "Create Lambda": the actual AWS Lambda function, created/updated directly
# by this Terraform run (executed by the pipeline's IACM stage).
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.lambda_role_arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = tonumber(var.timeout)
  memory_size   = tonumber(var.memory_size)

  s3_bucket         = var.s3_bucket
  s3_key            = var.s3_key
  s3_object_version = data.aws_s3_object.lambda_zip.version_id
}

# ---------------------------------------------------------------------------
# "Create Service": the Harness native AWS Lambda service entity, so the
# deployment is also visible/tracked in Harness (Services page), pointing at
# the same manifest + S3 artifact used above.
# ---------------------------------------------------------------------------
locals {
  lambda_service_yaml = <<-YAML
    service:
      name: ${var.function_name}
      identifier: lambda_service
      orgIdentifier: ${var.harness_org_id}
      projectIdentifier: ${var.harness_project_id}
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
                      connectorRef: ${var.github_connector_id}
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
                    connectorRef: ${var.aws_connector_id}
                    region: ${var.aws_region}
                    bucketName: ${var.s3_bucket}
                    filePath: ${var.s3_key}
  YAML
}

resource "harness_platform_service" "this" {
  identifier = "lambda_service"
  name       = var.function_name
  org_id     = var.harness_org_id
  project_id = var.harness_project_id
  yaml       = local.lambda_service_yaml

  depends_on = [aws_lambda_function.this]
}
