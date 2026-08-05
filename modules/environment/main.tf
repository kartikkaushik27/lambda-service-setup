# Harness Environment + AwsLambda Infrastructure Definition: the deployment
# target a native AwsLambdaDeploy step needs.
#
# One instance of this module is one (environment name, region) deployment
# target. Called once from the root config for the original project, and
# once per (project, environment, region) from inside iacm/ for every
# self-service project - see iacm/main.tf.

resource "harness_platform_environment" "this" {
  identifier = var.environment_identifier
  name       = var.environment_name
  org_id     = var.org_id
  project_id = var.project_id
  type       = var.environment_type
}

resource "harness_platform_infrastructure" "this" {
  identifier      = var.infra_identifier
  name            = var.infra_name
  org_id          = var.org_id
  project_id      = var.project_id
  env_id          = harness_platform_environment.this.identifier
  type            = "AwsLambda"
  deployment_type = "AwsLambda"

  yaml = yamlencode({
    infrastructureDefinition = {
      name              = var.infra_name
      identifier        = var.infra_identifier
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
