# Harness native AWS Lambda service (serviceDefinition.type = AwsLambda).
#
# The service describes *what* is deployed - the function definition manifest -
# and deliberately stores nothing about *where the artifact comes from*. Every
# field of the artifact source is a runtime input, filled in per execution by
# whatever stage built the package. That is what keeps the service independent
# of the artifact store: an S3 bucket today, a JFrog repository or a container
# registry tomorrow, with no change here.

locals {
  # A runtime input in Harness YAML. Kept as a name so the intent is obvious
  # wherever it appears below.
  runtime_input = "<+input>"

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
                  type       = var.artifact_source_type
                  spec = {
                    connectorRef = local.runtime_input
                    region       = local.runtime_input
                    bucketName   = local.runtime_input
                    filePath     = local.runtime_input
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
