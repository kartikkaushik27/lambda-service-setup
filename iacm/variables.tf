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
    aws_connector_id    = string
    github_branch       = optional(string, "main")
  })
}

# Auto-discovered lambdas: a comma-separated list of lambda-src/<project>/*
# directory names, set as a workspace-level Terraform variable by the
# pipeline's "Create Workspaces" step every run (not part of the committed
# tfvars file) - so adding or removing a lambda-src directory is the entire
# workflow for adding or removing a lambda. Its artifact is assumed to live
# at <project>/<name>/lambda.zip in var.artifact_buckets[var.region].
variable "lambda_names" {
  description = "Comma-separated lambda-src/<project>/* directory names this workspace deploys, auto-discovered per run."
  type        = string
  default     = ""
}

# One bucket per region this project is ever deployed to (AWS requires a
# Lambda's S3 source to live in the same region as the function) - small and
# static, so it stays in the committed tfvars file.
variable "artifact_buckets" {
  description = "S3 bucket holding every lambda's artifact for this project, keyed by region."
  type        = map(string)
  default     = {}
}

# Legacy escape hatch only: pins identifiers for a project migrated onto this
# schema from hand-named resources, so it isn't renamed/recreated. New
# projects should rely on lambda_names auto-discovery instead and never need
# this - see environments/demo-project.tfvars (none) vs environments/lambda-service-poc.tfvars (uses it).
variable "lambdas" {
  description = "Explicit per-lambda overrides, keyed the same as lambda_names would auto-discover. Only needed to pin pre-existing identifiers."

  type = map(object({
    artifact_by_region = optional(map(object({
      bucket = string
      key    = string
    })))
    function_definition_path   = optional(string)
    artifact_source_type       = optional(string, "AmazonS3")
    function_name               = optional(string)
    service_identifier          = optional(string)
    artifact_source_identifier  = optional(string)
  }))

  default = {}
}

variable "tags" {
  description = "Tags applied to every AWS resource created here."
  type        = map(string)
  default     = {}
}
