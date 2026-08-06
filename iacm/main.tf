# Executed by every (project, environment, region) workspace on every run -
# this is the deployment.
#
# Three modules per workspace:
#   - one Harness environment/infrastructure definition for this
#     (environment, region) - modules/environment
#   - one Lambda function per entry in var.lambdas - modules/lambda
#   - one Harness service per entry in var.lambdas - modules/service
#
# Inputs come from the project's committed tfvars file
# (environments/<project_name>.tfvars) plus the region/environment_name
# workspace-level variables set when the workspace was created. Credentials
# come from environment variables supplied by the workspace's credentials
# variable set, so this configuration declares no credential variables.

locals {
  # Harness/AWS identifiers only allow letters, numbers and underscores - the
  # project name is free-form (hyphens allowed, matching the tfvars filename
  # convention), so every identifier built from it goes through this first.
  project_key = replace(var.project_name, "-", "_")
  region_key  = replace(var.region, "-", "_")

  environment_type = var.environment_name == "prod" ? "Production" : "PreProduction"
}

# The environment is shared by every region this (project, environment_name)
# deploys to, but each region is its own workspace with its own Terraform
# state - so only one of them may create it. The multi-env pipeline sets
# manage_environment=true on exactly one (the first region it provisions for
# a given project/branch, run before the others - see
# templates/multi-env-pipeline.yaml.tftpl); every other region's workspace
# leaves it false and only creates its own infrastructure definition below,
# referencing the environment by its (deterministic, not module-output)
# identifier.
resource "harness_platform_environment" "this" {
  count = var.manage_environment ? 1 : 0

  identifier = "${local.project_key}_${var.environment_name}"
  name       = "${var.project_name}-${var.environment_name}"
  org_id     = var.harness.org_id
  project_id = var.harness.project_id
  type       = local.environment_type
}

# One per (project, environment_name, region) - i.e. one per workspace that
# manages its own infrastructure (every self-service region; not the legacy
# project, whose infra is created by the root config instead).
resource "harness_platform_infrastructure" "this" {
  count = var.manage_infrastructure ? 1 : 0

  identifier      = "${local.project_key}_${var.environment_name}_${local.region_key}"
  name            = "${var.project_name}-${var.environment_name}-${var.region}"
  org_id          = var.harness.org_id
  project_id      = var.harness.project_id
  env_id          = "${local.project_key}_${var.environment_name}"
  type            = "AwsLambda"
  deployment_type = "AwsLambda"

  yaml = yamlencode({
    infrastructureDefinition = {
      name              = "${var.project_name}-${var.environment_name}-${var.region}"
      identifier        = "${local.project_key}_${var.environment_name}_${local.region_key}"
      orgIdentifier     = var.harness.org_id
      projectIdentifier = var.harness.project_id
      environmentRef    = "${local.project_key}_${var.environment_name}"
      deploymentType    = "AwsLambda"
      type              = "AwsLambda"
      spec = {
        connectorRef = var.harness.aws_connector_id
        region       = var.region
      }
      allowSimultaneousDeployments = false
    }
  })

  # Only a real Terraform dependency when this workspace also owns the
  # environment (count 0 otherwise) - cross-workspace ordering is handled by
  # the pipeline running the owning region's workspace to completion first.
  depends_on = [harness_platform_environment.this]
}

locals {
  # A stable string, not a resource reference, so it resolves whether or not
  # this workspace's own state contains the environment (see
  # harness_platform_environment.this above).
  environment_id = "${local.project_key}_${var.environment_name}"
}

module "lambda" {
  source   = "../modules/lambda"
  for_each = var.lambdas

  function_name = coalesce(
    each.value.function_name,
    "${var.project_name}-${each.key}-${var.environment_name}",
  )
  description        = "Deployed by Harness IACM from ${lookup(var.tags, "Repository", "OpenTofu")} (${var.project_name}/${each.key}/${var.environment_name}/${var.region})"
  execution_role_arn = each.value.execution_role_arn

  runtime      = each.value.runtime
  handler      = each.value.handler
  timeout      = each.value.timeout
  memory_size  = each.value.memory_size
  architecture = each.value.architecture

  environment_variables = each.value.environment_variables
  publish_version       = each.value.publish_version
}

module "service" {
  source   = "../modules/service"
  for_each = var.lambdas

  service_identifier = coalesce(
    each.value.service_identifier,
    "${local.project_key}_${each.key}_${var.environment_name}_${local.region_key}",
  )
  service_name = coalesce(
    each.value.function_name,
    "${var.project_name}-${each.key}-${var.environment_name}",
  )
  org_id     = var.harness.org_id
  project_id = var.harness.project_id

  github_connector_id = var.harness.github_connector_id
  github_branch       = var.harness.github_branch

  # Convention: environments/<project>.tfvars is paired with a committed
  # manifest at harness/<project>/<lambda key>/function-definition.json,
  # unless the project overrides the path explicitly.
  function_definition_path = coalesce(
    each.value.function_definition_path,
    "harness/${var.project_name}/${each.key}/function-definition.json",
  )

  artifact_source_identifier = coalesce(
    each.value.artifact_source_identifier,
    "${local.project_key}_${each.key}_artifact",
  )
  artifact_source_type = each.value.artifact_source_type

  # Each service describes a function that must already exist, so a failed
  # function deployment never leaves a service pointing at nothing.
  depends_on = [module.lambda]
}
