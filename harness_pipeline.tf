# A single Deploy stage using Harness's native AWS Lambda deployment type.
# Running this pipeline is what actually calls the AWS API to create/update
# the Lambda function (via the AwsLambdaDeploy step).

locals {
  deploy_lambda_pipeline_yaml = <<-YAML
    pipeline:
      name: Deploy Lambda
      identifier: deploy_lambda_pipeline
      projectIdentifier: ${harness_platform_project.this.identifier}
      orgIdentifier: ${var.harness_org_id}
      tags: {}
      stages:
        - stage:
            name: Deploy Lambda
            identifier: deploy_lambda
            description: "Creates/updates the AWS Lambda function via Harness's native AWS Lambda deployment"
            type: Deployment
            spec:
              deploymentType: AwsLambda
              service:
                serviceRef: ${harness_platform_service.this.identifier}
              environment:
                environmentRef: ${harness_platform_environment.dev.identifier}
                infrastructureDefinitions:
                  - identifier: ${harness_platform_infrastructure.lambda.identifier}
              execution:
                steps:
                  - step:
                      name: AWS Lambda Deploy
                      identifier: AWS_Lambda_Deploy
                      type: AwsLambdaDeploy
                      timeout: 10m
                      spec: {}
                rollbackSteps:
                  - step:
                      name: AWS Lambda Rollback
                      identifier: AWS_Lambda_Rollback
                      type: AwsLambdaRollback
                      timeout: 10m
                      spec: {}
            failureStrategies:
              - onFailure:
                  errors:
                    - AllErrors
                  action:
                    type: StageRollback
            tags: {}
  YAML
}

resource "harness_platform_pipeline" "this" {
  identifier = "deploy_lambda_pipeline"
  name       = "Deploy Lambda"
  org_id     = var.harness_org_id
  project_id = harness_platform_project.this.identifier
  yaml       = local.deploy_lambda_pipeline_yaml

  depends_on = [
    harness_platform_service.this,
    harness_platform_infrastructure.lambda,
  ]
}
