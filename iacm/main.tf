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

module "environment" {
  source = "../modules/environment"
  count  = var.manage_environment ? 1 : 0

  org_id     = var.harness.org_id
  project_id = var.harness.project_id

  environment_identifier = "${local.project_key}_${var.environment_name}"
  environment_name       = "${var.project_name}-${var.environment_name}"
  environment_type       = local.environment_type

  infra_identifier = "${local.project_key}_${var.environment_name}_${local.region_key}"
  infra_name       = "${var.project_name}-${var.environment_name}-${var.region}"

  aws_connector_id = var.harness.aws_connector_id
  aws_region       = var.region
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

  artifact_bucket = each.value.artifact_by_region[var.region].bucket
  artifact_key    = each.value.artifact_by_region[var.region].key
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
