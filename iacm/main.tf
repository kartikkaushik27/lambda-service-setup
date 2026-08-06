# Executed by every (project, environment, region) workspace on every run -
# this is the deployment.
#
# Two things per workspace:
#   - one Harness environment/infrastructure definition for this
#     (environment, region)
#   - one Harness service per entry in var.lambdas - modules/service
#
# The AWS Lambda function itself is NOT created here. Harness's native
# AwsLambdaDeploy step creates it on first deploy (from the committed
# function-definition.json) and updates it on every deploy after - so
# Terraform never touches the function, and there is nothing for it to
# race with.
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

  # Every lambda this workspace manages: auto-discovered lambda-src/*
  # directory names (var.lambda_names, set per run by the pipeline) plus any
  # explicit override keys (var.lambdas - legacy projects only).
  lambda_keys = toset(concat(
    [for n in split(",", var.lambda_names) : n if n != ""],
    keys(var.lambdas),
  ))
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

# One per (project, environment_name, region, lambda) - i.e. one per lambda
# this workspace manages, not one shared per region - so infra count always
# tracks lambda count 1:1. Every lambda's infra is identical (region +
# connector only; nothing lambda-specific), but kept separate per lambda so
# each can be retired independently as lambdas are added or removed. Not
# created at all for the legacy project, whose infra is created by the root
# config instead.
resource "harness_platform_infrastructure" "this" {
  for_each = var.manage_infrastructure ? local.lambda_keys : []

  identifier      = "${local.project_key}_${var.environment_name}_${local.region_key}_${each.key}"
  name            = "${var.project_name}-${var.environment_name}-${var.region}-${each.key}"
  org_id          = var.harness.org_id
  project_id      = var.harness.project_id
  env_id          = "${local.project_key}_${var.environment_name}"
  type            = "AwsLambda"
  deployment_type = "AwsLambda"

  yaml = yamlencode({
    infrastructureDefinition = {
      name              = "${var.project_name}-${var.environment_name}-${var.region}-${each.key}"
      identifier        = "${local.project_key}_${var.environment_name}_${local.region_key}_${each.key}"
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

# Drops the old Lambda-creation module from every workspace's state without
# destroying the functions it created - Harness's native deploy step now
# owns them going forward. Safe to delete this block (and the archive
# provider requirement above) once every workspace has applied at least once
# with it present.
removed {
  from = module.lambda

  lifecycle {
    destroy = false
  }
}

module "service" {
  source   = "../modules/service"
  for_each = local.lambda_keys

  service_identifier = coalesce(
    try(var.lambdas[each.key].service_identifier, null),
    "${local.project_key}_${each.key}_${var.environment_name}_${local.region_key}",
  )
  service_name = coalesce(
    try(var.lambdas[each.key].function_name, null),
    "${var.project_name}-${each.key}-${var.environment_name}",
  )
  org_id     = var.harness.org_id
  project_id = var.harness.project_id

  github_connector_id = var.harness.github_connector_id
  github_branch       = var.harness.github_branch

  # Convention: environments/<project>.tfvars is paired with a committed
  # manifest at harness/<project>/<lambda key>/<region>/function-definition.json,
  # unless the project overrides the path explicitly. The region segment is
  # required even though every region's copy is identical content - Harness
  # fetches manifests by git path once per pipeline execution, so a project
  # deploying the same lambda to 2 regions in one run (test/stage/prod) would
  # otherwise have both "Deploy Lambdas" iterations resolve the same cached
  # fetch, corrupting the <+repeat.item> function name expression for both.
  function_definition_path = coalesce(
    try(var.lambdas[each.key].function_definition_path, null),
    "harness/${var.project_name}/${each.key}/${var.region}/function-definition.json",
  )

  artifact_source_identifier = coalesce(
    try(var.lambdas[each.key].artifact_source_identifier, null),
    "${local.project_key}_${each.key}_artifact",
  )
  artifact_source_type = try(var.lambdas[each.key].artifact_source_type, "AmazonS3")
}
