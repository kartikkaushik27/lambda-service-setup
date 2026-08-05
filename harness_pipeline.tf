# Three-stage pipeline:
#   1. CI    - Build Artifact:     zips lambda-src/ and uploads it to S3.
#   2. IACM  - Create Lambda and Service: runs Terraform (iacm/*.tf) which
#              creates/updates the real aws_lambda_function *and* the
#              Harness native AWS Lambda service entity.
#   3. CI    - Test Lambda Deployment: invokes the deployed function and
#              fails the pipeline if it doesn't respond as expected.
#
# All three stages run on Harness Cloud (hosted runners) - no delegate is
# required to run this pipeline.

locals {
  lambda_pipeline_yaml = <<-YAML
    pipeline:
      name: Lambda CI-IACM-Test Pipeline
      identifier: deploy_lambda_pipeline
      projectIdentifier: ${harness_platform_project.this.identifier}
      orgIdentifier: ${var.harness_org_id}
      tags: {}
      properties:
        ci:
          codebase:
            connectorRef: ${harness_platform_connector_github.this.identifier}
            repoName: ${var.github_repo_name}
            build: <+input>
      variables:
        - name: function_name
          type: String
          value: ${var.function_name}
        - name: s3_bucket
          type: String
          value: ${aws_s3_bucket.lambda_artifacts.id}
        - name: s3_key
          type: String
          value: ${local.lambda_artifact_key}
        - name: aws_region
          type: String
          value: ${var.aws_region}
      stages:
        - stage:
            name: Build Artifact
            identifier: build_artifact
            description: "CI stage - very simple, just for reference to the next stages: zips lambda-src/ and uploads it to S3."
            type: CI
            spec:
              cloneCodebase: true
              platform:
                os: Linux
                arch: Amd64
              runtime:
                type: Cloud
                spec: {}
              execution:
                steps:
                  - step:
                      type: Run
                      name: Zip and Upload Lambda Artifact
                      identifier: zip_and_upload
                      spec:
                        shell: Sh
                        image: alpine:3.19
                        command: |-
                          set -e
                          apk add --no-cache zip aws-cli >/dev/null
                          cd lambda-src
                          zip -r -q ../lambda.zip .
                          cd ..
                          aws s3 cp lambda.zip "s3://<+pipeline.variables.s3_bucket>/<+pipeline.variables.s3_key>" --region <+pipeline.variables.aws_region>
                          echo "Uploaded artifact to s3://<+pipeline.variables.s3_bucket>/<+pipeline.variables.s3_key>"
                        envVariables:
                          AWS_ACCESS_KEY_ID: <+secrets.getValue("aws_access_key_id")>
                          AWS_SECRET_ACCESS_KEY: <+secrets.getValue("aws_secret_access_key")>
                          AWS_SESSION_TOKEN: <+secrets.getValue("aws_session_token")>
            tags: {}
        - stage:
            name: Create Lambda and Service
            identifier: create_lambda_and_service
            description: "IACM stage - runs Terraform to create the AWS Lambda function and the Harness native AWS Lambda service."
            type: IACM
            spec:
              workspace: ${harness_platform_workspace.lambda.identifier}
              platform:
                os: Linux
                arch: Amd64
              runtime:
                type: Cloud
                spec: {}
              execution:
                steps:
                  - step:
                      type: IACMTerraformPlugin
                      name: init
                      identifier: init
                      spec:
                        command: init
                  - step:
                      type: IACMTerraformPlugin
                      name: plan
                      identifier: plan
                      spec:
                        command: plan
                  - step:
                      type: IACMTerraformPlugin
                      name: apply
                      identifier: apply
                      spec:
                        command: apply
            tags: {}
        - stage:
            name: Test Lambda Deployment
            identifier: test_lambda_deployment
            description: "Invokes the deployed Lambda function and fails the pipeline if the response isn't healthy."
            type: CI
            spec:
              cloneCodebase: false
              platform:
                os: Linux
                arch: Amd64
              runtime:
                type: Cloud
                spec: {}
              execution:
                steps:
                  - step:
                      type: Run
                      name: Invoke and Verify Lambda
                      identifier: invoke_and_verify
                      spec:
                        shell: Sh
                        image: alpine:3.19
                        command: |-
                          set -e
                          apk add --no-cache aws-cli >/dev/null
                          aws lambda invoke --function-name "<+pipeline.variables.function_name>" --payload '{}' --cli-binary-format raw-in-base64-out /tmp/out.json --region <+pipeline.variables.aws_region>
                          echo "---- Lambda response body ----"
                          cat /tmp/out.json
                          echo ""
                          if grep -Eq '"statusCode":[[:space:]]*200' /tmp/out.json; then
                            echo "PASS: Lambda invocation returned statusCode 200"
                          else
                            echo "FAIL: unexpected Lambda response"
                            exit 1
                          fi
                        envVariables:
                          AWS_ACCESS_KEY_ID: <+secrets.getValue("aws_access_key_id")>
                          AWS_SECRET_ACCESS_KEY: <+secrets.getValue("aws_secret_access_key")>
                          AWS_SESSION_TOKEN: <+secrets.getValue("aws_session_token")>
            tags: {}
  YAML
}

resource "harness_platform_pipeline" "this" {
  identifier = "deploy_lambda_pipeline"
  name       = "Lambda CI-IACM-Test Pipeline"
  org_id     = var.harness_org_id
  project_id = harness_platform_project.this.identifier
  yaml       = local.lambda_pipeline_yaml

  depends_on = [
    harness_platform_workspace.lambda,
  ]
}
