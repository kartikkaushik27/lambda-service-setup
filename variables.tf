# ---------------------------------------------------------------------------
# Lambda function variables
# ---------------------------------------------------------------------------

variable "function_name" {
  description = "Name of the AWS Lambda function (also used to derive the IAM role and S3 bucket names)."
  type        = string
  default     = "lambda-service-poc"
}

variable "runtime" {
  description = "AWS Lambda runtime identifier."
  type        = string
  default     = "nodejs20.x"
}

variable "handler" {
  description = "Lambda function handler (file.export)."
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

variable "lambda_environment_variables" {
  description = "Environment variables to expose to the Lambda function at runtime."
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region to create the Lambda function and supporting resources in."
  type        = string
  default     = "us-east-1"
}

# ---------------------------------------------------------------------------
# AWS credentials (sensitive - supply via TF_VAR_* env vars, never commit)
# ---------------------------------------------------------------------------

variable "aws_access_key_id" {
  description = "AWS access key ID (temporary STS session credentials)."
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key (temporary STS session credentials)."
  type        = string
  sensitive   = true
}

variable "aws_session_token" {
  description = "AWS session token (temporary STS session credentials)."
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Harness platform variables
# ---------------------------------------------------------------------------

variable "harness_account_id" {
  description = "Harness account identifier."
  type        = string
  default     = "aBh2PBI0T1CYMmA6iQFosg"
}

variable "harness_platform_api_key" {
  description = "Harness Personal Access Token used to authenticate the Harness provider."
  type        = string
  sensitive   = true
}

variable "harness_org_id" {
  description = "Harness organization identifier to create the project under."
  type        = string
  default     = "default"
}

variable "harness_project_id" {
  description = "Identifier for the new Harness project."
  type        = string
  default     = "lambda_service_poc"
}

variable "harness_project_name" {
  description = "Display name for the new Harness project."
  type        = string
  default     = "Lambda Service POC"
}

# ---------------------------------------------------------------------------
# GitHub variables
# ---------------------------------------------------------------------------

variable "github_owner" {
  description = "GitHub user/org that will own the new repository."
  type        = string
  default     = "kartikkaushik27"
}

variable "github_repo_name" {
  description = "Name of the GitHub repository to create for this OpenTofu project."
  type        = string
  default     = "lambda-service-setup"
}

variable "github_branch" {
  description = "Default branch of the GitHub repository (used by the Harness GitHub connector to fetch the Lambda function definition manifest)."
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "GitHub Personal Access Token, used by the github provider and stored as a Harness secret for the GitHub connector."
  type        = string
  sensitive   = true
}
