# Deployment target for the native AWS Lambda deploy step: an environment and
# an AwsLambda infrastructure definition that names the AWS connector and
# region to deploy into.
#
# Long-lived, so it belongs to the root configuration rather than to the
# per-deployment OpenTofu in iacm/.

resource "harness_platform_environment" "this" {
  identifier = var.environment_identifier
  name       = var.environment_name
  org_id     = var.org_id
  project_id = var.project_id
  type       = var.environment_type
}

locals {
  infrastructure_yaml = yamlencode({
    infrastructureDefinition = {
      name              = var.infrastructure_name
      identifier        = var.infrastructure_identifier
      orgIdentifier     = var.org_id
      projectIdentifier = var.project_id
      environmentRef    = harness_platform_environment.this.identifier
      deploymentType    = "AwsLambda"
      type              = "AwsLambda"
      spec = {
        connectorRef = var.aws_connector_id
        region       = var.aws_region
      }
      allowSimultaneousDeployments = false
    }
  })
}

resource "harness_platform_infrastructure" "this" {
  identifier      = var.infrastructure_identifier
  name            = var.infrastructure_name
  org_id          = var.org_id
  project_id      = var.project_id
  env_id          = harness_platform_environment.this.identifier
  type            = "AwsLambda"
  deployment_type = "AwsLambda"
  yaml            = local.infrastructure_yaml
}
