# Harness native AWS Lambda service (serviceDefinition.type = AwsLambda).
#
# The function definition manifest is fetched from Git and the deployment
# package from S3, which is what makes the deployed function visible on the
# Harness Services page and available to Harness-native deploy steps.

locals {
  service_yaml = yamlencode({
    service = {
      name              = var.service_name
      identifier        = var.service_identifier
      orgIdentifier     = var.org_id
      projectIdentifier = var.project_id
      serviceDefinition = {
        type = "AwsLambda"
        spec = {
          manifests = [
            {
              manifest = {
                identifier = "lambdaFunctionDefinition"
                type       = "AwsLambdaFunctionDefinition"
                spec = {
                  store = {
                    type = "Github"
                    spec = {
                      connectorRef = var.github_connector_id
                      gitFetchType = "Branch"
                      branch       = var.github_branch
                      paths        = [var.function_definition_path]
                    }
                  }
                }
              }
            }
          ]
          artifacts = {
            primary = {
              primaryArtifactRef = var.artifact_source_identifier
              sources = [
                {
                  identifier = var.artifact_source_identifier
                  type       = "AmazonS3"
                  spec = {
                    connectorRef = var.aws_connector_id
                    region       = var.aws_region
                    bucketName   = var.artifact_bucket

                    # Left as "<+input>" by default, so the package to deploy
                    # is chosen per execution rather than baked into the
                    # service - the pipeline supplies the key its CI stage
                    # just published.
                    filePath = var.artifact_file_path
                  }
                }
              ]
            }
          }
        }
      }
    }
  })
}

resource "harness_platform_service" "this" {
  identifier = var.service_identifier
  name       = var.service_name
  org_id     = var.org_id
  project_id = var.project_id
  yaml       = local.service_yaml
}
