variable "pipeline_identifier" {
  description = "Identifier of the pipeline."
  type        = string
  default     = "deploy_lambda_pipeline"
}

variable "pipeline_name" {
  description = "Display name of the pipeline."
  type        = string
  default     = "Lambda CI-IACM-Test Pipeline"
}

variable "org_id" {
  description = "Harness organization identifier."
  type        = string
}

variable "project_id" {
  description = "Harness project identifier."
  type        = string
}

variable "github_connector_id" {
  description = "Harness GitHub connector used to clone the codebase in the CI stages."
  type        = string
}

variable "github_repo_name" {
  description = "Repository the CI stages clone."
  type        = string
}

variable "workspace_id" {
  description = "IACM workspace the deployment stage runs."
  type        = string
}

variable "function_name" {
  description = "Lambda function the pipeline builds and verifies."
  type        = string
}

variable "artifact_bucket" {
  description = "S3 bucket the CI stage publishes the deployment package to."
  type        = string
}

variable "artifact_key" {
  description = "Stable S3 key the CI stage publishes to and the IACM stage deploys from."
  type        = string
}

variable "artifact_build_prefix" {
  description = "S3 prefix for immutable per-build packages. The CI stage publishes <prefix>/<build number>.zip and the deploy stage deploys that key."
  type        = string
}

variable "service_id" {
  description = "Harness service the deploy stage deploys. Created by the IACM stage, so this is the identifier it will use."
  type        = string
  default     = "lambda_service"
}

variable "artifact_source_id" {
  description = "Identifier of the service's primary artifact source, used when supplying its runtime input."
  type        = string
  default     = "awslambdaartifact"
}

variable "environment_id" {
  description = "Harness environment the deploy stage targets."
  type        = string
}

variable "infrastructure_id" {
  description = "Infrastructure definition the deploy stage targets."
  type        = string
}

variable "aws_region" {
  description = "Region the function and artifact bucket live in."
  type        = string
}

variable "ci_image" {
  description = "Container image the CI steps run in. Pin it so builds stay reproducible."
  type        = string
  default     = "alpine:3.19"
}

variable "step_timeout" {
  description = "Timeout applied to each step, in Harness duration format."
  type        = string
  default     = "10m"

  validation {
    condition     = can(regex("^[0-9]+(s|m|h)$", var.step_timeout))
    error_message = "step_timeout must be a Harness duration such as 30s, 10m or 1h."
  }
}

variable "credential_secret_ids" {
  description = "Identifiers of the Harness secrets holding the AWS credentials the CI steps use."
  type = object({
    aws_access_key_id     = string
    aws_secret_access_key = string
    aws_session_token     = string
  })
}
