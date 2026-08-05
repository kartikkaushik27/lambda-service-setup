variable "org_id" {
  description = "Harness organization identifier."
  type        = string
}

variable "project_id" {
  description = "Harness project identifier."
  type        = string
}

variable "environment_identifier" {
  description = "Identifier of the Harness environment."
  type        = string
  default     = "dev"
}

variable "environment_name" {
  description = "Display name of the Harness environment."
  type        = string
  default     = "dev"
}

variable "environment_type" {
  description = "Whether the environment is production or not."
  type        = string
  default     = "PreProduction"

  validation {
    condition     = contains(["PreProduction", "Production"], var.environment_type)
    error_message = "environment_type must be PreProduction or Production."
  }
}

variable "infrastructure_identifier" {
  description = "Identifier of the infrastructure definition."
  type        = string
  default     = "lambda_infra"
}

variable "infrastructure_name" {
  description = "Display name of the infrastructure definition."
  type        = string
  default     = "lambda-infra"
}

variable "aws_connector_id" {
  description = "Harness AWS connector the deploy step authenticates with."
  type        = string
}

variable "aws_region" {
  description = "Region to deploy the function into."
  type        = string
}
