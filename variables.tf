# The single source of truth for every input.
#
# Values used by the OpenTofu that runs inside the pipeline are rendered from
# here into iacm/config.auto.tfvars, so there is one place to change a setting
# and one diff to review.

# ---------------------------------------------------------------------------
# Existing Harness resources.
#
# These are platform plumbing owned outside this stack - the project and the
# connectors are expected to exist already, and are referenced by identifier.
# ---------------------------------------------------------------------------

variable "harness_account_id" {
  description = "Harness account identifier."
  type        = string
  default     = "aBh2PBI0T1CYMmA6iQFosg"
}

variable "harness_org_id" {
  description = "Harness organization holding the project."
  type        = string
  default     = "default"
}

variable "harness_project_id" {
  description = "Existing Harness project this stack is created in."
  type        = string
  default     = "lambda_service_poc"
}

variable "aws_connector_id" {
  description = "Existing Harness AWS connector. Used by the infrastructure definition and as the connector the service reads its artifact through."
  type        = string
  default     = "aws_lambda_connector"
}

variable "github_connector_id" {
  description = "Existing Harness GitHub connector. Used to clone the codebase, fetch the function definition manifest, and check out the IACM workspace."
  type        = string
  default     = "github_connector"
}

variable "harness_environment_type" {
  description = "Whether the Harness environment is treated as production."
  type        = string
  default     = "PreProduction"
}

variable "harness_platform_api_key" {
  description = "Harness API key. Supply via TF_VAR_harness_platform_api_key."
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Stack identity
# ---------------------------------------------------------------------------

variable "environment" {
  description = "Environment this stack represents. Names the Harness environment and is applied as a tag."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,15}$", var.environment))
    error_message = "environment must be lowercase alphanumeric with hyphens, up to 16 characters."
  }
}

variable "owner" {
  description = "Team or individual accountable for the stack. Applied as a tag."
  type        = string
  default     = "platform-engineering"
}

variable "additional_tags" {
  description = "Extra AWS tags merged into the tags applied to every resource."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Lambda function
# ---------------------------------------------------------------------------

variable "function_name" {
  description = "Name of the AWS Lambda function. Also seeds the IAM role, log group and artifact bucket names."
  type        = string
  default     = "lambda-service-poc"
}

variable "runtime" {
  description = "AWS Lambda runtime identifier."
  type        = string
  default     = "nodejs20.x"
}

variable "handler" {
  description = "Lambda function handler, in file.export form."
  type        = string
  default     = "index.handler"
}

variable "memory_size" {
  description = "Memory (MB) allocated to the Lambda function."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Lambda function timeout in seconds."
  type        = number
  default     = 10
}

variable "lambda_architecture" {
  description = "Instruction set the function runs on: x86_64 or arm64."
  type        = string
  default     = "x86_64"
}

variable "lambda_environment_variables" {
  description = "Environment variables exposed to the Lambda function at runtime."
  type        = map(string)
  default     = {}
}

variable "lambda_publish_version" {
  description = "Publish an immutable numbered version on each code change, so an earlier build can be re-pointed to."
  type        = bool
  default     = true
}

variable "lambda_additional_policy_arns" {
  description = "Extra managed policy ARNs to attach to the execution role beyond basic execution."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the function's log group."
  type        = number
  default     = 30
}

# ---------------------------------------------------------------------------
# Artifact storage
# ---------------------------------------------------------------------------

variable "artifact_retention_days" {
  description = "Days to keep superseded deployment packages before expiring them."
  type        = number
  default     = 90
}

variable "artifact_bucket_force_destroy" {
  description = "Allow `tofu destroy` to delete the artifact bucket while it still holds packages. Only enable for throwaway environments."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# AWS
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to create the Lambda function and supporting resources in."
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key_id" {
  description = "AWS access key id (short-lived STS credentials). Supply via TF_VAR_aws_access_key_id."
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key (short-lived STS credentials). Supply via TF_VAR_aws_secret_access_key."
  type        = string
  sensitive   = true
}

variable "aws_session_token" {
  description = "AWS session token (short-lived STS credentials). Supply via TF_VAR_aws_session_token."
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Pipeline and IACM workspace
# ---------------------------------------------------------------------------

variable "ci_image" {
  description = "Container image the CI steps run in."
  type        = string
  default     = "alpine:3.19"
}

variable "step_timeout" {
  description = "Timeout applied to each pipeline step, in Harness duration format."
  type        = string
  default     = "10m"
}

variable "cost_estimation_enabled" {
  description = "Show cost estimates alongside IACM plans."
  type        = bool
  default     = true
}

variable "provisioner_version" {
  description = "OpenTofu version the IACM workspace runs. \"latest\" tracks whatever Harness ships; pin an exact version once you have confirmed it is available to your account."
  type        = string
  default     = "latest"
}

# ---------------------------------------------------------------------------
# Multi-environment pipeline (multi_env_pipeline.tf)
#
# One pipeline, triggered by pushes to dev/test/stage/prod, that creates one
# IACM workspace per (project, region) the branch owns and runs every stage
# after that as a Harness looping strategy over those workspaces - see
# templates/multi-env-pipeline.yaml.tftpl for the full flow.
# ---------------------------------------------------------------------------

variable "multi_env_workspace_step_timeout" {
  description = "Timeout for the script step that creates/updates every IACM workspace for the triggering branch, in Harness duration format."
  type        = string
  default     = "5m"
}

variable "multi_env_iacm_step_timeout" {
  description = "Timeout for each init/plan/apply step in the repeated IACM stage."
  type        = string
  default     = "15m"
}

variable "multi_env_max_concurrency" {
  description = "How many validations the Validate Lambdas stage runs in parallel. Each iteration is just a read-only invoke against an already-deployed function, so this can safely run wider."
  type        = number
  default     = 3
}

variable "multi_env_deploy_max_concurrency" {
  description = "How many AwsLambdaDeploy iterations the Deploy Lambdas stage runs in parallel. Must stay 1: Harness resolves <+repeat.item> inside the git-fetched function-definition.json manifest per-iteration, and concurrent iterations of that resolution have been observed to cross-contaminate (one deploy targeting another iteration's function name), so deploys must be serialized."
  type        = number
  default     = 1
}

variable "multi_env_iacm_max_concurrency" {
  description = "How many IACM workspace applies the Create Lambda and Service stage runs in parallel. Must stay 1: the first region processed for each project creates the Harness environment every other region's workspace references, so regions cannot run concurrently."
  type        = number
  default     = 1
}

# ---------------------------------------------------------------------------
# GitHub
# ---------------------------------------------------------------------------

variable "github_owner" {
  description = "GitHub user or organization that owns the repository."
  type        = string
  default     = "kartikkaushik27"
}

variable "github_repo_name" {
  description = "Repository holding this configuration, the function source, and the OpenTofu the pipeline runs."
  type        = string
  default     = "lambda-service-setup"
}

variable "github_branch" {
  description = "Branch the Harness connector and IACM workspace read from."
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "GitHub personal access token. Supply via TF_VAR_github_token."
  type        = string
  sensitive   = true
}
