# Every input is supplied either by the project's committed tfvars file
# (environments/<project_name>.tfvars, linked to the workspace as a Git
# variable file) or, for region/environment, as workspace-level variables set
# when the workspace was created - see modules/environment and the pipeline
# that creates these workspaces (environment_pipeline.tf).
#
# There is deliberately no credential variable: the AWS and Harness providers
# read theirs from the environment, so a credential can never end up in a plan
# file.

variable "project_name" {
  description = "Logical project name. Scopes every Harness identifier this workspace creates, so two projects deployed to the same environment/region never collide. Matches the environments/*.tfvars filename by convention."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,39}$", var.project_name))
    error_message = "project_name must be lowercase alphanumeric with hyphens, up to 40 characters."
  }
}

# Set as a workspace-level Terraform variable when the workspace is created -
# one workspace is one region, so this is never part of the shared project
# tfvars file.
variable "region" {
  description = "AWS region this workspace's Lambda functions, service artifacts and infrastructure definition live in."
  type        = string
}

# Also a workspace-level variable, not part of the project tfvars file: the
# same tfvars file is reused by every environment/region workspace for this
# project, so the environment it's deployed to is never something the file
# itself can declare.
variable "environment_name" {
  description = "Environment this workspace deploys to. One of dev, test, stage, prod - the Git branch that owns this workspace."
  type        = string

  validation {
    condition     = contains(["dev", "test", "stage", "prod"], var.environment_name)
    error_message = "environment_name must be one of dev, test, stage, prod."
  }
}

# The original project's environment/infrastructure definitions are created
# by the root config instead (see harness.tf), since its pipeline's native
# AwsLambdaDeploy stage needs their identifiers at root-apply time, before
# this workspace exists. Its workspace sets both flags below to false so its
# own run creates neither.
#
# Every self-service project needs the two flags to differ, though: the
# environment is shared by every region a (project, environment_name) is
# deployed to, but each region is a separate workspace with a separate
# Terraform state, so only one workspace may create the shared environment
# (manage_environment=true, set on exactly one region by the multi-env
# pipeline) while every region - including that one - always creates its own
# infrastructure definition (manage_infrastructure stays at its default).
variable "manage_environment" {
  description = "Whether this workspace creates the Harness environment shared by every region of this (project, environment_name)."
  type        = bool
  default     = true
}

variable "manage_infrastructure" {
  description = "Whether this workspace creates its own (region-specific) Harness infrastructure definition."
  type        = bool
  default     = true
}

variable "harness" {
  description = "Harness scope and existing connectors every lambda/service/environment in this workspace is created against."

  type = object({
    org_id              = string
    project_id          = string
    github_connector_id = string
    github_branch       = string
    aws_connector_id    = string
  })
}

# Multiple lambdas, keyed by a short slug used to derive every Harness/AWS
# identifier this workspace creates for that lambda (function name, service
# identifier, artifact source identifier). Add another entry to deploy
# another function from the same project/environment/region - see
# environments/*.tfvars.
variable "lambdas" {
  description = "Lambda functions this project deploys in this environment/region."

  type = map(object({
    runtime               = string
    handler               = string
    timeout               = number
    memory_size           = number
    execution_role_arn    = string
    architecture          = optional(string, "x86_64")
    publish_version       = optional(bool, true)
    environment_variables = optional(map(string), {})

    # Bring-your-own deployment package: this workspace deploys whatever is
    # already at this lambda's bucket/key for var.region. Keyed by region,
    # not a single bucket/key, because AWS requires a Lambda's S3 source to
    # live in the same region as the function - a project deployed to more
    # than one region needs the same build published to a bucket in each.
    artifact_by_region = map(object({
      bucket = string
      key    = string
    }))

    function_definition_path = optional(string)
    artifact_source_type     = optional(string, "AmazonS3")

    # AWS Lambda function names and Harness identifiers can't be renamed
    # in place - changing either forces a destroy and recreate. Every
    # identifier below defaults to a project/environment/region-scoped
    # convention, but stays overridable so a project can be migrated onto
    # this schema without renaming the resources it already has.
    function_name              = optional(string)
    service_identifier         = optional(string)
    artifact_source_identifier = optional(string)
  }))

  validation {
    condition     = length(var.lambdas) > 0
    error_message = "lambdas must declare at least one function."
  }
}

variable "tags" {
  description = "Tags applied to every AWS resource created here."
  type        = map(string)
  default     = {}
}
