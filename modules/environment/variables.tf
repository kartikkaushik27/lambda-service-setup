variable "org_id" {
  description = "Harness organization identifier."
  type        = string
}

variable "project_id" {
  description = "Harness project identifier."
  type        = string
}

variable "environment_identifier" {
  description = "Harness environment identifier. Scope this by project/environment/region when the same Harness project hosts more than one deployment target with the same environment name."
  type        = string
}

variable "environment_name" {
  description = "Display name for the Harness environment."
  type        = string
}

variable "environment_type" {
  description = "PreProduction or Production."
  type        = string
  default     = "PreProduction"

  validation {
    condition     = contains(["PreProduction", "Production"], var.environment_type)
    error_message = "environment_type must be PreProduction or Production."
  }
}

variable "infra_identifier" {
  description = "Harness infrastructure definition identifier."
  type        = string
}

variable "infra_name" {
  description = "Display name for the infrastructure definition."
  type        = string
}

variable "aws_connector_id" {
  description = "Existing Harness AWS connector the infrastructure definition deploys through."
  type        = string
}

variable "aws_region" {
  description = "AWS region this deployment target's Lambda functions live in."
  type        = string
}
