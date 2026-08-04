# Harness "native" AWS Lambda service: a built-in Harness deployment type
# (serviceDefinition.type = AwsLambda) rather than a custom script service.
# The function definition manifest lives in the GitHub repo this project
# creates (harness/function-definition.json); the deployment package (zip)
# is pulled from the S3 bucket provisioned in aws.tf.

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
          variables:
            - name: function_name
              type: String
              value: ${var.function_name}
            - name: runtime
              type: String
              value: ${var.runtime}
            - name: handler
              type: String
              value: ${var.handler}
            - name: lambda_role_arn
              type: String
              value: ${aws_iam_role.lambda_exec.arn}
            - name: memory_size
              type: Number
              value: "${var.memory_size}"
            - name: timeout
              type: Number
              value: "${var.timeout}"
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
  ]
}
