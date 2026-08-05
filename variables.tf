# ---------------------------------------------------------------------------
# This file is the single source of truth for every input in the stack.
#
# Values consumed by the OpenTofu that runs inside the pipeline's IACM stage
# are rendered from here into iacm/config.auto.tfvars (see generated.tf), so
# there is exactly one place to change a setting and one diff to review.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Stack identity
# ---------------------------------------------------------------------------

variable "environment" {
  description = "Environment this stack represents. Applied as a tag and used in resource descriptions."
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
# Harness platform
# ---------------------------------------------------------------------------

variable "harness_endpoint" {
  description = "Harness API endpoint. Change this for a self-managed or non-default cluster."
  type        = string
  default     = "https://app.harness.io/gateway"
}

variable "harness_account_id" {
  description = "Harness account identifier."
  type        = string
  default     = "aBh2PBI0T1CYMmA6iQFosg"
}

variable "harness_platform_api_key" {
  description = "Harness API key. Supply via TF_VAR_harness_platform_api_key."
  type        = string
  sensitive   = true
}

variable "harness_org_id" {
  description = "Harness organization to create the project under."
  type        = string
  default     = "default"
}

variable "harness_project_id" {
  description = "Identifier of the Harness project."
  type        = string
  default     = "lambda_service_poc"
}

variable "harness_project_name" {
  description = "Display name of the Harness project."
  type        = string
  default     = "Lambda Service POC"
}

variable "harness_environment_type" {
  description = "Whether the Harness environment is treated as production."
  type        = string
  default     = "PreProduction"
}

variable "service_artifact_file_path" {
  description = "S3 key the Harness service deploys. \"<+input>\" makes it a runtime input, so the deploy stage supplies the package its CI stage just built. Set a literal key to pin the service to one package instead."
  type        = string
  default     = "<+input>"
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
