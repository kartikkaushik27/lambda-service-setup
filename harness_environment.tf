resource "harness_platform_environment" "dev" {
  identifier = "dev"
  name       = "dev"
  org_id     = var.harness_org_id
  project_id = harness_platform_project.this.identifier
  type       = "PreProduction"
}

locals {
  lambda_infra_yaml = <<-YAML
    infrastructureDefinition:
      name: lambda-infra
      identifier: lambda_infra
      orgIdentifier: ${var.harness_org_id}
      projectIdentifier: ${harness_platform_project.this.identifier}
      environmentRef: ${harness_platform_environment.dev.identifier}
      deploymentType: AwsLambda
      type: AwsLambda
      spec:
        connectorRef: ${harness_platform_connector_aws.this.identifier}
        region: ${var.aws_region}
      allowSimultaneousDeployments: false
  YAML
}

resource "harness_platform_infrastructure" "lambda" {
  identifier      = "lambda_infra"
  name            = "lambda-infra"
  org_id          = var.harness_org_id
  project_id      = harness_platform_project.this.identifier
  env_id          = harness_platform_environment.dev.identifier
  type            = "AwsLambda"
  deployment_type = "AwsLambda"
  yaml            = local.lambda_infra_yaml
}
